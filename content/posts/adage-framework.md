---
title: "Adage: A Configuration-Driven AWS Deployment Framework"
date: 2024-04-09
description: "A detailed guide on using config-driven architecture to scale AWS environments without hardcoding or Terraform overload."
tags: ["aws", "terraform", "devops", "automation"]
---

![Adage: A Configuration-Driven AWS Deployment Framework](/img/adage-system-diagram.png)

### Traditional AWS Deployments Are Holding You Back

If you've worked with AWS long enough, you’ve likely experienced these pain points:

- Manually updating Terraform every time a new environment or feature is needed
- Hardcoded infrastructure dependencies that make it difficult to scale
- Multiple teams needing access to Terraform, even if they only manage configurations
- Lack of auditability — who changed what, and when?

The traditional way of managing AWS infrastructure forces DevOps teams into bottlenecks and makes scaling complex architectures painful.

#### There’s a better way: Configuration-Driven AWS Deployments.

---

### The Configuration-Driven AWS Deployment Model

Instead of modifying Terraform every time something needs to be deployed, we separate **infrastructure development from deployment management**.

#### 1️⃣ Build Once, Deploy Anywhere

- Terraform engineers create reusable infrastructure components (VPC, Aurora DB, S3, Lambda, etc.)
- These components do not hardcode environment names or dependencies — everything is resolved dynamically
- References between components are defined via nicknames, ensuring that dependencies are discovered dynamically rather than through static mappings

#### 2️⃣ Deployment Is Fully Controlled by a Config Repo

- A JSON-based config repo defines what gets deployed and where
- Non-technical teams can update the config repo to trigger deployments — no Terraform needed
- Terraform fails if the config is missing, ensuring that only pre-approved components get deployed
- Every deployment is backed by Git, ensuring a clear, auditable history of changes and approvals

#### 3️⃣ Lambda Functions Are Developed & Deployed Separately

- Lambdas are independent of Terraform and can be built, tested, and deployed in isolation
- At runtime, they resolve dependencies dynamically using AWS Parameter Store
- This enables microservices and event-driven architectures without tight coupling

#### 4️⃣ Dynamic Dependency Resolution Instead of Hardcoded References

- Each deployed component registers itself in AWS Parameter Store after Terraform execution
- Other components dynamically discover their dependencies at runtime — no need for explicit cross-references in Terraform
- Nicknames provide a predictable lookup pattern
- Example: An RDS instance dynamically finds its VPC and subnets based on a nickname-driven lookup mechanism

#### 5️⃣ Scale & Evolve Architectures Using Config Updates

- Adding a new database, Lambda function, or microservice doesn’t require modifying Terraform
- Instead, teams update the config repo to define new deployments and connections
- This enables feature branches, parallel deployments, and sophisticated architectures — all controlled via simple config updates

#### 6️⃣ Built-In Security and Auditability

- All deployments are controlled via Git, ensuring version-controlled, trackable changes
- Access to modify configurations can be tightly restricted through Git permissions and AWS IAM policies
- Rollback and recovery are simplified, as previous configurations can always be restored
- No unauthorized changes — if it's not in Git, Terraform won't deploy it

---

### How It Works: Three Repositories Working Together

The **Adage** guide explains how to use the model:  👉 [View on GitHub](https://github.com/tstrall/adage)

This system is built around three Git repositories:

1. **Infrastructure as Code (`aws-iac`)**  👉 [View on GitHub](https://github.com/tstrall/aws-iac)

2. **Configuration (`aws-config`)**  👉 [View on GitHub](https://github.com/tstrall/aws-config)

3. **Lambda Functions (`aws-lambda`)**  👉 [View on GitHub](https://github.com/tstrall/aws-lambda)

This separation ensures Terraform engineers focus on building, while configuration managers control deployments.

---

### Why This Model Is a Game-Changer

✅ You only build infrastructure & application code once — no Terraform edits for each deployment  
✅ Deployment is fully controlled by config managers — no Terraform or AWS knowledge required  
✅ Lambdas are developed & tested in isolation  
✅ Terraform only deploys what's explicitly defined in the config repo  
✅ Engineers build, others deploy — with no coupling  
✅ Supports parallel deployments and feature branches  
✅ New services can be deployed just by updating configs  
✅ Auditability and rollback come for free via Git  
✅ Security-first model — no Git, no deploy

---

### Getting Started

Want to implement this model? Here’s what to do next:

1. Fork the [`aws-iac`](https://github.com/tstrall/aws-iac), [`aws-config`](https://github.com/tstrall/aws-config) and [`aws-lambda`](https://github.com/tstrall/aws-lambda) repositories  
2. Set up a CI/CD pipeline to sync the config repo with AWS Parameter Store  
3. Define IAM policies to restrict changes to `/iac/.../config` entries  
4. Deploy and test your first configuration-driven AWS environment!

---

**What do you think? Would this approach simplify your AWS deployments?**
