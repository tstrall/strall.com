---
title: "Terraform Is Not Object-Oriented — But My Infrastructure Is"
date: 2025-04-21
slug: "object-oriented-terraform"
description: "A config-first framework that makes modular, identity-aware deployments behave like object-oriented systems—even in Terraform."
---

![Adage system diagram](/img/adage-system-diagram.png)
*A high-level view of how Adage handles configuration-driven deployments*

Terraform wasn’t designed for object-oriented programming. It’s declarative, static, and prefers duplication over abstraction. But infrastructure doesn’t have to be.

With the right separation of concerns, you can make your infrastructure modular, composable, and runtime-aware. You can design a system where components behave more like objects: isolated, testable, and able to change behavior based on identity and configuration.

That’s what I set out to build. The result is [Adage](https://adage.usekarma.dev), a configuration-first deployment framework that brings object-oriented design to Terraform-based infrastructure—and lays the groundwork for [Karma](https://usekarma.dev), a system for modeling infrastructure as a living graph of change and consequence.

---

## Terraform Modules Are Not Objects

Terraform has modules, but they don’t encapsulate behavior the way software objects do. There’s no native support for inheritance, runtime polymorphism, or identity-based logic.

Most Terraform stacks are written per environment. They’re static, environment-bound, and contain hardcoded conditionals that duplicate logic instead of abstracting it.

But what if we treated infrastructure modules as configurable objects, and drove everything from an external configuration layer?

---

## Simulating OOP in Terraform

Here’s how Adage brings object-oriented principles into Terraform:

- **Encapsulation**  
  Traditional Terraform modules are just collections of files. There's no enforced boundary between what a module can or should touch.  
  *Adage:* Each component only acts on approved config pulled from AWS Parameter Store, ensuring clean separation of responsibility.

- **Composition**  
  Terraform supports composition, but it often leads to boilerplate and inconsistent reuse.  
  *Adage:* Components are composed from reusable shared logic and runtime-resolved configuration, minimizing duplication.

- **Inheritance**  
  Terraform has no built-in inheritance, so shared behavior must be duplicated or awkwardly wrapped.  
  *Adage:* Common behavior is centralized in shared `common` modules and injected into components via config.

- **Polymorphism**  
  Without runtime type awareness, Terraform uses hardcoded `count`, `for_each`, or `conditional` logic to switch behavior.  
  *Adage:* Components switch behavior dynamically based on values stored in Parameter Store, enabling runtime-dispatch-like behavior.

- **Runtime Safety**  
  Terraform doesn't have built-in promotion or rollback strategies—validation is manual and error-prone.  
  *Adage:* Controlled switchover, input validation, and config promotion are part of the framework, giving you runtime safety by design.

---

## The Core Ideas

- All deployment behavior is defined in Git, pushed to Parameter Store
- Components are deployed by name, not by writing code
- Nothing deploys unless it’s been explicitly defined and validated
- Runtime parameters are managed separately and can be promoted or rolled back
- Identity (like `dev`, `prod`, or `main-vpc`) determines behavior dynamically

This means infrastructure isn’t just code—it’s a system of objects, each with state, lineage, and a known identity.

---

## A Simple Example

To deploy a component like `aurora-postgres` for `dev`, you:

1. Define a config block in your `aws-config` repo
2. Push it to `/aurora-postgres/<nickname>/config` in Parameter Store
3. Deploy using a shared wrapper that knows how to handle the component

The Terraform logic is reused. The behavior is defined by config. The system resolves everything at runtime based on your account's environment binding.

---

## Why It Matters

Most infrastructure is written in a way that’s hard to test, hard to scale, and hard to reason about. By introducing structure—especially runtime-aware structure—you can:

- Eliminate copy-paste infrastructure
- Define shared behaviors once, and reuse them safely
- Build for change without fearing drift
- Treat deployments as versioned objects, not static scripts

This also opens the door to traceability, observability, and graph-based system modeling.

---

## Try It

You can get started by visiting [Adage](https://adage.usekarma.dev). The quickstart guides walk you through:

- Creating a reusable infrastructure layout
- Defining configuration in a separate Git repo
- Deploying fully controlled components using `terragrunt`

It’s designed to scale from a single developer to an organization with many environments and accounts.

---

## Related Reading

If you're interested in how infrastructure can evolve beyond code into a traceable, graph-based system, check out [Introducing Karma: Infrastructure as Consequence](https://www.strall.com/posts/introducing-karma/). It builds on the ideas in Adage and treats infrastructure as data, change as consequence, and systems as lineage-aware graphs.
