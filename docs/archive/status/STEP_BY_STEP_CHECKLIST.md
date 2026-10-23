# Step-by-Step Deployment Checklist

## ✅ Pre-Flight Check
- [ ] You have your GitHub Personal Access Token ready
- [ ] You have SSH access to your server
- [ ] You know your MongoDB connection details

---

## 🚀 Deployment Steps

### Step 1: Connect to Server
```bash
ssh root@your-server-ip
# or
ssh root@admin.lingafriq.com
```

**Status:** ⬜ Not Started | 🟡 In Progress | ✅ Complete

---

### Step 2: Clone Repository

**Option A: Quick Script (Recommended)**

1. On your server, create the script:
   ```bash
   cd /root
   nano quick-clone.sh
   ```

2. Paste this content:
   ```bash
   #!/bin/bash
   echo "Enter GitHub token:"
   read -s TOKEN
   if [ -d "/root/node-backend" ]; then
     cp /root/node-backend/.env /root/.env.backup 2>/dev/null
     rm -rf /root/node-backend
   fi
   git clone https://${TOKEN}@github.com/LingAfrika/node-backend.git /root/node-backend
   if [ -f "/root/.env.backup" ]; then
     cp /root/.env.backup /root/node-backend/.env
   fi
   ```

3. Save (Ctrl+X, Y, Enter), then run:
   ```bash
   chmod +x quick-clone.sh
   ./quick-clone.sh
   ```

**Option B: One-Line Command**
```bash
git clone https://YOUR_TOKEN@github.com/LingAfrika/node-backend.git /root/node-backend
```

**Verify:**
```bash
cd /root/node-backend
ls -la
# Should see: package.json, src/, tsconfig.json, etc.
```

**Status:** ⬜ Not Started | 🟡 In Progress | ✅ Complete

---

### Step 3: Set Up Environment Variables

1. Check if .env exists:
   ```bash
   cd /root/node-backend
   ls -la .env
   ```

2. If missing, create it:
   ```bash
   nano .env
   ```

3. Add these lines (replace with your actual values):
   ```env
   MONGODB_URI=mongodb://localhost:27017/lingafriq
   JWT_SECRET=google
   SCRAPER_SECRET=generate-with-openssl-rand-base64-32
   PORT=4000
   NODE_ENV=production
   ```

4. **IMPORTANT:** Keep `JWT_SECRET=google` (your existing secret)
   - Changing this would invalidate all existing user sessions!
   - Users would be logged out and need to log in again

5. Generate a secure SCRAPER_SECRET (optional but recommended):
   ```bash
   openssl rand -base64 32
   # Copy the output and paste it as SCRAPER_SECRET value
   # If you skip this, the scraper will use JWT_SECRET ("google")
   ```

5. Save file (Ctrl+X, Y, Enter)

**Status:** ⬜ Not Started | 🟡 In Progress | ✅ Complete

---

### Step 4: Deploy Code

1. Upload `DEPLOY_TO_SERVER.sh` to your server, or create it:
   ```bash
   cd /root/node-backend
   # Copy content from DEPLOY_TO_SERVER.sh on your local machine
   nano DEPLOY_TO_SERVER.sh
   # Paste the entire script content
   ```

2. Make executable and run:
   ```bash
   chmod +x DEPLOY_TO_SERVER.sh
   bash DEPLOY_TO_SERVER.sh
   ```

3. Watch for errors - the script should:
   - ✅ Create backups
   - ✅ Add scraper route
   - ✅ Install dependencies
   - ✅ Build TypeScript
   - ✅ Restart PM2

**Status:** ⬜ Not Started | 🟡 In Progress | ✅ Complete

---

### Step 5: Verify Backend is Running

1. Check PM2:
   ```bash
   pm2 status
   # Should show "server" as "online"
   ```

2. Check logs:
   ```bash
   pm2 logs server --lines 20
   # Look for: "app is connected to mongodb table"
   # Look for: "app is running on port 4000"
   ```

3. Test endpoint:
   ```bash
   curl http://localhost:4000/scraper/health
   # Should return JSON with success: true
   ```

**Status:** ⬜ Not Started | 🟡 In Progress | ✅ Complete

---

### Step 6: Generate Scraper Token

1. Generate token:
   ```bash
   cd /root/node-backend
   node scripts/generateScraperToken.js
   ```

2. **COPY THE ENTIRE TOKEN** (long string that appears)

3. Keep it safe - you'll need it next!

**Status:** ⬜ Not Started | 🟡 In Progress | ✅ Complete

---

### Step 7: Add GitHub Secrets

1. Go to: https://github.com/LingAfrika/node-backend/settings/secrets/actions

2. Click **"New repository secret"**

3. Add `SCRAPER_TOKEN`:
   - Name: `SCRAPER_TOKEN`
   - Value: (paste token from Step 6)
   - Click **"Add secret"**

4. Add `BACKEND_URL`:
   - Click **"New repository secret"** again
   - Name: `BACKEND_URL`
   - Value: `https://admin.lingafriq.com`
   - Click **"Add secret"**

**Status:** ⬜ Not Started | 🟡 In Progress | ✅ Complete

---

### Step 8: Final Verification

1. Test from server:
   ```bash
   curl http://localhost:4000/scraper/health
   ```

2. Check GitHub Actions:
   - Go to: https://github.com/LingAfrika/node-backend/actions
   - Verify workflows can access secrets

**Status:** ⬜ Not Started | 🟡 In Progress | ✅ Complete

---

## 🎉 You're Done!

All steps complete? Your backend should now be:
- ✅ Deployed and running
- ✅ Accessible via API
- ✅ Ready for automated content scraping
- ✅ Connected to MongoDB
- ✅ Secured with JWT tokens

---

## 🆘 Need Help?

**Common Issues:**

| Problem | Solution |
|---------|----------|
| Clone fails | Check token has `repo` scope |
| MongoDB error | Verify `MONGODB_URI` in .env |
| PM2 not running | Run `pm2 start dist/server.js --name server` |
| Token generation fails | Check `JWT_SECRET` exists in .env |
| Port 4000 in use | Change `PORT` in .env or kill process |

**Get Logs:**
```bash
pm2 logs server --lines 100
```

---

**Good luck! 🚀**

