# Games Content Operating Guide

## Content pipeline

1. **Source** — `tools/content_data/packs.py`  
2. **Generate** — `python tools/generate_lingafriq_content.py`  
3. **Bundle** — `assets/data/game_content.json` + `word_repo_game_seed.json`  
4. **Runtime** — `game_content_provider.dart` + `game_provider.dart` API fallbacks  

## Data shapes

### Phrase cards (most games)

Used by `GameProvider` → `PhraseCard`: `text`, `gloss`, `audio_native_url`, `level`.

Sources (priority): API `game-content` → API `cards` → word_repo → inline fallback.

### Structured game content

`game_content.json`:

- **words** — `GameWord` (Emoji Translator, tagging)  
- **proverbs** — `GameProverb` (Proverb Unlocker via `cultural_games.dart`)  
- **scenarios** — `GameScenario` (Market, Taxi, Greeting, Roleplay, Elders, Cultural Etiquette, FoodQuest, VillageQuest, Folktale)  

### Scenario `game` IDs (must match filters in screens)

| Game screen | `game` field in JSON |
|-------------|-------------------|
| Market Bargaining | `MarketBargaining` |
| Greeting Diplomacy | `GreetingDiplomacy` |
| Taxi Survival | `TaxiSurvival` |
| Roleplay Adventure | `RoleplayAdventure` |
| Elders Blessings | `EldersBlessings` |
| Cultural Etiquette | `CulturalEtiquette` |
| Food Quest | `FoodQuest` |
| Village Quest | `VillageQuest` |
| Folktale Reconstruction | `FolktaleReconstruction` |

Language key in JSON: lowercase (`yoruba`, `pidgin`, …) — matches games hub.

### Game tags on words

`WordMatch`, `SpeedRound`, `PronunciationDuel`, `ToneTrainer`, `GreetingDiplomacy`, `MarketBargaining`, `FoodQuest`, `ProverbUnlocker`, etc.

## All 37 game types — content strategy

| Category | Games | Primary content source |
|----------|-------|------------------------|
| Vocabulary | Word Match, Speed Round, Memory Map, Flashcard Safari, … | Phrase cards / word_repo |
| Pronunciation | Pronunciation Duel, Tone Trainer, Karaoke, Tongue Twister | Cards + MFA API + tone notes |
| Cultural | Proverb Unlocker, Greeting Diplomacy, Elders Blessings, Etiquette | game_content proverbs/scenarios |
| Simulation | Market, Taxi, Food Quest, Village Quest | game_content scenarios |
| AI-driven | Story Builder, Grammar Jam, Conversation Relay, Liar Liar | Polie + `polie_prompt_snippets.json` |
| Rhythm | Drum Rhythm, Rhythm Typing | Audio assets + cards |

## Adding content for a new game

1. Add scenarios or words in `packs.py` with correct `game` id.  
2. Regenerate JSON.  
3. If the game screen uses `gameScenariosProvider`, verify `GameContentFilter.game` string.  
4. Playtest one language + one difficulty.  

## Current scale (generated)

- **264** vocabulary words across 8 languages  
- **48** proverbs  
- **144** scenarios  
- **40** A1 lessons per language (5 units × 3 lessons) in authentic curriculum  

## Quality rules

- Pidgin is a **legitimate language** — not “broken English” in glosses.  
- Click/tone languages: encourage repetition, not “you are wrong.”  
- Market scenarios: greet before price.  
