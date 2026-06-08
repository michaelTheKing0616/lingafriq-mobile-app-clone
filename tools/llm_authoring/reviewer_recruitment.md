# Native reviewer recruitment program

LingAfriq ships curriculum (A1–C2) and game content for **14 languages**. Every promoted bundle requires at least one native speaker sign-off per language before store release.

## Target

| Milestone | Goal |
|-----------|------|
| Week 2 | Reviewer job descriptions posted for all 14 languages |
| Week 4 | ≥1 contracted reviewer per launch language (8) |
| Week 6 | ≥1 contracted reviewer per extended language (6) |
| Ongoing | 48h SLA on `pending_review` drafts |

## Role

- Edit LLM drafts in the **Native Reviewer App** (`tools/llm_authoring/native_reviewer_app`)
- Verify orthography, tone, cultural register, and proverb authenticity
- Approve or request changes; approved JSON is promoted via `publish_bundle.py`

## Compensation model (recommended)

- Per-lesson review fee (CEFR-weighted: A1 < C2)
- Monthly retainer for queue SLA in high-traffic languages (Yoruba, Hausa, Igbo, Swahili)
- Bonus for sub-24h turnaround on release-blocking batches

## Sourcing channels

1. University language departments (Nigeria, Kenya, South Africa, Ethiopia, Senegal)
2. Diaspora educator networks and African language teacher associations
3. Existing LingAfriq community ambassadors and UGC contributors
4. Professional linguists on Upwork/Contra with verified portfolio

## Onboarding checklist

1. NDA + content guidelines (no LLM apology phrases, no English leaks in target fields)
2. Account on reviewer app with `REVIEWER_API_TOKEN`
3. Calibration set: 5 pre-scored lessons per language (pass/fail rubric)
4. Access to staging MMS TTS for audio preview

## Contact log

Maintain recruiter notes in `LingAfriq Content Writing/reviewer_contacts.json` (not committed if it contains PII — use a private ops vault in production).
