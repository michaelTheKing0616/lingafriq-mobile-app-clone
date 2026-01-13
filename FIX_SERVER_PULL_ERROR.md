# Fix Server Pull Error

## Problem
Git is blocking the pull because:
1. Local changes exist in `dist/` folder (compiled files)
2. Untracked files in `dist/` folder would be overwritten

## Solution

The `dist/` folder contains compiled JavaScript files that should be regenerated, not tracked in git.

### Option 1: Remove dist folder and rebuild (Recommended)

```bash
cd /root/node-backend

# Remove the dist folder completely
rm -rf dist

# Pull latest code
git pull origin main

# Rebuild
npm run build

# Restart
pm2 restart server
```

### Option 2: Stash changes and pull

```bash
cd /root/node-backend

# Stash local changes
git stash

# Pull latest code
git pull origin main

# Rebuild (this will regenerate dist/)
npm run build

# Restart
pm2 restart server
```

### Option 3: Force pull (if you're sure you want to discard local changes)

```bash
cd /root/node-backend

# Discard all local changes
git reset --hard HEAD

# Pull latest code
git pull origin main

# Rebuild
npm run build

# Restart
pm2 restart server
```

## Recommended: Option 1

Since `dist/` is generated from `src/`, it's safe to delete it and rebuild.

---

**After pulling, the TypeScript errors will be fixed because the latest code includes the fixes!**

