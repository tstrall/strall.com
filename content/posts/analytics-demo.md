---
title: "Building a Modern Data Stack with dbt, BigQuery, and Tableau"
date: 2025-04-25
description: "End-to-end demo project: dbt transformations, BigQuery cloud warehouse, Tableau dashboard. Fully modular, automated, and production-ready."
tags: ["dbt", "bigquery", "tableau", "analytics", "modern-data-stack"]
---

![Building a Modern Data Stack with dbt, BigQuery, and Tableau](/img/dbt-analytics-demo.png)

I've published a full working demo of a modern analytics stack:

- dbt transformations modeled with raw → staging → marts
- BigQuery as the cloud data warehouse
- Tableau dashboard visualizing business metrics
- Fully modular, automated, and environment-agnostic setup

Explore the project:

- [Analytics Repo on GitHub](https://github.com/tstrall/analytics)
- [View Dashboard on Tableau Public](https://public.tableau.com/app/profile/ted.strall/viz/dbtAnalyticsDemo/Revenue)

Everything is built to be portable, extensible, and reproducible — designed both for demonstration and as a real starting point for more complex pipelines.

---

## Built With

- [dbt](https://www.getdbt.com/) — Data transformation
- [Google BigQuery](https://cloud.google.com/bigquery) — Cloud data warehouse
- [Tableau Public](https://public.tableau.com/) — Data visualization
- [GitHub](https://github.com/) — Source control

---

## What's Next

This version focuses on BigQuery + dbt + Tableau. Future improvements may include:

- Snowflake version
- Automated data ingestion with Fivetran
- Alternative visualization layers
