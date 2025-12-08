#!/usr/bin/env python3
"""
Backend Integration for Content Generation
Uploads generated content to the backend API
"""

import json
import os
import requests
from pathlib import Path
from typing import Dict, List
import time

class BackendContentUploader:
    """Uploads generated content to backend"""
    
    def __init__(self, api_url: str, api_key: str):
        self.api_url = api_url.rstrip('/')
        self.headers = {
            "Authorization": f"Bearer {api_key}",
            "Content-Type": "application/json"
        }
    
    def upload_phrase_cards(self, language: str, cards: List[Dict], batch_size: int = 50):
        """Upload phrase cards to backend in batches"""
        endpoint = f"{self.api_url}/content/phrase-cards"
        
        total = len(cards)
        uploaded = 0
        failed = 0
        
        # Upload in batches
        for i in range(0, total, batch_size):
            batch = cards[i:i+batch_size]
            try:
                response = requests.post(
                    endpoint,
                    json={"language": language, "cards": batch},
                    headers=self.headers,
                    timeout=60
                )
                
                if response.status_code in [200, 201]:
                    uploaded += len(batch)
                    print(f"✅ Uploaded batch {i//batch_size + 1}: {len(batch)} cards")
                else:
                    failed += len(batch)
                    print(f"❌ Failed batch {i//batch_size + 1}: {response.status_code} - {response.text[:200]}")
                
                time.sleep(0.5)  # Rate limiting
            except Exception as e:
                failed += len(batch)
                print(f"❌ Error uploading batch {i//batch_size + 1}: {e}")
        
        print(f"📊 Phrase cards: {uploaded} uploaded, {failed} failed out of {total}")
        return uploaded, failed
    
    def upload_roleplay_scenarios(self, language: str, scenarios: List[Dict], batch_size: int = 50):
        """Upload roleplay scenarios to backend in batches"""
        endpoint = f"{self.api_url}/content/roleplay-scenarios"
        
        total = len(scenarios)
        uploaded = 0
        failed = 0
        
        # Upload in batches
        for i in range(0, total, batch_size):
            batch = scenarios[i:i+batch_size]
            try:
                response = requests.post(
                    endpoint,
                    json={"language": language, "scenarios": batch},
                    headers=self.headers,
                    timeout=60
                )
                
                if response.status_code in [200, 201]:
                    uploaded += len(batch)
                    print(f"✅ Uploaded batch {i//batch_size + 1}: {len(batch)} scenarios")
                else:
                    failed += len(batch)
                    print(f"❌ Failed batch {i//batch_size + 1}: {response.status_code} - {response.text[:200]}")
                
                time.sleep(0.5)  # Rate limiting
            except Exception as e:
                failed += len(batch)
                print(f"❌ Error uploading batch {i//batch_size + 1}: {e}")
        
        print(f"📊 Roleplay scenarios: {uploaded} uploaded, {failed} failed out of {total}")
        return uploaded, failed
    
    def upload_from_directory(self, directory: Path):
        """Upload all content from a directory"""
        total_uploaded = 0
        total_failed = 0
        
        for file in sorted(directory.glob("*.json")):
            print(f"\n📄 Processing {file.name}...")
            
            with open(file, 'r', encoding='utf-8') as f:
                data = json.load(f)
                language = file.stem.split('_')[0]
                
                if "phrase_cards" in file.name:
                    uploaded, failed = self.upload_phrase_cards(language, data)
                    total_uploaded += uploaded
                    total_failed += failed
                elif "roleplay" in file.name:
                    uploaded, failed = self.upload_roleplay_scenarios(language, data)
                    total_uploaded += uploaded
                    total_failed += failed
        
        print(f"\n📊 Total: {total_uploaded} uploaded, {total_failed} failed")

if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="Upload content to backend")
    parser.add_argument("--directory", default="generated_content", help="Directory with JSON files")
    parser.add_argument("--api-url", default=os.getenv("BACKEND_API_URL", "http://localhost:3000"))
    parser.add_argument("--api-key", default=os.getenv("BACKEND_API_KEY"))
    
    args = parser.parse_args()
    
    if not args.api_key:
        print("❌ BACKEND_API_KEY required")
        exit(1)
    
    uploader = BackendContentUploader(args.api_url, args.api_key)
    uploader.upload_from_directory(Path(args.directory))

if __name__ == "__main__":
    uploader = BackendContentUploader(
        api_url="https://api.lingafriq.com",
        api_key=os.getenv("BACKEND_API_KEY")
    )
    uploader.upload_from_directory(Path("generated_content"))

