# Check Server Logs for Detailed Errors

## Step 1: Check PM2 Logs for Our New Logging

On your server, run:

```bash
pm2 logs server --lines 200 | grep -i "attempting\|insert\|article\|error\|authenticated"
```

**What to look for:**
- "Attempting to insert article: ..." - This confirms the latest code is running
- "Error saving article ..." - This will show the actual error
- "Error stack:" - This will show where the error is coming from

## Step 2: Check All Recent Logs

```bash
pm2 logs server --lines 100
```

Look for:
- Any errors related to article insertion
- The detailed logging we added
- Stack traces

## Step 3: Test Manually to See Real-Time Logs

While watching the logs, test the endpoint:

```bash
# In one terminal, watch logs
pm2 logs server --lines 0

# In another terminal, test the endpoint
cd /root/node-backend
TOKEN=$(node -e "const jwt=require('jsonwebtoken');require('dotenv').config();console.log(jwt.sign({type:'scraper'},process.env.JWT_SECRET));")

curl -X POST http://localhost:4000/scraper/articles/bulk \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{"articles": [{"title": "Test Article", "content": "Test content", "category": "history", "country": "Nigeria", "excerpt": "Test", "source_url": "https://test.com", "source_name": "Test", "tags": []}]}'
```

Watch the logs in real-time to see what happens.

---

**Run Step 1 first and share the output - this will show us exactly where the error is coming from!**

