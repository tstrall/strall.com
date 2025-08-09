---
title: "How to Set Up MongoDB Atlas → MSK (Kafka) → ClickHouse on AWS"
date: 2025-08-09T00:00:00Z
draft: false
description: "Step‑by‑step guide to streaming MongoDB change events into AWS MSK and landing them in ClickHouse, with security, cost controls, and validation."
tags: ["MongoDB", "Atlas", "Kafka", "MSK", "ClickHouse", "AWS", "CDC", "Event Streaming", "Data Engineering"]
---

This guide shows how to wire **MongoDB Atlas → Amazon MSK (Kafka) → ClickHouse** on AWS so that change events from existing MongoDB apps are captured in a fast, queryable store.

You’ll get:
- A **lossless CDC stream** of MongoDB changes into Kafka
- An optional **config‑driven normalizer** to add tags/attributes
- A **ClickHouse sink** for sub‑second queries and analytics
- Security and cost controls that work in a typical enterprise VPC

---

## 0) Architecture at a Glance

```
MongoDB Atlas (Change Streams)
        │  (Atlas Kafka Source Connector)
        ▼
    Amazon MSK (Kafka)  ──►  [Optional] Normalizer (Kafka consumer)
        │                           │
        │                           └─ emits normalized events
        ▼
   ClickHouse on AWS  ◄─────────────┘
   (Kafka Engine table or small consumer)
```

**Why this shape?** Atlas produces change events; MSK is your durable bus; ClickHouse gives you fast, tag‑rich queries and easy rollups.

---

## 1) Prerequisites

- **MongoDB Atlas** cluster (Replica Set) with **Change Streams** enabled.
- An **Amazon MSK** cluster (provisioned or serverless) reachable from Atlas or via a secure endpoint.
- **ClickHouse**:
  - *Option A (managed):* ClickHouse Cloud reachable from your VPC.
  - *Option B (self‑hosted):* EC2 hosts in a private subnet (recommended instance types: `c7i.large`+ SSD gp3).
- **Network & Auth**:
  - Decide on Kafka auth: **SASL/SCRAM** or **IAM**. Keep it consistent across connectors.
  - Allow Atlas egress to your MSK bootstrap via **Public Endpoint + TLS** or **PrivateLink** if your org requires it.
  - Security Groups: allow Kafka ports (default 9092 TLS) from the connector’s egress.

> Tip: For POCs, SASL/SCRAM is the quickest to wire. For production, IAM auth and PrivateLink are common.

---

## 2) Atlas → MSK: Kafka Source Connector

In **Atlas UI** (Data Federation / Integrations), create a **Kafka Source Connector** for each collection you want to stream. Configure it with **updateLookup** so updates carry post‑image docs.

**Connector JSON (example):**

```json
{
  "name": "atlas-to-msk-records",
  "connector.class": "com.mongodb.kafka.connect.MongoSourceConnector",
  "connection.uri": "mongodb+srv://<USER>:<PASS>@<CLUSTER>/?retryWrites=true&w=majority",
  "database": "ingest",
  "collection": "files",
  "publish.full.document.only": "true",
  "change.stream.full.document": "updateLookup",
  "output.format.value": "json",
  "output.format.key": "json",
  "topic.prefix": "events.mongo.ingest.files",
  "poll.await.time.ms": "500",
  "poll.max.batch.size": "1000",
  "bootstrap.servers": "<MSK_BOOTSTRAP_BROKERS>",
  "security.protocol": "SASL_SSL",
  "sasl.mechanism": "SCRAM-SHA-512",
  "sasl.jaas.config": "org.apache.kafka.common.security.scram.ScramLoginModule required username="<MSK_USER>" password="<MSK_PASSWORD>";"
}
```

**Notes**
- For multiple collections, create separate connectors or use a DB‑level stream with different topic prefixes.
- If MSK uses **IAM auth**, swap SASL settings for the AWS MSK IAM client configs.

---

