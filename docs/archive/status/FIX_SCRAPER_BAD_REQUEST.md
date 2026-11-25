# Fix: Scraper "Bad Request" Error

## Problem Analysis

From the logs, I can see:
- ✅ API health check works (`/scraper/health`)
- ✅ Scraper successfully scraped 29 articles from Wikipedia
- ❌ Posting articles fails with "API error: Bad Request"

This suggests the backend route exists but there's an issue with:
1. The request body format
2. The backend code on the server is outdated
3. Request validation failing

## Solution: Update Backend on Server

The backend on your server needs to be updated with the latest code that includes:
- Improved error logging
- Better request validation
- Detailed error messages

### Step 1: Pull Latest Code on Server

```bash
cd /root/node-backend
git pull origin main
```

### Step 2: Rebuild and Restart

```bash
cd /root/node-backend
npm run build
pm2 restart server
```

### Step 3: Check Logs

```bash
pm2 logs server --lines 50
```

Look for any errors or the new logging messages.

### Step 4: Test the Endpoint Manually

Test if the endpoint works with a simple request:

```bash
# First, get your scraper token (if you don't have it)
cd /root/node-backend
node scripts/generateScraperToken.js

# Then test with curl (replace YOUR_TOKEN with actual token)
curl -X POST http://localhost:4000/scraper/articles/bulk \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"articles": [{"title": "Test Article", "content": "Test content", "category": "history", "country": "Nigeria", "excerpt": "Test", "source_url": "https://test.com", "source_name": "Test", "tags": []}]}'
```

### Step 5: Check Backend Logs for Details

After running the test (or the workflow), check the PM2 logs:

```bash
pm2 logs server --lines 100
```

You should now see detailed logging like:
- "Received bulk articles request"
- "Request body keys: ..."
- "Articles type: array"
- "Articles length: 29"

This will help identify the exact issue.

## Alternative: Quick Fix Script

Run this on your server to update everything:

```bash
cd /root/node-backend
git pull origin main
npm run build
pm2 restart server
echo "✅ Backend updated! Check logs with: pm2 logs server"
```

## What Changed

1. **Improved error handling in scraper client** - Now shows detailed API errors
2. **Added logging to scraper route** - Shows what the backend receives
3. **Better error messages** - Easier to debug issues

## Next Steps

After updating the backend:
1. Run the GitHub Actions workflow again
2. Check the logs for the detailed error messages
3. If it still fails, the logs will show exactly what's wrong

## Expected Behavior

After the fix, you should see in the workflow logs:
- ✅ API connection successful
- ✅ Scraped X articles from Wikipedia
- ✅ Posting X articles to backend API...
- ✅ Articles saved successfully
- ✅ Results: Saved: X, Skipped: Y

---

**Run the update commands on your server and then test the workflow again!**

