# 🛠️ Automation Implementation Plan

## **QUICK START: AUTOMATED CONTENT GENERATION**

This plan provides a practical roadmap to automate 70-85% of content acquisition.

---

## **PHASE 1: SETUP (Weeks 1-4)**

### **1.1 Infrastructure Setup**
```bash
# Create automation workspace
mkdir content-automation
cd content-automation

# Set up Python environment
python -m venv venv
source venv/bin/activate  # or `venv\Scripts\activate` on Windows

# Install dependencies
pip install openai anthropic groq requests beautifulsoup4
pip install wiktionaryparser tatoeba-api
pip install pymongo sqlalchemy
pip install python-dotenv
```

### **1.2 API Keys Setup**
```bash
# .env file
GROQ_API_KEY=your_groq_key
OPENAI_API_KEY=your_openai_key  # Optional, for higher quality
ANTHROPIC_API_KEY=your_anthropic_key  # Optional
WIKTIONARY_API_KEY=not_needed  # Public API
TATOEBA_API_KEY=not_needed  # Public API
```

### **1.3 Database Setup**
- MongoDB for content storage
- PostgreSQL for structured data
- Redis for caching

---

## **PHASE 2: CONTENT GENERATORS (Weeks 5-12)**

### **2.1 AI Chat Content Generator**

```python
# content_generators/ai_chat_generator.py
import os
from groq import Groq
from typing import List, Dict

class AIChatContentGenerator:
    def __init__(self):
        self.client = Groq(api_key=os.getenv("GROQ_API_KEY"))
        self.model = "llama-3.1-70b-versatile"
    
    def generate_translation_phrases(self, language: str, count: int = 1000) -> List[Dict]:
        """Generate common phrases for translation mode"""
        prompt = f"""
        Generate {count} common phrases in {language} with English translations.
        Include:
        - Greetings
        - Questions
        - Common expressions
        - Numbers
        - Time expressions
        - Directions
        - Shopping
        - Food
        
        Format: JSON array with 'phrase', 'translation', 'category', 'level'
        """
        
        response = self.client.chat.completions.create(
            model=self.model,
            messages=[{"role": "user", "content": prompt}],
            response_format={"type": "json_object"}
        )
        
        return self._parse_response(response)
    
    def generate_tutor_prompts(self, language: str, level: str, count: int = 100) -> List[Dict]:
        """Generate tutor prompts for specific CEFR level"""
        prompt = f"""
        Generate {count} teaching prompts for {language} at {level} level.
        Each prompt should:
        - Teach a specific grammar point
        - Include examples
        - Be culturally appropriate
        - Follow CEFR guidelines
        
        Format: JSON array with 'prompt', 'grammar_point', 'examples', 'level'
        """
        
        # Similar implementation...
    
    def generate_roleplay_scenarios(self, language: str, count: int = 200) -> List[Dict]:
        """Generate roleplay scenarios"""
        # Implementation...
```

### **2.2 Public Resource Extractor**

```python
# content_generators/public_resources.py
import requests
from wiktionaryparser import WiktionaryParser
from typing import List, Dict

class PublicResourceExtractor:
    def __init__(self):
        self.wiktionary = WiktionaryParser()
        self.tatoeba_base = "https://tatoeba.org/en/api_v0"
    
    def extract_from_wiktionary(self, language: str, word: str) -> Dict:
        """Extract word information from Wiktionary"""
        try:
            word_data = self.wiktionary.fetch(word, language)
            return {
                'word': word,
                'definitions': word_data.get('definitions', []),
                'pronunciations': word_data.get('pronunciations', []),
                'etymology': word_data.get('etymology', ''),
            }
        except Exception as e:
            print(f"Error extracting from Wiktionary: {e}")
            return {}
    
    def extract_from_tatoeba(self, language: str, count: int = 1000) -> List[Dict]:
        """Extract sentence pairs from Tatoeba"""
        url = f"{self.tatoeba_base}/search"
        params = {
            'query': '',
            'from': language,
            'to': 'eng',
            'trans_filter': 'limit',
            'trans_to': 'eng',
            'page': 1,
            'per_page': count
        }
        
        response = requests.get(url, params=params)
        if response.status_code == 200:
            return self._parse_tatoeba_response(response.json())
        return []
    
    def extract_from_wikipedia(self, language: str, topic: str) -> Dict:
        """Extract cultural content from Wikipedia"""
        # Implementation using Wikipedia API
        pass
```

