# Complete Guide: Review and Publish Articles

## Overview

Articles scraped by the automated workflow are saved with `published: false` by default. They need manual review and approval before being visible in the mobile app.

---

## Method 1: Using MongoDB Shell (Direct Database Access)

### Step 1: Connect to MongoDB

```bash
mongo -u lingafriqadmin -p lingafriq123 --authenticationDatabase lingafriq
```

### Step 2: View Unpublished Articles

```javascript
use lingafriq

// Count unpublished articles
db.culturearticles.count({ published: false })

// List all unpublished articles
db.culturearticles.find({ published: false }).pretty()

// List with specific fields
db.culturearticles.find(
  { published: false },
  { title: 1, category: 1, country: 1, created_at: 1 }
).sort({ created_at: -1 })
```

### Step 3: Review an Article

```javascript
// View a specific article in detail
db.culturearticles.findOne({ title: "Yoruba people" })

// Or by ID
db.culturearticles.findOne({ _id: ObjectId("YOUR_ARTICLE_ID") })
```

### Step 4: Publish a Single Article

```javascript
// Publish by title
db.culturearticles.updateOne(
  { title: "Yoruba people" },
  { 
    $set: { 
      published: true,
      published_date: new Date(),
      updated_at: new Date()
    }
  }
)

// Publish by ID
db.culturearticles.updateOne(
  { _id: ObjectId("YOUR_ARTICLE_ID") },
  { 
    $set: { 
      published: true,
      published_date: new Date(),
      updated_at: new Date()
    }
  }
)
```

### Step 5: Publish Multiple Articles

```javascript
// Publish all unpublished articles (use with caution!)
db.culturearticles.updateMany(
  { published: false },
  { 
    $set: { 
      published: true,
      published_date: new Date(),
      updated_at: new Date()
    }
  }
)

// Publish by category
db.culturearticles.updateMany(
  { published: false, category: "history" },
  { 
    $set: { 
      published: true,
      published_date: new Date(),
      updated_at: new Date()
    }
  }
)

// Publish by country
db.culturearticles.updateMany(
  { published: false, country: "Nigeria" },
  { 
    $set: { 
      published: true,
      published_date: new Date(),
      updated_at: new Date()
    }
  }
)
```

### Step 6: Feature an Article

```javascript
// Make an article featured
db.culturearticles.updateOne(
  { title: "Yoruba people" },
  { 
    $set: { 
      featured: true,
      updated_at: new Date()
    }
  }
)
```

### Step 7: Edit Article Content

```javascript
// Update article title
db.culturearticles.updateOne(
  { _id: ObjectId("YOUR_ARTICLE_ID") },
  { 
    $set: { 
      title: "New Title",
      updated_at: new Date()
    }
  }
)

// Update article content
db.culturearticles.updateOne(
  { _id: ObjectId("YOUR_ARTICLE_ID") },
  { 
    $set: { 
      content: "Updated content here...",
      updated_at: new Date()
    }
  }
)

// Update multiple fields
db.culturearticles.updateOne(
  { _id: ObjectId("YOUR_ARTICLE_ID") },
  { 
    $set: { 
      title: "New Title",
      content: "New content",
      category: "tradition",
      featured: true,
      updated_at: new Date()
    }
  }
)
```

### Step 8: Delete an Article

```javascript
// Delete by title
db.culturearticles.deleteOne({ title: "Article Title" })

// Delete by ID
db.culturearticles.deleteOne({ _id: ObjectId("YOUR_ARTICLE_ID") })
```

### Step 9: Verify Published Articles

```javascript
// Count published articles
db.culturearticles.count({ published: true })

// List published articles
db.culturearticles.find({ published: true }).pretty()

// List featured articles
db.culturearticles.find({ published: true, featured: true }).pretty()
```

---

## Method 2: Using API Endpoints (Recommended)

### Step 1: Get Your Authentication Token

You need a JWT token to access admin endpoints. Get it from your backend:

```bash
cd /root/node-backend
node -e "const jwt=require('jsonwebtoken');require('dotenv').config();console.log(jwt.sign({userId:'admin'},process.env.JWT_SECRET));"
```

Save this token for API calls.

### Step 2: View Unpublished Articles (via API)

```bash
# Get all articles (including unpublished - requires auth)
curl -H "Authorization: Bearer YOUR_TOKEN" \
  https://admin.lingafriq.com/culture-magazine/articles?published=false
```

### Step 3: Publish an Article via API

```bash
# Update article to published
curl -X PUT \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"published": true, "published_date": "'$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")'"}' \
  https://admin.lingafriq.com/culture-magazine/articles/ARTICLE_ID
```

### Step 4: Feature an Article via API

```bash
curl -X PUT \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"featured": true}' \
  https://admin.lingafriq.com/culture-magazine/articles/ARTICLE_ID
```

---

## Method 3: Using Official Admin Panel (Recommended - Easiest Method!)

**⚠️ IMPORTANT:** Use the official admin panel at **https://lingafriq-admin.web.app/** for all article management.

