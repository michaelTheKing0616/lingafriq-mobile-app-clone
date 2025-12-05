#!/bin/bash
# Deployment script for LingAfriq Backend
# Run this on your DigitalOcean server

echo "========================================"
echo "🚀 LingAfriq Backend Deployment"
echo "========================================"
echo ""

cd /root/node-backend

echo "📂 Creating backup of current files..."
mkdir -p backups
cp -r src backups/src-backup-$(date +%Y%m%d-%H%M%S) 2>/dev/null || true
cp package.json backups/package-backup-$(date +%Y%m%d-%H%M%S).json 2>/dev/null || true

echo "✅ Backup created"
echo ""

echo "📥 Creating new files..."

# Create scraper route
cat > src/routes/scraper.route.ts << 'SCRAPER_ROUTE_EOF'
import { Router, Request, Response } from 'express';
import jwt from 'jsonwebtoken';
import CultureArticle from '../models/cultureMagazine.model.js';

const router = Router();

// Middleware to verify scraper token
const verifyScraperToken = (req: Request, res: Response, next: Function) => {
  const authHeader = req.headers['authorization'];
  
  if (!authHeader) {
    return res.status(401).json({ 
      success: false, 
      error: 'Missing authorization header' 
    });
  }

  const token = authHeader.replace('Bearer ', '');
  const scraperSecret = process.env.SCRAPER_SECRET || process.env.JWT_SECRET;

  try {
    jwt.verify(token, scraperSecret!);
    next();
  } catch (error) {
    return res.status(403).json({ 
      success: false, 
      error: 'Invalid or expired token' 
    });
  }
};

// Bulk save articles endpoint
router.post('/articles/bulk', verifyScraperToken, async (req: Request, res: Response) => {
  try {
    const { articles } = req.body;

    if (!Array.isArray(articles)) {
      return res.status(400).json({
        success: false,
        error: 'Articles must be an array'
      });
    }

    const savedArticles = [];
    const skippedArticles = [];
    const errors = [];

    for (const article of articles) {
      try {
        const existing = await CultureArticle.findOne({ title: article.title });
        
        if (existing) {
          skippedArticles.push({ title: article.title, reason: 'Already exists' });
          continue;
        }

        if (!article.title || !article.content || !article.category) {
          skippedArticles.push({ title: article.title || 'Unknown', reason: 'Missing required fields' });
          continue;
        }

        const newArticle = new CultureArticle({
          ...article,
          published: false,
          featured: false,
          author: article.author || 'LingAfriq Editorial Team',
          published_date: article.published_date || new Date(),
          created_at: new Date(),
          updated_at: new Date()
        });

        await newArticle.save();
        savedArticles.push({ id: newArticle._id, title: newArticle.title, category: newArticle.category });

      } catch (error: any) {
        errors.push({ title: article.title, error: error.message });
      }
    }

    res.json({
      success: true,
      message: 'Bulk article save completed',
      stats: {
        total: articles.length,
        saved: savedArticles.length,
        skipped: skippedArticles.length,
        errors: errors.length
      },
      savedArticles,
      skippedArticles,
      errors
    });

  } catch (error: any) {
    console.error('Bulk save error:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to save articles',
      message: error.message
    });
  }
});

// Health check endpoint
router.get('/health', (req: Request, res: Response) => {
  res.json({
    success: true,
    message: 'Scraper API is running',
    timestamp: new Date().toISOString()
  });
});

export default router;
SCRAPER_ROUTE_EOF

echo "✅ Created src/routes/scraper.route.ts"

# Add scraper import to index.route.ts (backup first)
if ! grep -q "scraperRouter" src/routes/index.route.ts; then
  echo "📝 Adding scraper route to index.route.ts..."
  # Add import after other route imports
  sed -i '/import userConnectionRouter/a import scraperRouter from "../routes/scraper.route.js";' src/routes/index.route.ts
  # Add router.use after other route uses
  sed -i '/router.use("\/connections", userConnectionRouter);/a router.use("/scraper", scraperRouter); // Secure API for automated scrapers' src/routes/index.route.ts
  echo "✅ Added scraper route"
else
  echo "✅ Scraper route already configured"
fi

# Add protect middleware export
if ! grep -q "export const protect" src/middleware/auth.middleware.ts; then
  echo "📝 Adding protect middleware..."
  echo "" >> src/middleware/auth.middleware.ts
  echo "// Alias for compatibility with new routes" >> src/middleware/auth.middleware.ts
  echo "export const protect = requireSignin;" >> src/middleware/auth.middleware.ts
  echo "✅ Added protect middleware"
else
  echo "✅ Protect middleware already exists"
fi

# Create token generator script
cat > scripts/generateScraperToken.js << 'TOKEN_SCRIPT_EOF'
import jwt from 'jsonwebtoken';
import dotenv from 'dotenv';

dotenv.config();

const secret = process.env.SCRAPER_SECRET || process.env.JWT_SECRET;

if (!secret) {
  console.error('❌ ERROR: No JWT_SECRET found in .env');
  process.exit(1);
}

const token = jwt.sign({ type: 'scraper', purpose: 'automated_content_import', generated: new Date().toISOString() }, secret);

console.log('');
console.log('==========================================');
console.log('✅ SCRAPER TOKEN GENERATED');
console.log('==========================================');
console.log('');
console.log(token);
console.log('');
console.log('Add this to GitHub Secrets as SCRAPER_TOKEN');
console.log('==========================================');
console.log('');
TOKEN_SCRIPT_EOF

echo "✅ Created scripts/generateScraperToken.js"

echo ""
echo "========================================"
echo "📦 Installing dependencies..."
echo "========================================"
npm install

echo ""
echo "========================================"
echo "🔨 Building TypeScript..."
echo "========================================"
npm run build

echo ""
echo "========================================"
echo "🔄 Restarting backend..."
echo "========================================"
pm2 restart server
pm2 save

echo ""
echo "========================================"
echo "✅ DEPLOYMENT COMPLETE!"
echo "========================================"
echo ""
echo "Test new endpoint:"
echo "  curl http://localhost:4000/scraper/health"
echo ""