### **2.3 Game Content Generator**

```python
# content_generators/game_content_generator.py
class GameContentGenerator:
    def generate_wordmatch_phrases(self, language: str, count: int = 500) -> List[Dict]:
        """Generate phrases for WordMatch+Audio game"""
        # Use AI + public resources
        pass
    
    def generate_grammar_passages(self, language: str, count: int = 300) -> List[Dict]:
        """Generate grammar passages with intentional errors"""
        # Use AI to generate passages, then inject errors
        pass
    
    def generate_story_prompts(self, language: str, count: int = 100) -> List[Dict]:
        """Generate story builder prompts"""
        # Use AI + folktales from Project Gutenberg
        pass
```

---

## **PHASE 3: QUALITY ASSURANCE (Weeks 13-20)**

### **3.1 Automated Validators**

```python
# validators/content_validator.py
from utils.diacritics_enforcer import DiacriticsEnforcer
from utils.supported_languages import SupportedLanguages

class ContentValidator:
    def __init__(self):
        self.diacritics_enforcer = DiacriticsEnforcer()
    
    def validate_phrase(self, phrase: Dict, language: str) -> Dict:
        """Validate a phrase with multiple checks"""
        errors = []
        warnings = []
        
        # Check diacritics
        if SupportedLanguages.requiresDiacritics(language):
            corrected, changed = self.diacritics_enforcer.enforceWithMetadata(
                phrase['text'], language
            )
            if changed:
                warnings.append(f"Diacritics corrected: {phrase['text']} → {corrected}")
                phrase['text'] = corrected
        
        # Check format
        if not phrase.get('text') or not phrase.get('translation'):
            errors.append("Missing required fields")
        
        # Check length
        if len(phrase['text']) > 200:
            warnings.append("Phrase is very long")
        
        # Check language
        if not SupportedLanguages.isSupported(language):
            errors.append(f"Unsupported language: {language}")
        
        return {
            'valid': len(errors) == 0,
            'errors': errors,
            'warnings': warnings,
            'phrase': phrase
        }
    
    def validate_batch(self, phrases: List[Dict], language: str) -> Dict:
        """Validate a batch of phrases"""
        results = {
            'valid': [],
            'invalid': [],
            'warnings': []
        }
        
        for phrase in phrases:
            validation = self.validate_phrase(phrase, language)
            if validation['valid']:
                results['valid'].append(validation['phrase'])
            else:
                results['invalid'].append(validation)
            results['warnings'].extend(validation['warnings'])
        
        return results
```

### **3.2 Human Review System**

```python
# review/human_review.py
import random
from typing import List, Dict

class HumanReviewSystem:
    def __init__(self, review_percentage: float = 0.15):
        self.review_percentage = review_percentage
    
    def select_sample(self, content: List[Dict]) -> List[Dict]:
        """Select a random sample for human review"""
        sample_size = int(len(content) * self.review_percentage)
        return random.sample(content, sample_size)
    
    def mark_for_review(self, content: Dict, reason: str):
        """Mark content for human review"""
        content['review_status'] = 'pending'
        content['review_reason'] = reason
        content['reviewed_by'] = None
        content['reviewed_at'] = None
    
    def approve_content(self, content: Dict, reviewer: str):
        """Approve content after review"""
        content['review_status'] = 'approved'
        content['reviewed_by'] = reviewer
        content['reviewed_at'] = datetime.now()
        
        # Auto-approve similar content
        self._auto_approve_similar(content)
```

---

## **PHASE 4: AUDIO GENERATION (Weeks 21-32)**

### **4.1 TTS Generator**

