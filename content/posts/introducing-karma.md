---
title: "Introducing Karma: Infrastructure as Consequence"
description: "Karma is a new open source system for modeling and managing infrastructure as graph-aware, testable components — built for observability, introspection, and machine learning."
date: 2025-04-18
tags: ["infrastructure", "terraform", "aws", "devops", "config", "open source"]
---

**Karma is an experimental system that treats infrastructure not just as state — but as consequence.**

---

## What Is Karma?

Karma is a new open source project that builds on the ideas behind [Adage](https://github.com/tstrall/adage), extending them into a fully introspectable, graph-based runtime.

At its core, Karma models your infrastructure as a graph of components, each defined by versioned configuration (in Git and AWS Parameter Store) and connected by runtime dependencies. Every component is:

- Declarative  
- Testable  
- Traceable  

And crucially: each deployment is shaped by what came before.

---

## Why Karma?

Modern infrastructure tooling is powerful, but often opaque. Config lives in templates, deployments are one-off executions, and visibility into how things connect is limited.

Karma flips that model by treating configuration and runtime as first-class graph objects. This allows:

- Change propagation across components  
- Data science and graph learning on real infrastructure  
- Observability that works without digging through Terraform state  
- Lightweight automation using just Parameter Store and Git  

---

## How It Works

Each Karma-managed component follows a simple pattern:

1. Config is defined in Git as a JSON object  
2. That config is published to Parameter Store (e.g. `/iac/serverless-site/my-site/config`)  
3. Terraform consumes the config and produces runtime output  
4. That output is written to Parameter Store at a matching `/runtime` path  
5. Karma reads both config and runtime, constructs a graph, and exposes it via API  

Under the hood, Karma uses Amazon Neptune to store the system graph.

---

## What Karma Enables

Once Karma has built a live view of your infrastructure, you can:

- Propose a config update and simulate its impact  
- Analyze drift between config and runtime  
- Query for relationships and dependencies  
- Trigger Terraform applies or component reloads  
- Integrate with external tools for UI, audit, machine learning, or compliance  

Karma gives infrastructure memory — and turns that memory into power.

---

## Early Status, Clear Direction

Karma is in early development, but already supports:

- Config-driven component deployment via Adage  
- Parameter Store as a universal config and runtime bus  
- Initial Neptune graph building  
- API-driven exploration and change requests  

You can follow progress at [github.com/usekarma](https://github.com/usekarma) or explore the [Karma project page](/karma/) for demos and theory.

---

## Built on Adage

Karma would not exist without Adage — a reusable infrastructure framework for AWS that promotes clean config separation, secure IAM practices, and deployment via Terragrunt.

If you're curious about how Karma fits into a real AWS deployment model, start with the [Adage deployment guide](https://github.com/tstrall/adage).

---

## Try It Yourself

Karma is being developed transparently — and **usekarma.dev** is deployed using the very system it describes.

If you're interested in contributing, experimenting, or just seeing what a graph-aware deployment system feels like, you can:

- Fork the [Adage repos](https://github.com/tstrall/adage)  
- Read the [Karma Theory](/theory/) section  
- Watch this space for more articles  

---

Infrastructure can be testable, observable, and intelligent.  
Karma is one step toward making that real.
