#!/bin/bash
set -e

# Install GitHub CLI from official GitHub repo (Debian/Ubuntu)
echo "🛠 Installing GitHub CLI..."

# Install dependencies
sudo apt update
sudo apt install -y curl apt-transport-https

# Add GitHub CLI package repository
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
  sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg

echo \ 
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | \
  sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null

# Install gh CLI
sudo apt update
sudo apt install gh -y

# Verify installation
echo "✅ GitHub CLI version installed:"
gh version

# Install jq via apt
sudo apt update
sudo apt install -y jq

# Verify installation
echo "✅ jq version installed:"
jq --version
