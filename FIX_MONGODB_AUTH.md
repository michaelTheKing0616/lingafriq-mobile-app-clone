# Fix MongoDB Authentication Error

## The Problem

The error `MongoServerError: there are no users authenticated` means MongoDB requires authentication, but your connection string doesn't include credentials.

## Solution Options

### Option 1: Add Authentication to Connection String (Recommended)

If your MongoDB has authentication enabled, update your `.env` file:

```bash
cd /root/node-backend
nano .env
```

Change:
```env
MONGODB_URI=mongodb://localhost:27017/lingafriq
```

To (with username and password):
```env
MONGODB_URI=mongodb://username:password@localhost:27017/lingafriq
```

**Replace `username` and `password` with your actual MongoDB credentials.**

### Option 2: Disable MongoDB Authentication (If Local Development)

If this is a local MongoDB and you want to disable authentication:

1. **Edit MongoDB config:**
   ```bash
   sudo nano /etc/mongod.conf
   ```

2. **Find and comment out or remove the security section:**
   ```yaml
   # security:
   #   authorization: enabled
   ```

3. **Restart MongoDB:**
   ```bash
   sudo systemctl restart mongod
   # Or if using service:
   sudo service mongod restart
   ```

4. **Keep your connection string simple:**
   ```env
   MONGODB_URI=mongodb://localhost:27017/lingafriq
   ```

### Option 3: Create MongoDB User (If No User Exists)

If MongoDB requires auth but you don't have a user:

1. **Connect to MongoDB without auth (temporarily disable auth):**
   ```bash
   mongosh
   # Or: mongo (older versions)
   ```

2. **Create a user:**
   ```javascript
   use lingafriq
   db.createUser({
     user: "lingafriq_user",
     pwd: "your_secure_password",
     roles: [{ role: "readWrite", db: "lingafriq" }]
   })
   ```

3. **Update your `.env`:**
   ```env
   MONGODB_URI=mongodb://lingafriq_user:your_secure_password@localhost:27017/lingafriq
   ```

4. **Re-enable authentication in MongoDB config if you disabled it.**

## After Fixing

1. **Restart the backend:**
   ```bash
   cd /root/node-backend
   pm2 restart server
   ```

2. **Check logs:**
   ```bash
   pm2 logs server --lines 20
   ```

3. **Test the scraper workflow again.**

---

## Quick Check: What's Your Current Connection String?

Run this to see your current MongoDB URI (without showing the password if it exists):

```bash
cd /root/node-backend
grep MONGODB_URI .env | sed 's/:[^@]*@/:***@/'
```

This will show if you have credentials in the connection string or not.

---

**Choose the option that fits your setup and update the connection string!**

