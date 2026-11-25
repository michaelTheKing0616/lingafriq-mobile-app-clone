# Lesson Item Import Guide

## Overview

This guide explains how to generate and import lesson items to the backend database.

## Prerequisites

1. Backend server running and accessible
2. Admin authentication token (for bulk import)
3. MongoDB connection configured

## Step 1: Generate Lesson Items

### Option A: Generate All Items (10,000+)

```bash
cd mobile-app-main/scripts
python lesson_generator.py
```

This will generate:
- `lesson_items.json` - Full JSON export
- `lesson_items.csv` - CSV export

### Option B: Generate for Specific Language/Level

Modify the `lesson_generator.py` script or use templates to generate specific batches.

## Step 2: Review Generated Items

Before importing, review the generated items:

```bash
# Check JSON file
cat lesson_items.json | head -100

# Count total items
python -c "import json; data = json.load(open('lesson_items.json')); print(f'Total items: {len(data)}')"

# Filter out placeholders (quality_score = 0.0)
python -c "import json; data = json.load(open('lesson_items.json')); valid = [i for i in data if i.get('quality_score', 0) > 0]; print(f'Valid items: {len(valid)}')"
```

## Step 3: Import to Backend

### Using the Import Script

```bash
# Basic usage
python import_to_backend.py \
  --file lesson_items.json \
  --api-url http://localhost:3000/api

# With custom batch size
python import_to_backend.py \
  --file lesson_items.json \
  --api-url http://localhost:3000/api \
  --batch-size 50
```

### Using curl (for testing)

```bash
# Get admin token first (login to admin dashboard or use auth endpoint)
TOKEN="your-admin-token"

# Import items
curl -X POST http://localhost:3000/api/v1/lesson-items/bulk-import \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d @lesson_items.json
```

### Direct API Call (with authentication)

The import endpoint requires admin authentication:

```
POST /api/v1/lesson-items/bulk-import
Authorization: Bearer <admin-token>
Content-Type: application/json

{
  "items": [
    {
      "id": "yo-a1-001",
      "language": "Yoruba",
      "language_code": "yo",
      "level": "A1",
      "category": "greetings",
      "type": "vocabulary",
      "text": "Ẹ káàárọ̀",
      "ipa": "ɛ̀ káː rɔ̀",
      "translation": "Good morning",
      "tone_pattern": ["low", "high", "low"],
      "difficulty": 0.2,
      "usage_context": "formal",
      "cultural_note": "Used before noon",
      "quality_score": 0.95,
      "verified_by_native": false
    }
  ]
}
```

## Step 4: Verify Import

### Check Statistics

```bash
curl http://localhost:3000/api/v1/lesson-items/stats
```

Response:
```json
{
  "success": true,
  "data": {
    "summary": {
      "total": 10000,
      "avg_quality_score": 0.95,
      "verified_count": 5000
    },
    "by_language": [
      {"_id": "yo", "count": 833},
      {"_id": "ha", "count": 833}
    ],
    "by_level": [
      {"_id": "A1", "count": 3600},
      {"_id": "A2", "count": 3000}
    ]
  }
}
```

### Query Items

```bash
# Get items by language
curl "http://localhost:3000/api/v1/lesson-items?language_code=yo&level=A1&limit=10"

# Get verified items only
curl "http://localhost:3000/api/v1/lesson-items?verified_only=true&min_quality_score=0.95"
```

## Import Process Details

### What Gets Imported

- Items with `quality_score > 0` (placeholders are skipped)
- Validates required fields (id, language_code, level, text, translation)
- Updates existing items (by id) or creates new ones

### Batch Processing

- Processes items in batches (default: 100 per batch)
- Continues on errors (logs individual item errors)
- Returns summary with counts of imported/updated/skipped items

### Response Format

```json
{
  "success": true,
  "message": "Import completed: 5000 imported, 200 updated, 10 skipped",
  "data": {
    "imported": 5000,
    "updated": 200,
    "skipped": 10,
    "errors": [
      "Item invalid-001: Missing required fields"
    ]
  }
}
```

## Troubleshooting

### Common Issues

1. **Authentication Error**
   - Ensure you're using an admin token
   - Check token expiration
   - Verify token has admin permissions

2. **Validation Errors**
   - Check required fields are present
   - Verify field types match schema
   - Ensure enum values are valid (level, type, usage_context)

3. **Duplicate IDs**
   - Existing items with same ID will be updated
   - Check if this is intended behavior

4. **Large File Uploads**
   - Consider splitting into smaller batches
   - Use batch-size parameter
   - Monitor server memory usage

### Error Handling

The import script will:
- Continue processing on individual item errors
- Log errors for review
- Return summary of all operations
- Not rollback on partial failures (each item is independent)

## Next Steps

After successful import:

1. **Verify Data Quality**
   - Review statistics endpoint
   - Spot check imported items
   - Verify language/level distribution

2. **Native Speaker Verification**
   - Set up verification workflow
   - Update `verified_by_native` flags
   - Update `quality_score` based on reviews

3. **Audio Generation**
   - Generate TTS audio for items
   - Update `audio_url` fields
   - Verify audio accessibility

4. **Mobile App Integration**
   - Update mobile app to fetch lesson items
   - Test item display and interaction
   - Verify performance with large dataset

## API Endpoints

### Import
- `POST /api/v1/lesson-items/bulk-import` - Bulk import items (Admin)

### Query
- `GET /api/v1/lesson-items` - Get items with filters
- `GET /api/v1/lesson-items/stats` - Get statistics

### Query Parameters (GET /api/v1/lesson-items)
- `language_code` - Filter by language code (e.g., "yo")
- `level` - Filter by CEFR level (A0-C1)
- `category` - Filter by category
- `type` - Filter by type (vocabulary, grammar, etc.)
- `min_quality_score` - Minimum quality score (default: 0.95)
- `verified_only` - Only verified items (true/false)
- `page` - Page number (default: 1)
- `limit` - Items per page (default: 50)

## Example Workflow

```bash
# 1. Generate items
cd scripts
python lesson_generator.py

# 2. Review items
python -c "import json; data = json.load(open('lesson_items.json')); print(f'Total: {len(data)}, Valid: {len([i for i in data if i.get(\"quality_score\", 0) > 0])}')"

# 3. Import to backend
python import_to_backend.py \
  --file lesson_items.json \
  --api-url http://localhost:3000/api \
  --batch-size 100

# 4. Verify import
curl http://localhost:3000/api/v1/lesson-items/stats | jq

# 5. Query sample items
curl "http://localhost:3000/api/v1/lesson-items?language_code=yo&level=A1&limit=5" | jq
```

