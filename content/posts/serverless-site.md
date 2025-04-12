---
title: "Build a Serverless Static Site on AWS in Minutes — with Adage"
date: 2025-04-12
description: "Use the Adage open source framework to deploy a fully serverless static website on AWS using config-driven infrastructure and Git-based workflows."
tags: ["aws", "serverless", "terraform", "s3", "cloudfront", "adage"]
categories: ["quickstart", "deployment"]
draft: false
---

![Serverless Static Website](/img/serverless-site.drawio.png)

## The fastest way to go live with infrastructure you actually understand

What if you could deploy a secure, fast, fully serverless website on AWS using just a JSON config file — and know exactly how it works under the hood?

That’s the idea behind [**Adage:** A Configuration-Driven AWS Deployment Framework](https://github.com/tstrall/adage) that separates your infrastructure, your config, and your application code into distinct, composable layers.

In this guide, you'll see how to go from zero to live in a few minutes using the `serverless-site` component — and how this approach gives you clarity, repeatability, and control without locking you into someone else's boilerplate.

---

## What You'll Deploy

- Amazon S3 for hosting your static content  
- CloudFront for global CDN distribution  
- ACM and Route 53 for HTTPS and DNS  
- SSM Parameter Store as the configuration backbone  

No Terraform editing. No AWS Console clicking. Just a config file and a deploy script.

---

## Step 1 – Define Your Config

Create a JSON file in the `aws-config` repo:

```json
{
  "content_bucket_prefix": "mydemo.strall.com",
  "site_name": "mydemo.strall.com",
  "route53_zone_name": "strall.com",
  "domain_aliases": ["www.mydemo.strall.com"],
  "enable_custom_domain": true,
  "cloudfront_comment": "Public demo site",
  "tags": {
    "project": "adage",
    "environment": "dev"
  }
}
```

Give it a nickname (e.g., `mydemo`) and deploy the config to AWS Parameter Store:

```sh
cd aws-config/
AWS_PROFILE=dev-iac ./scripts/deploy.sh serverless-site mydemo
```

---

## Step 2 – Deploy Infrastructure

From the `aws-iac` repo, deploy the infrastructure:

```sh
cd aws-iac/
AWS_PROFILE=dev-iac ./scripts/deploy.sh serverless-site mydemo
```

Terraform reads the config from Parameter Store and provisions everything: S3, CloudFront, DNS, and ACM.

---

## Step 3 – Publish Your Site

Once deployed, publish your static content:

```sh
cd strall.com/
AWS_PROFILE=dev-iac ./scripts/deploy.sh serverless-site mydemo
```

The script builds your Hugo site, syncs it to S3, and triggers a CloudFront invalidation. If a custom domain was configured, it will print the live URL.

---

## What This Pattern Enables

This approach provides:

- Reusable Terraform components across environments  
- Git-controlled JSON configs to drive all deployments  
- Dynamic dependency resolution using AWS Parameter Store  
- Clean separation of concerns: infrastructure, config, and code  
- Fast teardown and rebuild cycles with consistent state  

---

## Teardown is Simple Too

You can destroy the infrastructure without removing the config:

```sh
cd aws-iac/
AWS_PROFILE=dev-iac ./deploy.sh serverless-site mydemo --destroy
```

Your config remains in Git and Parameter Store for future use.

---

## Try It Yourself

1. Fork the [Adage repos](https://github.com/tstrall/adage)  
2. Create a config for your project  
3. Deploy your first live component  
4. Build from there

To see the full quickstart and details, visit:

[Serverless Static Website Quickstart](https://github.com/tstrall/adage/blob/main/quickstarts/serverless-site.md)
