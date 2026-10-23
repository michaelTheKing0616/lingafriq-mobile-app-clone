# Google Play Store Publishing Guide

## Why Your App Might Not Be Visible Yet

### 1. **Review Process (Most Common)**
Google reviews all apps before publishing. This typically takes:
- **New apps:** 1-7 days (sometimes up to 14 days)
- **Updates:** Few hours to 3 days
- **First-time publishers:** Longer review (up to 7 days)

**Check status in Play Console:**
- Go to: https://play.google.com/console
- Navigate to: **Release** → **Production** (or your release track)
- Look for status: "Pending review", "In review", or "Available"

### 2. **Testing Requirements (CRITICAL for New Accounts)**
If your Google Play Developer account was created **after November 2023**, you MUST complete:

- **Closed Testing Phase:**
  - Create a closed test track
  - Add at least **12 testers**
  - Keep the app in closed testing for **14 consecutive days**
  - Only after this can you publish to production

**Check if this applies:**
- Go to: **Testing** → **Closed testing**
- If you see a warning about testing requirements, you need to complete this first

### 3. **App Status Issues**

**Check these in Play Console:**

- **App Status:** 
  - Go to: **Policy** → **App content**
  - Ensure no policy violations
  
- **Content Rating:**
  - Go to: **Policy** → **Content rating**
  - Must be completed before publishing
  
- **Store Listing:**
  - Go to: **Store presence** → **Main store listing**
  - Ensure all required fields are filled (description, screenshots, etc.)

- **Target Countries:**
  - Go to: **Pricing & distribution**
  - Ensure your target countries are selected

### 4. **Release Track Status**

Check which track your app is on:
- **Internal testing:** Only visible to internal testers
- **Closed testing:** Only visible to testers you added
- **Open testing:** Visible to anyone who joins
- **Production:** Visible to everyone (if approved)

**To check:**
1. Go to: **Release** → **Production** (or your track)
2. Check if status shows "Available" or "Pending review"

### 5. **Search Visibility**

Even if published, new apps may not appear in search immediately:
- Can take **24-48 hours** to appear in search results
- Try accessing via direct link: `https://play.google.com/store/apps/details?id=com.owlab.lingafriq`
- Search for your exact app name

## How to Check Your App Status

### Step-by-Step:

1. **Login to Play Console:**
   https://play.google.com/console

2. **Select your app:** LingAfriq

3. **Check Release Dashboard:**
   - Go to: **Release** → **Dashboard**
   - Look for any warnings or errors (red/yellow indicators)

4. **Check Production Track:**
   - Go to: **Release** → **Production**
   - Check status:
     - ✅ **Available:** App is live (may take time to appear in search)
     - ⏳ **Pending review:** Waiting for Google review
     - ❌ **Rejected:** Check rejection reason

5. **Check Testing Requirements:**
   - Go to: **Testing** → **Closed testing**
   - If you see a message about "14-day testing requirement", you need to complete this first

6. **Check Policy Status:**
   - Go to: **Policy** → **App content**
   - Ensure no violations

## Common Issues & Solutions

### Issue: "App shows 'Available' but not visible"
**Solution:**
- Wait 24-48 hours for search indexing
- Try direct link: `https://play.google.com/store/apps/details?id=YOUR_PACKAGE_NAME`
- Check if app is restricted to specific countries

### Issue: "Pending review for days"
**Solution:**
- This is normal for first-time publishers
- Can take up to 7 days
- Check for any policy violations or missing information

### Issue: "Testing requirement not met"
**Solution:**
- Create closed test track
- Add 12+ testers
- Keep app in closed testing for 14 days
- Then you can publish to production

### Issue: "Content rating incomplete"
**Solution:**
- Go to: **Policy** → **Content rating**
- Complete the questionnaire
- Submit for review

## Next Steps

1. **Check Play Console** for current status
2. **Verify testing requirements** (if account is new)
3. **Complete any missing information** (content rating, store listing)
4. **Wait for review** (can take up to 7 days)
5. **Check direct link** after status shows "Available"

## Direct App Link

Once published, your app will be available at:
```
https://play.google.com/store/apps/details?id=com.owlab.lingafriq
```

Replace `com.owlab.lingafriq` with your actual package name if different.

## Need Help?

- **Play Console Help:** https://support.google.com/googleplay/android-developer
- **Contact Support:** In Play Console, go to **Help & feedback** → **Contact us**

