#!/bin/bash
set -euo pipefail

# Usage: AWS_PROFILE=dev-iac ./deploy.sh [component] nickname
# If only one argument is given, component defaults to serverless-site

if [[ $# -eq 1 ]]; then
  COMPONENT="serverless-site"
  NICKNAME="$1"
elif [[ $# -eq 2 ]]; then
  COMPONENT="$1"
  NICKNAME="$2"
else
  echo "Usage: AWS_PROFILE=your-profile ./deploy.sh [component] nickname"
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
"$SCRIPT_DIR/publish_site.py" --component "$COMPONENT" "$NICKNAME"