## 3) (Optional) Normalizer: Config‑Driven Tags & Attributes

Keep your pipeline generic by externalizing “what becomes a tag/attr” into a mapping file.

**Mapping YAML (snippet):**
```yaml
mappings:
  - match: { ns.db: ingest, ns.coll: files }
    event_type_override:
      when: "$eq(fullDocument.status, 'arrived')"
      value: "file_arrived"
      else: "file_event"
    tags:   [consumer_id, file_type, status]
    attrs:
      - size_bytes
      - expected_count
      - checksum
```

**Skeleton consumer (Python):**
```python
from confluent_kafka import Consumer, Producer
import json, os

c = Consumer({
  'bootstrap.servers': os.environ['KAFKA_BOOTSTRAP'],
  'group.id': 'normalizer',
  'auto.offset.reset': 'earliest',
  'security.protocol': 'SASL_SSL',
  'sasl.mechanism': 'SCRAM-SHA-512',
  'sasl.username': os.environ['KAFKA_USER'],
  'sasl.password': os.environ['KAFKA_PASS']
})
p = Producer({'bootstrap.servers': os.environ['KAFKA_BOOTSTRAP']})

c.subscribe(['events.mongo.ingest.files'])

while True:
    msg = c.poll(1.0)
    if not msg or msg.error(): continue
    ch = json.loads(msg.value())
    doc = ch.get("fullDocument", {})
    event = {
      "ts": ch.get("clusterTimeIso") or ch.get("clusterTime"),
      "source": "mongo",
      "ns": ch["ns"],
      "event_type": "file_arrived" if doc.get("status") == "arrived" else ch["operationType"],
      "idempotency_key": f"mongo:{doc.get('_id')}:{ch['operationType']}:{ch.get('clusterTime')}",
      "tags": {"consumer_id": doc.get("consumer_id"), "file_type": doc.get("file_type"), "status": doc.get("status")},
      "attrs": {"size_bytes": doc.get("size_bytes"), "checksum": doc.get("checksum")}
    }
    p.produce('events.normalized.record', json.dumps(event).encode('utf-8'))
```

You can skip this step initially and write raw Atlas events straight to ClickHouse; add the normalizer later without changing Atlas/MSK.

---

## 4) MSK → ClickHouse: Two Ingestion Options

### Option A — **ClickHouse Kafka Engine** (fewer moving parts)
Create a Kafka table and a materialized view into your storage table.

```sql
-- Kafka source table
CREATE TABLE kafka_record_src (
  value String
) ENGINE = Kafka
SETTINGS kafka_broker_list = '<MSK_BOOTSTRAP_BROKERS>',
         kafka_topic_list = 'events.normalized.record',
         kafka_group_name = 'ch-sink',
         kafka_format = 'JSONAsString',
         kafka_security_protocol = 'SASL_SSL',
         kafka_sasl_mechanism = 'SCRAM-SHA-512',
         kafka_sasl_username = '<MSK_USER>',
         kafka_sasl_password = '<MSK_PASSWORD>';

-- Storage table
CREATE TABLE record_raw
(
  ts              DateTime,
  event_type      LowCardinality(String),
  source          LowCardinality(String),
  ns_db           LowCardinality(String),
  ns_coll         LowCardinality(String),
  idempotency_key String,
  tags            JSON,
  attrs           JSON,
  _ingested_at    DateTime DEFAULT now()
)
ENGINE = MergeTree
PARTITION BY toYYYYMM(ts)
ORDER BY (ts, event_type, ns_db, ns_coll);

-- Materialized view to parse JSON and insert
CREATE MATERIALIZED VIEW mv_record_ingest TO record_raw AS
SELECT
  parseDateTimeBestEffort(JSON_VALUE(value, '$.ts'))                                  AS ts,
  JSON_VALUE(value, '$.event_type')                                                   AS event_type,
  JSON_VALUE(value, '$.source')                                                       AS source,
  JSON_VALUE(value, '$.ns.db')                                                        AS ns_db,
  JSON_VALUE(value, '$.ns.coll')                                                      AS ns_coll,
  JSON_VALUE(value, '$.idempotency_key')                                              AS idempotency_key,
  CAST(JSON_VALUE(value, '$.tags'), 'JSON')                                           AS tags,
  CAST(JSON_VALUE(value, '$.attrs'), 'JSON')                                          AS attrs
FROM kafka_record_src;
```

