# Proposal: Early Ticket Prediction via Mongo–Kafka–ClickHouse Fabric

### One-Line Pitch
> “By unifying MongoDB changes, system signals, and ServiceNow tickets in one stream, we can give on-call engineers an **early-warning signal** that a ticket is about to be generated — improving response time without adding noise.”

---

## Executive Summary
We propose to extend the existing MongoDB → Kafka → ClickHouse pipeline with ServiceNow ticket data to create an **early-warning signal** for incidents. The goal is to give the system the ability to **recognize conditions that typically lead to a ServiceNow ticket, before the ticket is actually opened**.

This is a lightweight, non-disruptive pilot aimed at demonstrating **practical usefulness** rather than rigorous measurement.

---

## Concept
- **Inputs**: 
  - MongoDB Change Streams (CDC)
  - System logs and metrics
  - ServiceNow ticket open/resolve events

- **Pipeline**: 
  - All events flow into Kafka (`events.enriched`).
  - ClickHouse ingests via Kafka engine → consolidated `events_merge` table.

- **Outputs**: 
  - An **“Early Ticket” signal** is generated when the system observes conditions that historically precede tickets (e.g., lag spikes, error bursts, entropy changes).
  - Signals published to Kafka topic `ops.earlywarn` and displayed in Grafana.

---

## Value Proposition
- **One timeline**: unify changes, anomalies, lag, and ticket breadcrumbs in a single view.  
- **Earlier visibility**: on-call teams see “ticket likely soon” flags, improving response speed.  
- **Operator confidence**: helps prioritize noise vs. real issues.  
- **Non-invasive**: no changes to existing monitoring/alerting; runs in shadow mode initially.  
- **Future extensibility**: foundation for machine learning or automation once proven useful.

---

## Pilot Plan
1. **Ingest ServiceNow tickets** into Kafka and ClickHouse.  
2. **Label pre-incident windows** (e.g., 60 minutes before each ticket open).  
3. **Compute basic features**: error rates, lag z-scores, CDC burstiness, entropy/sequence metrics.  
4. **Define simple rules** to raise “TicketSoon” signals (e.g., lag ≥2σ + high CDC rate).  
5. **Display signals in Grafana** alongside existing events and ticket breadcrumbs.  
6. **Shadow mode trial** (2–3 weeks): collect operator feedback on usefulness.  

---

## Success Criteria
- **Visibility**: operators can see why the system expects a ticket (transparent “reasons”).  
- **Confidence**: feedback indicates signals would have helped in recent incidents.  
- **Adoption potential**: leadership sees a clear path to reduce MTTR and noise fatigue.  

---

## Next Steps
- Stand up Kafka topic for ServiceNow events.  
- Build ClickHouse ingestion + Grafana panel.  
- Run 2–3 week shadow pilot with one service.  
