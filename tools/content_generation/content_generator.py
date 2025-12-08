#!/usr/bin/env python3
"""
LingAfriq Content Generation Pipeline
Automates content generation using freely available resources and AI
"""

import json
import os
import requests
from typing import Dict, List, Optional
from dataclasses import dataclass, asdict
from pathlib import Path
import time
import random

# Free resources
WIKTIONARY_API = "https://en.wiktionary.org/api/rest_v1/page/definition"
TATOEBA_API = "https://tatoeba.org/en/api_v0/search"
WIKIPEDIA_API = "https://en.wikipedia.org/api/rest_v1/page/summary"

# Supported languages
SUPPORTED_LANGUAGES = [
    "yoruba", "hausa", "igbo", "swahili", "zulu", "xhosa",
    "amharic", "twi", "afrikaans", "pidgin", "wolof", "somali"
]

@dataclass
class PhraseCard:
    """Phrase card for games and learning"""
    card_id: str
    language: str
    text: str
    ascii: Optional[str]
    gloss: str
    ipa: Optional[str]
    level: str
    tags: List[str]
    audio_native_url: Optional[str]
    context_examples: List[str]
    srs: Dict

@dataclass
class RoleplayScenario:
    """Roleplay scenario for AI chat"""
    id: str
    language: str
    scenario: str
    user_prompt: str
    assistant_response: str
    cultural_notes: str
    difficulty: str

class ContentGenerator:
    """Main content generation class"""
    
    def __init__(self, output_dir: str = "generated_content"):
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(exist_ok=True)
        
    def generate_phrase_cards(self, language: str, count: int = 100) -> List[Dict]:
        """Generate phrase cards using Wiktionary and AI"""
        cards = []
        
        # Common phrases for each language
        common_phrases = self._get_common_phrases(language)
        
        for i, phrase_data in enumerate(common_phrases[:count]):
            card = PhraseCard(
                card_id=f"{language}_phrase_{i+1:04d}",
                language=language,
                text=phrase_data.get("text", ""),
                ascii=phrase_data.get("ascii"),
                gloss=phrase_data.get("gloss", ""),
                ipa=phrase_data.get("ipa"),
                level=phrase_data.get("level", "A1"),
                tags=phrase_data.get("tags", []),
                audio_native_url=None,  # Will be generated via TTS
                context_examples=phrase_data.get("examples", []),
                srs={"ease": 2.5, "repetitions": 0, "interval_days": 0}
            )
            cards.append(asdict(card))
            
        return cards
    
    def generate_roleplay_scenarios(self, language: str, count: int = 50) -> List[Dict]:
        """Generate roleplay scenarios using AI"""
        scenarios = []
        
        # Common scenarios
        scenario_templates = [
            {
                "scenario": "Market bargaining",
                "user_prompt": "You want to buy fruits at a local market. Negotiate the price.",
                "cultural_notes": "Bargaining is expected in markets. Start at 60% of asking price."
            },
            {
                "scenario": "Greeting an elder",
                "user_prompt": "You meet an elder in your community. Greet them respectfully.",
                "cultural_notes": "Use formal greetings and show respect through body language."
            },
            {
                "scenario": "Ordering food",
                "user_prompt": "You're at a restaurant. Order your favorite local dish.",
                "cultural_notes": "Be polite and ask about ingredients if you have allergies."
            },
            {
                "scenario": "Asking for directions",
                "user_prompt": "You're lost. Ask someone for directions to the nearest landmark.",
                "cultural_notes": "People are generally helpful. Thank them appropriately."
            },
            {
                "scenario": "Family gathering",
                "user_prompt": "You're at a family gathering. Introduce yourself to relatives.",
                "cultural_notes": "Family is important. Show respect to elders first."
            }
        ]
        
        for i, template in enumerate(scenario_templates[:count]):
            scenario = RoleplayScenario(
                id=f"{language}_roleplay_{i+1:04d}",
                language=language,
                scenario=template["scenario"],
                user_prompt=template["user_prompt"],
                assistant_response=f"[AI-generated response for {language}]",
                cultural_notes=template["cultural_notes"],
                difficulty=random.choice(["A1", "A2", "B1"])
            )
            scenarios.append(asdict(scenario))
            
        return scenarios
    
    def _get_common_phrases(self, language: str) -> List[Dict]:
        """Get common phrases for a language"""
        # This would be expanded with actual data sources
        # For now, return template structure
        phrases = {
            "yoruba": [
                {"text": "Báwo ní?", "gloss": "How are you?", "level": "A1", "tags": ["greeting"]},
                {"text": "Ẹ káàárọ̀", "gloss": "Good morning", "level": "A1", "tags": ["greeting"]},
                {"text": "Mo dúpé", "gloss": "Thank you", "level": "A1", "tags": ["courtesy"]},
            ],
            "swahili": [
                {"text": "Habari yako?", "gloss": "How are you?", "level": "A1", "tags": ["greeting"]},
                {"text": "Asante", "gloss": "Thank you", "level": "A1", "tags": ["courtesy"]},
            ],
            # Add more languages...
        }
        
        return phrases.get(language, [])
    
    def save_to_file(self, data: List[Dict], filename: str):
        """Save generated content to JSON file"""
        filepath = self.output_dir / filename
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        print(f"Saved {len(data)} items to {filepath}")
    
    def generate_all_content(self):
        """Generate all content for all languages"""
        print("Starting content generation pipeline...")
        
        for language in SUPPORTED_LANGUAGES:
            print(f"\nGenerating content for {language}...")
            
            # Generate phrase cards
            phrase_cards = self.generate_phrase_cards(language, count=500)
            self.save_to_file(
                phrase_cards,
                f"{language}_phrase_cards.json"
            )
            
            # Generate roleplay scenarios
            roleplay_scenarios = self.generate_roleplay_scenarios(language, count=50)
            self.save_to_file(
                roleplay_scenarios,
                f"{language}_roleplay_scenarios.json"
            )
            
            time.sleep(1)  # Rate limiting
        
        print("\n✅ Content generation complete!")

if __name__ == "__main__":
    generator = ContentGenerator()
    generator.generate_all_content()

