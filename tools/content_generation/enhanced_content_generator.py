#!/usr/bin/env python3
"""
Enhanced LingAfriq Content Generation Pipeline
Combines free resources (Wiktionary, Tatoeba, Wikipedia, OpenSubtitles) with AI generation (Groq)
"""

import json
import os
import requests
from typing import Dict, List, Optional, Tuple
from dataclasses import dataclass, asdict
from pathlib import Path
import time
import random
import re
from urllib.parse import quote
import hashlib

# Free resources
WIKTIONARY_API = "https://en.wiktionary.org/api/rest_v1/page/definition"
TATOEBA_API = "https://tatoeba.org/en/api_v0/search"
WIKIPEDIA_API = "https://en.wikipedia.org/api/rest_v1/page/summary"
OPENSUBTITLES_API = "https://opensubtitles.com/api/v1/search"
PROJECT_GUTENBERG_API = "https://gutendex.com/books/"

# Groq API (free tier available - 30 requests/min, 14,400 requests/day)
GROQ_API_URL = "https://api.groq.com/openai/v1/chat/completions"
GROQ_MODEL = "llama-3.1-70b-versatile"  # Best for multilingual

# Supported languages with ISO codes
SUPPORTED_LANGUAGES = {
    "yoruba": {"code": "yo", "name": "Yoruba", "country": "Nigeria", "iso639_3": "yor"},
    "hausa": {"code": "ha", "name": "Hausa", "country": "Nigeria", "iso639_3": "hau"},
    "igbo": {"code": "ig", "name": "Igbo", "country": "Nigeria", "iso639_3": "ibo"},
    "swahili": {"code": "sw", "name": "Swahili", "country": "Kenya", "iso639_3": "swa"},
    "zulu": {"code": "zu", "name": "Zulu", "country": "South Africa", "iso639_3": "zul"},
    "xhosa": {"code": "xh", "name": "Xhosa", "country": "South Africa", "iso639_3": "xho"},
    "amharic": {"code": "am", "name": "Amharic", "country": "Ethiopia", "iso639_3": "amh"},
    "twi": {"code": "tw", "name": "Twi", "country": "Ghana", "iso639_3": "twi"},
    "afrikaans": {"code": "af", "name": "Afrikaans", "country": "South Africa", "iso639_3": "afr"},
    "pidgin": {"code": "pcm", "name": "Nigerian Pidgin", "country": "Nigeria", "iso639_3": "pcm"},
    "wolof": {"code": "wo", "name": "Wolof", "country": "Senegal", "iso639_3": "wol"},
    "somali": {"code": "so", "name": "Somali", "country": "Somalia", "iso639_3": "som"},
}

