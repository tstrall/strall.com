# 🚀 Getting Started

This guide walks you through launching your own **serverless, HTTPS-enabled static website** on AWS using Hugo and Terraform — starting from this repo.

Once you complete these steps, you'll have a fully deployed personal site, live under your own domain, built with clean AWS infrastructure and fully under your control.

---

## ✅ Getting Started

- [ ] Fork this repo to your GitHub account
- [ ] Clone it to your machine:
  ```bash
  git clone https://github.com/YOUR_USERNAME/strall.com.git
  cd strall.com
  ```
- [ ] Install [Hugo](https://gohugo.io/getting-started/installing/) locally
- [ ] Review the `README.md` and project structure

---

## ⚙️ Configure Your Site

- [ ] Update `config.toml` with your site's title, baseURL, and settings
- [ ] Edit or replace `content/_index.md` (homepage)
- [ ] Add your first article under `content/posts/`
- [ ] Optionally customize or install a Hugo theme
- [ ] Test locally:
  ```bash
  hugo server
  ```

---

## ☁️ Deploy AWS Infrastructure

> You'll need an AWS account and access to deploy with Terraform.

- [ ] Clone or reference [`aws-iac`](https://github.com/tstrall/aws-iac)
- [ ] Configure Terraform modules to create:
  - [ ] S3 bucket for static hosting
  - [ ] CloudFront distribution
  - [ ] ACM certificate for HTTPS (must be in `us-east-1`)
  - [ ] Route 53 hosted zone or DNS records
- [ ] Run `terraform apply` to deploy your infrastructure

---

## 🚀 Publish Your Site

- [ ] Generate the static site:
  ```bash
  hugo
  ```
- [ ] Upload the contents of the `public/` directory to your S3 bucket
- [ ] Invalidate the CloudFront cache (optional)
- [ ] Visit your domain in a browser and verify HTTPS is working

---

## ✨ Optional Enhancements

- [ ] Add a `/usage` page to show AWS costs
- [ ] Enable GitHub Actions for automated deploys
- [ ] Add a custom theme, contact link, or resume section

---

## 💡 Notes

- This setup uses only low-cost AWS services (S3, CloudFront, ACM, Route 53)
- With typical usage, it can run for under $1/month
- You fully own and control your domain, content, and infra

Questions or ideas? Open an issue or fork and customize away!

Happy deploying! 🚀