```python
# audio/tts_generator.py
from google.cloud import texttospeech
import os

class TTSGenerator:
    def __init__(self):
        self.client = texttospeech.TextToSpeechClient()
    
    def generate_audio(self, text: str, language: str, voice_name: str = None) -> bytes:
        """Generate audio using Google Cloud TTS"""
        # Map language codes
        language_code = self._map_language_code(language)
        
        # Select voice
        if not voice_name:
            voice_name = self._get_default_voice(language_code)
        
        synthesis_input = texttospeech.SynthesisInput(text=text)
        voice = texttospeech.VoiceSelectionParams(
            language_code=language_code,
            name=voice_name,
            ssml_gender=texttospeech.SsmlVoiceGender.NEUTRAL
        )
        audio_config = texttospeech.AudioConfig(
            audio_encoding=texttospeech.AudioEncoding.MP3
        )
        
        response = self.client.synthesize_speech(
            input=synthesis_input,
            voice=voice,
            audio_config=audio_config
        )
        
        return response.audio_content
    
    def batch_generate(self, phrases: List[Dict], language: str) -> List[Dict]:
        """Generate audio for multiple phrases"""
        results = []
        for phrase in phrases:
            try:
                audio = self.generate_audio(phrase['text'], language)
                phrase['audio_url'] = self._save_audio(phrase['id'], audio)
                results.append(phrase)
            except Exception as e:
                print(f"Error generating audio for {phrase['id']}: {e}")
                phrase['audio_status'] = 'failed'
        
        return results
```

### **4.2 Native Speaker Review Queue**

```python
# audio/native_review.py
class NativeSpeakerReview:
    def flag_for_review(self, phrase: Dict, reason: str):
        """Flag phrase for native speaker review"""
        phrase['native_review_status'] = 'pending'
        phrase['native_review_reason'] = reason
        phrase['native_review_priority'] = self._calculate_priority(phrase)
    
    def _calculate_priority(self, phrase: Dict) -> int:
        """Calculate review priority (1-5, 5 = highest)"""
        priority = 1
        
        # High priority for common phrases
        if phrase.get('category') in ['greeting', 'question', 'common']:
            priority += 2
        
        # High priority for tonal languages
        if SupportedLanguages.isTonal(phrase['language']):
            priority += 1
        
        # High priority for critical content
        if phrase.get('is_critical'):
            priority += 2
        
        return min(priority, 5)
```

---

## **PHASE 5: DEPLOYMENT & MONITORING (Weeks 33-40)**

### **5.1 Automation Pipeline**

```python
# pipeline/main_pipeline.py
from content_generators.ai_chat_generator import AIChatContentGenerator
from content_generators.public_resources import PublicResourceExtractor
from validators.content_validator import ContentValidator
from review.human_review import HumanReviewSystem
from audio.tts_generator import TTSGenerator

class ContentGenerationPipeline:
    def __init__(self):
        self.ai_generator = AIChatContentGenerator()
        self.resource_extractor = PublicResourceExtractor()
        self.validator = ContentValidator()
        self.review_system = HumanReviewSystem(review_percentage=0.15)
        self.tts_generator = TTSGenerator()
    
    def generate_language_content(self, language: str):
        """Generate all content for a language"""
        print(f"Generating content for {language}...")
        
        # 1. Generate AI Chat content
        print("Generating AI Chat content...")
        ai_chat_content = self._generate_ai_chat_content(language)
        
        # 2. Extract from public resources
        print("Extracting from public resources...")
        public_content = self._extract_public_content(language)
        
        # 3. Merge and deduplicate
        print("Merging content...")
        merged_content = self._merge_content(ai_chat_content, public_content)
        
        # 4. Validate
        print("Validating content...")
        validated_content = self.validator.validate_batch(merged_content, language)
        
        # 5. Human review (sampling)
        print("Selecting sample for review...")
        review_sample = self.review_system.select_sample(validated_content['valid'])
        
        # 6. Generate audio
        print("Generating audio...")
        audio_content = self.tts_generator.batch_generate(validated_content['valid'], language)
        
        # 7. Store in database
        print("Storing in database...")
        self._store_content(audio_content, language)
        
        print(f"Content generation complete for {language}!")
        return {
            'total': len(merged_content),
            'valid': len(validated_content['valid']),
            'invalid': len(validated_content['invalid']),
            'review_sample': len(review_sample),
            'audio_generated': len(audio_content)
        }
    
    def _generate_ai_chat_content(self, language: str) -> List[Dict]:
        """Generate AI Chat content"""
        content = []
        
        # Translation phrases
        content.extend(self.ai_generator.generate_translation_phrases(language, 1000))
        
        # Tutor prompts
        for level in ['A1', 'A2', 'B1', 'B2', 'C1', 'C2']:
            content.extend(self.ai_generator.generate_tutor_prompts(language, level, 100))
        
        # Roleplay scenarios
        content.extend(self.ai_generator.generate_roleplay_scenarios(language, 200))
        
        return content
    
    def _extract_public_content(self, language: str) -> List[Dict]:
        """Extract content from public resources"""
        content = []
        
        # Extract from Tatoeba
        tatoeba_content = self.resource_extractor.extract_from_tatoeba(language, 1000)
        content.extend(tatoeba_content)
        
        # Extract from Wiktionary (common words)
        common_words = self._get_common_words(language)
        for word in common_words[:500]:
            word_data = self.resource_extractor.extract_from_wiktionary(language, word)
            if word_data:
                content.append(word_data)
        
        return content
    
    def _merge_content(self, ai_content: List[Dict], public_content: List[Dict]) -> List[Dict]:
        """Merge and deduplicate content"""
        # Implementation...
        pass
    
    def _store_content(self, content: List[Dict], language: str):
        """Store content in database"""
        # Implementation...
        pass
```