**Pros:** native, simple; **Cons:** runs inside CH, so size your CH nodes appropriately.

### Option B — **Small Kafka Consumer** (more control)
Run a tiny service that reads from MSK and inserts via HTTP/Native protocol. Useful if you need retries, dedupe, or transformations outside CH.

---

## 5) Security: Networking & Encryption

- **Kafka traffic:** TLS in transit (`SASL_SSL`), MSK broker TLS certs by default.
- **Atlas → MSK:** Restrict Atlas IP access list to MSK endpoints; use PrivateLink if required.
- **ClickHouse:** Place behind an internal ALB or use VPC only; enforce TLS on native/HTTP ports.
- **Secrets:** Store creds in **AWS Secrets Manager** and mount via ECS/EC2 IAM roles.
- **Least privilege:** IAM policies for MSK Connect/consumers limited to specific topics.

---

## 6) Cost Controls (POC‑friendly)

- **MSK**: If possible, use **MSK Serverless**; for provisioned clusters, keep broker count small and set low retention on POC topics.
- **ClickHouse**: Right‑size instance (`c7i.large`) and enable TTLs (e.g., 30–90 days) on `record_raw`.
- **Storage**: Consider parallel **S3 sink** via MSK Connect for cheap long‑term archive (Parquet); query with Athena as needed.
- **Normalizer**: Run on **Fargate Spot** or a t4g.nano EC2 for pennies/day.

---

## 7) Validation Checklist

- **Atlas connector is RUNNING**, offsets increasing.
- **Messages visible in MSK**: use `kafkacat`/`kcat` from a bastion host.
- **ClickHouse rows increasing**: `SELECT count() FROM record_raw WHERE ts >= now() - INTERVAL 5 MINUTE;`
- **Latency sanity**: run a quick percentile query.
```sql
SELECT quantileExact(0.95)(toFloat64OrZero(JSON_VALUE(attrs,'$.latency_sec')))
FROM record_raw
WHERE ts >= now() - INTERVAL 15 MINUTE;
```

---

## 8) Tear‑down Notes

- Delete Atlas connectors to stop egress.
- Drop CH Kafka engine table and MV (storage table optional if you want to keep data).
- Reduce MSK topic retention or delete topics to stop storage accrual.

---

## 9) Where to Go Next

- Add **materialized views** for slot/consumer/job health.
- Publish **alerts** to a Kafka `ops.alerts` topic from ClickHouse queries.
- Stream the same MSK topics to **S3 (Parquet)** with MSK Connect for cheap archive + Athena.
- Train **baseline models** (ARIMA/GBTs) using 30–90 days of history.

---

### Appendix: Minimal Security Group Rules

- **MSK brokers:** allow inbound TLS port 9092 from Atlas egress IPs and your ClickHouse/consumer subnets.
- **ClickHouse:** allow inbound 8443/9440 (if TLS HTTP/Native) from app subnets/bastion.
- **Egress:** allow ClickHouse/consumers to reach MSK, and Atlas to reach MSK if using public endpoints.

---

With this setup, you can capture state changes from systems already running on MongoDB and make them searchable, aggregatable, and automatable on AWS — with minimal moving parts and a clean upgrade path to richer analytics and ML.

---

**Related Posts**  
- [Generic, Config-Driven CDC Pipeline from MongoDB to ClickHouse](/posts/mongo-cdc-clickhouse/)  
- [First Things to Do After Capturing MongoDB Change Streams in ClickHouse](/posts/clickhouse-first-steps/)  
