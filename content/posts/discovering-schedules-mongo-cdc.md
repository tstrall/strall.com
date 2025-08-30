---
title: "Discovering Schedules and Dependencies from Mongo Change Streams"
date: 2025-08-30
draft: false
tags: ["MongoDB", "Change Data Capture", "ClickHouse", "Monitoring", "Self-Discovery"]
---

Many systems already know a lot about themselves — you just have to listen.  
MongoDB change streams (CDC) emit a continuous feed of inserts, updates, and deletes. With a little routing into a fast analytical database like **ClickHouse**, you can let the system “discover itself”: jobs, runs, schedules, dependencies, and even the fingerprints of human intervention.

---

## 1. Capture the Raw Feed

First, set up a connector:

```
MongoDB → Kafka → ClickHouse
```

In ClickHouse, land the JSON envelopes losslessly:

```sql
CREATE TABLE raw_cdc
(
  ts       DateTime64(3, 'UTC'),
  ns_db    LowCardinality(String),
  ns_coll  LowCardinality(String),
  op       LowCardinality(String),
  doc_id   String,
  full     String   -- full JSON document as string
)
ENGINE = MergeTree
PARTITION BY toYYYYMM(ts)
ORDER BY (ns_db, ns_coll, ts);
```

Now you’ve got an immutable log of everything Mongo emits.

---

## 2. Normalize Events

Next, create a view to extract candidates for analysis. Different systems put identifiers in different places, so keep it flexible:

```sql
CREATE VIEW evt AS
SELECT
  ts,
  ns_db,
  ns_coll,
  op,
  coalesce(
    JSON_VALUE(full, '$.fullDocument.job_id'),
    JSON_VALUE(full, '$.job_id'),
    concat(ns_db, '.', ns_coll)
  ) AS job_id,
  coalesce(
    JSON_VALUE(full, '$.fullDocument.event_type'),
    JSON_VALUE(full, '$.event'),
    op
  ) AS event_type,
  JSON_VALUE(full, '$.fullDocument.corr_id') AS corr_id
FROM raw_cdc;
```

At this point you can ask: *what kinds of events exist?*

```sql
SELECT event_type, count() AS n
FROM evt
GROUP BY event_type
ORDER BY n DESC;
```

---

## 3. Segment Runs

A **run** is one execution of a job. There are two main ways to segment:

### By correlation ID
If your events have a `corr_id`:

```sql
SELECT job_id, corr_id,
       minIf(ts, event_type ILIKE 'START%') AS t_start,
       maxIf(ts, event_type ILIKE 'SUCCESS%') AS t_success,
       maxIf(ts, event_type ILIKE 'FAIL%') AS t_fail
FROM evt
GROUP BY job_id, corr_id;
```

### By time gaps
If not, use idle gaps to split runs:

```sql
WITH j AS (
  SELECT job_id, ts
  FROM evt
  ORDER BY job_id, ts
),
gaps AS (
  SELECT job_id, ts,
         dateDiff('minute',
           lagInFrame(ts) OVER (PARTITION BY job_id ORDER BY ts), ts
         ) AS gap_min
  FROM j
)
SELECT job_id,
       sum(if(gap_min IS NULL OR gap_min > 60, 1, 0))
         OVER (PARTITION BY job_id ORDER BY ts) AS run_seq,
       min(ts) OVER (PARTITION BY job_id, run_seq) AS t_start,
       max(ts) OVER (PARTITION BY job_id, run_seq) AS t_end
FROM gaps;
```

---

## 4. Learn Schedules and SLAs

With a few weeks of runs, you can compute typical due times and windows:

```sql
WITH runs AS (
  SELECT job_id, toStartOfDay(ts) AS d, max(ts) AS t_done
  FROM evt
  WHERE event_type ILIKE 'SUCCESS%'
  GROUP BY job_id, d
)
SELECT
  job_id,
  toDayOfWeek(t_done) AS dow,
  quantileExact(0.5)(toHour(t_done)*60 + toMinute(t_done)) AS p50_min_of_day,
  greatest(15,
    quantileExact(0.9)(toHour(t_done)*60 + toMinute(t_done)) -
    quantileExact(0.1)(toHour(t_done)*60 + toMinute(t_done))
  ) AS window_min,
  count() AS n
FROM runs
GROUP BY job_id, dow
HAVING n >= 20
ORDER BY job_id, dow;
```

