# Content Generation Pipeline

Automated content generation for LingAfriq using freely available resources and AI.

## Overview

This pipeline generates comprehensive content for all 12 supported languages:
- Phrase cards for games and learning
- Roleplay scenarios for AI chat
- Grammar exercises
- Cultural content
- And more...

## Setup

1. Install dependencies:
```bash
pip install requests python-dotenv
```

2. Set environment variables:
```bash
export GROQ_API_KEY="your_groq_api_key"
export BACKEND_API_URL="https://api.lingafriq.com"
export BACKEND_API_KEY="your_backend_api_key"
```

## Usage

### Generate Content

```bash
# Generate all content for all languages
python content_generator.py

# Generate specific language
python content_generator.py --language yoruba --count 1000
```

### Upload to Backend

```bash
python backend_integration.py
```

## Content Types

### Phrase Cards
- Used in games (WordMatch, Pronunciation Duel, etc.)
- Includes: text, gloss, IPA, level, tags, examples
- SRS-ready data structure

### Roleplay Scenarios
- Used in AI chat roleplay mode
- Includes: scenario, prompts, cultural notes
- Difficulty levels (A1-C2)

## Data Sources

1. **Wiktionary API** - Word definitions and pronunciations
2. **Tatoeba** - Example sentences
3. **Wikipedia** - Cultural context
4. **AI Generation** - Groq API for accurate translations
5. **Public Datasets** - Open-source language resources

## Output

Generated content is saved to `generated_content/` directory:
- `{language}_phrase_cards.json`
- `{language}_roleplay_scenarios.json`
- `{language}_grammar_exercises.json`

## Integration

Content is automatically uploaded to backend via REST API:
- `POST /api/content/phrase-cards`
- `POST /api/content/roleplay-scenarios`

## Quality Assurance

- Native speaker review (manual)
- AI accuracy checks
- Cultural appropriateness validation
- Diacritics enforcement

