# JWT_SECRET Explanation

## ⚠️ Important: Don't Change Your Existing JWT_SECRET!

### Your Current Setup
- **JWT_SECRET**: `google` (this is what you're currently using)
- **Why it matters**: This secret is used to sign and verify ALL user authentication tokens

### What Happens If You Change It?

If you change `JWT_SECRET` from `google` to something else:

❌ **All existing user sessions will be invalidated**
- Users currently logged into the app will be logged out
- They'll need to log in again
- Any stored tokens in the app will stop working

❌ **API tokens will break**
- Any integrations using JWT tokens will fail
- Mobile app users will need to re-authenticate

✅ **Safe to keep**: `JWT_SECRET=google` works fine for now

---

## Recommended Setup

### Option 1: Keep It Simple (Recommended for now)
```env
JWT_SECRET=google
# Scraper will use JWT_SECRET automatically
```

**Pros:**
- ✅ No disruption to existing users
- ✅ Simple setup
- ✅ Works immediately

**Cons:**
- ⚠️ Less secure (but acceptable for now)

---

### Option 2: Add Separate Scraper Secret (Better security)
```env
JWT_SECRET=google
SCRAPER_SECRET=your-secure-random-string-here
```

**Pros:**
- ✅ Keeps existing user sessions intact
- ✅ Scraper uses a more secure secret
- ✅ No user disruption

**Cons:**
- ⚠️ One extra variable to manage

**To generate SCRAPER_SECRET:**
```bash
openssl rand -base64 32
```

---

## How It Works

The scraper code checks for secrets in this order:

1. First: `SCRAPER_SECRET` (if set)
2. Fallback: `JWT_SECRET` (if `SCRAPER_SECRET` not set)

So you can:
- Use just `JWT_SECRET=google` → Scraper uses "google"
- Use both → Scraper uses `SCRAPER_SECRET`, users use `JWT_SECRET`

---

## Your .env File Should Look Like:

```env
MONGODB_URI=mongodb://localhost:27017/lingafriq
JWT_SECRET=google
PORT=4000
NODE_ENV=production

# Optional (but recommended):
# SCRAPER_SECRET=generate-with-openssl-rand-base64-32
```

---

## Summary

✅ **DO**: Keep `JWT_SECRET=google`  
✅ **DO**: Optionally add `SCRAPER_SECRET` for better security  
❌ **DON'T**: Change `JWT_SECRET` unless you want to force all users to log in again

---

## Future Consideration

If you want to improve security later (without disrupting users):

1. **Phase 1**: Add `SCRAPER_SECRET` (no disruption)
2. **Phase 2**: Plan a maintenance window to rotate `JWT_SECRET`
3. **Phase 3**: Notify users in advance, then change `JWT_SECRET`
4. **Phase 4**: Users log in again with new tokens

But for now, **keeping `JWT_SECRET=google` is perfectly fine!** ✅

