# Tope's requests to turn into cards (added 2026-10-22)

Convert each item into a proper card (in the charter format) under the phase named, add it to CARD_STATUS.tsv, then mark it "carded" here.

Carded 2026-10-22. R1 is P7-945, P4-168, P6-085, P7-946, P7-947, P8-934. R2 is P2-058, P7-949. The Lens collection save is an acceptance criterion on P7-946 because P7-909 already owns the collection. The R1 model-choice update is carded as a revision of P7-945, P4-168, and P7-947, plus P6-086 (server SigLIP) and P7-950 (on-device fallback). Build order is P4-168, then P6-086, then P7-945, P7-946, P7-950, then P7-947. These do not jump ahead of the open P1 cards.

R3 is carded 2026-10-23 on F-007, with build slices P7-951, P7-952, and P7-953. F-011, F-021, F-103, and F-104 only reference that path. These do not jump ahead of the open P2 cards.

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

## R1 update: model choice (Tope, 2026-10-22; replaces the "MobileNet-family" line above) — carded
- On the phone, use **MobileNetV4** (Apache-2.0) as a TFLite ML Kit custom model for instant offline recognition.
- When online, or when on-device confidence is low, fall back to **SigLIP** (Apache-2.0), an open-vocabulary model: match the image against each language's Living Dictionary word list (English glosses), so new objects or languages need no retraining. Use a small or quantized variant on the phone if it meets the speed target; otherwise run it on the server behind the AI gateway, sending images only with opt-in.
- Use SigLIP's confident matches, after user confirmation and with opt-in, to build the African-objects fine-tuning set for MobileNetV4.
- **Do not use Ultralytics YOLO** (AGPL). Check the licence of each specific set of trained model files (not just the code) and log it in the licence register before using it.

## R3. Illustrated winding lesson path (phase P7, F-007) — carded
- Problem: the main Path screen is not yet a single illustrated journey. Lesson nodes need a vertical, scrolling, zig-zag trail.
- Build: large numbered nodes joined by dotted trails, starting at the bottom and moving upward. Node states are done (green and a tick), current (highlighted, learner avatar beside it, a "Play now" pill and the lesson title), locked (grey and a lock), and review-due (marked from FSRS). Adaptive pacing (R2, P7-949) may open or skip a node for a fast learner, and must not hide a lesson the learner is allowed to reach.
- Sections: a banner between groups of nodes shows the unit name, the CEFR level, and the can-do statement. The page scrolls to the current node. Tapping a node opens a preview with the lesson goal, time, XP, and start or review.
- Scenes: culturally specific illustrated characters and props along the path for each language and unit (Yoruba, Igbo, Hausa, Zulu, Xhosa, Swahili, Pidgin), plus Polie the mascot animated in Rive. The background is parchment textured per language. Locked areas ahead are dimmed.
- Performance: lazy-load sections, hold 60 fps on a low-end Android, and work offline from Drift.
- Accessibility: every node has a label and a state for screen readers, a minimum tap size, a reduced-motion mode, and alt text on the art.
- Art: original or commercially licensed only, logged in the licence register, and drawn to the design pack and the brand kit. An unlicensed file is not shipped. Until EXT-16 delivers a `.riv`, Polie is a labelled still, not a stand-in animation.
- Cards: F-007 holds the acceptance criteria. P7-951 draws the trail and the node states. P7-952 adds banners, auto-scroll, the preview sheet, and the long-path budget. P7-953 places the licensed scenes and Polie. F-011 (personal plan), F-021 (tone units), and F-103 / F-104 (village maps) link to this path and do not keep a second lesson-progress store.
- Do not build these ahead of the open P2 cards.
