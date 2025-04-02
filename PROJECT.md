# 📋 strall.com Project Roadmap

This file tracks the actual steps needed to bring `strall.com` online as a working, publicly hosted static website using Hugo + AWS + Terraform. This is the real internal checklist based on the current state.

---

## ✅ Done

- [x] Created GitHub repo: `strall.com`
- [x] Wrote and refined `README.md`
- [x] Added Apache 2.0 `LICENSE`

---

## 🧱 Setup: Hugo Site (Local)

- [x] Initialize Hugo site inside repo
- [x] Create homepage (`content/_index.md`) and basic layout
- [ ] Add one article (`content/posts/...`) as a starting point
- [ ] Verify local build using `hugo server`

---

## ☁️ Setup: AWS Infra with Terraform

- [ ] Define Terraform config in `aws-iac` for:
  - [ ] S3 bucket (static site hosting)
  - [ ] CloudFront distribution (HTTPS)
  - [ ] ACM certificate (in us-east-1)
  - [ ] Route 53 DNS record
- [ ] Deploy infrastructure to AWS
- [ ] Test HTTPS + domain routing (e.g., `https://strall.com`)

---

## 🚀 Deploy Site Content

- [ ] Run `hugo` to generate `public/` folder
- [ ] Upload contents of `public/` to S3 bucket
- [ ] Invalidate CloudFront cache (if needed)
- [ ] Confirm site is live and looks correct

---

## 📝 Final Polish

- [ ] Create `usage.md` showing real AWS costs
- [ ] Add `/about` or `/_index.md` homepage content
- [ ] Add footer or header links: GitHub, LinkedIn, etc.
- [ ] Add link to live site in `README.md`
- [ ] Enable S3 versioning or lifecycle policy (optional)

---

## 📣 Launch & Share

- [ ] Announce on LinkedIn (or elsewhere)
- [ ] Add link to GitHub profile bio
