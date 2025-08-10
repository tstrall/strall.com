---
title: "Actions in Karma: From Events to Execution"
date: 2025-08-09T16:50:00-05:00
draft: false
tags: ["karma", "architecture", "cdc", "clickhouse", "kafka", "actions", "fsm"]
summary: "In Karma, every action is just another event. This post explains the pattern for turning anomalies and rules into commands, tracking their execution, and feeding the results back into the same event pipeline."
---

## Actions Are Just Events

Karma treats decisions and commands the same way it treats observations — as **events**.  
Instead of calling a system directly, Karma writes an action request to Kafka.  
Subscribers (executors) perform the work and report progress and results back as more events.

---

## Core Topics

- `events.normalized` — raw observations from any CDC-like source.
- `actions.requested` — commands Karma issues.
- `actions.progress` — in-flight status (started, retrying, percent).
- `actions.result` — outcomes (succeeded / failed / cancelled).
- `actions.dlq` — unprocessable or exhausted retries.

---

## Action Lifecycle

`REQUESTED → ACCEPTED → STARTED → (RETRYING)* → {SUCCEEDED | FAILED | CANCELLED}`

Each state change is its own event, correlated by `action_id`.

---

## Action Envelope

Actions use the same envelope as normalized events, with a command payload:

```json
{
  "ts": "2025-08-10T16:42:00Z",
  "event_type": "action.requested",
  "entity_id": "job:abc123",
  "correlation_id": "slot:2025-08-10T16:30Z",
  "idempotency_key": "act:restart:job:abc123:1691685720",
  "source": {"system":"karma","ns":{"component":"rules-fsm"}},
  "tags": {"action":"restart_job","priority":"high","tenant":"foo"},
  "attrs": {
    "command": "restart_job",
    "args": {"job_id":"abc123","force":true},
    "ttl_sec": 600
  }
}
```

Workers publish progress and outcomes with the same `action_id`:

```json
{ "event_type":"action.started",  ... }
{ "event_type":"action.succeeded", "attrs":{"duration_ms": 3820} }
{ "event_type":"action.failed",    "attrs":{"error":"timeout"} }
```

---

## Why Model Actions as Events?

1. **Auditability** — every decision, attempt, and result is in the ledger.
2. **Loose Coupling** — rules don’t care who executes the action.
3. **Retry & Recovery** — retries, compensations, and DLQs are first-class.
4. **Unified Analytics** — MTTA, MTTR, success rate, error taxonomy, all in ClickHouse.
5. **Same Pipeline** — actions and observations share infrastructure.

---

## Execution Model

- **Producers**: Lambdas, FSMs, or ML models decide *what* to do and publish to `actions.requested`.
- **Consumers**: Executors for each domain (Control-M, Slack, S3, APIs) consume and perform the work.
- **Results**: Executors publish to `actions.progress` and `actions.result`, which flow back into the ledger.

---

## Synchronous APIs (Optional)

Even “sync” calls are just wrappers:
- API publishes to `actions.requested`.
- Returns an `action_id`.
- UI polls or subscribes for updates from `actions.progress` and `actions.result`.

---

## Observability

In ClickHouse, build materialized views:

- `action_state_current` — latest status per action.
- MTTA / MTTR by action type or tenant.
- Success rates and error categories.
- Link actions to the triggering event via `correlation_id`.
