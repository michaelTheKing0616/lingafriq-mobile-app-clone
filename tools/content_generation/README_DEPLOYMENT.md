# Content Generation - Deployment Guide

## Quick Start

### 1. Local Development

```bash
cd tools/content_generation
pip install -r requirements.txt

# Set environment variables
export GROQ_API_KEY="your_groq_key"
export BACKEND_API_URL="https://api.lingafriq.com"
export BACKEND_API_KEY="your_backend_key"

# Generate content for all languages
python enhanced_content_generator.py

# Or for specific language
python enhanced_content_generator.py --language yoruba --count 1000

# Upload to backend
python backend_integration.py
```

### 2. GitHub Actions (Automatic)

The pipeline runs automatically daily at 2 AM UTC via GitHub Actions.

**Setup:**
1. Add secrets to GitHub repository:
   - `GROQ_API_KEY`
   - `BACKEND_API_URL`
   - `BACKEND_API_KEY`

2. Workflow will:
   - Generate content daily
   - Upload to backend
   - Commit generated files

**Manual trigger:**
- Go to Actions → Content Generation Pipeline → Run workflow

### 3. DigitalOcean Backend (Cron Job)

**On your DigitalOcean server:**

```bash
# 1. Clone/update the mobile-app repo
cd /path/to/repos
git clone https://github.com/LingAfrika/lingafriq-mobile-app.git || cd lingafriq-mobile-app && git pull

# 2. Navigate to backend
cd node-backend-main

# 3. Make scripts executable
chmod +x scripts/content-generation.sh
chmod +x scripts/setup-cron.sh

# 4. Set up environment variables in .env
echo "GROQ_API_KEY=your_key" >> .env
echo "BACKEND_API_URL=https://api.lingafriq.com" >> .env
echo "BACKEND_API_KEY=your_key" >> .env

# 5. Set up cron job
./scripts/setup-cron.sh

# 6. Test manually first
./scripts/content-generation.sh

# 7. Check logs
tail -f /var/log/content-generation.log
```

**Cron Schedule:**
- Daily at 2 AM: `0 2 * * *`
- Every 6 hours: `0 */6 * * *`
- Weekly: `0 2 * * 0`

## Commands Reference

### Generate Content

```bash
# All languages
python enhanced_content_generator.py

# Specific language
python enhanced_content_generator.py --language yoruba --count 500

# With custom output
python enhanced_content_generator.py --output /path/to/output
```

### Upload Content

```bash
# Upload all files in generated_content/
python backend_integration.py

# Custom directory
python backend_integration.py --directory /path/to/content
```

### Full Pipeline

```bash
# Generate and upload
python automated_pipeline.py

# Generate only
python automated_pipeline.py --generate-only

# Upload only
python automated_pipeline.py --upload-only

# Specific language
python automated_pipeline.py --language swahili
```

## Environment Variables

Required:
- `GROQ_API_KEY` - Get free key from https://console.groq.com
- `BACKEND_API_URL` - Your backend API URL
- `BACKEND_API_KEY` - Backend authentication key

## Monitoring

### Check Generation Status

```bash
# View logs
tail -f tools/content_generation/pipeline.log

# Check generated files
ls -lh tools/content_generation/generated_content/

# Count items
find tools/content_generation/generated_content/ -name "*.json" -exec wc -l {} +
```

### Backend Verification

```bash
# Check API endpoints
curl -H "Authorization: Bearer $BACKEND_API_KEY" \
  "$BACKEND_API_URL/content/phrase-cards?language=yoruba&limit=10"

curl -H "Authorization: Bearer $BACKEND_API_KEY" \
  "$BACKEND_API_URL/content/roleplay-scenarios?language=yoruba&limit=10"
```

## Troubleshooting

### API Rate Limits

If you hit rate limits:
- Reduce batch sizes in `backend_integration.py`
- Add longer delays between requests
- Generate content in smaller batches

### Memory Issues

For large generations:
- Process one language at a time
- Use `--language` flag
- Reduce `--count` parameter

### Authentication Errors

- Verify `BACKEND_API_KEY` is correct
- Check backend API is accessible
- Ensure user has admin permissions

## Production Deployment

1. **Set up on DigitalOcean:**
   ```bash
   ssh user@your-server
   cd /opt/lingafriq
   ./scripts/setup-cron.sh
   ```

2. **Monitor:**
   ```bash
   # Check cron job
   crontab -l
   
   # View logs
   tail -f /var/log/content-generation.log
   ```

3. **Update:**
   ```bash
   cd /opt/lingafriq
   git pull
   ./scripts/content-generation.sh
   ```

## Support

For issues or questions:
- Check logs: `pipeline.log`
- Review GitHub Actions logs
- Check backend API status

