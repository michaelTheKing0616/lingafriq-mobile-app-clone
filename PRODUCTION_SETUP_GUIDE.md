# 🚀 LingAfriq Production Setup Guide

Complete guide for setting up all optional production features.

---

## ✅ ALREADY WORKING (No Setup Needed!)

These features work with your current configuration:

### Voice Recognition
```bash
VOICE_SERVICE_URL=http://localhost:5051  # ✅ Already configured
HUGGINGFACE_TOKEN=hf_oJi...              # ✅ Already configured
```
**Status**: Ready to use!

### TTS (Text-to-Speech)
```bash
VOICE_SERVICE_URL=http://localhost:5051  # ✅ Already configured
HUGGINGFACE_TOKEN=hf_oJi...              # ✅ Already configured
```
**Status**: Ready to use!

### Redis Caching
```bash
REDIS_HOST=127.0.0.1  # ✅ Already configured
REDIS_PORT=6379       # ✅ Already configured
```
**Status**: Ready to use!

---

## 📦 OPTIONAL ENHANCEMENTS

### 1. CDN Setup for File Uploads

**Purpose**: Serve uploaded files (images, audio, video) from a separate domain for security and performance.

#### Why You Need This:
- ✅ Better security (isolate user-uploaded content)
- ✅ Better performance (CDN caching)
- ✅ Reduced server load
- ✅ Prevent XSS attacks from uploaded files

#### Option A: Cloudflare R2 (FREE - 10GB/month)

**Step 1**: Create Cloudflare R2 Account
```bash
# Go to: https://dash.cloudflare.com/
# Navigate to: R2 Object Storage
# Click: "Create bucket"
# Bucket name: lingafriq-uploads
```

**Step 2**: Get R2 API Credentials
```bash
# In Cloudflare Dashboard:
# R2 > Manage R2 API Tokens > Create API Token
# Copy: Access Key ID and Secret Access Key
```

**Step 3**: Add to Backend `.env`
```bash
# CDN Configuration
CDN_DOMAIN=https://uploads.lingafriq.com
CDN_PROVIDER=cloudflare-r2
CDN_BUCKET=lingafriq-uploads
CDN_REGION=auto
R2_ACCESS_KEY_ID=your_access_key_here
R2_SECRET_ACCESS_KEY=your_secret_key_here
R2_ACCOUNT_ID=your_account_id_here

# Alternative: Use Cloudflare Workers URL
CDN_DOMAIN=https://lingafriq-uploads.r2.cloudflarestorage.com
```

**Step 4**: Update DNS (Optional - for custom domain)
```bash
# In Cloudflare DNS settings:
# Add CNAME record:
# Name: uploads
# Target: lingafriq-uploads.r2.cloudflarestorage.com
```

#### Option B: AWS S3 Free Tier (5GB)

**Step 1**: Create S3 Bucket
```bash
aws s3 mb s3://lingafriq-uploads --region us-east-1
```

**Step 2**: Enable Public Read (for serving files)
```bash
aws s3api put-bucket-policy --bucket lingafriq-uploads --policy '{
  "Version": "2012-10-17",
  "Statement": [{
    "Sid": "PublicReadGetObject",
    "Effect": "Allow",
    "Principal": "*",
    "Action": "s3:GetObject",
    "Resource": "arn:aws:s3:::lingafriq-uploads/*"
  }]
}'
```

**Step 3**: Get AWS Credentials
```bash
# Go to: AWS IAM Console
# Create new user with S3 access
# Save: Access Key ID and Secret Access Key
```

**Step 4**: Add to Backend `.env`
```bash
CDN_DOMAIN=https://lingafriq-uploads.s3.amazonaws.com
CDN_PROVIDER=aws-s3
CDN_BUCKET=lingafriq-uploads
CDN_REGION=us-east-1
AWS_ACCESS_KEY_ID=your_access_key_here
AWS_SECRET_ACCESS_KEY=your_secret_key_here
```

#### Option C: Local File Server (For Testing)

**Step 1**: Create uploads directory
```bash
mkdir -p /var/www/lingafriq-uploads
chmod 755 /var/www/lingafriq-uploads
```

