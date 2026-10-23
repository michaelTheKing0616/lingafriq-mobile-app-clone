# Force Update Server with Latest Code

## The Problem

Your server logs show:
- ✅ Request received
- ❌ Missing new logging ("Attempting to insert article")
- ❌ Error: "there are no users authenticated"

This means the server is running **old code** without our fixes.

## Solution: Force Update

### Step 1: Force Pull Latest Code

```bash
cd /root/node-backend
git fetch origin
git reset --hard origin/main
```

This **forces** the server to match the repository exactly, discarding any local changes.

### Step 2: Clean Build

```bash
cd /root/node-backend
rm -rf dist
npm run build
```

### Step 3: Restart PM2

```bash
pm2 stop server
pm2 delete server
cd /root/node-backend
pm2 start dist/server.js --name server
pm2 save
```

### Step 4: Verify New Code is Running

```bash
# Check for new logging
pm2 logs server --lines 30 | grep -i "attempting\|insert\|article"

# Test endpoint
curl http://localhost:4000/scraper/health
```

### Step 5: Test Workflow Again

After updating, run the GitHub Actions workflow. You should now see:
- "Attempting to insert article: ..." in PM2 logs
- "Successfully inserted article: ..." for each article
- Or detailed error messages showing the actual problem

---

## If Error Persists After Update

If you still get "there are no users authenticated" after updating, check:

1. **Check PM2 logs for detailed errors:**
   ```bash
   pm2 logs server --lines 100 | grep -i "error\|authenticated\|article"
   ```

2. **Test manually with curl:**
   ```bash
   # Get token
   cd /root/node-backend
   node scripts/generateScraperToken.js
   
   # Test (replace YOUR_TOKEN)
   curl -X POST http://localhost:4000/scraper/articles/bulk \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer YOUR_TOKEN" \
     -d '{"articles": [{"title": "Test", "content": "Test", "category": "history", "country": "Nigeria", "excerpt": "Test", "source_url": "https://test.com", "source_name": "Test", "tags": []}]}'
   ```

3. **Check MongoDB directly:**
   ```bash
   # Connect to MongoDB
   mongosh
   # Or: mongo (depending on version)
   
   # Check if collection exists
   use lingafriq
   db.culturearticles.find().limit(5)
   ```

---

**Run the force update commands first, then test again!**

