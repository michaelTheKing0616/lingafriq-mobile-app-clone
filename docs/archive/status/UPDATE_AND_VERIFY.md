# Update Backend and Verify Fix

## Step 1: Update Backend on Server

Run these commands on your server:

```bash
cd /root/node-backend
git pull origin main
npm run build
pm2 restart server
```

## Step 2: Verify the Update

Check that the latest code is deployed:

```bash
# Check git log to see latest commit
cd /root/node-backend
git log --oneline -3

# Should show: "Fix article saving to bypass AdminJS authentication check"
```

## Step 3: Check Backend Logs

```bash
pm2 logs server --lines 50
```

Look for any errors or the new logging we added.

## Step 4: Test the Scraper Endpoint Manually

Test with a single article to verify it works:

```bash
# Get your scraper token (if you don't have it)
cd /root/node-backend
node scripts/generateScraperToken.js

# Test with curl (replace YOUR_TOKEN)
curl -X POST http://localhost:4000/scraper/articles/bulk \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "articles": [{
      "title": "Test Article",
      "content": "Test content",
      "excerpt": "Test excerpt",
      "category": "history",
      "country": "Nigeria",
      "source_url": "https://test.com",
      "source_name": "Test",
      "tags": ["test"]
    }]
  }'
```

**Expected:** Should return success with `saved: 1` instead of an error.

## Step 5: Run GitHub Actions Workflow Again

After updating the backend:
1. Go to: https://github.com/LingAfrika/node-backend/actions
2. Run "Culture Magazine Scraper" workflow
3. Should now show `Saved: 29` instead of `Errors: 29`

## Step 6: Verify Articles Were Saved

```bash
# Check if articles exist
curl http://localhost:4000/culture-magazine/articles?page=1&limit=5
```

Should return JSON with article data.

---

**The fix is in the code - you just need to update the backend on your server!**

