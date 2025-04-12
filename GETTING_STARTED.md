# Getting Started

This guide walks you through creating your own serverless static website by forking and customizing this repository.

---

## Choose Your Starting Point

- **Option A: Start fresh**  
  - Create your own Github repo
  - Install go and hugo
  - Run `hugo new site .`
  - Copy [`scripts/publish_site.py`](./scripts/publish_site.py) from this repo into your new repo
  - Follow the [Serverless Static Website Quickstart](https://github.com/tstrall/adage/blob/main/quickstarts/serverless-site.md) to connect it to reusable AWS infrastructure.

- **Option B: Fork this repo**  
  Get a complete working Hugo site with a configured theme, helper scripts, and a live example you can deploy. Replace or delete the content as needed.

---

## Step 1: Fork & Rename the Repository

1. [Fork this repo on GitHub](https://github.com/tstrall/strall.com/fork)
2. On your fork’s GitHub page, click **Settings** → **Repository name**
   - Rename it to whatever you like (e.g., `my-awesome-site`)
3. Clone your renamed repo to your local machine:

   ```bash
   git clone https://github.com/YOUR_USERNAME/YOUR_REPO.git
   cd YOUR_REPO
   ```

> Replace `YOUR_USERNAME` and `YOUR_REPO` with your GitHub username and the name of your fork.

---

## Step 2: Install Required Tools

Use the provided helper scripts on Mac, Linux, or Windows WSL:

```bash
./scripts/install_go_and_hugo.sh
```

---

## Step 3: Initialize and Customize the Site

```bash
hugo new site . --force
```

Add the PaperMod theme or choose another (see [Hugo Themes](https://themes.gohugo.io/)):

```bash
git submodule add https://github.com/adityatelange/hugo-PaperMod themes/PaperMod
```

Edit `config.toml` to match your site title and menu.

---

## Step 4: Preview Locally

```bash
hugo server
```

Visit [http://localhost:1313](http://localhost:1313) to see your site.

---

## Step 5: Deploy to AWS

Use the Terraform modules from [`aws-iac`](https://github.com/tstrall/aws-iac) and configuration from [`aws-config`](https://github.com/tstrall/aws-config) to deploy to S3 + CloudFront with HTTPS and DNS support.

Refer to the [Serverless Static Website Quickstart](https://github.com/tstrall/adage/blob/main/quickstarts/serverless-site.md) for detailed setup instructions.

---

## Step 6: Publish Your Site

Once your infrastructure is deployed, use the `publish_site.py` script to upload your site content and refresh the CloudFront cache.

```bash
AWS_PROFILE=dev-iac ./scripts/publish_site.py --nickname test-site
```

To preview the S3 sync without making changes:

```bash
AWS_PROFILE=dev-iac ./scripts/publish_site.py --nickname test-site --dry-run
```

This script:
- Builds the Hugo site
- Uploads it to the correct S3 bucket based on the runtime config
- Invalidates CloudFront to reflect content changes

For full usage details and runtime config requirements, see [scripts/publish_site.md](./scripts/publish_site.md).
