#!/usr/bin/env python3
"""
Backend Import Script
Imports generated lesson items to the backend database via API

Usage:
    python import_to_backend.py --file lesson_items.json --api-url http://localhost:3000/api
"""

import json
import argparse
import requests
from typing import List, Dict
import sys

def import_lesson_items(file_path: str, api_url: str, batch_size: int = 100, auth_token: str = None):
    """
    Import lesson items to backend in batches
    
    Args:
        file_path: Path to JSON file containing lesson items
        api_url: Base URL of the backend API
        batch_size: Number of items to import per batch
    """
    print(f"📥 Loading lesson items from {file_path}...")
    
    try:
        with open(file_path, 'r', encoding='utf-8') as f:
            items = json.load(f)
    except FileNotFoundError:
        print(f"❌ Error: File {file_path} not found")
        return False
    except json.JSONDecodeError as e:
        print(f"❌ Error: Invalid JSON in {file_path}: {e}")
        return False
    
    total_items = len(items)
    print(f"✅ Loaded {total_items} lesson items")
    
    # Filter out placeholder items (quality_score = 0.0)
    real_items = [item for item in items if item.get('quality_score', 0) > 0]
    placeholder_count = total_items - len(real_items)
    
    if placeholder_count > 0:
        print(f"⚠️  Skipping {placeholder_count} placeholder items")
    
    print(f"📤 Importing {len(real_items)} real lesson items...")
    
    # Import in batches
    success_count = 0
    error_count = 0
    
    for i in range(0, len(real_items), batch_size):
        batch = real_items[i:i + batch_size]
        batch_num = (i // batch_size) + 1
        total_batches = (len(real_items) + batch_size - 1) // batch_size
        
        print(f"\n📦 Batch {batch_num}/{total_batches} ({len(batch)} items)...")
        
        try:
            # Import endpoint
            endpoint = f"{api_url}/v1/lesson-items/bulk-import"
            
            headers = {'Content-Type': 'application/json'}
            if auth_token:
                headers['Authorization'] = f'Bearer {auth_token}'
            
            response = requests.post(
                endpoint,
                json={'items': batch},
                headers=headers,
                timeout=60
            )
            
            if response.status_code == 200 or response.status_code == 201:
                result = response.json()
                batch_success = result.get('imported', len(batch))
                success_count += batch_success
                print(f"  ✅ Successfully imported {batch_success} items")
            else:
                print(f"  ❌ Error: HTTP {response.status_code}")
                print(f"  Response: {response.text}")
                error_count += len(batch)
                
        except requests.exceptions.RequestException as e:
            print(f"  ❌ Network error: {e}")
            error_count += len(batch)
        except Exception as e:
            print(f"  ❌ Unexpected error: {e}")
            error_count += len(batch)
    
    print(f"\n📊 Import Summary:")
    print(f"  ✅ Successfully imported: {success_count}")
    print(f"  ❌ Errors: {error_count}")
    print(f"  ⏭️  Skipped placeholders: {placeholder_count}")
    print(f"  📈 Total: {total_items}")
    
    return error_count == 0

def main():
    parser = argparse.ArgumentParser(description='Import lesson items to backend')
    parser.add_argument('--file', '-f', required=True, help='Path to lesson items JSON file')
    parser.add_argument('--api-url', '-u', default='http://localhost:3000/api', 
                       help='Backend API base URL')
    parser.add_argument('--batch-size', '-b', type=int, default=100,
                       help='Number of items per batch (default: 100)')
    parser.add_argument('--auth-token', '-t', type=str, default=None,
                       help='Admin authentication token (required for import)')
    
    args = parser.parse_args()
    
    success = import_lesson_items(args.file, args.api_url, args.batch_size, args.auth_token)
    sys.exit(0 if success else 1)

if __name__ == '__main__':
    main()

