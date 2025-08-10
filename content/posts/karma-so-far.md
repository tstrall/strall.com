---
title: "Karma: Current State and Next Steps"
date: 2025-08-09T17:28:00-05:00
draft: false
tags: ["karma", "architecture", "cdc", "clickhouse", "graphdb", "kafka", "entropy"]
summary: "Karma now ingests, normalizes, and routes events from any CDC-like source into a shared ledger, optional graph, and an action loop — setting the stage for learned expectations and autonomous intervention."
---

## Overview

Karma has evolved from an idea about tracking system state into a working, composable framework for:

1. **Ingesting** change streams, metrics, or logs from any source.
2. **Normalizing** them into a consistent envelope with rich tags.
3. **Routing** them to analytical and relational sinks.
4. **Closing the loop** with an action pipeline that treats commands as first-class events.

Entropy — the learning layer that predicts and reacts to drift — is the only major piece still to come.

---

## Current Capabilities

### 1. Universal Event Ingestion
- **Sources**: Any CDC/log/metric stream — MongoDB change streams, Adage outputs, Datadog metrics, S3 events, etc.
- **Transport**: Kafka (MSK), with `events.normalized` as the shared topic.
- **Extensible**: Adding a new source is a matter of writing or configuring a Kafka Connect pipeline.

### 2. Normalized Event Model
- All events use the same envelope:
  - `ts` (timestamp)
  - `event_type`
  - `entity_id`
  - `correlation_id`
  - `tags` (arbitrary key/value for filtering)
  - `attrs` (payload details)
- This uniformity allows downstream tools to query, join, and reason about events without source-specific logic.

### 3. Analytical Ledger in ClickHouse
- Events are written to ClickHouse for:
  - Time series queries
  - Ad hoc analysis
  - Materialized views for dashboards and KPIs
- High-tag cardinality is supported without penalty to ingestion speed.

### 4. Optional Graph Sink
- Parallel Kafka → GraphDB pipeline captures relationships:
  - Causal links (A leads to B)
  - Entity hierarchies (job → steps → substeps)
  - Lineage and dependency mapping
- Enables state machine construction, impact analysis, and “what-if” queries.

### 5. Actions as Events
- Karma doesn’t call systems directly — it **publishes action requests** to Kafka.
- Executors consume `actions.requested`, perform the work, and publish progress and results.
- Every step is auditable, retryable, and visible in ClickHouse.

---

## What’s Next: Entropy Layer

The final planned major capability:
- **Learn expectations**: For each entity and step, predict what should happen next and when.
- **Detect drift**: Flag anomalies, lateness, and missing steps in real time.
- **Close the loop**: Suggest or trigger corrective actions via the action pipeline.
- **Metrics**: Track MTTA, MTTR, precision/recall of automated interventions.

This will allow Karma to act as an autonomous SRE, identifying and addressing operational issues without constant human monitoring.

---

## Why It Matters

With Karma in place:
- Teams can unify disparate operational signals into a single, queryable system.
- Actions and observations share the same infrastructure, making automation safer and auditable.
- Adding a new data source, dashboard, or automation path doesn’t require redesigning the whole system.

Entropy will turn it from a **monitoring and orchestration backbone** into a **self-learning, self-healing system**.
