# LingAfriq UX Brand Voice

## Voice qualities

Human · Warm · Culturally rooted · Encouraging · Clear · Emotionally safe

## Principles

1. **Encourage action** — “Try saying it aloud.” / “Let’s hear your pronunciation.”
2. **Protect confidence** — Never “Wrong.” / “Failed.”
3. **Celebrate progress** — Tie feedback to fluency and identity.
4. **Reinforce culture** — “You just used a traditional greeting correctly.”

## Implemented in app

`lib/content/lingafriq_ux_voice.dart` powers:

- Quiz feedback snackbars (`quiz_section_widget.dart`)
- Lesson completion messages (`lesson_complete_widget.dart`)
- Share text (`lesson_flow_screen.dart`)

## Copy library (samples)

| Context | Avoid | Prefer |
|---------|-------|--------|
| Quiz miss | Incorrect | Native speakers would phrase it slightly differently. |
| Quiz hit | Correct! | That sounded natural. |
| Streak break | You failed your streak | Your learning momentum is still alive. |
| Loading | Loading… | Preparing your pronunciation coach… |
| Error | Error 500 | We couldn’t connect. Your progress is safe. |

## Polie alignment

Polie verdicts: `correct` | `close` | `incorrect` — UI copy for `close` should mirror “refine phrasing” tone, not shame.
