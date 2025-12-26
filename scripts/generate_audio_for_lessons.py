#!/usr/bin/env python3
"""
Audio Generation Script for Lesson Items
Generates audio for lesson items via backend API

Usage:
    python generate_audio_for_lessons.py --api-url http://localhost:3000/api --auth-token <token>
"""

import argparse
import requests
import sys
from typing import List, Dict
import time

def generate_audio_batch(api_url: str, auth_token: str, item_ids: List[str], batch_size: int = 10):
    """Generate audio for a batch of lesson items"""
    results = {
        'success': 0,
        'failed': 0,
        'errors': [],
    }

    for i in range(0, len(item_ids), batch_size):
        batch = item_ids[i:i + batch_size]
        batch_num = (i // batch_size) + 1
        total_batches = (len(item_ids) + batch_size - 1) // batch_size

        print(f"\n📦 Processing batch {batch_num}/{total_batches} ({len(batch)} items)...")

        try:
            endpoint = f"{api_url}/v1/lesson-items/generate-audio/batch"
            headers = {
                'Authorization': f'Bearer {auth_token}',
                'Content-Type': 'application/json',
            }

            response = requests.post(
                endpoint,
                json={'item_ids': batch},
                headers=headers,
                timeout=300,
            )

            if response.status_code == 200:
                result = response.json()
                if result.get('success'):
                    summary = result.get('data', {}).get('summary', {})
                    results['success'] += summary.get('success', 0)
                    results['failed'] += summary.get('failed', 0)
                    print(f"  ✅ Batch completed: {summary.get('success', 0)} success, {summary.get('failed', 0)} failed")
                else:
                    results['failed'] += len(batch)
                    print(f"  ❌ Batch failed: {result.get('message', 'Unknown error')}")
            else:
                results['failed'] += len(batch)
                print(f"  ❌ HTTP {response.status_code}: {response.text}")

            # Rate limiting
            time.sleep(1)

        except requests.exceptions.RequestException as e:
            results['failed'] += len(batch)
            results['errors'].append(f"Batch {batch_num}: {str(e)}")
            print(f"  ❌ Network error: {e}")

    return results

def generate_audio_for_missing(api_url: str, auth_token: str, filters: Dict = None):
    """Generate audio for all items missing audio"""
    try:
        endpoint = f"{api_url}/v1/lesson-items/generate-audio/missing"
        headers = {
            'Authorization': f'Bearer {auth_token}',
            'Content-Type': 'application/json',
        }

        response = requests.post(
            endpoint,
            json=filters or {},
            headers=headers,
            timeout=600,
        )

        if response.status_code == 200:
            result = response.json()
            if result.get('success'):
                summary = result.get('data', {}).get('summary', {})
                print(f"\n✅ Audio generation completed:")
                print(f"  Total: {summary.get('total', 0)}")
                print(f"  Success: {summary.get('success', 0)}")
                print(f"  Failed: {summary.get('failed', 0)}")
                return True
            else:
                print(f"❌ Error: {result.get('message', 'Unknown error')}")
                return False
        else:
            print(f"❌ HTTP {response.status_code}: {response.text}")
            return False

    except requests.exceptions.RequestException as e:
        print(f"❌ Network error: {e}")
        return False

def main():
    parser = argparse.ArgumentParser(description='Generate audio for lesson items')
    parser.add_argument('--api-url', '-u', default='http://localhost:3000/api',
                       help='Backend API base URL')
    parser.add_argument('--auth-token', '-t', required=True,
                       help='Admin authentication token')
    parser.add_argument('--item-ids', '-i', nargs='+',
                       help='Specific item IDs to generate audio for')
    parser.add_argument('--language-code', '-l',
                       help='Generate audio for items in this language only')
    parser.add_argument('--level', '-lv',
                       help='Generate audio for items at this level only')
    parser.add_argument('--limit', type=int,
                       help='Maximum number of items to process')
    parser.add_argument('--batch-size', '-b', type=int, default=10,
                       help='Batch size for processing')

    args = parser.parse_args()

    if args.item_ids:
        # Generate for specific items
        print(f"🎵 Generating audio for {len(args.item_ids)} specific items...")
        results = generate_audio_batch(
            args.api_url,
            args.auth_token,
            args.item_ids,
            args.batch_size,
        )
        print(f"\n📊 Final Results:")
        print(f"  ✅ Success: {results['success']}")
        print(f"  ❌ Failed: {results['failed']}")
        sys.exit(0 if results['failed'] == 0 else 1)
    else:
        # Generate for missing items
        filters = {}
        if args.language_code:
            filters['language_code'] = args.language_code
        if args.level:
            filters['level'] = args.level
        if args.limit:
            filters['limit'] = args.limit

        print(f"🎵 Generating audio for missing items...")
        if filters:
            print(f"  Filters: {filters}")

        success = generate_audio_for_missing(args.api_url, args.auth_token, filters)
        sys.exit(0 if success else 1)

if __name__ == '__main__':
    main()

