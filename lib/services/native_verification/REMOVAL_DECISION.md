# P4-153 — app-side native verification tools

**Decision (2026-10-26):** No `lib/services/native_verification` implementation ships in the learner app. Native verification and two-native promotion run on the content engine and Studio workflow (`native_validation.py`, P4-122; admin review queues). The checklist UI remains in `native_review_checklist_service.dart` for bundled reviewer tooling only. Do not add parallel client-side verification flows.
