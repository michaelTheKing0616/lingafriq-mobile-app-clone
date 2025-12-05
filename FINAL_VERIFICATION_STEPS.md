# Final Verification and Testing Steps

## Step 1: Verify Backend is Running with Latest Code

On your server, run:

```bash
# Check PM2 status
pm2 status

# Check backend logs for any errors
pm2 logs server --lines 30

# Test the scraper health endpoint
curl http://localhost:4000/scraper/health
```

**Expected output:**
- PM2 shows `server` as `online`
- Logs show: "app is connected to mongodb table" and "app is running on port 4000"
- Health endpoint returns: `{"success": true, "message": "Scraper API is running", ...}`

## Step 2: Test the Scraper Endpoint Manually (Optional)

Test if the scraper endpoint accepts articles:

```bash
# Generate a test token (if you don't have it)
cd /root/node-backend
node scripts/generateScraperToken.js

# Test with a single article (replace YOUR_TOKEN)
curl -X POST http://localhost:4000/scraper/articles/bulk \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "articles": [{
      "title": "Test Article",
      "content": "This is a test article content",
      "excerpt": "Test excerpt",
      "category": "history",
      "country": "Nigeria",
      "source_url": "https://test.com",
      "source_name": "Test Source",
      "tags": ["test"]
    }]
  }'
```

**Expected output:**
```json
{
  "success": true,
  "message": "Bulk article save completed",
  "stats": {
    "total": 1,
    "saved": 1,
    "skipped": 0,
    "errors": 0
  },
  ...
}
```

## Step 3: Test GitHub Actions Workflow

1. Go to: https://github.com/LingAfrika/node-backend/actions
2. Find "Culture Magazine Scraper" workflow
3. Click "Run workflow" → "Run workflow" (manual trigger)
4. Watch it run and check the logs

**What to look for:**
- ✅ "API connection successful"
- ✅ "Scraped X articles from Wikipedia"
- ✅ "Posting X articles to backend API..."
- ✅ "SCRAPER COMPLETED SUCCESSFULLY!"
- ✅ Results showing saved articles

## Step 4: Verify Articles Were Added

After the workflow completes, check if articles are in your database:

```bash
# On your server, check if articles exist
curl http://localhost:4000/culture-magazine/articles?page=1&limit=5
```

Or test from outside:
```bash
curl https://admin.lingafriq.com/culture-magazine/articles?page=1&limit=5
```

**Expected:** JSON response with article data

## Step 5: Check Backend Logs for Details

If the workflow runs, check what the backend received:

```bash
pm2 logs server --lines 100 | grep -i "scraper\|article\|bulk"
```

You should see logs like:
- "Received bulk articles request"
- "Request body keys: ..."
- "Articles type: array"
- "Articles length: 29"

## Step 6: Schedule Automatic Scraping

The workflow is already scheduled to run daily at 2 AM UTC. Verify the schedule:

1. Go to: https://github.com/LingAfrika/node-backend/actions/workflows/scraper-cron.yml
2. Check the schedule: `cron: '0 2 * * *'` (daily at 2 AM UTC)

## Troubleshooting

### If workflow still fails with "Bad Request":

1. **Check backend logs:**
   ```bash
   pm2 logs server --lines 200
   ```
   Look for the detailed logging we added.

2. **Verify the route exists:**
   ```bash
   curl http://localhost:4000/scraper/health
   ```

3. **Check if backend has latest code:**
   ```bash
   cd /root/node-backend
   git log --oneline -3
   ```
   Should show recent commits including "Add detailed logging to scraper route"

4. **Rebuild if needed:**
   ```bash
   cd /root/node-backend
   git pull origin main
   npm run build
   pm2 restart server
   ```

### If articles aren't being saved:

1. Check MongoDB is running:
   ```bash
   systemctl status mongod
   ```

2. Check backend can connect to MongoDB:
   ```bash
   pm2 logs server | grep -i mongo
   ```
   Should show: "app is connected to mongodb table"

## Success Checklist

- [ ] Backend is running (`pm2 status` shows online)
- [ ] Health endpoint works (`curl http://localhost:4000/scraper/health`)
- [ ] GitHub Actions workflow runs successfully
- [ ] Articles are being saved to database
- [ ] Backend logs show detailed information
- [ ] PM2 is configured to persist (`pm2 save` done)
- [ ] PM2 starts on boot (`pm2 startup` done)

---

## Next Steps After Verification

Once everything works:

1. **Monitor the first scheduled run** (2 AM UTC daily)
2. **Check articles in your app** - they should appear in the Culture Magazine section
3. **Review saved articles** periodically to ensure quality
4. **Adjust scraping schedule** if needed (edit `.github/workflows/scraper-cron.yml`)

---

**Run Step 1 first to verify everything is working, then test the GitHub Actions workflow!**

