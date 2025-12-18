# 🔒 Nginx Reverse Proxy Setup (Secure Backend)

## ✅ BEST PRACTICE ARCHITECTURE

Keep your backend bound to `127.0.0.1` (localhost only) and use Nginx as a reverse proxy.

### **Architecture:**
```
Internet (Mobile App, GitHub Actions)
    ↓ (HTTPS on port 443)
Nginx Reverse Proxy
    ↓ (HTTP to localhost:4000)
Backend (binds to 127.0.0.1:4000 only)
    ↓
MongoDB (localhost)
```

**Benefits:**
- ✅ Backend never directly exposed to internet
- ✅ Nginx handles SSL/TLS encryption
- ✅ Nginx can add rate limiting, caching, DDoS protection
- ✅ Backend stays on localhost (most secure)
- ✅ Mobile app and GitHub Actions connect via Nginx

---

## 🚀 SETUP NGINX (5 Minutes)

### **Step 1: Install Nginx**

```bash
# Update packages
apt update

# Install nginx
apt install nginx -y

# Start nginx
systemctl start nginx
systemctl enable nginx

# Check status
systemctl status nginx
```

---

### **Step 2: Create Nginx Configuration**

```bash
# Create config file
nano /etc/nginx/sites-available/lingafriq-backend
```

**Paste this configuration:**

```nginx
server {
    listen 80;
    server_name admin.lingafriq.com;

    # Increase timeout for scraper
    proxy_connect_timeout 600;
    proxy_send_timeout 600;
    proxy_read_timeout 600;
    send_timeout 600;

    # Proxy all requests to backend
    location / {
        proxy_pass http://127.0.0.1:4000;
        proxy_http_version 1.1;
        
        # WebSocket support (for chat)
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        
        # Forward real IP
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # CORS headers (if needed)
        add_header Access-Control-Allow-Origin * always;
        add_header Access-Control-Allow-Methods 'GET, POST, PUT, DELETE, OPTIONS' always;
        add_header Access-Control-Allow-Headers 'Content-Type, Authorization' always;
        
        if ($request_method = 'OPTIONS') {
            return 204;
        }
    }

    # Rate limiting for scraper endpoint (optional)
    location /scraper/ {
        limit_req zone=scraper_limit burst=5;
        proxy_pass http://127.0.0.1:4000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    # Static files and media
    location /media/ {
        proxy_pass http://127.0.0.1:4000;
    }
}

# Rate limit zone (add to top of file)
limit_req_zone $binary_remote_addr zone=scraper_limit:10m rate=10r/m;
```

**Save:** `Ctrl+X`, then `Y`, then `Enter`

---

### **Step 3: Enable the Configuration**

```bash
# Create symbolic link
ln -s /etc/nginx/sites-available/lingafriq-backend /etc/nginx/sites-enabled/

# Remove default config (optional)
rm /etc/nginx/sites-enabled/default

# Test nginx config
nginx -t

# Should show: "syntax is okay" and "test is successful"

# Reload nginx
systemctl reload nginx
```

---

### **Step 4: Configure Backend to Bind to Localhost**

**In your backend `.env` file:**

```bash
# Edit .env
nano /root/node-backend/.env
```

**Make sure it has:**
```bash
# Bind to localhost only (secure!)
HOST=127.0.0.1
PORT=4000

# Or if your server.js uses different variables:
BIND_IP=127.0.0.1
```

**Save and restart:**
```bash
pm2 restart server
```

---

### **Step 5: Test Everything**

```bash
# Test from localhost (should work)
curl http://127.0.0.1:4000/healthcheck
curl http://127.0.0.1:4000/scraper/health

# Test from outside via nginx (should also work)
curl http://admin.lingafriq.com/healthcheck
curl http://admin.lingafriq.com/scraper/health

# Both should return JSON!
```

---

## 🔐 OPTIONAL: Add SSL (HTTPS)

### **Use Let's Encrypt (Free SSL):**

```bash
# Install certbot
apt install certbot python3-certbot-nginx -y

# Get SSL certificate
certbot --nginx -d admin.lingafriq.com

# Follow prompts:
# - Enter email
# - Agree to terms
# - Choose: Redirect HTTP to HTTPS

# Auto-renewal
certbot renew --dry-run
```

**After SSL:**
- Mobile app uses: `https://admin.lingafriq.com` ✅
- GitHub Actions uses: `https://admin.lingafriq.com` ✅
- Backend stays on localhost:4000 ✅

---

## 🎯 MEANWHILE: FIX GIT ISSUE

**The corrupted package.json needs to be fixed first:**

```bash
cd /root/node-backend

# Check what's in package.json
cat package.json

# If it shows "404: Not Found", restore it:
# Download from GitHub directly (different method)
wget -O package.json https://github.com/LingAfrika/node-backend/raw/main/package.json

# Or restore from backup:
cp backups/package-backup-*.json package.json

# Then install:
npm install
```

---

## 🔄 OR: Fresh Clone Approach

**Easiest - Start fresh:**

```bash
# Backup current
mv /root/node-backend /root/node-backend-old

# Clone fresh (no auth needed for public repo)
cd /root
git clone https://github.com/LingAfrika/node-backend.git

# Navigate
cd node-backend

# Copy your .env from old
cp /root/node-backend-old/.env .env

# Install
npm install

# Build
npm run build

# Update PM2
pm2 delete server
pm2 start dist/server.js --name server
pm2 save

# Test
curl http://localhost:4000/scraper/health
```

---

## ✅ RECOMMENDED APPROACH

**Do this in order:**

1. **Fix package.json** (restore or re-download)
2. **Install & build**
3. **Set up Nginx reverse proxy**
4. **Keep backend on 127.0.0.1** (secure!)
5. **Test via nginx**
6. **Add SSL (optional but recommended)**

---

**Which do you want to try first:**
1. Fresh clone (easiest)
2. Fix current installation
3. Set up Nginx first, then fix backend

Let me know and I'll guide you through! 🚀
