#!/usr/bin/env python3
"""
Automated Content Generation Pipeline
Runs periodically to generate and upload content
Can be triggered manually or via cron/systemd
"""

import os
import sys
import json
from pathlib import Path
from datetime import datetime
import time

# Add parent directory to path
sys.path.insert(0, str(Path(__file__).parent))

from enhanced_content_generator import EnhancedContentGenerator
from backend_integration import BackendContentUploader

class AutomatedPipeline:
    """Automated pipeline for content generation and upload"""
    
    def __init__(self, backend_url: str = None, backend_api_key: str = None, groq_api_key: str = None):
        self.backend_url = backend_url or os.getenv("BACKEND_API_URL", "https://api.lingafriq.com")
        self.backend_api_key = backend_api_key or os.getenv("BACKEND_API_KEY")
        self.groq_api_key = groq_api_key or os.getenv("GROQ_API_KEY")
        self.output_dir = Path("generated_content")
        self.log_file = Path("pipeline.log")
        
    def log(self, message: str):
        """Log message with timestamp"""
        timestamp = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        log_message = f"[{timestamp}] {message}"
        print(log_message)
        
        with open(self.log_file, 'a', encoding='utf-8') as f:
            f.write(log_message + "\n")
    
    def run_generation(self, language: str = None):
        """Run content generation"""
        self.log("🚀 Starting content generation...")
        
        try:
            generator = EnhancedContentGenerator(
                output_dir=str(self.output_dir),
                groq_api_key=self.groq_api_key
            )
            
            if language:
                self.log(f"Generating content for {language}...")
                phrase_cards = generator.generate_phrase_cards(language, count=500)
                generator.save_to_file(phrase_cards, f"{language}_phrase_cards.json")
                
                roleplay_scenarios = generator.generate_roleplay_scenarios(language, count=200)
                generator.save_to_file(roleplay_scenarios, f"{language}_roleplay_scenarios.json")
            else:
                generator.generate_all_content()
            
            self.log("✅ Content generation complete")
            return True
        except Exception as e:
            self.log(f"❌ Generation failed: {e}")
            import traceback
            self.log(traceback.format_exc())
            return False
    
    def run_upload(self):
        """Upload generated content to backend"""
        if not self.backend_api_key:
            self.log("⚠️  BACKEND_API_KEY not set. Skipping upload.")
            return False
        
        self.log("📤 Starting content upload...")
        
        try:
            uploader = BackendContentUploader(
                api_url=self.backend_url,
                api_key=self.backend_api_key
            )
            
            if not self.output_dir.exists() or not list(self.output_dir.glob("*.json")):
                self.log("⚠️  No content files found. Run generation first.")
                return False
            
            uploader.upload_from_directory(self.output_dir)
            
            self.log(f"📊 Upload complete: {uploader.uploaded_count} uploaded, {uploader.failed_count} failed")
            return uploader.failed_count == 0
        except Exception as e:
            self.log(f"❌ Upload failed: {e}")
            import traceback
            self.log(traceback.format_exc())
            return False
    
    def run_full_pipeline(self, language: str = None):
        """Run full pipeline: generate + upload"""
        self.log("="*60)
        self.log("🎬 Starting full content generation pipeline")
        self.log("="*60)
        
        try:
            # Generate content
            if not self.run_generation(language):
                return False
            
            # Small delay before upload
            time.sleep(5)
            
            # Upload content
            if not self.run_upload():
                self.log("⚠️  Upload had errors, but generation succeeded")
            
            self.log("="*60)
            self.log("🎉 Pipeline complete!")
            self.log("="*60)
            return True
        except Exception as e:
            self.log(f"❌ Pipeline failed: {e}")
            import traceback
            self.log(traceback.format_exc())
            return False

if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="Automated content generation pipeline")
    parser.add_argument("--language", help="Specific language (optional)")
    parser.add_argument("--generate-only", action="store_true", help="Only generate, don't upload")
    parser.add_argument("--upload-only", action="store_true", help="Only upload, don't generate")
    parser.add_argument("--backend-url", default=os.getenv("BACKEND_API_URL", "https://api.lingafriq.com"))
    parser.add_argument("--backend-key", default=os.getenv("BACKEND_API_KEY"))
    parser.add_argument("--groq-key", default=os.getenv("GROQ_API_KEY"))
    
    args = parser.parse_args()
    
    pipeline = AutomatedPipeline(
        backend_url=args.backend_url,
        backend_api_key=args.backend_key,
        groq_api_key=args.groq_key
    )
    
    if args.generate_only:
        success = pipeline.run_generation(args.language)
        sys.exit(0 if success else 1)
    elif args.upload_only:
        success = pipeline.run_upload()
        sys.exit(0 if success else 1)
    else:
        success = pipeline.run_full_pipeline(args.language)
        sys.exit(0 if success else 1)
