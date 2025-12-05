# Find and Update Backend on Server

## Step 1: Find Where the Backend Is

Run these commands to locate your backend:

```bash
# Check if node-backend exists anywhere
find /root -name "node-backend" -type d 2>/dev/null

# Check where PM2 is running the server from
pm2 info server | grep "script path"

# Or check the PM2 process details
pm2 describe server
```

## Step 2: Check Current Directory Structure

```bash
# See what's in /root
ls -la /root

# Check if there's a backend somewhere else
ls -la /var/www 2>/dev/null
ls -la /opt 2>/dev/null
```

## Step 3: If Backend Doesn't Exist, Clone It Again

If you can't find it, clone it fresh:

```bash
cd /root
git clone https://YOUR_GITHUB_TOKEN@github.com/LingAfrika/node-backend.git /root/node-backend
cd /root/node-backend
```

## Step 4: If Backend Exists Elsewhere

If you find it in a different location (e.g., `/var/www/node-backend`), navigate there:

```bash
cd /path/to/node-backend  # Replace with actual path
git pull origin main
npm run build
pm2 restart server
```

## Step 5: Update PM2 to Point to Correct Location

If the backend is in a different location, update PM2:

```bash
# Stop current server
pm2 stop server
pm2 delete server

# Start from correct location
cd /path/to/node-backend  # Replace with actual path
pm2 start dist/server.js --name server
pm2 save
```

---

**Run the find commands first to locate your backend!**

