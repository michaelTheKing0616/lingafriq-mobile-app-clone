# Update Scraper Workflow to Use API

The existing `scraper-cron.yml` workflow uses direct MongoDB connection. Since you're using local MongoDB, we need to update it to use the API approach.

## Step 1: Update the Workflow File

On your server or locally, update `.github/workflows/scraper-cron.yml`:

```yaml
name: Culture Magazine Scraper

on:
  schedule:
    # Run daily at 2 AM UTC
    - cron: '0 2 * * *'
  workflow_dispatch:  # Allow manual trigger

jobs:
  run-scraper:
    name: Run Culture Content Scraper
    runs-on: ubuntu-latest
    
    steps:
    - name: Checkout code
      uses: actions/checkout@v4

    - name: Setup Node.js
      uses: actions/setup-node@v4
      with:
        node-version: '18.x'
        cache: 'npm'

    - name: Install dependencies
      run: npm ci

    - name: Build TypeScript
      run: npm run build

    - name: Run scraper via API
      env:
        BACKEND_URL: ${{ secrets.BACKEND_URL }}
        SCRAPER_TOKEN: ${{ secrets.SCRAPER_TOKEN }}
        NEWS_API_KEY: ${{ secrets.NEWS_API_KEY }}
        NODE_ENV: production
      run: |
        echo "🚀 Starting daily content scraper (API mode)..."
        echo ""
        
        # Verify secrets are set
        if [ -z "$BACKEND_URL" ]; then
          echo "❌ ERROR: BACKEND_URL secret is not set!"
          exit 1
        fi
        
        if [ -z "$SCRAPER_TOKEN" ]; then
          echo "❌ ERROR: SCRAPER_TOKEN secret is not set!"
          exit 1
        fi
        
        echo "✅ Backend URL: $BACKEND_URL"
        echo "✅ Scraper token configured"
        echo ""
        
        # Run scraper via API
        node -e "
          import('./dist/services/scraperClient.service.js')
            .then(m => m.runScraperViaAPI())
            .then(() => {
              console.log('');
              console.log('✅ Daily scraping complete!');
              console.log('');
              console.log('Check articles at:');
              console.log('  ' + process.env.BACKEND_URL + '/culture-magazine/articles');
            })
            .catch(err => {
              console.error('❌ Scraper error:', err.message);
              if (err.message.includes('connect')) {
                console.error('');
                console.error('Troubleshooting:');
                console.error('  1. Backend is not accessible');
                console.error('     → Verify BACKEND_URL is correct');
                console.error('  2. Invalid SCRAPER_TOKEN');
                console.error('     → Regenerate token on server');
                console.error('  3. Backend is down');
                console.error('     → Check PM2 status on server');
              }
              process.exit(1);
            });
        "

    - name: Log completion
      run: |
        echo ""
        echo "=========================================="
        echo "✅ Daily scraper completed!"
        echo "=========================================="
        echo ""
        echo "Fresh content added to Culture Magazine"
        echo "Check your backend API for new articles"
        echo ""
```

## Step 2: Commit and Push

If you update it locally:
```bash
git add .github/workflows/scraper-cron.yml
git commit -m "Update scraper workflow to use API instead of direct MongoDB"
git push
```

Or update it directly on GitHub:
1. Go to: https://github.com/LingAfrika/node-backend
2. Navigate to: `.github/workflows/scraper-cron.yml`
3. Click "Edit" (pencil icon)
4. Replace the content with the updated version above
5. Click "Commit changes"

## Step 3: Test the Workflow

1. Go to: https://github.com/LingAfrika/node-backend/actions
2. Find "Culture Magazine Scraper" workflow
3. Click "Run workflow" → "Run workflow" (manual trigger)
4. Watch it run and check for errors

## Step 4: Verify Articles Were Added

After the workflow completes:

```bash
# On your server
curl http://localhost:4000/culture-magazine/articles?page=1&limit=5
```

Or check via your backend API endpoint.

---

## What Changed?

**Before:** Direct MongoDB connection (requires MONGODB_URI secret)
**After:** API-based approach (uses BACKEND_URL + SCRAPER_TOKEN)

This is more secure because:
- ✅ MongoDB stays private (only accessible from server)
- ✅ Uses secure JWT authentication
- ✅ Works with local MongoDB
- ✅ No need to expose MongoDB connection string

