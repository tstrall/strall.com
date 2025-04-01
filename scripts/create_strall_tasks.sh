#!/bin/bash

REPO="tstrall/strall.com"
PROJECT_NAME="strall.com"
GITHUB_USER="tstrall"

TASKS=(
  "Configure strall.com GitHub repo:::Ensure README and LICENSE are up to date"
  "Initialize Hugo site locally:::Run: hugo new site . and add default layout/content"
  "Create first post for homepage:::Write content/_index.md and content/posts/..."
  "Set up Terraform config in aws-iac:::Define S3, CloudFront, ACM, Route 53 modules"
  "Deploy infrastructure to AWS:::Run: terraform apply and verify"
  "Build site using Hugo:::Run: hugo to generate public/ folder"
  "Upload content to S3:::Run: aws s3 sync public/ s3://your-bucket-name"
  "Invalidate CloudFront cache:::Optional but helpful for clean deploy"
  "Verify live site via HTTPS:::Check https://strall.com in a browser"
  "Create /usage page:::Summarize AWS cost based on actual use"
  "Link to GETTING_STARTED.md in README:::Improves visibility for users"
  "Create announcement draft:::Optional LinkedIn post or tweet"
  "Write HOWTO.md for others:::Step-by-step guide for forkers"
)

# Get the project number (not GraphQL ID!) using gh-projects (GitHub CLI extension)
PROJECT_NUM=$(gh projects list --user "$GITHUB_USER" --format json | jq -r ".projects[] | select(.title==\"$PROJECT_NAME\") | .number")

if [ -z "$PROJECT_NUM" ]; then
  echo "❌ Project '$PROJECT_NAME' not found under user '$GITHUB_USER'."
  exit 1
fi

echo "✅ Using project: $PROJECT_NAME (Number: $PROJECT_NUM)"

for task in "${TASKS[@]}"; do
  TITLE=$(echo "$task" | cut -d':' -f1)
  BODY=$(echo "$task" | cut -d':' -f4)

  echo "➕ Creating issue: $TITLE"
  ISSUE_URL=$(gh issue create --repo "$REPO" --title "$TITLE" --body "$BODY" --web=false | grep -Eo 'https://github.com/[^ ]+')

  if [ -z "$ISSUE_URL" ]; then
    echo "⚠️ Failed to create or capture issue URL for: $TITLE"
    continue
  fi

  echo "🔗 Linking issue to project..."
  gh projects item-add "$PROJECT_NUM" --user "$GITHUB_USER" --url "$ISSUE_URL"
done