Result:  
- “Job X usually completes around 01:05 on Mondays.”  
- “The window of variation is ~20 minutes.”

---

## 5. Infer Dependencies

Jobs often follow one another. Two approaches:

### With correlation IDs
```sql
WITH s AS (
  SELECT job_id, corr_id, min(ts) AS t
  FROM evt
  WHERE event_type ILIKE 'SUCCESS%' AND corr_id IS NOT NULL
  GROUP BY job_id, corr_id
)
SELECT a.job_id AS from_job, b.job_id AS to_job,
       count() AS co, quantileExact(0.5)(dateDiff('minute', a.t, b.t)) AS lag_min
FROM s a
JOIN s b ON a.corr_id=b.corr_id AND a.job_id!=b.job_id AND b.t >= a.t
GROUP BY from_job, to_job
HAVING co >= 20
ORDER BY co DESC;
```

### Without correlation IDs
```sql
WITH daily AS (
  SELECT job_id, toStartOfDay(ts) AS d,
         min(ts) AS first_ts, max(ts) AS last_ts
  FROM evt
  WHERE event_type ILIKE 'SUCCESS%'
  GROUP BY job_id, d
)
SELECT a.job_id AS from_job, b.job_id AS to_job,
       count() AS days,
       quantileExact(0.5)(dateDiff('minute', a.last_ts, b.first_ts)) AS lag_min
FROM daily a
JOIN daily b ON a.d=b.d AND a.job_id!=b.job_id AND b.first_ts>=a.last_ts
GROUP BY from_job, to_job
HAVING days >= 10
ORDER BY days DESC;
```

This produces a DAG: “Job A usually precedes Job B by ~15 minutes.”

---

## 6. Detect Late or Missing Runs

Generate daily expectations automatically:

```sql
CREATE TABLE runs_expected
ENGINE = MergeTree
ORDER BY (job_id, due_at) AS
SELECT
  job_id,
  toDateTime(
    concat(formatDateTime(addDays(today(), 1), '%Y-%m-%d'), ' ',
           toString(intDiv(p50_min_of_day,60)), ':',
           toString(modulo(p50_min_of_day,60)), ':00'),
    'America/Chicago') AS due_at,
  due_at + toIntervalMinute(window_min) AS wait_until
FROM job_profile
WHERE dow = toDayOfWeek(addDays(today(), 1));
```

Then compare actual events vs. expected windows to mark each run as `MET`, `LATE`, or `MISSING`.

---

## 7. Fingerprints of Human Intervention

Even without ticket logs, some patterns are clear:

- **Restart:** fail → quick success outside normal cadence.  
- **Backfill:** a cluster of old dates appearing at once.  
- **Override:** downstream runs without upstream MET.  

You can store these as synthetic “actions”:

```sql
SELECT job_id, ts AS fail_ts,
       anyLastIf(ts, event_type ILIKE 'SUCCESS%') OVER
         (PARTITION BY job_id ORDER BY ts ROWS BETWEEN CURRENT ROW AND 10 FOLLOWING)
         AS next_success_ts,
       dateDiff('minute', ts, next_success_ts) AS gap_min
FROM evt
WHERE event_type ILIKE 'FAIL%'
  AND gap_min BETWEEN 0 AND 15;
```

---

## 8. What You Get

After a few weeks of data flowing in:

- A **catalog of jobs** discovered from events.  
- **Profiles** of their schedules and variability.  
- A **DAG of dependencies** with typical lags.  
- A **status table** of daily runs (MET/LATE/MISSING).  
- Inferred **action logs** showing how problems were resolved.  

All of it without hand-entered crontabs or manual DAG definitions.

---

## Why This Matters

- **Self-Discovery**: The system tells you what’s normal.  
- **Reliability**: You can alert on late/missing runs without configuring each one by hand.  
- **Learning**: Over time, you can predict lateness earlier, suggest interventions, or even automate the simplest remediations.  

Mongo already knows a lot from its history — streaming CDC into ClickHouse just makes it visible, queryable, and actionable.