**Step 2**: Configure Nginx to serve files
```nginx
# /etc/nginx/sites-available/uploads.lingafriq.com
server {
    listen 80;
    server_name uploads.lingafriq.com;
    
    root /var/www/lingafriq-uploads;
    
    # Security headers
    add_header X-Content-Type-Options nosniff;
    add_header X-Frame-Options DENY;
    add_header Content-Security-Policy "default-src 'none'; img-src 'self'; media-src 'self';";
    
    # Serve files
    location / {
        try_files $uri =404;
    }
}
```

**Step 3**: Enable site
```bash
sudo ln -s /etc/nginx/sites-available/uploads.lingafriq.com /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

**Step 4**: Add to Backend `.env`
```bash
CDN_DOMAIN=http://uploads.lingafriq.com
FILE_UPLOAD_PATH=/var/www/lingafriq-uploads
```

---

### 2. Database Backups

**Purpose**: Automated MongoDB backups with retention policy.

#### Step 1: Install mongodump (if not already installed)
```bash
# Ubuntu/Debian
sudo apt-get install mongodb-database-tools

# macOS
brew install mongodb-database-tools

# Windows
# Download from: https://www.mongodb.com/try/download/database-tools
```

#### Step 2: Create Backup Directory
```bash
mkdir -p /var/backups/lingafriq
chmod 700 /var/backups/lingafriq  # Secure permissions
```

#### Step 3: Add to Backend `.env`
```bash
# Database Backup Configuration
BACKUP_DIR=/var/backups/lingafriq
BACKUP_RETENTION_DAYS=7  # Keep backups for 7 days

# Optional: Cloud backup
BACKUP_CLOUD_PROVIDER=s3  # or 'gcs' for Google Cloud Storage
BACKUP_CLOUD_BUCKET=lingafriq-backups
```

#### Step 4: Test Manual Backup
```bash
cd /path/to/node-backend-main
node -e "import('./dist/utils/backup.js').then(m => m.backupService.createBackup())"
```

#### Step 5: Schedule Automated Backups (Cron)
```bash
# Edit crontab
crontab -e

# Add this line (backup daily at 2 AM)
0 2 * * * cd /path/to/node-backend-main && node -e "import('./dist/utils/backup.js').then(m => m.backupService.createBackup())" >> /var/log/lingafriq-backup.log 2>&1
```

#### Step 6: Setup Backup to Cloud (Optional)

**For AWS S3:**
```bash
# Install AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# Configure AWS
aws configure
# Enter: AWS Access Key ID, Secret Access Key, Region (us-east-1)

# Add to .env
BACKUP_CLOUD_PROVIDER=s3
BACKUP_CLOUD_BUCKET=lingafriq-backups
BACKUP_CLOUD_REGION=us-east-1
```

**For Google Cloud Storage:**
```bash
# Install gcloud CLI
curl https://sdk.cloud.google.com | bash
exec -l $SHELL
gcloud init

# Create bucket
gsutil mb gs://lingafriq-backups

# Add to .env
BACKUP_CLOUD_PROVIDER=gcs
BACKUP_CLOUD_BUCKET=lingafriq-backups
```

---

### 3. HTTPS Certificates (Let's Encrypt - FREE)

**Purpose**: Secure your API with HTTPS.

#### Option A: Certbot (Recommended for Production)

**Step 1**: Install Certbot
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install certbot python3-certbot-nginx

# macOS
brew install certbot

# Windows (WSL recommended)
wsl --install
# Then run Ubuntu commands above
```

**Step 2**: Get Certificate
```bash
# For domain: api.lingafriq.com
sudo certbot --nginx -d api.lingafriq.com

# Follow prompts:
# - Enter email address
# - Agree to terms
# - Redirect HTTP to HTTPS: Yes
```

**Step 3**: Certbot Auto-Renewal
```bash
# Test renewal
sudo certbot renew --dry-run

# Auto-renewal is already configured by Certbot
# Certificates will renew automatically
```

**Step 4**: Add to Backend `.env`
```bash
# Certificates (Certbot manages these automatically)
SSL_CERT_PATH=/etc/letsencrypt/live/api.lingafriq.com/fullchain.pem
SSL_KEY_PATH=/etc/letsencrypt/live/api.lingafriq.com/privkey.pem

# Enable HTTPS in Node.js
NODE_ENV=production
ENABLE_HTTPS=true
```

#### Option B: Cloudflare (Easiest - Zero Config)

**Step 1**: Add Domain to Cloudflare
```bash
# Go to: https://dash.cloudflare.com/
# Click: "Add a Site"
# Enter: lingafriq.com
# Select: Free plan
```

