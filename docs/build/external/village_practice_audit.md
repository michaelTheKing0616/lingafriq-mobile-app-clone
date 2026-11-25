---
card_id: P9-959
gate: G9
version: "1.0.0"
date: "2026-10-28"
req_ids:
  - EP-§9.2-01
  - EP-§9.2-02
canonical_surfaces: 12
defect_count: 4
audit_complete: true
evidence_links:
  elevation: docs/source/ELEVATION.md#§9.2:L1571-L1627
  rtm: docs/build/rtm_slices/P9_village_eng.csv
checker: scripts/safety/village_practice_audit_check.py
---

# Village practice audit (EP-§9.2-01 / EP-§9.2-02)

Principle (ELEVATION §9.2): every social surface must create **language practice with real people** or **belonging**, and must reflect at least one of **speed**, **voice**, **ephemerality**, or **creativity** (WhatsApp / TikTok / Snapchat patterns, pointed at learning).

Legend: **S** speed · **V** voice · **E** ephemerality · **C** creativity · **P** practice outcome · **B** belonging outcome

## Implemented surfaces (P9 / F Done)

| Surface | Cards | Ship | P / B outcome | S | V | E | C | Notes |
|---|---|---|---|:--:|:--:|:--:|:--:|---|
| Circles | P9-943, F-111 | Done / Draft UI | B: language village & study circles; P: circle-scoped chat/clips | Y | Y | N | Y | Guardian/teacher join rules server-side |
| Private & group chat | P9-944–946, F-114 | Done | P: Tone Lens, gloss/save, tutor check, opt-in voice-note transcript | Y | Y | N | Y | E2EE overlays on-device (P9-940) |
| Practice Rooms | P9-947, F-108 | Done / Draft UI | P: turn-based speaking, topic+CEFR, labelled AI facilitator | Y | Y | N | Y | Not open mic (§9.2-20) |
| Clips capture & post | P9-948 | Done | P: 15–60s target-language clips, moderation before publish | Y | Y | N | Y | Minor circle scope |
| Clip templates | P9-949 | Done | P: verified phrase/proverb/twister presets into camera | Y | Y | N | Y | Lexicon/WOTD anchored |
| Clip duets / stitch | P9-950 | Done | P: say-after-me duet + native stitch correction | Y | Y | N | Y | TikTok-style practice |
| Square (language feed) | P9-956, F-113 | Done / Draft | P: language-tagged posts + per-word Tone Lens | Y | N | N | Y | Moderation before publish |
| Circle stories 24h | P9-957, F-128 | Done / Draft | P: short target-language status clips in circle | Y | Y | Y | Y | Member scope only |
| Native corrections | P9-951, F-122 | Done / Draft | P: learner phrase → verified native fix + reputation | Y | Y | N | Y | Feeds content QA queue |
| Classrooms & roster | P9-952–954, F-125–126 | Done / Draft | P: assignments, auto-graded speaking, can-do progress, LiveKit | Y | Y | N | Y | School consent gate |
| Festival events | P9-955 | Done | P: seasonal cultural sessions → live/replay Practice Rooms | Y | Y | N | Y | Belonging + scheduled speak |
| Group flashcard focus | P9-958, F-109 | Done / Draft | P: honest co-learner roster or empty; shared deck practice | Y | N | N | Y | Mock co-learners removed (P9-958) |

## Planned Village surfaces (F Draft — outcome named, not yet elevated)

| Surface | Cards | P / B outcome | S | V | E | C |
|---|---|---|:--:|:--:|:--:|:--:|
| Villages hub & map | F-103–107 | B: place-based belonging; P: market/café/elder scenario speak hooks (carded) | Y | Y | N | Y |
| Matching pairs (group) | F-110 | P: paired recall in circle session | Y | N | N | Y |
| Circle clash | F-112 | P: friendly competition on language tasks | Y | N | N | Y |
| Call history | F-115 | B: resume speaking relationships | Y | Y | N | N |
| Community guidelines entry | F-116 | B: safe belonging norms (supporting, not primary practice) | Y | N | N | N |
| Social hub / connections | F-118 | B: find practice partners; P: language-overlap discovery (carded) | Y | N | N | N |
| Friend quests / challenge | F-119 | P: peer speaking/challenge tasks | Y | Y | N | Y |
| Share progress | F-120 | B: celebrate competence; weak direct practice | Y | N | N | N |
| Social gifting | F-121 | B: generosity; practice only if gift unlocks speak content | Y | N | N | N |
| Ancestral tree | F-123 | B: heritage belonging; P: story prompts (carded) | N | N | N | Y |
| Micro-mentors | F-124 | P: short verified-native Q&A | Y | Y | N | Y |
| Social audio rooms (legacy radio) | F-127 | P: must merge into Practice Rooms or gate off | Y | Y | N | N |
| Snaps & streaks | F-130 | B: habit; P: only if streak tied to speak metrics (carded) | Y | Y | Y | Y |
| Community feed (generic) | F-131 | Must stay language-tagged like Square or defect | Y | N | N | N |
| Explore / profile | F-132 | B: discovery; needs language-practice CTA per card | Y | N | N | N |
| UGC create / voice contrib | F-133–134 | P: learner-produced target-language media | Y | Y | N | Y |
| Native verify / review queues | F-135–136 | P: quality labour as practice for validators | Y | Y | N | N |

## Defects (fail all four: S, V, E, C)

| Surface | Cards | Why defect | Remediation card |
|---|---|---|---|
| Community guidelines welcome | F-116 | Static policy text only; no speak/voice/ephemeral/creative hook | F-116 must add practice CTA or merge into chat onboarding |
| Social hub (connections list) | F-118 | Draft spec is directory-only; no voice/speed/ephemeral/creative mechanic yet | F-118 elevation: language overlap + one-tap Practice Room |
| Share progress | F-120 | Share sheet without mandatory target-language artifact | F-120: require can-do or clip artifact |
| Generic community feed | F-131 | Duplicate of Square without Tone Lens / language tag requirement in draft | Fold into P9-956 Square or add EP-§9.2 hooks before ship |

## Not in scope (safety-only, not Village practice surfaces)

Guardian hub (P9-912–920), moderation console (P9-921–932), E2EE plumbing (P9-937–941), analytics (P10-930+): support G9 but are not counted as Village social practice surfaces for EP-§9.2-01.

## Open build items

- **P9-942** (group calls): Draft; must inherit Practice Room turn rules + adult/circle gate before audit pass.
- **F-103–107** village map shells: Draft; practice outcomes carded but not wired.

Run `python3 scripts/safety/village_practice_audit_check.py --check` to validate front matter, row coverage, and defect list consistency.
