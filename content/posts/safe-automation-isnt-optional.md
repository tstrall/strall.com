---
title: "Safe Automation Isn't Optional"
date: 2025-08-17
draft: false
author: "Ted Strall"
description: "Operationalizing Geoffrey Hinton’s maternal instinct in autonomous systems, with a practical governance layer and a nod to Asimov’s Three Laws."
tags: ["AI governance", "autonomous systems", "SRE", "safety", "Hinton", "Asimov", "Karma"]
categories: ["Engineering", "AI"]
slug: "safe-automation-isnt-optional"
---

# Safe Automation Isn’t Optional
*Operationalizing Geoffrey Hinton’s “Maternal Instinct” in Autonomous Systems*

By Ted Strall

## From Philosophy to Engineering

In recent talks, **Geoffrey Hinton** — one of the pioneers of modern AI — has argued that advanced autonomous systems need something like a **maternal instinct**: a built-in drive to protect, nurture, and avoid harm.

That idea matters because it puts safety at the core of system design, not as an afterthought. Most automation is built to optimize for performance. Hinton’s point is that protection and stability should be part of the architecture from the beginning.

While his focus is on general AI, the same principle applies to **autonomous infrastructure** — systems that already operate at large scale without direct human oversight.

## From Asimov’s Laws to Practical Governance

In the 1940s, science fiction writer **Isaac Asimov** imagined a future where robots were guided by three simple rules:

1. **Do no harm to humans** — and prevent harm when possible.  
2. **Obey human orders** unless they cause harm.  
3. **Protect yourself** unless doing so would cause harm or violate an order.

These “Three Laws of Robotics” were fiction, but they captured a lasting truth: **autonomous systems need embedded principles to guide their decisions.**

Hinton’s “maternal instinct” is a modern echo of that idea — safety and care as a built-in bias, not a bolt-on safeguard. **Karma** is my attempt to make such principles *practical for the systems we already run today*: a governance layer that senses context, prefers protective actions, and learns from the outcomes of every decision.

### From Fictional Laws to Practical Policies

| **Asimov’s Law** | **Karma’s Parallel in Autonomous Systems** |
|------------------|--------------------------------------------|
| **1. Do no harm to humans (and prevent harm when possible).** | Prefer protective actions over risky ones, and avoid repeating harmful actions (“memory of harm”). |
| **2. Obey human orders unless they cause harm.** | Follow operational policies unless doing so would violate safety constraints or known protective rules. |
| **3. Protect your own existence unless that causes harm or violates orders.** | Maintain system health and stability, but never at the expense of safety or policy compliance. |

> *While Asimov’s Laws focus on human safety in fictional robots, modern autonomous systems need to protect complex ecosystems — financial, technical, and operational — where “harm” can be indirect, fast-moving, and non-obvious. Karma adapts the spirit of the Laws into a form that’s enforceable in real infrastructure.*

## The Problem in Today’s Automation

Every day, critical systems run on their own:

- Financial markets execute trades in microseconds.  
- Power grids shift loads to balance demand.  
- Cloud platforms scale and reroute workloads automatically.

These automations are designed to optimize for speed, efficiency, or cost. They are not designed to prefer protective actions over risky ones.

When they behave unexpectedly, humans are still the fallback — stepping in after the fact, often under time pressure and with incomplete context.

## The Missing Layer

Hinton’s “maternal instinct” points to a governance layer that most autonomous systems lack:

- **Context awareness** — understanding what is happening in light of when, where, and why.  
- **Protective bias** — starting with low-impact, reversible actions before drastic ones.  
- **Explainability** — recording the reasoning and conditions for every decision.  
- **Memory of harm** — avoiding actions that have previously caused damage.

Without this layer, automation can be efficient under normal conditions but fragile when facing the unexpected.

## Karma: A Governance Framework for Autonomous Systems

To explore how a “maternal instinct” could be expressed in code, I’ve been developing an open-source framework called **Karma**. It governs autonomous systems in real time, embedding protective bias, context, and accountability into their control loops.

Karma works in five stages:

1. **Sense** — Gather metrics, logs, and events from across the system.  
2. **Model** — Build a live event graph showing components, relationships, and state.  
3. **Decide** — Apply policies that begin with gentle, reversible actions.  
4. **Act** — Make controlled changes (scale, throttle, rollback, failover).  
5. **Learn** — Record the decision, compare predicted vs. actual results, and adjust policy to prevent repeat harm.

The design parallels the original philosophical concept of karma — every action recorded, every consequence evaluated, and future decisions shaped by accumulated history.

## Why This Matters

**In the near term:**  
- Reduce noise and false positives in operational alerting.  
- Shorten recovery times by using low-impact remedies first.

**Over time:**  
- Provide a reusable pattern for autonomous systems that need to be explainable and safe under changing conditions.  
- Offer a governance approach that can be adapted to multiple domains — from infrastructure to AI agents — without redesigning from scratch.

The principle is simple: machine-made decisions can be **protective by default and accountable by design**.
