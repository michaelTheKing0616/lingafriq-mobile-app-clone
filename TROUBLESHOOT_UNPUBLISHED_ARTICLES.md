# Troubleshooting: No Unpublished Articles Showing

## Issue
The Culture Magazine component shows no articles in the "Unpublished" status filter.

## ✅ Fixes Applied

### 1. Backend Fix (Pushed)
- **File:** `src/controllers/cultureMagazine.controller.ts`
- **Change:** Removed hardcoded `published: true` filter
- **Now:** Backend respects the `published` query parameter
- **Status:** ✅ Pushed to GitHub (commit `6971d6f`)

### 2. Frontend Fix (Pushed)
- **File:** `src/components/tables/CultureMagazineTable.tsx`
- **Change:** Improved response handling for paginated data
- **Status:** ✅ Pushed to GitHub

## 🔧 Next Steps on Server

### Step 1: Update Backend on Server

```bash
cd /root/node-backend
git pull origin main
npm run build
pm2 restart server
```

### Step 2: Verify Articles Exist

Check if there are actually unpublished articles in the database:

```bash
mongo -u lingafriqadmin -p lingafriq123 --authenticationDatabase lingafriq
```

Then:
```javascript
use lingafriq
// Count all articles
db.culturearticles.count()

// Count unpublished articles
db.culturearticles.count({ published: false })

// List unpublished articles
db.culturearticles.find({ published: false }).limit(5).pretty()
exit
```

### Step 3: Test the API Directly

Test if the backend API returns unpublished articles:

```bash
# Get all articles (should include unpublished)
curl "https://admin.lingafriq.com/culture-magazine/articles?limit=100"

# Get only unpublished articles
curl "https://admin.lingafriq.com/culture-magazine/articles?published=false&limit=100"
```

### Step 4: Check Admin Panel

1. **Clear browser cache:** `Ctrl+Shift+R`
2. **Refresh the page**
3. **Select "Unpublished" from Status filter**
4. **Check browser console (F12)** for any errors

## 🐛 Common Issues

### Issue 1: All Articles Are Already Published
**Solution:** Check database - if all articles have `published: true`, there are no unpublished articles to show.

### Issue 2: Scraper Didn't Run
**Solution:** Check if the scraper workflow ran successfully and created articles.

### Issue 3: Backend Not Updated
**Solution:** Make sure you pulled the latest backend code and restarted PM2.

### Issue 4: API Response Format
**Solution:** Check browser Network tab to see the actual API response structure.

## 📊 Debugging Steps

1. **Check Browser Console:**
   - Open DevTools (F12)
   - Go to Console tab
   - Look for errors when filtering

2. **Check Network Tab:**
   - Open DevTools (F12)
   - Go to Network tab
   - Filter by "articles"
   - Click on the request
   - Check the Response tab to see what the API returns

3. **Check Backend Logs:**
   ```bash
   pm2 logs server --lines 50 | grep -i "article\|culture"
   ```

## ✅ Expected Behavior

After fixes:
- **"All" filter:** Shows all articles (published + unpublished)
- **"Published" filter:** Shows only published articles
- **"Unpublished" filter:** Shows only unpublished articles

---

**After updating the backend on the server, the unpublished articles should appear!**

