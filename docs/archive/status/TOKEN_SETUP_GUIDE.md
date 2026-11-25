# Token Setup Guide

## Two Different Tokens Needed

You need **two different tokens** for different purposes:

---

## 1. GitHub Personal Access Token (PAT)

**Purpose:** Clone/pull the repository on your server

**Answer to your question:** ✅ **YES** - A token created from your personal GitHub account WILL work for the LingAfrika repository since you have admin access. Personal Access Tokens work for any repository you have access to, including organization repos.

### How to Create:

1. Go to: https://github.com/settings/tokens?type=beta
   - (This takes you to YOUR personal account - that's correct!)
   
2. Click **"Generate new token"** → **"Generate new token (classic)"**

3. Settings:
   - **Note:** `LingAfriq Server Access`
   - **Expiration:** 90 days (or your preference)
   - **Scopes:** Check `repo` (this gives full access to repositories)

4. Click **"Generate token"**

5. **COPY THE TOKEN IMMEDIATELY** - you won't see it again!

### How to Use on Server:

**Option A: Use the script (recommended)**
```bash
# Upload CLONE_REPO_WITH_TOKEN.sh to your server, then:
bash CLONE_REPO_WITH_TOKEN.sh
# Enter your token when prompted
```

**Option B: Manual clone**
```bash
# Replace YOUR_TOKEN with your actual token
git clone https://YOUR_TOKEN@github.com/LingAfrika/node-backend.git /root/node-backend
```

**Option C: Set as environment variable (more secure)**
```bash
export GITHUB_TOKEN="your_token_here"
git clone https://${GITHUB_TOKEN}@github.com/LingAfrika/node-backend.git /root/node-backend
```

---

## 2. Scraper JWT Token (for API)

**Purpose:** Authenticate the GitHub Actions scraper with your backend API

**This is DIFFERENT from the GitHub token!**

### How to Generate:

1. **First, deploy the backend code** (using the GitHub token above)

2. **On your server, run:**
   ```bash
   cd /root/node-backend
   node scripts/generateScraperToken.js
   ```

3. **Copy the output token**

4. **Add to GitHub Secrets:**
   - Go to: https://github.com/LingAfrika/node-backend/settings/secrets/actions
   - Click **"New repository secret"**
   - Name: `SCRAPER_TOKEN`
   - Value: (paste the token from step 3)
   - Click **"Add secret"**

---

## Quick Setup Checklist

- [ ] Create GitHub PAT from your personal account
- [ ] Clone repository on server using PAT
- [ ] Deploy backend code (run `DEPLOY_TO_SERVER.sh`)
- [ ] Generate scraper JWT token on server
- [ ] Add scraper JWT token to GitHub Secrets as `SCRAPER_TOKEN`
- [ ] Add `BACKEND_URL` to GitHub Secrets (e.g., `https://admin.lingafriq.com`)

---

## Troubleshooting

### "Permission denied" when using password
- GitHub no longer accepts passwords for git operations
- You MUST use a Personal Access Token instead
- The token acts as your password

### Token doesn't work for organization repo
- Make sure you selected `repo` scope when creating the token
- Verify you have admin access to the LingAfrika organization
- Try creating a new token with `repo` scope

### Can't generate scraper token
- Make sure `.env` file exists with `JWT_SECRET` or `SCRAPER_SECRET`
- Make sure you've run `npm install` and `npm run build`
- Make sure the backend is running: `pm2 status`

