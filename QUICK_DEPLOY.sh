#!/bin/bash
# Quick Deployment Script - Copy and paste this entire script into your server
# Run: bash QUICK_DEPLOY.sh

set -e  # Exit on error

echo "========================================"
echo "🚀 LingAfriq Backend Quick Deploy"
echo "========================================"
echo ""

# Step 1: Get GitHub token
echo "📝 Step 1: Enter your GitHub Personal Access Token:"
read -s GITHUB_TOKEN

if [ -z "$GITHUB_TOKEN" ]; then
  echo "❌ Error: Token is required"
  exit 1
fi

echo ""
echo "✅ Token received"
echo ""

# Step 2: Backup and clone
echo "📂 Step 2: Backing up and cloning repository..."
if [ -d "/root/node-backend" ]; then
  echo "  ⚠️  Backing up existing .env..."
  cp /root/node-backend/.env /root/.env.backup 2>/dev/null || echo "  ⚠️  No .env to backup"
  rm -rf /root/node-backend
fi

echo "  📥 Cloning repository..."
git clone https://${GITHUB_TOKEN}@github.com/LingAfrika/node-backend.git /root/node-backend

if [ $? -ne 0 ]; then
  echo "  ❌ Clone failed!"
  exit 1
fi

# Restore .env
if [ -f "/root/.env.backup" ]; then
  cp /root/.env.backup /root/node-backend/.env
  rm /root/.env.backup
  echo "  ✅ .env restored"
else
  echo "  ⚠️  No .env found - you'll need to create one"
fi

echo "  ✅ Repository cloned"
echo ""

# Step 3: Check .env
echo "📝 Step 3: Checking .env file..."
cd /root/node-backend

if [ ! -f ".env" ]; then
  echo "  ⚠️  .env file not found!"
  echo "  Creating template .env file..."
  cat > .env << 'ENVEOF'
MONGODB_URI=mongodb://localhost:27017/lingafriq
JWT_SECRET=CHANGE_THIS_TO_A_SECURE_RANDOM_STRING_MINIMUM_32_CHARACTERS
PORT=4000
NODE_ENV=production
ENVEOF
  echo "  ✅ Template .env created"
  echo ""
  echo "  ⚠️  IMPORTANT: Edit .env and set your JWT_SECRET!"
  echo "  Run: nano /root/node-backend/.env"
  echo "  Then run this script again or continue manually"
  echo ""
  read -p "  Press Enter to continue (make sure JWT_SECRET is set) or Ctrl+C to exit..."
else
  echo "  ✅ .env file exists"
fi

# Step 4: Run deployment script
echo ""
echo "🔧 Step 4: Running deployment script..."
if [ -f "DEPLOY_TO_SERVER.sh" ]; then
  chmod +x DEPLOY_TO_SERVER.sh
  bash DEPLOY_TO_SERVER.sh
else
  echo "  ⚠️  DEPLOY_TO_SERVER.sh not found, running basic setup..."
  npm install
  npm run build
  pm2 restart server || pm2 start dist/server.js --name server
  pm2 save
fi

echo ""
echo "========================================"
echo "✅ DEPLOYMENT COMPLETE!"
echo "========================================"
echo ""

# Step 5: Generate token
echo "🔑 Step 5: Generating scraper token..."
if [ -f "scripts/generateScraperToken.js" ]; then
  node scripts/generateScraperToken.js
else
  echo "  ⚠️  Token generator script not found"
  echo "  You may need to run the deployment script first"
fi

echo ""
echo "========================================"
echo "📋 NEXT STEPS:"
echo "========================================"
echo ""
echo "1. Copy the scraper token above"
echo "2. Add it to GitHub Secrets:"
echo "   https://github.com/LingAfrika/node-backend/settings/secrets/actions"
echo "   - Name: SCRAPER_TOKEN"
echo "   - Value: (paste token)"
echo ""
echo "3. Add BACKEND_URL secret:"
echo "   - Name: BACKEND_URL"
echo "   - Value: https://admin.lingafriq.com"
echo ""
echo "4. Test the endpoint:"
echo "   curl http://localhost:4000/scraper/health"
echo ""
echo "========================================"

