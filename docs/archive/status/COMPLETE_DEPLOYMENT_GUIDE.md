# Complete Backend Deployment Guide

## Prerequisites
- ✅ GitHub Personal Access Token (you have this!)
- ✅ SSH access to your DigitalOcean server
- ✅ Backend repository URL: `https://github.com/LingAfrika/node-backend.git`

---

## Step 1: Connect to Your Server

Open your terminal/SSH client and connect to your server:

```bash
ssh root@your-server-ip
# Or if you use a domain:
ssh root@admin.lingafriq.com
```

---

## Step 2: Clone the Repository

### Option A: Using the Script (Recommended)

1. **Upload the clone script to your server:**

   On your **local machine** (Windows), you can use SCP or just copy-paste the script content.

2. **On your server, create the script:**

   ```bash
   cd /root
   nano clone-repo.sh
   ```

3. **Paste this content:**

   ```bash
   #!/bin/bash
   echo "========================================"
   echo "🔐 Clone Backend Repository"
   echo "========================================"
   echo ""
   
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
   ```

4. **Save and exit** (Ctrl+X, then Y, then Enter)

5. **Make it executable and run:**

   ```bash
   chmod +x clone-repo.sh
   ./clone-repo.sh
   ```

6. **When prompted, paste your GitHub token** (it won't show on screen for security)

### Option B: Manual Clone (Alternative)

If the script doesn't work, do it manually:

```bash
# Replace YOUR_TOKEN with your actual GitHub token
cd /root
git clone https://YOUR_TOKEN@github.com/LingAfrika/node-backend.git /root/node-backend
```

---

## Step 3: Verify Repository Cloned

Check that the files are there:

```bash
cd /root/node-backend
ls -la
```

You should see:
- `package.json`
- `src/` directory
- `tsconfig.json`
- etc.

---

## Step 4: Set Up Environment Variables

1. **Check if .env exists:**

   ```bash
   cd /root/node-backend
   ls -la .env
   ```

2. **If .env doesn't exist, create it:**

   ```bash
   nano .env
   ```

3. **Add these required variables:**

   ```env
   # MongoDB Connection (use your local MongoDB)
   MONGODB_URI=mongodb://localhost:27017/lingafriq
   # Or if MongoDB requires authentication:
   # MONGODB_URI=mongodb://username:password@localhost:27017/lingafriq
   
   # JWT Secret (KEEP YOUR EXISTING VALUE!)
   # ⚠️ DO NOT CHANGE THIS - it would break existing user sessions!
   JWT_SECRET=google
   
   # Scraper Secret (optional but recommended for better security)
   # If not set, scraper will use JWT_SECRET
   # Generate with: openssl rand -base64 32
   SCRAPER_SECRET=your-secure-random-string-here
   
   # Server Port (optional, defaults to 4000)
   PORT=4000
   
   # Environment (optional)
   NODE_ENV=production
   ```

4. **Save and exit** (Ctrl+X, then Y, then Enter)

   **Important:** 
   - **KEEP `JWT_SECRET=google`** - This is your existing secret. Changing it would:
     - Invalidate all existing user login tokens
     - Force all users to log in again
     - Break any existing API integrations
   - `SCRAPER_SECRET` is optional - if you don't set it, the scraper will use `JWT_SECRET`
   - You can generate a secure `SCRAPER_SECRET` with: `openssl rand -base64 32`
   - Make sure `MONGODB_URI` matches your actual MongoDB setup

---

## Step 5: Upload and Run Deployment Script

1. **On your server, create the deployment script:**

   ```bash
   cd /root/node-backend
   nano DEPLOY_TO_SERVER.sh
   ```

2. **Copy the entire content from `DEPLOY_TO_SERVER.sh`** (from your local machine) and paste it into the nano editor.

3. **Save and exit** (Ctrl+X, then Y, then Enter)

4. **Make it executable:**

   ```bash
   chmod +x DEPLOY_TO_SERVER.sh
   ```

5. **Run the deployment script:**

   ```bash
   bash DEPLOY_TO_SERVER.sh
   ```

   This will:
   - Create backups
   - Add the scraper route
   - Update index routes
   - Install dependencies
   - Build TypeScript
   - Restart PM2

6. **Watch for any errors** - if you see errors, note them down.

---

## Step 6: Verify Backend is Running

1. **Check PM2 status:**

   ```bash
   pm2 status
   ```

   You should see `server` with status `online`.

2. **Check PM2 logs for errors:**

   ```bash
   pm2 logs server --lines 50
   ```

   Look for:
   - ✅ "app is connected to mongodb table"
   - ✅ "app is running on port 4000"
   - ❌ Any error messages

3. **Test the scraper health endpoint:**

   ```bash
   curl http://localhost:4000/scraper/health
   ```

   Expected response:
   ```json
   {
     "success": true,
     "message": "Scraper API is running",
     "timestamp": "2025-12-04T..."
   }
   ```

4. **If the backend isn't running, check:**

   ```bash
   # Check if MongoDB is running
   systemctl status mongod
   # Or
   ps aux | grep mongod
   
   # Check if port 4000 is in use
   netstat -tulpn | grep 4000
   ```

---

## Step 7: Generate Scraper JWT Token

1. **Generate the token:**

   ```bash
   cd /root/node-backend
   node scripts/generateScraperToken.js
   ```

2. **Copy the entire token** that's displayed (it's a long string)

   Example output:
   ```
   ==========================================
   ✅ SCRAPER TOKEN GENERATED
   ==========================================
   
   eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJ0eXBlIjoic2NyYXBlciIsInB1cnBvc2UiOiJhdXRvbWF0ZWRfY29udGVudF9pbXBvcnQiLCJnZW5lcmF0ZWQiOiIyMDI1LTEyLTA0VDE4OjAwOjAwLjAwMFoifQ.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
   
   Add this to GitHub Secrets as SCRAPER_TOKEN
   ==========================================
   ```