**Step 2**: Update Nameservers
```bash
# Cloudflare will show you 2 nameservers like:
# ns1.cloudflare.com
# ns2.cloudflare.com

# Go to your domain registrar (e.g., GoDaddy, Namecheap)
# Update nameservers to Cloudflare's nameservers
```

**Step 3**: Enable SSL
```bash
# In Cloudflare Dashboard:
# SSL/TLS > Overview > Select: "Full (strict)"
# SSL/TLS > Edge Certificates > Enable: "Always Use HTTPS"
```

**Step 4**: No Backend Changes Needed!
```bash
# Cloudflare handles HTTPS automatically
# Your backend can still use HTTP (Cloudflare will encrypt)
# Just ensure: NODE_ENV=production
```

#### Option C: Self-Signed (Development Only)

**Step 1**: Generate Certificate
```bash
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes
```

**Step 2**: Add to Backend `.env`
```bash
SSL_CERT_PATH=/path/to/cert.pem
SSL_KEY_PATH=/path/to/key.pem
ENABLE_HTTPS=true
```

**⚠️ Warning**: Self-signed certificates will show browser warnings. Use only for development!

---

### 4. ClamAV Virus Scanning (Optional but Recommended)

**Purpose**: Scan uploaded files for viruses/malware.

#### Step 1: Install ClamAV

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install clamav clamav-daemon

# Update virus definitions
sudo freshclam

# Start daemon
sudo systemctl start clamav-daemon
sudo systemctl enable clamav-daemon
```

**macOS:**
```bash
brew install clamav

# Create config files
sudo mkdir -p /opt/homebrew/etc/clamav
sudo cp /opt/homebrew/etc/clamav/freshclam.conf.sample /opt/homebrew/etc/clamav/freshclam.conf
sudo cp /opt/homebrew/etc/clamav/clamd.conf.sample /opt/homebrew/etc/clamav/clamd.conf

# Update virus definitions
sudo freshclam

# Start daemon
brew services start clamav
```

**Windows:**
```bash
# Download from: https://www.clamav.net/downloads
# Or use WSL (recommended)
```

#### Step 2: Configure ClamAV

**Edit daemon config:**
```bash
sudo nano /etc/clamav/clamd.conf

# Uncomment these lines:
TCPSocket 3310
TCPAddr 127.0.0.1
```

**Restart daemon:**
```bash
sudo systemctl restart clamav-daemon
```

#### Step 3: Test ClamAV
```bash
# Test with EICAR test file (harmless test virus)
wget https://secure.eicar.org/eicar.com
clamdscan eicar.com
# Should detect: "Eicar-Test-Signature FOUND"

# Clean up
rm eicar.com
```

#### Step 4: No Backend Config Needed!
```bash
# File upload middleware will automatically use ClamAV if installed
# It gracefully falls back if ClamAV is not available
```

#### Step 5: Monitor ClamAV
```bash
# Check daemon status
sudo systemctl status clamav-daemon

# Check logs
sudo tail -f /var/log/clamav/clamav.log

# Update virus definitions manually
sudo freshclam
```

---

## 🔄 Updating Configuration

### After Adding Any New Environment Variables:

**Step 1**: Update `.env` file
```bash
cd /path/to/node-backend-main
nano .env
# Add new variables
```

**Step 2**: Restart Backend
```bash
# If using PM2
pm2 restart lingafriq-backend

# If using systemd
sudo systemctl restart lingafriq-backend

# If running directly
# Stop with Ctrl+C
npm start

# If using Docker
docker-compose restart backend
```

**Step 3**: Verify Configuration
```bash
# Check health endpoint
curl http://localhost:4000/health/detailed

# Should show:
# - Redis: connected
# - Database: connected
# - All services: operational
```

---

## 🧪 Testing Your Setup

### Test CDN Upload
```bash
curl -X POST http://localhost:4000/api/media/upload \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "file=@test-image.jpg"

# Should return URL starting with CDN_DOMAIN
```

### Test Backup
```bash
curl http://localhost:4000/api/admin/backup/create \
  -H "Authorization: Bearer ADMIN_TOKEN"

# Check backup directory
ls -lh /var/backups/lingafriq/
```

### Test HTTPS
```bash
curl https://api.lingafriq.com/health
# Should return 200 OK without certificate errors
```

### Test ClamAV
```bash
# Upload a test file
curl -X POST http://localhost:4000/api/media/upload \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -F "file=@clean-file.jpg"