### **5.2 Monitoring & Reporting**

```python
# monitoring/monitor.py
class ContentGenerationMonitor:
    def generate_report(self, language: str, results: Dict):
        """Generate generation report"""
        report = f"""
        Content Generation Report for {language}
        ==========================================
        Total Generated: {results['total']}
        Valid: {results['valid']}
        Invalid: {results['invalid']}
        Review Sample: {results['review_sample']}
        Audio Generated: {results['audio_generated']}
        
        Success Rate: {(results['valid'] / results['total'] * 100):.2f}%
        """
        print(report)
        return report
```

---

## **QUICK START SCRIPT**

```python
# run_generation.py
from pipeline.main_pipeline import ContentGenerationPipeline
from utils.supported_languages import SupportedLanguages

def main():
    pipeline = ContentGenerationPipeline()
    
    # Generate content for all languages
    for language in SupportedLanguages.codes:
        print(f"\n{'='*50}")
        print(f"Processing {language}...")
        print(f"{'='*50}\n")
        
        results = pipeline.generate_language_content(language)
        
        # Generate report
        monitor = ContentGenerationMonitor()
        monitor.generate_report(language, results)
        
        print(f"\n{language} complete!\n")

if __name__ == "__main__":
    main()
```

---

## **ESTIMATED TIMELINE & COSTS**

### **Timeline:**
- **Weeks 1-4**: Setup (infrastructure, APIs, databases)
- **Weeks 5-12**: Content generation (AI + public resources)
- **Weeks 13-20**: Quality assurance (automated + human review)
- **Weeks 21-32**: Audio generation (TTS + native review)
- **Weeks 33-40**: Deployment, monitoring, refinement

**Total: 40 weeks (~10 months)**

### **Costs:**
- **LLM API**: $2,000-5,000 (Groq is very affordable)
- **TTS API**: $10,000-20,000 (Google Cloud TTS free tier + paid)
- **Infrastructure**: $5,000 (servers, databases)
- **Human Review**: $100,000-150,000 (15-30% sampling)
- **Native Audio Review**: $50,000-100,000 (critical content)
- **Image Licensing**: $48,000-96,000

**Total: $215,000-376,000** (vs. $1,321,200 original)

**Savings: 71-84%** 🎉

---

## **NEXT STEPS**

1. ✅ Set up automation infrastructure
2. ✅ Create content generation scripts
3. ✅ Integrate public resource APIs
4. ✅ Set up quality assurance system
5. ✅ Begin content generation
6. ✅ Human review process
7. ✅ Audio generation
8. ✅ Deploy and monitor

**This automation strategy makes comprehensive content acquisition highly feasible!** 🚀