See `ADMIN_PANEL_CULTURE_MAGAZINE.md` for detailed instructions on using the admin panel.

---

## Method 3b: Using AdminJS (Alternative - if available)

### Step 1: Access Admin Panel

Navigate to: `https://admin.lingafriq.com/admin`

### Step 2: Login

**Credentials:**
- Email: `admin@lingafriq.com`
- Password: `lingafriq123`

### Step 3: Navigate to Culture Articles

1. Look for **"CultureArticle"** in the left sidebar
2. Click on it to view all articles

### Step 4: Filter Unpublished Articles

1. Click the **"Filter"** button (funnel icon)
2. Add filter: `published` = `false`
3. Click **"Apply"**
4. You'll now see only unpublished articles

**Alternative:** Sort by "Created At" (newest first) to see recently scraped articles

### Step 5: Review an Article

1. Click on an article title to open it
2. Review:
   - **Title** - Is it accurate?
   - **Content** - Is it appropriate and well-formatted?
   - **Category** - Is it correct?
   - **Country** - Is it accurate?
   - **Source URL** - Does it work?
   - **Tags** - Are they relevant?

### Step 6: Edit Article (if needed)

1. Click the **"Edit"** button (pencil icon)
2. Make changes to any field
3. Click **"Save"** when done

### Step 7: Publish Article

**Option A: Publish from List View**
1. In the article list, click the **checkbox** next to the article
2. Click **"Bulk actions"** dropdown
3. Select **"Edit"**
4. Check **"Published"** checkbox
5. Optionally check **"Featured"**
6. Click **"Save"**

**Option B: Publish from Edit View**
1. Open the article
2. Click **"Edit"**
3. Check the **"Published"** checkbox
4. Optionally check **"Featured"** to feature it
5. Set **"Published Date"** to today's date (or leave as is)
6. Click **"Save"**

### Step 8: Bulk Publish Multiple Articles

1. Select multiple articles using checkboxes
2. Click **"Bulk actions"** → **"Edit"**
3. Check **"Published"** = `true`
4. Click **"Save"**
5. All selected articles will be published

### Step 9: Feature Articles

1. Open an article
2. Click **"Edit"**
3. Check **"Featured"** checkbox
4. Click **"Save"**
5. Featured articles appear prominently in the mobile app

### Step 10: Delete Articles

1. Select article(s) using checkbox
2. Click **"Bulk actions"** → **"Delete"**
3. Confirm deletion
4. **Warning:** This permanently deletes the article!

---

## AdminJS Tips

### Quick Actions

- **Search:** Use the search bar to find specific articles
- **Sort:** Click column headers to sort
- **Filter:** Use filters to find articles by category, country, etc.
- **Export:** Export articles to CSV/JSON if needed

### Recommended Workflow

1. **Daily:** Check for new unpublished articles
2. **Review:** Read through content for quality
3. **Edit:** Fix any issues (typos, categories, etc.)
4. **Publish:** Publish quality articles
5. **Feature:** Feature the best articles

---

## Quick Workflow Script

Create a script to quickly publish articles:

```bash
# Create publish script
cat > /root/publish_articles.sh << 'EOF'
#!/bin/bash

# Connect to MongoDB and publish articles
mongo -u lingafriqadmin -p lingafriq123 --authenticationDatabase lingafriq << EOM
use lingafriq

// Publish all unpublished articles
db.culturearticles.updateMany(
  { published: false },
  { 
    $set: { 
      published: true,
      published_date: new Date(),
      updated_at: new Date()
    }
  }
)

// Show count
print("Published articles: " + db.culturearticles.count({ published: true }))
print("Unpublished articles: " + db.culturearticles.count({ published: false }))
EOM
EOF

chmod +x /root/publish_articles.sh
```

Run it:
```bash
/root/publish_articles.sh
```

---

## Best Practices

1. **Review Before Publishing**: Always review content for accuracy and appropriateness
2. **Check Sources**: Verify source URLs are valid and properly cited
3. **Categorize Correctly**: Ensure articles are in the right category
4. **Feature Quality Content**: Only feature high-quality, engaging articles
5. **Regular Reviews**: Set up a schedule to review new articles (e.g., weekly)

---

## Monitoring Published Articles

```javascript
// In MongoDB shell
use lingafriq

// Get statistics
db.culturearticles.aggregate([
  {
    $group: {
      _id: "$category",
      total: { $sum: 1 },
      published: { 
        $sum: { $cond: ["$published", 1, 0] }
      },
      unpublished: { 
        $sum: { $cond: ["$published", 0, 1] }
      }
    }
  }
])

// Get articles by country
db.culturearticles.aggregate([
  {
    $group: {
      _id: "$country",
      count: { $sum: 1 },
      published: { 
        $sum: { $cond: ["$published", 1, 0] }
      }
    }
  },
  { $sort: { count: -1 } }
])
```

---

**Choose the method that works best for you. Method 1 (MongoDB Shell) is fastest for bulk operations!**

