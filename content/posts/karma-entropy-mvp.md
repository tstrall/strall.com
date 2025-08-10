---
title: "Implementing Entropy in Karma: The First Step"
date: 2025-08-09T20:00:00-05:00
draft: false
tags: ["karma", "entropy", "mvp", "clickhouse", "cdc", "automation", "sre"]
summary: "A practical blueprint for the first entropy-capable version of Karma — using simple statistical measures and ClickHouse queries to detect surprise."
---

## Goal

Take Karma from **recording events** to **spotting surprises**.

We’re not aiming for a PhD-level probabilistic model yet — just enough to:

- Learn what “normal” looks like for each tracked process.
- Flag deviations as events (`entropy.deviation`) in real time.
- Feed those events into the action loop.

---

## Scope of the MVP

1. **Data Source**:  
   ClickHouse table populated by normalized events (via Kafka).
   
2. **Target Entities**:  
   Any `(entity_id, step)` combination — e.g., supplier response time, file arrival, job completion.

3. **Metric**:  
   Latency between defined step boundaries (or between event types).

4. **Output**:  
   - Current entropy score.
   - A boolean “out of expectation” flag.
   - Context tags for correlation.

---

## Calculating Entropy

We start with **bucketed latency distributions**:

```sql
SELECT
  entity_id,
  step,
  intDiv(latency_ms, 500) * 500 AS latency_bucket,
  count() AS bucket_count
FROM events
WHERE event_ts >= now() - INTERVAL 7 DAY
GROUP BY entity_id, step, latency_bucket
```

Then apply **Shannon’s entropy** formula in SQL or downstream code:

```sql
SELECT
  entity_id,
  step,
  -sum(p * log2(p)) AS entropy
FROM (
  SELECT
    entity_id,
    step,
    latency_bucket,
    bucket_count / sum(bucket_count) OVER (PARTITION BY entity_id, step) AS p
  FROM latency_distribution
) t
GROUP BY entity_id, step
```

---

## Defining “Surprise”

We don’t want to fire on every fluctuation. Instead:

1. **Baseline**: Median entropy over the last N days.
2. **Tolerance**: Median Absolute Deviation (MAD) or % change threshold.
3. **Trigger**: Current entropy > baseline + tolerance.

Example:

```sql
SELECT
  entity_id,
  step,
  current_entropy,
  baseline_entropy,
  (current_entropy - baseline_entropy) > 0.5 AS is_surprising
FROM ...
```

---

## Publishing the Event

Once `is_surprising = 1`, publish a normalized event to Kafka:

```json
{
  "event_type": "entropy.deviation",
  "entity_id": "supplier_A",
  "step": "quote_response",
  "entropy": 2.35,
  "baseline_entropy": 1.5,
  "tags": {
    "priority": "high",
    "detected_by": "karma.entropy.v1"
  },
  "ts": "2025-08-09T19:58:00Z"
}
```

This flows into:
- The action loop (automatic responses, notifications).
- The same ClickHouse table for historical tracking.
- Any downstream analytics or dashboards.

---

## Why This Works Now

- **No new infrastructure**: Uses existing ClickHouse + Kafka stack.
- **Simple math**: Baselines + deviations, no heavy ML yet.
- **Extensible**: You can swap in more sophisticated models later.

---

## Roadmap After MVP

1. Add **sequence entropy** (order of steps, not just latency).
2. Model **joint entropy** of multiple tags (supplier + product type).
3. Incorporate **forecasting** for expected future entropy.
4. Feed deviations into **self-healing playbooks**.
