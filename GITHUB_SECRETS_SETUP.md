# GitHub Secrets Setup - What You Need

## ✅ GOOD NEWS!

Your backend **already has a MongoDB database connected**. All the new features I added (Culture Magazine, Media Processing, Chat, User Connections) will automatically use your **existing database** - everything stays consistent!

---

## 🔐 REQUIRED SECRETS (Only 2!)

You need to add **only 2 secrets** to GitHub Actions for the workflows to run:

### 1. **MONGODB_URI** (Your existing database)
This is the MongoDB connection string your backend is already using.

**Where to find it:**
- Check your current backend deployment
- Or look in your local `.env` file if you have one
- It looks like: `mongodb+srv://username:password@cluster.mongodb.net/lingafriq?retryWrites=true`

**If you don't have it:**
- Check with your team who set up the backend
- Or check your hosting provider (Heroku, Railway, Render, etc.)
- Or check MongoDB Atlas if that's what you're using

---

### 2. **JWT_SECRET** (Your existing secret key)
This is the secret key your backend uses for authentication tokens.

**Where to find it:**
- Check your current backend deployment environment variables
- Or look in your local `.env` file
- It's a long random string (32+ characters)

**If you don't have it:**
- Check with your team who set up the backend
- Or check your hosting provider's environment variables
- **IMPORTANT**: If you change this, all existing user sessions will be invalidated (users will need to log in again)

---

## 🎯 HOW TO ADD THESE TO GITHUB

**Step 1:** Go to your backend repo
```
https://github.com/lingafriq/node-backend
```

**Step 2:** Navigate to Secrets
- Click **"Settings"** tab (top menu)
- Scroll down left sidebar → **"Secrets and variables"** → **"Actions"**

**Step 3:** Add MONGODB_URI
- Click **"New repository secret"**
- Name: `MONGODB_URI` (exactly this, case-sensitive!)
- Secret: Paste your MongoDB connection string
- Click **"Add secret"**

**Step 4:** Add JWT_SECRET
- Click **"New repository secret"** again
- Name: `JWT_SECRET` (exactly this!)
- Secret: Paste your JWT secret key
- Click **"Add secret"**

---

## 📊 OPTIONAL SECRETS (For Enhanced Features)

These are **optional** but recommended for full functionality:

### 3. **NEWS_API_KEY** (For Culture Magazine auto-scraper)
- Get free: https://newsapi.org (100 requests/day free)
- Enables automatic African news/culture content gathering
- **If not provided**: Scraper will only use web scraping (slower but still works)

### 4. **OPENAI_API_KEY** (For future AI features)
- Get from: https://platform.openai.com/api-keys
- Currently not used, but ready for future AI content generation
- **If not provided**: No problem, not needed yet

### 5. **HOSTNAME** (Your API URL)
- Example: `https://api.lingafriq.com` or `https://your-backend.herokuapp.com`
- Used for generating full media URLs
- **If not provided**: Backend uses relative paths (still works)

### 6. **NODE_ENV** (Environment)
- Value: `production`
- **If not provided**: Defaults to development mode

---

## ✅ WHAT SECRETS YOU DEFINITELY NEED

### Minimum to get workflows running:
```
✅ MONGODB_URI (your existing database)
✅ JWT_SECRET (your existing auth key)
```

### Recommended for full features:
```
✅ MONGODB_URI
✅ JWT_SECRET  
✅ NEWS_API_KEY (free from newsapi.org)
✅ HOSTNAME (your backend URL)
```

---

## 🔍 HOW TO FIND YOUR EXISTING CREDENTIALS

### Option 1: Check Current Deployment
If your backend is already deployed somewhere:

**Heroku:**
```bash
heroku config -a your-app-name
```

**Railway:**
- Go to your project → Variables tab
- Copy MONGODB_URI and JWT_SECRET

**Render:**
- Go to your service → Environment tab
- Copy MONGODB_URI and JWT_SECRET

---

### Option 2: Check Local Files
If you have the backend running locally:

**Look for `.env` file:**
```bash
cd node-backend
cat .env
```

You should see something like:
```bash
MONGODB_URI=mongodb+srv://...
JWT_SECRET=abc123xyz...
```

---

### Option 3: Check with Your Team
Ask whoever set up the backend for:
- MongoDB connection string (MONGODB_URI)
- JWT secret key (JWT_SECRET)

---

## ⚠️ IMPORTANT NOTES

### About MONGODB_URI:
- ✅ Uses your **existing database**
- ✅ All new collections (articles, media, messages, connections) will be added automatically
- ✅ Your existing data (users, lessons, progress) stays unchanged
- ✅ No data migration needed - it just works!

### About JWT_SECRET:
- ⚠️ Must be the **same value** your backend is currently using
- ⚠️ If you change it, all users will need to log in again
- ✅ If you don't know it, don't guess - find the actual value

### Database Structure:
Your MongoDB will now have these collections:
```
Existing:
- users
- languages
- lessons
- quizzes
- progress
- etc.

New (auto-created):
- articles (Culture Magazine)
- media (Media uploads)
- chatmessages (Chat history)
- userconnections (Social graph)
```

All in the **same database** - perfectly integrated! ✅

---

## 🚀 AFTER ADDING SECRETS

### Check if they're correct:

1. **Go to Actions tab**
2. **Click "Deploy Backend"**
3. **Click "Run workflow"**
4. **Watch the run**

**If it succeeds (green ✅):**
- Secrets are correct!
- Backend builds successfully
- Download artifacts or deploy

**If it fails (red ❌):**
- Click on the failed run
- Look for error message
- Common issues:
  - `MONGODB_URI is not defined` → Add the secret
  - `Cannot connect to MongoDB` → Check connection string format
  - `JWT_SECRET is not defined` → Add the secret

---

## 🎉 SUMMARY

**What you need to do:**
1. ✅ Find your existing MONGODB_URI (from deployment or team)
2. ✅ Find your existing JWT_SECRET (from deployment or team)
3. ✅ Add both to GitHub Secrets
4. ✅ Re-run the workflow
5. ✅ Success! 🚀

**What I did:**
- ✅ Fixed the workflow hanging issue
- ✅ All new features use your existing database
- ✅ No database migration needed
- ✅ Everything stays consistent
- ✅ Ready to deploy!

**Next step:** Just add those 2 secrets and you're good to go! 🎯