3. **Keep this token safe** - you'll need it in the next step!

---

## Step 8: Add Secrets to GitHub

1. **Go to your GitHub repository:**
   - Navigate to: `https://github.com/LingAfrika/node-backend`

2. **Go to Settings → Secrets and variables → Actions**

3. **Add the following secrets:**

   ### Secret 1: `SCRAPER_TOKEN`
   - Click **"New repository secret"**
   - Name: `SCRAPER_TOKEN`
   - Value: (paste the token from Step 7)
   - Click **"Add secret"**

   ### Secret 2: `BACKEND_URL`
   - Click **"New repository secret"**
   - Name: `BACKEND_URL`
   - Value: `https://admin.lingafriq.com`
   - Click **"Add secret"**

   ### Secret 3: `MONGODB_URI` (if needed)
   - Only add this if your GitHub Actions workflow needs direct MongoDB access
   - For the API approach, you don't need this!

---

## Step 9: Test the Complete Setup

1. **Test from your server:**

   ```bash
   # Test health endpoint
   curl http://localhost:4000/scraper/health
   
   # Test with authentication (replace TOKEN with your scraper token)
   curl -X POST http://localhost:4000/scraper/articles/bulk \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer YOUR_SCRAPER_TOKEN_HERE" \
     -d '{"articles": [{"title": "Test Article", "content": "Test content", "category": "history", "country": "Nigeria"}]}'
   ```

2. **Test from GitHub Actions:**
   - Go to: `https://github.com/LingAfrika/node-backend/actions`
   - Manually trigger the scraper workflow (if available)
   - Or wait for the scheduled run
   - Check the logs to see if articles are being saved

---

## Step 10: Verify Everything Works

### Checklist:

- [ ] Repository cloned successfully
- [ ] `.env` file created with all required variables
- [ ] Deployment script ran without errors
- [ ] PM2 shows `server` as `online`
- [ ] `curl http://localhost:4000/scraper/health` returns success
- [ ] Scraper token generated
- [ ] GitHub Secrets added (`SCRAPER_TOKEN` and `BACKEND_URL`)
- [ ] Backend accessible from outside (if using Nginx reverse proxy)

---

## Troubleshooting

### Problem: "Cannot connect to MongoDB"

**Solution:**
```bash
# Check if MongoDB is running
systemctl status mongod

# If not running, start it
systemctl start mongod

# Check MongoDB connection string in .env
cat /root/node-backend/.env | grep MONGODB_URI
```

### Problem: "Port 4000 already in use"

**Solution:**
```bash
# Find what's using port 4000
lsof -i :4000

# Kill the process or change PORT in .env
```

### Problem: "PM2 server not found"

**Solution:**
```bash
# Start the server with PM2
cd /root/node-backend
pm2 start dist/server.js --name server
pm2 save
```

### Problem: "Cannot generate scraper token"

**Solution:**
```bash
# Check if JWT_SECRET or SCRAPER_SECRET exists in .env
cat /root/node-backend/.env | grep -E "JWT_SECRET|SCRAPER_SECRET"

# If JWT_SECRET is missing, add it (use your existing value "google")
echo "JWT_SECRET=google" >> /root/node-backend/.env

# Optional: Add a separate SCRAPER_SECRET for better security
echo "SCRAPER_SECRET=$(openssl rand -base64 32)" >> /root/node-backend/.env

# Rebuild and restart
cd /root/node-backend
npm run build
pm2 restart server
```

**Note:** Keep `JWT_SECRET=google` to avoid breaking existing user sessions!

### Problem: "Git clone fails with authentication"

**Solution:**
- Verify your GitHub token has `repo` scope
- Make sure you're using the token, not your password
- Try the token in a browser first: `https://YOUR_TOKEN@github.com/LingAfrika/node-backend.git`

---

## Next Steps

Once everything is working:

1. **Monitor the backend:**
   ```bash
   pm2 monit
   ```

2. **Set up automatic backups** (optional)

3. **Configure Nginx reverse proxy** (if not already done)

4. **Test the GitHub Actions scraper workflow**

---

## Support

If you encounter any issues:
1. Check PM2 logs: `pm2 logs server --lines 100`
2. Check system logs: `journalctl -u mongod` (if using systemd)
3. Verify all environment variables: `cat /root/node-backend/.env`
4. Test MongoDB connection: `mongo` or `mongosh` (depending on version)

---

**Good luck! 🚀**

