---
title: "Splitting the Ledger and the Graph: Why Karma Uses Separate Pipelines for ClickHouse and Graph DB"
date: 2025-08-09T12:30:00-05:00
draft: false
tags: ["karma", "architecture", "cdc", "clickhouse", "graphdb", "kafka", "kstreams"]
summary: "Karma uses a single normalized event stream to feed both a ClickHouse ledger and an optional graph database — but through separate pipelines for flexibility, scalability, and clarity."
---

## One Stream, Two Very Different Destinations

Karma treats **anything that emits changes** — databases, infrastructure tools, metrics, logs, file drops — as a CDC-like source.  
All of these sources are normalized into a **common event envelope** and published to Kafka (`events.normalized`).  

From there, the normalized stream can be consumed by multiple sinks — but ClickHouse and a Graph DB have such different needs that they get **separate pipelines**.

---

## Why Separate Pipelines?

### 1. Different Data Models
- **ClickHouse**: flat, append-only tables; perfect for large-scale time-series analytics, baselines, and aggregations.
- **Graph DB**: nodes, edges, and relationship properties; built for traversals, lineage, and dependency analysis.

### 2. Independent Scaling
- The ClickHouse sink might handle millions of events per minute in batch inserts.
- The Graph DB sink might process fewer events but do heavier transformations (merging nodes, recalculating edges).
- Each can scale up or down without affecting the other.

### 3. Different Connectors
- ClickHouse: Kafka Connect sink, Kafka table engine.
- Graph DB: native streaming ingest (Neo4j Kafka Connect, Neptune Streams, JanusGraph with Gremlin).
- Keeping them separate avoids coupling unrelated logic.

### 4. Easier Experimentation
- You can evolve your graph schema without touching the main ledger.
- You can temporarily disable graph ingestion without losing ClickHouse history.

---

## The Karma Pattern
Real-World Graph DB Use Cases in Karma

- Root cause tracing: traverse dependencies to see what led to an anomaly.

- Impact analysis: predict what will break if a service fails.

- State machine modeling: track transitions and detect unexpected states.

- Multi-hop alerts: notify based on cascading effects, not just single metrics.

When to Skip the Graph DB

- If your needs are limited to metrics, baselines, and statistical anomaly detection, ClickHouse alone may suffice.

- Graph DB makes sense when relationships and path-dependent reasoning are core to the problem.