# Should succeed

# Try uploading EICAR test file (will be blocked)
```

---

## 🚨 Troubleshooting

### CDN Issues
```bash
# Check CDN configuration
curl http://localhost:4000/health/detailed | jq '.services.cdn'

# Check file permissions
ls -la /var/www/lingafriq-uploads/

# Check nginx logs
sudo tail -f /var/log/nginx/error.log
```

### Backup Issues
```bash
# Check mongodump is installed
which mongodump

# Check backup directory permissions
ls -la /var/backups/lingafriq/

# Check MongoDB connection
mongosh --eval "db.adminCommand('ping')"

# Check backup logs
tail -f /var/log/lingafriq-backup.log
```

### Certificate Issues
```bash
# Check certificate expiry
sudo certbot certificates

# Renew certificate manually
sudo certbot renew --force-renewal

# Check nginx config
sudo nginx -t

# Check SSL configuration
openssl s_client -connect api.lingafriq.com:443 -servername api.lingafriq.com
```

### ClamAV Issues
```bash
# Check daemon status
sudo systemctl status clamav-daemon

# Check if socket is listening
netstat -an | grep 3310

# Update definitions
sudo freshclam

# Check virus database version
clamdscan --version

# Restart daemon
sudo systemctl restart clamav-daemon
```

---

## 📊 Monitoring Your Setup

### Health Checks
```bash
# Basic health
curl http://localhost:4000/health

# Detailed health (includes all services)
curl http://localhost:4000/health/detailed

# Readiness (Kubernetes)
curl http://localhost:4000/health/ready

# Liveness (Kubernetes)
curl http://localhost:4000/health/live
```

### Redis Monitoring
```bash
# Connect to Redis
redis-cli

# Check stats
INFO stats

# Monitor commands in real-time
MONITOR

# Check memory usage
INFO memory
```

### MongoDB Monitoring
```bash
# Connect to MongoDB
mongosh

# Check database stats
use lingafriq
db.stats()

# Check collection sizes
db.user.stats()

# Check current operations
db.currentOp()
```

---

## 🎯 Production Checklist

Before deploying to production, ensure:

### Required (Must Have)
- ✅ HTTPS enabled (Let's Encrypt or Cloudflare)
- ✅ Environment variables configured
- ✅ Database backups scheduled
- ✅ Redis running and connected
- ✅ Health endpoints responding
- ✅ Firewall configured
- ✅ Rate limiting active

### Recommended (Should Have)
- ✅ CDN configured for file uploads
- ✅ ClamAV virus scanning installed
- ✅ Monitoring/alerting setup
- ✅ Log rotation configured
- ✅ Backup restoration tested
- ✅ Load testing completed

### Optional (Nice to Have)
- ⭐ Cloud backup to S3/GCS
- ⭐ CDN with custom domain
- ⭐ Kubernetes deployment
- ⭐ Multi-region setup
- ⭐ Read replicas for MongoDB

---

## 💡 Quick Start (Minimum Production Setup)

If you want to go to production quickly with minimum setup:

```bash
# 1. Use Cloudflare for HTTPS (zero config)
# Add domain to Cloudflare, update nameservers - Done!

# 2. Keep file uploads local for now
CDN_DOMAIN=http://localhost:4000
FILE_UPLOAD_PATH=/var/uploads

# 3. Setup basic backups
mkdir -p /var/backups/lingafriq
BACKUP_DIR=/var/backups/lingafriq
BACKUP_RETENTION_DAYS=7

# 4. Add to crontab (daily backups)
0 2 * * * cd /path/to/backend && node -e "import('./dist/utils/backup.js').then(m => m.backupService.createBackup())"

# 5. Restart backend
pm2 restart all
```

**That's it!** You're production-ready with minimal setup.

---

## 📚 Additional Resources

- [Cloudflare R2 Docs](https://developers.cloudflare.com/r2/)
- [Let's Encrypt Docs](https://letsencrypt.org/docs/)
- [ClamAV Documentation](https://docs.clamav.net/)
- [MongoDB Backup Guide](https://www.mongodb.com/docs/manual/core/backups/)
- [Redis Best Practices](https://redis.io/docs/management/optimization/)

---

**Need Help?** All these features are optional and won't affect core functionality!

