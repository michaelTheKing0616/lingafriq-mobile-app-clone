# LingAfriq Master Lesson Template

Every lesson follows the same **10-stage pedagogical engine**, mapped to current app section types.

## Stages → App delivery

| # | Stage | Purpose | App section |
|---|--------|---------|-------------|
| 1 | Warm opening | Reduce anxiety, streak, teaser | Tutorial intro text |
| 2 | Context scene | Real situation (market, elder, voice note) | Tutorial + image/video |
| 3 | Vocabulary | Core phrases + audio | Tutorial + `audio_url` |
| 4 | Pronunciation lab | Tone/clicks, repeat-after-me | Tutorial CTA → Tone Rhythm Trainer |
| 5 | Grammar pattern | Pattern recognition, not lecture | Tutorial examples |
| 6 | Guided practice | Recognition → production | Instant Quiz + Word Quiz |
| 7 | AI conversation | Live practice | Polie Roleplay deep link (`polie_roleplay` in curriculum JSON) |
| 8 | Cultural intelligence | Respect, proverb, etiquette | `cultural_notes` + Magazine link |
| 9 | Retention challenge | Recall under light pressure | Long Quiz |
| 10 | Victory | XP, identity reinforcement | `LessonCompleteWidget` + `LingAfriqUxVoice` |

## Lesson JSON fields (authentic curriculum)

```json
{
  "id": "Yoruba-A1-u1-l1",
  "title": "Morning greetings",
  "objective": "Greet by time of day.",
  "cultural_notes": "Greeting culture is the spine of social life.",
  "tags": {
    "difficulty": "A1",
    "vocab_theme": "greetings",
    "cultural_topic": "elder_respect",
    "pronunciation_difficulty": "tone_aware",
    "ai_readiness": "beginner_slow"
  },
  "vocab": [{ "word": "Ẹ kú àárọ̀", "meaning": "Good morning", "example": "..." }],
  "dialogue": { "script": [...], "scene": "..." },
  "polie_roleplay": { "persona": "Encouraging Mentor", "prompt": "...", "correction_level": "gentle" },
  "exercises": [{ "type": "flashcards" }, { "type": "listening" }, { "type": "speaking" }]
}
```

## Lesson archetypes

- **Core fluency** — survival communication
- **Pronunciation lab** — tone / clicks
- **AI conversation mission** — roleplay scenario
- **Cultural intelligence** — etiquette + proverb
- **Historical persona mission** — narrative arc (see `persona_missions.json`)
- **Media-based** — Import Media → generated lesson
- **Live classroom** — tutor plan + pre-class Polie review

## Authoring checklist

- [ ] Answers “When would I actually use this?”
- [ ] Includes slow + native audio plan
- [ ] Respect/register noted where relevant
- [ ] Polie prompt uses gentle correction for A1
- [ ] No placeholder vocabulary
- [ ] Native reviewer sign-off
