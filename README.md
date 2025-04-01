# strall.com

This is the source code and content for [strall.com](https://strall.com) — a personal portfolio and demo hub built using my open-source AWS infrastructure framework.

## 🛠️ Build Your Own Serverless Static Website

Want to create your own **serverless, HTTPS-enabled static website** on AWS?

This repo is designed as a starting point for anyone who owns a domain name and wants to deploy a clean, fast, and fully serverless website using the same tools and infrastructure behind [strall.com](https://strall.com).

The site is built using [Hugo](https://gohugo.io/) and deployed to AWS using modular Terraform components from [`aws-iac`](https://github.com/tstrall/aws-iac), configured with [`aws-config`](https://github.com/tstrall/aws-config).

### ✅ Get Started

1. **Fork this repo**
2. Follow the [Getting Started Guide](./GETTING_STARTED.md)
3. Add your own content (Markdown, images, custom pages)
4. Configure your domain (Route 53 or external)
5. Deploy using Terraform modules from [`aws-iac`](https://github.com/tstrall/aws-iac)

---

## 🚀 What's Included

- Hugo-based static site
- Markdown-powered articles and documentation
- Deployment to S3 + CloudFront with HTTPS via ACM
- DNS hosted with Route 53
- Real usage & cost transparency
- Clean structure for others to fork and use

---

## 📄 Content Structure

```text
content/            # Articles, homepage, and post content
layouts/            # Hugo templates
static/             # Static assets (e.g., CSS, images)
config.toml         # Hugo site configuration
deploy/             # Optional deployment scripts
```

---

## 📃 Usage and Cost

This infrastructure is designed to have low operational overhead. You’ll be paying for:

- A Route 53 hosted zone (~$0.50/month)
- Any data transfer out from CloudFront (~$0.085/GB after Free Tier)
- S3 storage and requests (minimal for most static sites)

Actual charges will depend on your usage and AWS region. See [usage](https://strall.com/usage) for real-world examples from this deployment. storage, bandwidth, request volume, and DNS charges.

---

## 📎 Links

- 🌍 [Live Site](https://strall.com)
- 📘 [aws-iac GitHub Repo](https://github.com/tstrall/aws-iac)
- ⚙️ [aws-config GitHub Repo](https://github.com/tstrall/aws-config)
- 🧠 [Latest Article](https://strall.com/posts/config-driven-aws)
- 💼 [LinkedIn](https://www.linkedin.com/in/ted-strall-1057b44/)
- 📂 [GitHub Profile](https://github.com/tstrall)

---

## 📜 License

This project is licensed under the [Apache 2.0 License](LICENSE).

---

## 👩‍💻 Author

Built and maintained by [tstrall](https://strall.com).

This site is part of a larger open-source effort to define reusable AWS infrastructure and configuration strategies. Fork it, explore it, or use it as your own starting point.
