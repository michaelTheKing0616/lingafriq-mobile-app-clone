# Restore Backend Directory

## The Problem

PM2 is configured to run from `/root/node-backend/dist/server.js`, but the directory doesn't exist. The backend might have been deleted or moved.

## Solution: Clone and Set Up Fresh

### Step 1: Check if Directory Exists

```bash
ls -la /root/node-backend
```

If it says "No such file or directory", proceed to Step 2.

### Step 2: Clone the Repository

```bash
cd /root
git clone https://YOUR_GITHUB_TOKEN@github.com/LingAfrika/node-backend.git /root/node-backend
```

Replace `YOUR_GITHUB_TOKEN` with your actual GitHub token.

### Step 3: Set Up Environment Variables

```bash
cd /root/node-backend
nano .env
```

Add these (use your actual values):

```env
MONGODB_URI=mongodb://localhost:27017/lingafriq
JWT_SECRET=google
PORT=4000
NODE_ENV=production
```

Save: Ctrl+X, Y, Enter

### Step 4: Install Dependencies and Build

```bash
cd /root/node-backend
npm install
npm run build
```

### Step 5: Restart PM2

```bash
# Stop and delete the old process
pm2 stop server
pm2 delete server

# Start fresh from the correct location
cd /root/node-backend
pm2 start dist/server.js --name server
pm2 save
```

### Step 6: Verify It's Running

```bash
pm2 status
pm2 logs server --lines 20
```

You should see:
- ✅ "app is connected to mongodb table"
- ✅ "app is running on port 4000"

### Step 7: Test the Scraper Endpoint

```bash
curl http://localhost:4000/scraper/health
```

Should return JSON with `success: true`.

---

**Run these commands in order to restore your backend!**

