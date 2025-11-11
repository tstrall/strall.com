---
title: "CasePilot — Config-Driven, Retrieval-Augmented Decision Engine"
date: 2025-11-11T09:00:00-06:00
draft: false
tags: ["AI", "LLM", "retrieval", "automation", "open-source", "agentic-systems"]
summary: "CasePilot is an open-source framework for retrieval-augmented decision making — turning any dataset of labeled approvals or classifications into an explainable LLM-powered decision engine."
---

### From Prompts to Policies

Over the past few months I’ve been thinking a lot about *agentic systems* — AI that doesn’t just generate text, but actually **makes decisions** using its own contextual memory.  
The result of that line of thinking is **CasePilot**: a minimal, open-source framework for retrieval-augmented decision making.

---

### The Core Idea

Most organizations already have history:  
thousands of approvals, denials, classifications, and triage outcomes.  
CasePilot uses that history directly — without retraining or fine-tuning.

1. **Embed historical decisions** from a CSV or database  
2. **Retrieve similar examples** for a new request using vector search  
3. **Prompt an LLM** with those examples and a structured decision schema  
4. **Return a deterministic, explainable decision** (like APPROVE / REJECT) with a rationale

The result is a *config-driven decision engine* that learns your implicit rules simply by example.

---

### Why It Matters

Traditional ML models require labeled data, training cycles, and hyperparameter tuning.  
LLM-based pipelines are flexible but often opaque.  
CasePilot lives in between — transparent enough to audit, yet general enough to apply to:

- Expense or loan approvals  
- Change or access request workflows  
- HR or procurement decisions  
- Policy compliance audits  
- Support or incident triage  

You don’t retrain anything. You just configure your schema and let the model reason by similarity.

---

### Under the Hood

- **Schema-driven ingestion** — YAML defines how structured fields are concatenated into text  
- **Retrieval-augmented inference** — cosine similarity over embedding vectors (OpenAI or local models)  
- **Prompt templating** — Jinja2 templates define exactly how the LLM sees examples  
- **CLI + FastAPI server** — run locally or deploy as an internal decision API  
- **Pluggable backends** — OpenAI, Anthropic, Bedrock, or SentenceTransformers (offline)  

Each decision includes the top-K examples it referenced, making the reasoning trace auditable.

---

### How to Use It

```bash
pip install casepilot

casepilot ingest --csv data/samples.csv --schema config/schema.yaml
casepilot serve  --schema config/schema.yaml --prompt config/prompt.yaml
