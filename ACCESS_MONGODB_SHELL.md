# Access MongoDB Shell

## For MongoDB 3.6 (Your Version)

Use `mongo` instead of `mongosh`:

```bash
mongo
```

If that doesn't work, try:

```bash
mongo --host localhost --port 27017
```

Or with authentication (if you know the credentials):

```bash
mongo -u username -p password --authenticationDatabase admin
```

## Check MongoDB Status

First, check if MongoDB is running:

```bash
sudo systemctl status mongod
# Or:
sudo service mongod status
```

## If MongoDB Shell Doesn't Work

### Option 1: Install MongoDB Shell (mongosh)

For newer MongoDB versions:

```bash
# Install mongosh
curl -fsSL https://www.mongodb.org/static/pgp/server-6.0.asc | sudo gpg -o /usr/share/keyrings/mongodb-server-6.0.gpg --dearmor
echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-6.0.gpg ] https://repo.mongodb.org/apt/ubuntu focal/mongodb-org/6.0 multiverse" | sudo tee /etc/apt/sources.list.d/mongodb-org-6.0.list
sudo apt-get update
sudo apt-get install -y mongodb-mongosh
```

### Option 2: Use mongo (Legacy)

For MongoDB 3.6, use the legacy `mongo` shell:

```bash
mongo
```

If it's not in PATH, find it:

```bash
which mongo
# Or:
find /usr -name mongo 2>/dev/null
```

## Quick Fix: Check Current MongoDB Connection

Instead of accessing the shell, you can check your current MongoDB setup:

```bash
cd /root/node-backend
cat .env | grep MONGODB_URI
```

This will show your current connection string. If it doesn't have username/password, that's the problem.

## Alternative: Disable MongoDB Authentication

If you want to disable authentication (for local development):

1. **Edit MongoDB config:**
   ```bash
   sudo nano /etc/mongod.conf
   ```

2. **Comment out or remove the security section:**
   ```yaml
   # security:
   #   authorization: enabled
   ```

3. **Restart MongoDB:**
   ```bash
   sudo systemctl restart mongod
   # Or:
   sudo service mongod restart
   ```

4. **Keep your connection string simple:**
   ```env
   MONGODB_URI=mongodb://localhost:27017/lingafriq
   ```

5. **Restart backend:**
   ```bash
   cd /root/node-backend
   pm2 restart server
   ```

---

**Try `mongo` first (for MongoDB 3.6), or disable authentication if this is a local development server!**

