# ClickHouse DDL and Queries for TicketSoon Pilot

## Kafka ingestion tables
```sql
CREATE TABLE kafka_events (
  ts DateTime64(3), source String, service String, entity_id String,
  verb String, magnitude Float64, severity UInt8,
  labels Array(String), corr_id String, payload String
) ENGINE = Kafka
SETTINGS kafka_broker_list = 'broker:9092',
         kafka_topic_list = 'events.enriched',
         kafka_group_name = 'ch-events-consumer',
         kafka_format = 'JSONEachRow';

CREATE TABLE events_merge (
  ts DateTime64(3), source LowCardinality(String), service LowCardinality(String),
  entity_id String, verb LowCardinality(String), magnitude Float64, severity UInt8,
  labels Array(String), corr_id String, payload String
) ENGINE = MergeTree ORDER BY (service, ts) TTL ts + INTERVAL 30 DAY;

CREATE MATERIALIZED VIEW mv_events TO events_merge AS
SELECT * FROM kafka_events;
```

## Ticket ingestion tables
```sql
CREATE TABLE tickets_kafka (ts DateTime64(3), ticket_id String, service String,
  severity UInt8, state LowCardinality(String), category LowCardinality(String),
  short_desc String, corr_id String)
ENGINE=Kafka SETTINGS kafka_broker_list='broker:9092',
  kafka_topic_list='ops.tickets', kafka_group_name='ch-sn', kafka_format='JSONEachRow';

CREATE TABLE tickets (ts DateTime64(3), ticket_id String, service LowCardinality(String),
  severity UInt8, state LowCardinality(String), category LowCardinality(String),
  short_desc String, corr_id String)
ENGINE=MergeTree ORDER BY (service, ts);

CREATE MATERIALIZED VIEW mv_tickets TO tickets AS SELECT * FROM tickets_kafka;
```

## RCA query (90-minute window)
```sql
SELECT ts, source, service, entity_id, verb, magnitude, severity, labels, corr_id
FROM events_merge
WHERE corr_id = {corr:String}
  AND ts BETWEEN {t0:DateTime} AND {t1:DateTime}
ORDER BY ts;
```

## Blast radius query
```sql
WITH bounds AS (
  SELECT min(ts)-INTERVAL 30 MINUTE AS t0, max(ts)+INTERVAL 30 MINUTE AS t1
  FROM events_merge WHERE corr_id = {corr:String}
)
SELECT service, count() AS events, uniqExact(entity_id) AS entities
FROM events_merge, bounds
WHERE corr_id = {corr:String} AND ts BETWEEN bounds.t0 AND bounds.t1
GROUP BY service ORDER BY events DESC;
```

## Normality (seasonality) query
```sql
SELECT toDayOfWeek(ts) AS dow, toHour(ts) AS hour, verb, count() AS n
FROM events_merge
WHERE service = {svc:String} AND ts >= now() - INTERVAL 30 DAY
GROUP BY dow, hour, verb ORDER BY dow, hour, verb;
```
