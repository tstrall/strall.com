---
title: "A Generic, Config-Driven CDC Pipeline from MongoDB to ClickHouse"
date: 2025-08-09T00:00:00Z
draft: false
description: "How to capture MongoDB change streams, normalize them with dynamic tags and attributes, and land them in ClickHouse for universal, queryable event history."
tags: ["MongoDB", "CDC", "Kafka", "ClickHouse", "Adage", "Karma", "Event Streaming", "Data Engineering"]
---

When you already have systems tracking their own state in MongoDB, you can turn that into a real-time stream of structured events without rewriting application logic. This approach captures every meaningful change from Mongo, tags it with relevant metadata, and makes it instantly queryable in ClickHouse — all through a generic, reusable pattern.

The idea:
- **One fixed event envelope** for all sources
- **Dynamic tags/attributes** defined in config files
- **No code changes** when onboarding new collections

## 1. The Fixed Event Envelope

Every CDC message has the same top-level structure, no matter what source system or collection it came from:

```json
{
  "ts": "2025-08-09T14:00:07Z",
  "source": "mongo",
  "ns": {"db":"<db>","coll":"<coll>"},
  "event_type": "insert|update|delete",
  "idempotency_key": "mongo:<_id>:<op>:<ts>",
  "tags": { /* dynamic */ },
  "attrs": { /* dynamic */ },
  "raw": { /* optional original doc/delta */ }
}
```

The **core fields** never change; only `tags` and `attrs` adapt to the source.

## 2. Config-Driven Mapping

A YAML file declares the tagging and attribute logic for each collection.

```yaml
defaults:
  hash_pii: true
  max_label_cardinality: 100000

mappings:
  - match: { ns.db: commodity, ns.coll: supplier_responses }
    event_type_override:
      when: "$exists(fullDocument.response_at)"
      value: "response_received"
      else: "request_sent"
    tags:
      - supplier_id
      - consumer_id
      - status
    attrs:
      - latency_sec: "$secondsDiff(fullDocument.response_at, fullDocument.sent_at)"
      - record_count
      - file_name
    drops:
      - payload_blob
    pii:
      - consumer_email

  - match: { ns.db: ingest, ns.coll: files }
    event_type_override:
      when: "$eq(fullDocument.status, 'arrived')"
      value: "file_arrived"
    tags:
      - consumer_id
      - file_type
    attrs:
      - size_bytes
      - expected_count
      - checksum
    computed:
      - is_large: "$gt(fullDocument.size_bytes, 1048576)"
```

## 3. The Normalizer Service

A small containerized service:
- Consumes raw MongoDB Atlas change stream topics from Kafka
- Looks up the mapping for `ns.db` + `ns.coll`
- Applies tag/attr extraction rules
- Emits the normalized event to a common Kafka topic

Onboarding a new source means adding to `mapping.yaml` — no redeploy required.

## 4. ClickHouse as the Sink

A single table handles all normalized events:

```sql
CREATE TABLE record_raw
(
  ts               DateTime CODEC(Delta, ZSTD),
  event_type       LowCardinality(String),
  source           LowCardinality(String),
  ns_db            LowCardinality(String),
  ns_coll          LowCardinality(String),
  idempotency_key  String,
  tags             JSON,
  attrs            JSON,
  _ingested_at     DateTime DEFAULT now()
)
ENGINE = MergeTree
PARTITION BY toYYYYMM(ts)
ORDER BY (ts, event_type, ns_db, ns_coll);
```

JSON columns keep the schema flexible for dynamic tags/attrs.

## 5. Guardrails

Generic pipelines need protection against runaway complexity:
- **Cardinality caps** on tags
- **PII hashing/dropping** from config
- **Large field drops** to keep payloads lean
- **Fallback mode** for unmapped collections

## 6. Why This Works

This pattern is reusable because:
- The **envelope** is fixed
- The **metadata** is externalized to config
- Any team can plug in their collection by writing a mapping block
- ClickHouse queries work for any source with zero schema changes

It’s a classic Adage/Karma move — decoupling *what is happening* from *how you use it later*.

## 7. Example Queries

Recent top event types:
```sql
SELECT event_type, count()
FROM record_raw
WHERE ts >= now() - INTERVAL 1 HOUR
GROUP BY event_type
ORDER BY count() DESC;
```

Latency by supplier:
```sql
SELECT JSON_VALUE(tags,'$.supplier_id') AS supplier,
       avg(toFloat64OrZero(JSON_VALUE(attrs,'$.latency_sec'))) AS avg_lat
FROM record_raw
WHERE ts >= now() - INTERVAL 24 HOUR
  AND supplier IS NOT NULL
GROUP BY supplier
ORDER BY avg_lat DESC;
```

**End result**:
You can tap *any* MongoDB-backed system, stream its state changes to Kafka, and land them in ClickHouse — giving you a live, queryable history of everything that happens, with zero disruption to existing workflows.