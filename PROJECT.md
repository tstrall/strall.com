# strall.com Project Roadmap

This file tracks the actual steps needed to bring `strall.com` online as a working, publicly hosted static website using Hugo + AWS + Terraform. This is the real internal checklist based on the current state.

---

## Done

- [x] Created GitHub repo: `strall.com`
- [x] Wrote and refined `README.md`
- [x] Added Apache 2.0 `LICENSE`

---

## Setup: Hugo Site (Local)

- [x] Initialize Hugo site inside repo
- [x] Create homepage (`content/_index.md`) and basic layout
- [x] Add one article (`content/posts/...`) as a starting point
- [x] Verify local build using `hugo server`

---

## Setup: AWS Infra with Terraform

- [x] Define Terraform config in `aws-iac` for:
  - [x] S3 bucket (static site hosting)
  - [x] CloudFront distribution (HTTPS)
  - [ ] ACM certificate (in us-east-1)
  - [ ] Route 53 DNS record
- [x] Deploy infrastructure to AWS
- [x] Test HTTPS + domain routing (e.g., `https://strall.com`)

---

## Deploy Site Content

- [x] Run `hugo` to generate `public/` folder
- [x] Upload contents of `public/` to S3 bucket
- [x] Invalidate CloudFront cache (if needed)
- [ ] Confirm site is live and looks correct

---

## Final Polish

- [ ] Create `usage.md` showing real AWS costs
- [x] Add `/about` or `/_index.md` homepage content
- [x] Add link to live site in `README.md`
- [ ] Enable S3 versioning or lifecycle policy (optional)

---

## Launch & Share

- [ ] Announce on LinkedIn (or elsewhere)
- [ ] Add link to GitHub profile bio
