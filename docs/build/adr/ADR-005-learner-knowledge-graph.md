charter: v2

# ADR-005 — One Learner Knowledge Graph

Status: accepted 2026-10-23. Builder default, Tope may override. Card P2-041.

## The four models this replaces

Each of these currently stores its own memory of the learner:

1. Vocabulary SM-2 in `lib/services/vocabulary_progress_service.dart` and `lib/services/offline/vocabulary_store.dart`.
2. Chat word memory SM-2 in `lib/providers/ai_chat_provider_groq.dart`.
3. Game SM-2 in `lib/providers/game_provider.dart`.
4. Bayesian Knowledge Tracing plus the half-life regression curve in `lib/learning/core/bkt_mastery.dart`, `lib/learning/core/hlr_forgetting_curve.dart`, and `lib/learning/learner_model/learner_model_service.dart`, scheduled by `lib/learning/scheduling/review_scheduler.dart`.

## The graph

One graph per user and language. Nodes are lexemes (with senses), grammar patterns, phonological skills, pragmatic skills, and can-do statements. A node holds FSRS-6 stability, difficulty, and retrievability, plus production strength, recognition strength, last evidence, and error counts. FSRS-6 is the only scheduler (P2-043). The four models above stop being sources of truth. They are not deleted by this decision.

## Migration order

1. P2-042 writes an idempotent learning event. Nothing else in this step deletes a model.
2. Later graph cards project nodes from those events.
3. P2-043 makes FSRS-6 the scheduler that reads the graph.
4. The four writers are changed to emit events, then they are no longer read.
5. P5-019 removes the four implementations after the graph is the reader.

## Privacy

The graph is on-device first. Raw audio is not stored unless the learner opts in. A pronunciation event may store a score and an error label without the audio bytes.