# Comprehensive phrase categories
PHRASE_CATEGORIES = [
    "greetings", "courtesy", "numbers", "time", "directions", "food",
    "family", "colors", "weather", "shopping", "transport", "health",
    "emotions", "activities", "travel", "business", "education", "culture",
    "animals", "body", "clothing", "home", "nature", "sports", "technology"
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
    tags: List[str]

class EnhancedContentGenerator:
    """Enhanced content generator with AI and free sources"""
    
    def __init__(self, output_dir: str = "generated_content", groq_api_key: Optional[str] = None):
        self.output_dir = Path(output_dir)
        self.output_dir.mkdir(exist_ok=True)
        self.groq_api_key = groq_api_key or os.getenv("GROQ_API_KEY")
        self.groq_headers = {
            "Authorization": f"Bearer {self.groq_api_key}",
            "Content-Type": "application/json"
        } if self.groq_api_key else None
        self.request_count = 0
        self.rate_limit_delay = 2.1  # 30 requests/min = 1 request per 2 seconds
        
    def _call_groq_api(self, prompt: str, system_prompt: str = None, max_retries: int = 3) -> Optional[str]:
        """Call Groq API for AI generation with rate limiting"""
        if not self.groq_api_key:
            return None
        
        # Rate limiting
        if self.request_count > 0 and self.request_count % 25 == 0:
            print(f"⏳ Rate limiting: waiting 60 seconds...")
            time.sleep(60)
        
        for attempt in range(max_retries):
            try:
                messages = []
                if system_prompt:
                    messages.append({"role": "system", "content": system_prompt})
                messages.append({"role": "user", "content": prompt})
                
                response = requests.post(
                    GROQ_API_URL,
                    headers=self.groq_headers,
                    json={
                        "model": GROQ_MODEL,
                        "messages": messages,
                        "temperature": 0.7,
                        "max_tokens": 2000,
                    },
                    timeout=30
                )
                
                if response.status_code == 200:
                    self.request_count += 1
                    return response.json()["choices"][0]["message"]["content"]
                elif response.status_code == 429:
                    wait_time = 60
                    print(f"⏳ Rate limited. Waiting {wait_time} seconds...")
                    time.sleep(wait_time)
                    continue
                else:
                    print(f"Groq API error: {response.status_code} - {response.text}")
                    if attempt < max_retries - 1:
                        time.sleep(5)
                        continue
                    return None
            except Exception as e:
                print(f"Error calling Groq API (attempt {attempt + 1}): {e}")
                if attempt < max_retries - 1:
                    time.sleep(5)
                    continue
                return None
        
        return None
    
    def _get_wiktionary_definition(self, word: str, language: str) -> Optional[Dict]:
        """Get word definition from Wiktionary"""
        try:
            lang_code = SUPPORTED_LANGUAGES.get(language, {}).get("code", "")
            url = f"{WIKTIONARY_API}/{quote(word)}"
            response = requests.get(url, timeout=10)
            
            if response.status_code == 200:
                data = response.json()
                if lang_code in data:
                    return data[lang_code]
            return None
        except Exception as e:
            return None
    
    def _get_tatoeba_sentences(self, language: str, query: str, count: int = 5) -> List[str]:
        """Get example sentences from Tatoeba"""
        try:
            lang_code = SUPPORTED_LANGUAGES.get(language, {}).get("code", "")
            url = f"{TATOEBA_API}?from={lang_code}&to=eng&query={quote(query)}&trans_filter=limit&trans_to=eng&trans_link=direct&limit={count}"
            response = requests.get(url, timeout=10)
            
            if response.status_code == 200:
                data = response.json()
                sentences = []
                for result in data.get("results", [])[:count]:
                    if "text" in result:
                        sentences.append(result["text"])
                return sentences
            return []
        except Exception as e:
            return []
    
    def _get_wikipedia_content(self, topic: str, language: str) -> Optional[str]:
        """Get Wikipedia content for cultural context"""
        try:
            lang_code = SUPPORTED_LANGUAGES.get(language, {}).get("code", "")
            url = f"{WIKIPEDIA_API}/{quote(topic)}"
            response = requests.get(url, timeout=10)
            
            if response.status_code == 200:
                data = response.json()
                return data.get("extract", "")
            return None
        except Exception as e:
            return None
    
    def _get_common_phrases(self, language: str) -> List[Dict]:
        """Get comprehensive common phrases using AI and free sources"""
        phrases = []
        
        # Base phrases from curated lists
        base_phrases = self._get_base_phrases(language)
        phrases.extend(base_phrases)
        
        # Generate additional phrases using AI (batch processing for efficiency)
        if self.groq_api_key:
            print(f"🤖 Generating AI phrases for {language}...")
            ai_phrases = self._generate_phrases_with_ai(language, count=300)
            phrases.extend(ai_phrases)
        
        # Enrich with Wiktionary and Tatoeba (limited to avoid rate limits)
        enriched_phrases = []
        for i, phrase in enumerate(phrases[:500]):
            enriched = self._enrich_phrase(phrase, language)
            enriched_phrases.append(enriched)
            if i % 10 == 0:
                time.sleep(0.5)  # Rate limiting
        
        return enriched_phrases
    
    def _get_base_phrases(self, language: str) -> List[Dict]:
        """Get comprehensive base phrases from curated lists"""
        base_data = {
            "yoruba": [
                {"text": "Báwo ní?", "gloss": "How are you?", "level": "A1", "tags": ["greeting"]},
                {"text": "Ẹ káàárọ̀", "gloss": "Good morning", "level": "A1", "tags": ["greeting"]},
                {"text": "Mo dúpé", "gloss": "Thank you", "level": "A1", "tags": ["courtesy"]},
                {"text": "Ẹ jọ̀ọ́", "gloss": "Please", "level": "A1", "tags": ["courtesy"]},
                {"text": "Ẹ kú ìrọ̀lẹ́", "gloss": "Good afternoon", "level": "A1", "tags": ["greeting"]},
                {"text": "Ẹ káalẹ́", "gloss": "Good evening", "level": "A1", "tags": ["greeting"]},
                {"text": "Ó dàbọ̀", "gloss": "Goodbye", "level": "A1", "tags": ["greeting"]},
                {"text": "Mo ní ìdí", "gloss": "I'm sorry", "level": "A1", "tags": ["courtesy"]},
                {"text": "Kí ni orúkọ rẹ?", "gloss": "What is your name?", "level": "A1", "tags": ["greeting"]},
                {"text": "Orúkọ mi ni...", "gloss": "My name is...", "level": "A1", "tags": ["greeting"]},
                {"text": "Mo wá láti...", "gloss": "I come from...", "level": "A1", "tags": ["introduction"]},
                {"text": "Báwo ni a ṣe ń lọ sí...?", "gloss": "How do we get to...?", "level": "A2", "tags": ["directions"]},
                {"text": "Ẹ jẹun", "gloss": "Eat (polite)", "level": "A1", "tags": ["food", "courtesy"]},
                {"text": "Mo fẹ́...", "gloss": "I want...", "level": "A1", "tags": ["shopping"]},
                {"text": "Èlọ ni?", "gloss": "How much?", "level": "A1", "tags": ["shopping"]},
            ],
            "swahili": [
                {"text": "Habari yako?", "gloss": "How are you?", "level": "A1", "tags": ["greeting"]},
                {"text": "Asante", "gloss": "Thank you", "level": "A1", "tags": ["courtesy"]},
                {"text": "Karibu", "gloss": "Welcome", "level": "A1", "tags": ["greeting"]},
                {"text": "Hujambo", "gloss": "Hello", "level": "A1", "tags": ["greeting"]},
                {"text": "Sijambo", "gloss": "I'm fine", "level": "A1", "tags": ["greeting"]},
                {"text": "Tafadhali", "gloss": "Please", "level": "A1", "tags": ["courtesy"]},
                {"text": "Samahani", "gloss": "Excuse me/Sorry", "level": "A1", "tags": ["courtesy"]},
                {"text": "Kwaheri", "gloss": "Goodbye", "level": "A1", "tags": ["greeting"]},
                {"text": "Jina lako ni nani?", "gloss": "What is your name?", "level": "A1", "tags": ["greeting"]},
                {"text": "Jina langu ni...", "gloss": "My name is...", "level": "A1", "tags": ["greeting"]},
            ],
            "hausa": [
                {"text": "Yaya kake?", "gloss": "How are you? (m)", "level": "A1", "tags": ["greeting"]},
                {"text": "Yaya kike?", "gloss": "How are you? (f)", "level": "A1", "tags": ["greeting"]},
                {"text": "Na gode", "gloss": "Thank you", "level": "A1", "tags": ["courtesy"]},
                {"text": "Barka da safiya", "gloss": "Good morning", "level": "A1", "tags": ["greeting"]},
                {"text": "Barka da rana", "gloss": "Good afternoon", "level": "A1", "tags": ["greeting"]},
                {"text": "Barka da yamma", "gloss": "Good evening", "level": "A1", "tags": ["greeting"]},
            ],
            "igbo": [
                {"text": "Kedu?", "gloss": "How are you?", "level": "A1", "tags": ["greeting"]},
                {"text": "Daalụ", "gloss": "Thank you", "level": "A1", "tags": ["courtesy"]},
                {"text": "Ndewo", "gloss": "Hello", "level": "A1", "tags": ["greeting"]},
                {"text": "Ka ọ dị?", "gloss": "How are you? (informal)", "level": "A1", "tags": ["greeting"]},
            ],
            "zulu": [
                {"text": "Sawubona", "gloss": "Hello", "level": "A1", "tags": ["greeting"]},
                {"text": "Ngiyabonga", "gloss": "Thank you", "level": "A1", "tags": ["courtesy"]},
                {"text": "Unjani?", "gloss": "How are you?", "level": "A1", "tags": ["greeting"]},
            ],
            "xhosa": [
                {"text": "Molo", "gloss": "Hello", "level": "A1", "tags": ["greeting"]},
                {"text": "Enkosi", "gloss": "Thank you", "level": "A1", "tags": ["courtesy"]},
            ],
            "amharic": [
                {"text": "እንዴት ነህ?", "gloss": "How are you? (m)", "level": "A1", "tags": ["greeting"]},
                {"text": "እንዴት ነሽ?", "gloss": "How are you? (f)", "level": "A1", "tags": ["greeting"]},
                {"text": "አመሰግናለሁ", "gloss": "Thank you", "level": "A1", "tags": ["courtesy"]},
            ],
            "twi": [
                {"text": "Ɛte sɛn?", "gloss": "How are you?", "level": "A1", "tags": ["greeting"]},
                {"text": "Medaase", "gloss": "Thank you", "level": "A1", "tags": ["courtesy"]},
            ],
            "afrikaans": [
                {"text": "Hoe gaan dit?", "gloss": "How are you?", "level": "A1", "tags": ["greeting"]},
                {"text": "Dankie", "gloss": "Thank you", "level": "A1", "tags": ["courtesy"]},
            ],
            "pidgin": [
                {"text": "How you dey?", "gloss": "How are you?", "level": "A1", "tags": ["greeting"]},
                {"text": "Thank you", "gloss": "Thank you", "level": "A1", "tags": ["courtesy"]},
            ],
            "wolof": [
                {"text": "Nanga def?", "gloss": "How are you?", "level": "A1", "tags": ["greeting"]},
                {"text": "Jërejëf", "gloss": "Thank you", "level": "A1", "tags": ["courtesy"]},
            ],
            "somali": [
                {"text": "Sidee tahay?", "gloss": "How are you?", "level": "A1", "tags": ["greeting"]},
                {"text": "Mahadsanid", "gloss": "Thank you", "level": "A1", "tags": ["courtesy"]},
            ],
        }
        
        return base_data.get(language, [])
    
    def _generate_phrases_with_ai(self, language: str, count: int = 300) -> List[Dict]:
        """Generate phrases using Groq AI in batches"""
        if not self.groq_api_key:
            return []
        
        lang_info = SUPPORTED_LANGUAGES.get(language, {})
        lang_name = lang_info.get("name", language)
        
        system_prompt = f"""You are an expert linguist specializing in {lang_name}. 
Generate accurate, culturally appropriate phrases with correct diacritics and tone marks.
Always provide native script, English gloss, IPA transcription, and cultural context.
Be culturally sensitive and accurate."""
        
        # Generate in batches of 50 to avoid token limits
        all_phrases = []
        batch_size = 50
        num_batches = (count + batch_size - 1) // batch_size
        
        for batch_num in range(num_batches):
            batch_count = min(batch_size, count - len(all_phrases))
            if batch_count <= 0:
                break
            
            prompt = f"""Generate {batch_count} common, useful phrases in {lang_name} covering these categories:
{', '.join(PHRASE_CATEGORIES)}

For each phrase, provide:
1. Native script with correct diacritics/tone marks
2. English translation (gloss)
3. IPA transcription (if known)
4. CEFR level (A1, A2, B1, B2, C1, or C2)
5. Category tags (2-3 relevant tags)
6. Cultural context note (brief)

Format as JSON array:
[
  {{
    "text": "native script with diacritics",
    "gloss": "English translation",
    "ipa": "/ipa transcription/",
    "level": "A1",
    "tags": ["category1", "category2"],
    "cultural_notes": "brief cultural context"
  }}
]

Return ONLY valid JSON array, no markdown, no explanations."""
            
            response = self._call_groq_api(prompt, system_prompt)
            if response:
                try:
                    # Extract JSON from response
                    json_match = re.search(r'\[.*\]', response, re.DOTALL)
                    if json_match:
                        phrases = json.loads(json_match.group())
                        all_phrases.extend(phrases)
                        print(f"  ✓ Generated batch {batch_num + 1}/{num_batches} ({len(phrases)} phrases)")
                    else:
                        print(f"  ⚠️  No JSON found in batch {batch_num + 1}")
                except Exception as e:
                    print(f"  ❌ Error parsing batch {batch_num + 1}: {e}")
            
            # Rate limiting between batches
            if batch_num < num_batches - 1:
                time.sleep(self.rate_limit_delay)
        
        return all_phrases[:count]
    
    def _enrich_phrase(self, phrase: Dict, language: str) -> Dict:
        """Enrich phrase with Wiktionary and Tatoeba data"""
        text = phrase.get("text", "")
        
        # Get example sentences from Tatoeba (limited to avoid rate limits)
        if random.random() < 0.3:  # Only 30% of phrases
            examples = self._get_tatoeba_sentences(language, text, count=2)
            phrase["examples"] = examples[:2]
        else:
            phrase["examples"] = phrase.get("examples", [])
        
        return phrase
    
    def generate_phrase_cards(self, language: str, count: int = 500) -> List[Dict]:
        """Generate comprehensive phrase cards"""
        print(f"📝 Generating {count} phrase cards for {language}...")
        
        # Get comprehensive phrases
        common_phrases = self._get_common_phrases(language)
        
        cards = []
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
        
        print(f"✅ Generated {len(cards)} phrase cards for {language}")
        return cards
    
    def _generate_roleplay_with_ai(self, language: str, scenario_template: Dict) -> Optional[Dict]:
        """Generate roleplay scenario using AI"""
        if not self.groq_api_key:
            return None
        
        lang_info = SUPPORTED_LANGUAGES.get(language, {})
        lang_name = lang_info.get("name", language)
        country = lang_info.get("country", "African")
        
        system_prompt = f"""You are a cultural expert and language teacher for {lang_name}.
Create authentic, culturally appropriate roleplay scenarios that reflect real-life situations
in {country} communities. Use correct diacritics and tone marks."""
        
        prompt = f"""Create a detailed roleplay scenario in {lang_name}:

Scenario: {scenario_template['scenario']}
User Prompt: {scenario_template['user_prompt']}

Generate:
1. A natural user utterance in {lang_name} (with correct diacritics/tone marks)
2. An appropriate assistant response in {lang_name} (with correct diacritics/tone marks)
3. Detailed cultural notes explaining context, appropriateness, and cultural nuances
4. Difficulty level (A1, A2, B1, B2, C1, or C2)
5. Relevant tags (2-4 tags)

Format as JSON:
{{
  "user_utterance": "user's phrase in {lang_name}",
  "assistant_response": "assistant's response in {lang_name}",
  "cultural_notes": "detailed cultural context and nuances",
  "difficulty": "A1",
  "tags": ["tag1", "tag2"]
}}

Return ONLY valid JSON, no markdown."""
        
        response = self._call_groq_api(prompt, system_prompt)
        if not response:
            return None
        
        try:
            json_match = re.search(r'\{.*\}', response, re.DOTALL)
            if json_match:
                return json.loads(json_match.group())
        except Exception as e:
            print(f"Error parsing AI roleplay response: {e}")
        
        return None
    
    def generate_roleplay_scenarios(self, language: str, count: int = 200) -> List[Dict]:
        """Generate comprehensive roleplay scenarios"""
        print(f"🎭 Generating {count} roleplay scenarios for {language}...")
        
        # Comprehensive scenario templates
        scenario_templates = [
            {"scenario": "Market bargaining", "user_prompt": "You want to buy fruits at a local market. Negotiate the price.", "tags": ["shopping", "market"]},
            {"scenario": "Greeting an elder", "user_prompt": "You meet an elder in your community. Greet them respectfully.", "tags": ["greeting", "respect"]},
            {"scenario": "Ordering food", "user_prompt": "You're at a restaurant. Order your favorite local dish.", "tags": ["food", "restaurant"]},
            {"scenario": "Asking for directions", "user_prompt": "You're lost. Ask someone for directions to the nearest landmark.", "tags": ["directions", "travel"]},
            {"scenario": "Family gathering", "user_prompt": "You're at a family gathering. Introduce yourself to relatives.", "tags": ["family", "introduction"]},
            {"scenario": "Taxi negotiation", "user_prompt": "You need a taxi. Negotiate the fare before getting in.", "tags": ["transport", "negotiation"]},
            {"scenario": "Hospital visit", "user_prompt": "You're at a hospital. Describe your symptoms to the doctor.", "tags": ["health", "medical"]},
            {"scenario": "Job interview", "user_prompt": "You're in a job interview. Answer questions about your experience.", "tags": ["business", "career"]},
            {"scenario": "School enrollment", "user_prompt": "You're enrolling your child in school. Ask about the curriculum.", "tags": ["education", "school"]},
            {"scenario": "Wedding ceremony", "user_prompt": "You're attending a wedding. Congratulate the couple appropriately.", "tags": ["culture", "celebration"]},
            {"scenario": "Bank transaction", "user_prompt": "You're at a bank. Open a new account.", "tags": ["business", "finance"]},
            {"scenario": "Phone call to family", "user_prompt": "You're calling a family member. Have a conversation.", "tags": ["family", "communication"]},
            {"scenario": "Shopping for clothes", "user_prompt": "You're buying traditional clothes. Ask about sizes and prices.", "tags": ["shopping", "clothing"]},
            {"scenario": "Asking for help", "user_prompt": "You need help with something. Politely ask a stranger.", "tags": ["courtesy", "help"]},
            {"scenario": "Cultural festival", "user_prompt": "You're at a cultural festival. Ask about the traditions.", "tags": ["culture", "festival"]},
            {"scenario": "Bus stop conversation", "user_prompt": "You're at a bus stop. Ask when the next bus arrives.", "tags": ["transport", "time"]},
            {"scenario": "Traditional ceremony", "user_prompt": "You're attending a traditional ceremony. Participate appropriately.", "tags": ["culture", "ceremony"]},
            {"scenario": "Buying phone credit", "user_prompt": "You need to buy phone credit. Ask the vendor.", "tags": ["shopping", "technology"]},
            {"scenario": "Meeting new neighbor", "user_prompt": "You just moved in. Introduce yourself to your neighbor.", "tags": ["greeting", "introduction"]},
            {"scenario": "Complaining about service", "user_prompt": "Service was poor. Complain politely but firmly.", "tags": ["business", "courtesy"]},
        ]
        
        scenarios = []
        templates_to_use = (scenario_templates * (count // len(scenario_templates) + 1))[:count]
        
        for i, template in enumerate(templates_to_use):
            # Generate with AI
            ai_data = self._generate_roleplay_with_ai(language, template) if self.groq_api_key else None
            
            if ai_data:
                scenario = RoleplayScenario(
                    id=f"{language}_roleplay_{i+1:04d}",
                    language=language,
                    scenario=template["scenario"],
                    user_prompt=template["user_prompt"],
                    assistant_response=ai_data.get("assistant_response", f"[AI-generated for {language}]"),
                    cultural_notes=ai_data.get("cultural_notes", template.get("cultural_notes", "")),
                    difficulty=ai_data.get("difficulty", random.choice(["A1", "A2", "B1"])),
                    tags=ai_data.get("tags", template.get("tags", []))
                )
            else:
                # Fallback to template
                scenario = RoleplayScenario(
                    id=f"{language}_roleplay_{i+1:04d}",
                    language=language,
                    scenario=template["scenario"],
                    user_prompt=template["user_prompt"],
                    assistant_response=f"[AI-generated response for {language}]",
                    cultural_notes=template.get("cultural_notes", "Cultural context will be added."),
                    difficulty=random.choice(["A1", "A2", "B1"]),
                    tags=template.get("tags", [])
                )
            
            scenarios.append(asdict(scenario))
            
            # Rate limiting for AI calls
            if self.groq_api_key and i < len(templates_to_use) - 1:
                time.sleep(self.rate_limit_delay)
            
            if (i + 1) % 10 == 0:
                print(f"  ✓ Generated {i + 1}/{count} scenarios")
        
        print(f"✅ Generated {len(scenarios)} roleplay scenarios for {language}")
        return scenarios
    
    def save_to_file(self, data: List[Dict], filename: str):
        """Save generated content to JSON file"""
        filepath = self.output_dir / filename
        with open(filepath, 'w', encoding='utf-8') as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        print(f"💾 Saved {len(data)} items to {filepath}")
    
    def generate_all_content(self):
        """Generate all content for all languages"""
        print("🚀 Starting enhanced content generation pipeline...")
        print(f"📁 Output directory: {self.output_dir}")
        
        if not self.groq_api_key:
            print("⚠️  Warning: GROQ_API_KEY not set. AI generation will be limited.")
        else:
            print(f"🤖 AI generation enabled (Groq API)")
        
        total_phrase_cards = 0
        total_roleplay_scenarios = 0
        
        for language in SUPPORTED_LANGUAGES.keys():
            print(f"\n{'='*60}")
            print(f"🌍 Generating content for {SUPPORTED_LANGUAGES[language]['name']}...")
            print(f"{'='*60}")
            
            # Generate phrase cards
            phrase_cards = self.generate_phrase_cards(language, count=500)
            self.save_to_file(phrase_cards, f"{language}_phrase_cards.json")
            total_phrase_cards += len(phrase_cards)
            
            # Generate roleplay scenarios
            roleplay_scenarios = self.generate_roleplay_scenarios(language, count=200)
            self.save_to_file(roleplay_scenarios, f"{language}_roleplay_scenarios.json")
            total_roleplay_scenarios += len(roleplay_scenarios)
            
            time.sleep(2)  # Rate limiting between languages
        
        print(f"\n{'='*60}")
        print("✅ Content generation complete!")
        print(f"📊 Total phrase cards: {total_phrase_cards}")
        print(f"📊 Total roleplay scenarios: {total_roleplay_scenarios}")
        print(f"📁 Files generated: {len(list(self.output_dir.glob('*.json')))}")
        print(f"{'='*60}")

if __name__ == "__main__":
    import argparse
    
    parser = argparse.ArgumentParser(description="Generate content for LingAfriq")
    parser.add_argument("--language", help="Specific language to generate (optional)")
    parser.add_argument("--count", type=int, default=500, help="Number of phrases to generate")
    parser.add_argument("--output", default="generated_content", help="Output directory")
    parser.add_argument("--groq-key", help="Groq API key (or set GROQ_API_KEY env var)")
    
    args = parser.parse_args()
    
    generator = EnhancedContentGenerator(
        output_dir=args.output,
        groq_api_key=args.groq_key
    )
    
    if args.language:
        if args.language in SUPPORTED_LANGUAGES:
            phrase_cards = generator.generate_phrase_cards(args.language, count=args.count)
            generator.save_to_file(phrase_cards, f"{args.language}_phrase_cards.json")
            
            roleplay_scenarios = generator.generate_roleplay_scenarios(args.language, count=200)
            generator.save_to_file(roleplay_scenarios, f"{args.language}_roleplay_scenarios.json")
        else:
            print(f"❌ Language '{args.language}' not supported")
            print(f"Supported: {', '.join(SUPPORTED_LANGUAGES.keys())}")
    else:
        generator.generate_all_content()
