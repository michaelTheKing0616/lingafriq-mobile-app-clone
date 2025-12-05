#!/bin/bash
# Script to clone/update the backend repo using a GitHub Personal Access Token
# Run this on your DigitalOcean server

echo "========================================"
echo "🔐 Clone Backend Repository"
echo "========================================"
echo ""

# Prompt for GitHub token
echo "Enter your GitHub Personal Access Token:"
read -s GITHUB_TOKEN

if [ -z "$GITHUB_TOKEN" ]; then
  echo "❌ Error: Token is required"
  exit 1
fi

echo ""
echo "📂 Setting up repository..."

# Remove old directory if it exists
if [ -d "/root/node-backend" ]; then
  echo "⚠️  Backing up existing .env file..."
  cp /root/node-backend/.env /root/.env.backup 2>/dev/null || echo "No .env found to backup"
  
  echo "🗑️  Removing old directory..."
  rm -rf /root/node-backend
fi

# Clone using token
echo "📥 Cloning repository..."
git clone https://${GITHUB_TOKEN}@github.com/LingAfrika/node-backend.git /root/node-backend

if [ $? -ne 0 ]; then
  echo "❌ Clone failed. Check your token and repository access."
  exit 1
fi

# Restore .env if it was backed up
if [ -f "/root/.env.backup" ]; then
  echo "✅ Restoring .env file..."
  cp /root/.env.backup /root/node-backend/.env
  rm /root/.env.backup
else
  echo "⚠️  No .env file found. You'll need to create one."
fi

echo ""
echo "========================================"
echo "✅ Repository cloned successfully!"
echo "========================================"
echo ""
echo "Next steps:"
echo "1. cd /root/node-backend"
echo "2. Create/verify .env file has all required variables"
echo "3. Run: bash DEPLOY_TO_SERVER.sh"
echo "4. Generate scraper token: node scripts/generateScraperToken.js"
echo ""

