# Tope's requests to turn into cards (added 2026-10-22)

Convert each item into a proper card (in the charter format) under the phase named, add it to CARD_STATUS.tsv, then mark it "carded" here.

Carded 2026-10-22. R1 is P7-945, P4-168, P6-085, P7-946, P7-947, P8-934. R2 is P2-058, P7-949. The Lens collection save is an acceptance criterion on P7-946 because P7-909 already owns the collection.

## R1. On-device object recogniser for Point & Say (phase P7; also touches P4 and P6) — carded
- Problem: `point_and_say_screen.dart` uses ML Kit's default object detector, which only gives 5 coarse labels (food, home goods, fashion, plant, place). That's too vague to teach words.
- Build: a MobileNet-family classifier (Apache-2.0; log it in the licence register) as an ML Kit custom model (TFLite), running fully on the device and offline.
- Map the model's labels to Living Dictionary entries per language: the word, human audio first (TTS as fallback), and an example sentence. When a label has no entry, show an honest "not in dictionary yet" and offer to suggest a word into the review queue.
- Phase 2: fine-tune on African everyday objects (e.g. plantain, garri, agbada, mortar and pestle, danfo, akara, kente). Use only commercially licensed or newly collected images, and log the dataset licences.
- Acceptance: works in airplane mode; recognition under 150 ms on a mid-range Android; top-3 accuracy measured on a held-out African-objects set; no photo leaves the device without opt-in; Point & Say stays in its current place in navigation.
- Extras: a camera "word hunt" game (P8) and feeding into the Lens collection for spaced-repetition review (links to P7-909).

## R2. Adaptive lesson delivery and pacing (phases P2 and P7; builds on P2-041, P2-043, P5-019, P6-008 and P8-905) — carded
- Goal: lessons adapt to each learner's pace and ability, not just their review timing.
- Use the single learner knowledge graph (P2-041) to estimate per-skill mastery. Signals: accuracy, response time, hint use, the scorer's pronunciation and tone scores, and session length and drop-off. A small on-device model is fine, e.g. Bayesian or logistic knowledge tracing; it doesn't need to be a deep network.
- Adapt: lesson length, how new items mix with reviews, difficulty (aim for 80–85% success, as in P8-905), when to move to the next CEFR step, extra tone or pronunciation drills where weak, and a pace setting the learner can see and override.
- Fairness and honesty: explain why something was recommended ("You're strong on greetings, so we've added more numbers"). Never lock content behind the model. Under-16s get the same adaptation with no profiling for marketing.
- Acceptance: an A/B test or offline replay shows better 7-day retention or completion than fixed pacing; the learner can reset or override; the model runs on the device and works offline.
