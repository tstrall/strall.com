---
title: "First Things to Do After Capturing MongoDB Change Streams in ClickHouse"
date: 2025-08-09T00:00:00Z
draft: false
description: "Now that you have CDC events flowing into ClickHouse, here are the first queries, alerts, and analyses that give you value on day one."
tags: ["MongoDB", "CDC", "Kafka", "ClickHouse", "Adage", "Karma", "Event Streaming", "Data Engineering", "Monitoring"]
---

Once your MongoDB change streams are flowing through Kafka and landing in ClickHouse, you’ve got a live, queryable event history for every state change in your systems.

The obvious next step: **start using it immediately** — even before you build full-blown dashboards or machine learning models.

## 1. Detect Missing or Late Events

One of the fastest wins is catching when something *doesn’t* happen.
If you know a collection normally sees certain events every day, you can query for absences:

```sql
SELECT ns_db, ns_coll, count() AS events
FROM record_raw
WHERE ts >= today()
GROUP BY ns_db, ns_coll
HAVING events = 0;
```

You can also set up a query to check if an expected supplier or consumer is late:

```sql
SELECT JSON_VALUE(tags,'$.consumer_id') AS consumer,
       max(ts) AS last_event
FROM record_raw
WHERE ts >= now() - INTERVAL 2 DAY
GROUP BY consumer
HAVING last_event < now() - INTERVAL 1 HOUR;
```

## 2. Monitor Latency Trends

If you store durations as an attribute (e.g. `latency_sec`), you can plot changes over time:

```sql
SELECT toStartOfInterval(ts, INTERVAL 15 MINUTE) AS bucket,
       avg(toFloat64OrZero(JSON_VALUE(attrs,'$.latency_sec'))) AS avg_latency
FROM record_raw
WHERE ts >= now() - INTERVAL 24 HOUR
GROUP BY bucket
ORDER BY bucket;
```

This is immediately useful for spotting slowdowns before they cause SLA violations.

## 3. Trace Multi-Step Workflows

Because you kept **tags** flexible, you can reconstruct sequences of events for a specific job, consumer, or transaction:

```sql
SELECT ts, event_type, tags
FROM record_raw
WHERE JSON_VALUE(tags,'$.job_id') = '20250809-abc123'
ORDER BY ts;
```

This turns ClickHouse into a **forensics tool** — no extra instrumentation needed.

## 4. Build Simple SLO Dashboards

Even without Grafana, you can run queries that give you health snapshots:

```sql
SELECT event_type,
       count() AS events,
       round(events / (SELECT count() FROM record_raw WHERE ts >= now() - INTERVAL 1 HOUR), 2) AS pct
FROM record_raw
WHERE ts >= now() - INTERVAL 1 HOUR
GROUP BY event_type
ORDER BY pct DESC;
```

This works for system-wide monitoring until you formalize SLIs/SLOs.

## 5. Train Your First Baseline Models

With historical data accumulating, you can start with lightweight predictive checks:

- **ARIMA** on event counts to forecast expected volume
- **Shallow neural nets** to flag unusual patterns
- **Simple rules** like “if supplier X’s latency > mean + 3σ, alert”

Because ClickHouse is fast, you can export data for training without disrupting queries.

## 6. Automate Interventions

Once you have a stream of tagged, timestamped events, you can:

- Trigger follow-up jobs if certain sequences are incomplete
- Send alerts only when *patterns* deviate, not on every single event
- Replace some manual SRE “eyes-on-glass” work with automated state checks

**Bottom line:**
As soon as CDC data hits ClickHouse, you can monitor, alert, and analyze — **before** you invest in bigger architecture changes. It’s the shortest path from “we captured the events” to “we’re making better decisions in real time.”

---

**Related Posts**  
- [Generic, Config-Driven CDC Pipeline from MongoDB to ClickHouse](/posts/mongo-cdc-clickhouse/)  
- [How to Set Up MongoDB Atlas → MSK → ClickHouse on AWS](/posts/2025-08-09-atlas-msk-clickhouse-setup/)
