# Quick Fix for Server Pull Error

## Run These Commands on Your Server:

```bash
cd /root/node-backend

# Remove the dist folder (it's compiled code, will be regenerated)
rm -rf dist

# Pull latest code (now includes the TypeScript fixes)
git pull origin main

# Rebuild TypeScript to JavaScript
npm run build

# Restart the server
pm2 restart server
```

## Why This Works:

1. **`dist/` folder** contains compiled JavaScript files generated from TypeScript
2. These files should **NOT** be in git (they're build artifacts)
3. Removing `dist/` and rebuilding ensures you have the latest compiled code
4. The latest code includes the TypeScript fixes I just pushed

## Expected Result:

After running these commands:
- ✅ Latest code pulled successfully
- ✅ TypeScript compiles without errors
- ✅ Server restarts with new code
- ✅ All routes (Analytics, Devices, etc.) should work

---

**Note:** The TypeScript errors you're seeing are from the OLD code. The latest code on GitHub has these fixes already applied!

