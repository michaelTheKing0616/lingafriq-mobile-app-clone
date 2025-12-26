#!/usr/bin/env python3
"""
Template Expansion Script
Expands lesson_templates.json with comprehensive content for all languages and categories
This script can be run incrementally to build up the template library
"""

import json
import os
from typing import Dict, List

# Language-specific vocabulary data
# This would ideally come from linguistic databases, but we provide foundational data here

YORUBA_CONTENT = {
    "A0": {
        "sounds_tones": [
            {"text": "a", "ipa": "a", "tone_pattern": ["mid"], "translation": "vowel sound a", "usage_context": "pronunciation"},
            {"text": "á", "ipa": "á", "tone_pattern": ["high"], "translation": "high tone a", "usage_context": "pronunciation"},
            {"text": "à", "ipa": "à", "tone_pattern": ["low"], "translation": "low tone a", "usage_context": "pronunciation"},
            {"text": "e", "ipa": "e", "tone_pattern": ["mid"], "translation": "vowel sound e", "usage_context": "pronunciation"},
            {"text": "é", "ipa": "é", "tone_pattern": ["high"], "translation": "high tone e", "usage_context": "pronunciation"},
            {"text": "è", "ipa": "è", "tone_pattern": ["low"], "translation": "low tone e", "usage_context": "pronunciation"},
            {"text": "ẹ", "ipa": "ɛ", "tone_pattern": ["mid"], "translation": "open e sound", "usage_context": "pronunciation"},
            {"text": "ẹ́", "ipa": "ɛ́", "tone_pattern": ["high"], "translation": "high tone ẹ", "usage_context": "pronunciation"},
            {"text": "ẹ̀", "ipa": "ɛ̀", "tone_pattern": ["low"], "translation": "low tone ẹ", "usage_context": "pronunciation"},
            {"text": "i", "ipa": "i", "tone_pattern": ["mid"], "translation": "vowel sound i", "usage_context": "pronunciation"},
            {"text": "í", "ipa": "í", "tone_pattern": ["high"], "translation": "high tone i", "usage_context": "pronunciation"},
            {"text": "ì", "ipa": "ì", "tone_pattern": ["low"], "translation": "low tone i", "usage_context": "pronunciation"},
            {"text": "o", "ipa": "o", "tone_pattern": ["mid"], "translation": "vowel sound o", "usage_context": "pronunciation"},
            {"text": "ó", "ipa": "ó", "tone_pattern": ["high"], "translation": "high tone o", "usage_context": "pronunciation"},
            {"text": "ò", "ipa": "ò", "tone_pattern": ["low"], "translation": "low tone o", "usage_context": "pronunciation"},
            {"text": "ọ", "ipa": "ɔ", "tone_pattern": ["mid"], "translation": "open o sound", "usage_context": "pronunciation"},
            {"text": "ọ́", "ipa": "ɔ́", "tone_pattern": ["high"], "translation": "high tone ọ", "usage_context": "pronunciation"},
            {"text": "ọ̀", "ipa": "ɔ̀", "tone_pattern": ["low"], "translation": "low tone ọ", "usage_context": "pronunciation"},
            {"text": "u", "ipa": "u", "tone_pattern": ["mid"], "translation": "vowel sound u", "usage_context": "pronunciation"},
            {"text": "ú", "ipa": "ú", "tone_pattern": ["high"], "translation": "high tone u", "usage_context": "pronunciation"},
            {"text": "ù", "ipa": "ù", "tone_pattern": ["low"], "translation": "low tone u", "usage_context": "pronunciation"},
        ]
    },
    "A1": {
        "numbers": [
            {"text": "oókan", "ipa": "óːkàn", "tone_pattern": ["high", "low"], "translation": "one", "usage_context": "vocabulary"},
            {"text": "èjì", "ipa": "èdʒì", "tone_pattern": ["low", "low"], "translation": "two", "usage_context": "vocabulary"},
            {"text": "ẹ̀ta", "ipa": "ɛ̀tá", "tone_pattern": ["low", "high"], "translation": "three", "usage_context": "vocabulary"},
            {"text": "ẹ̀rin", "ipa": "ɛ̀rĩ", "tone_pattern": ["low", "mid"], "translation": "four", "usage_context": "vocabulary"},
            {"text": "àrún", "ipa": "àrún", "tone_pattern": ["low", "high"], "translation": "five", "usage_context": "vocabulary"},
            {"text": "ẹ̀fà", "ipa": "ɛ̀fà", "tone_pattern": ["low", "low"], "translation": "six", "usage_context": "vocabulary"},
            {"text": "èje", "ipa": "èdʒé", "tone_pattern": ["low", "high"], "translation": "seven", "usage_context": "vocabulary"},
            {"text": "ẹ̀jọ", "ipa": "ɛ̀dʒɔ", "tone_pattern": ["low", "mid"], "translation": "eight", "usage_context": "vocabulary"},
            {"text": "ẹ̀sàn", "ipa": "ɛ̀sã", "tone_pattern": ["low", "mid"], "translation": "nine", "usage_context": "vocabulary"},
            {"text": "ẹ̀wá", "ipa": "ɛ̀wá", "tone_pattern": ["low", "high"], "translation": "ten", "usage_context": "vocabulary"},
        ]
    }
}

def expand_templates(input_file: str, output_file: str):
    """Expand templates file with additional content"""
    # Load existing templates
    if os.path.exists(input_file):
        with open(input_file, 'r', encoding='utf-8') as f:
            templates = json.load(f)
    else:
        templates = {}
    
    # Add expanded content
    # Start with Yoruba as an example - this pattern can be repeated for all languages
    if 'yoruba' not in templates:
        templates['yoruba'] = {}
    
    # Merge A0 sounds_tones
    if 'A0' not in templates['yoruba']:
        templates['yoruba']['A0'] = {}
    
    if 'sounds_tones' not in templates['yoruba']['A0']:
        templates['yoruba']['A0']['sounds_tones'] = []
    
    # Add new items without duplicates
    existing_texts = {item['text'] for item in templates['yoruba']['A0'].get('sounds_tones', [])}
    for item in YORUBA_CONTENT['A0']['sounds_tones']:
        if item['text'] not in existing_texts:
            templates['yoruba']['A0']['sounds_tones'].append(item)
    
    # Merge A1 numbers
    if 'A1' not in templates['yoruba']:
        templates['yoruba']['A1'] = {}
    
    if 'numbers' not in templates['yoruba']['A1']:
        templates['yoruba']['A1']['numbers'] = []
    
    existing_texts = {item['text'] for item in templates['yoruba']['A1'].get('numbers', [])}
    for item in YORUBA_CONTENT['A1']['numbers']:
        if item['text'] not in existing_texts:
            templates['yoruba']['A1']['numbers'].append(item)
    
    # Save expanded templates
    with open(output_file, 'w', encoding='utf-8') as f:
        json.dump(templates, f, indent=2, ensure_ascii=False)
    
    print(f"✅ Expanded templates saved to {output_file}")

if __name__ == '__main__':
    script_dir = os.path.dirname(__file__)
    input_file = os.path.join(script_dir, 'lesson_templates.json')
    output_file = os.path.join(script_dir, 'lesson_templates.json')
    
    expand_templates(input_file, output_file)

