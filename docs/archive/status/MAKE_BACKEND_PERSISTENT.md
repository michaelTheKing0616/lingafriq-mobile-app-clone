# Make Backend Persistent - Never Lose It Again

## Step 1: Verify Current Setup

First, make sure everything is working:

```bash
# Check backend exists
ls -la /root/node-backend

# Check PM2 is running
pm2 status

# Check backend is accessible
curl http://localhost:4000/scraper/health
```

## Step 2: Save PM2 Configuration Permanently

PM2 needs to be saved so it restarts on server reboot:

```bash
# Save current PM2 process list
pm2 save

# Generate startup script (runs PM2 on boot)
pm2 startup

# This will output a command like:
# sudo env PATH=$PATH:/usr/bin pm2 startup systemd -u root --hp /root
# Copy and run that command!
```

After running `pm2 startup`, it will give you a command to run. **Copy and run that exact command!**

## Step 3: Verify PM2 Will Start on Boot

```bash
# Check if startup script exists
systemctl status pm2-root 2>/dev/null || systemctl status pm2-$(whoami) 2>/dev/null

# Or check the service
systemctl list-units | grep pm2
```

## Step 4: Create a Backup Script (Optional but Recommended)

Create a script to quickly restore if needed:

```bash
cd /root
cat > restore-backend.sh << 'EOF'
#!/bin/bash
echo "Restoring backend..."

if [ ! -d "/root/node-backend" ]; then
    echo "Backend not found. Cloning..."
    git clone https://YOUR_GITHUB_TOKEN@github.com/LingAfrika/node-backend.git /root/node-backend
    cd /root/node-backend
    
    # Create .env if it doesn't exist
    if [ ! -f ".env" ]; then
        cat > .env << 'ENVEOF'
MONGODB_URI=mongodb://localhost:27017/lingafriq
JWT_SECRET=google
PORT=4000
NODE_ENV=production
ENVEOF
    fi
    
    npm install
    npm run build
    pm2 start dist/server.js --name server
    pm2 save
    echo "✅ Backend restored!"
else
    echo "Backend exists. Updating..."
    cd /root/node-backend
    git pull origin main
    npm install
    npm run build
    pm2 restart server
    echo "✅ Backend updated!"
fi
EOF

chmod +x restore-backend.sh
echo "✅ Backup script created at /root/restore-backend.sh"
```

**Note:** Replace `YOUR_GITHUB_TOKEN` in the script with your actual token, or better yet, use an environment variable.

## Step 5: Protect the Directory (Prevent Accidental Deletion)

```bash
# Make the directory read-only for others (optional)
chmod 755 /root/node-backend

# Or create a simple protection script
cat > /root/protect-backend.sh << 'EOF'
#!/bin/bash
if [ ! -d "/root/node-backend" ]; then
    echo "⚠️  WARNING: Backend directory missing!"
    echo "Run: /root/restore-backend.sh"
fi
EOF

chmod +x /root/protect-backend.sh
```

## Step 6: Set Up Automatic Updates (Optional)

Create a cron job to pull updates daily:

```bash
# Edit crontab
crontab -e

# Add this line (runs daily at 3 AM, pulls updates, rebuilds, restarts)
0 3 * * * cd /root/node-backend && git pull origin main && npm run build && pm2 restart server
```

## Step 7: Verify Everything is Saved

```bash
# Check PM2 saved processes
pm2 list
pm2 save

# Verify startup script
pm2 startup

# Test: Reboot the server (if safe to do so)
# After reboot, check:
# pm2 status
# Should show server running automatically
```

## Step 8: Document Your Setup

Create a quick reference file:

```bash
cat > /root/BACKEND_INFO.txt << 'EOF'
Backend Location: /root/node-backend
PM2 Process Name: server
Port: 4000
Environment: production

To update:
cd /root/node-backend
git pull origin main
npm run build
pm2 restart server

To restore if deleted:
/root/restore-backend.sh

PM2 Commands:
- pm2 status          # Check status
- pm2 logs server     # View logs
- pm2 restart server  # Restart
- pm2 stop server     # Stop
EOF

cat /root/BACKEND_INFO.txt
```

## Quick Checklist

- [ ] Backend directory exists at `/root/node-backend`
- [ ] PM2 process is running (`pm2 status`)
- [ ] PM2 saved (`pm2 save`)
- [ ] PM2 startup configured (`pm2 startup` + ran the command)
- [ ] Backend responds to health check (`curl http://localhost:4000/scraper/health`)
- [ ] Backup script created (`/root/restore-backend.sh`)
- [ ] Documentation created (`/root/BACKEND_INFO.txt`)

---

## Most Important: PM2 Startup

The **most critical step** is running `pm2 startup` and then executing the command it gives you. This ensures PM2 (and your backend) starts automatically when the server reboots.

**Run this now:**
```bash
pm2 startup
# Then copy and run the command it outputs!
```

---

**After completing these steps, your backend will persist across reboots and be easy to restore if needed!**

