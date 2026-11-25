charter: v2

# 06 — Test strategy

Rule: **tests are written from the spec before the code** (card `test_plan` → Tester writes failing tests → Worker builds → Tester runs). A green suite that did not fail first is a review finding. Flakes are fixed, never retried.

## Layers
| Layer | Scope | Tooling (verify in repo before use) | Gate |
|---|---|---|---|
| Static | analyzer zero-warning on touched files; T0 lints: placeholder/fake-success, token compliance, copy rules, no-telemetry-in-core-lesson | `dart analyze`, `scripts/plan/*`, repo lints added by P1/P2/P3 cards | every card |
| Unit | pure logic: scorers, tone rules, XP/streak/retention maths, sync outbox, content validators | `flutter test`, Jest for `backend/` | every card |
| Widget + golden | every component state; goldens light/dark at 100%/200% text; diacritic stacking | `flutter test --update-goldens` only by Tester; golden diffs reviewed | design-touching cards |
| Contract | API schemas, content pack schema, AvatarDirector ↔ Rive state-machine inputs, store-receipt webhooks | schema snapshot tests; `.riv` contract tests | integration points |
| Integration | DB migrations up/down, auth flows, payments webhooks, moderation pipeline, offline queue replay | backend integration tests against ephemeral DB | P1, P2, P9, P10 |
| E2E | first-launch → first spoken word ≤60 s; lesson complete; offline lesson + sync; purchase; report → moderation | `integration_test` on device lab (low-end Android + iOS) | hub gates |
| Evals | AI: scorer accuracy per language (GOP, tone), tutor safety, persona fidelity, translation/content QA; fixed held-out sets, versioned | `backend/evals` harness (P6 cards) | G8 and every model change |
| Performance | cold start, frame cost, APK/IPA size, memory on 2 GB device; API p95 | perf traces in CI; size gate | G3, hub gates, G12 |
| Security | dependency audit, secret scan, authz tests per endpoint, rate limits, PII redaction in logs; external pen test | CI scanners + P1/P12 cards; EXT-17 | G1, G12 |
| Accessibility | semantics, focus order, contrast, 200% text, reduced motion, captions | a11y test suite; external audit (EXT-27) | G3, hub gates, G12 |
| Content | schema valid, licence present, native verification status, placeholder-free, audio present where required | content validators (P4 cards) | every content wave |

## Coverage and quality bars
| Item | Bar |
|---|---|
| Line coverage, touched files | ≥80% unit + widget; scorers and safety code ≥95% |
| Golden coverage | 100% of catalogue components, every declared state |
| States per screen | skeleton, empty, error, offline, AI-unavailable, under-review each have a test |
| Flakiness | zero tolerated; quarantined test blocks the card until fixed |
| Determinism | fixed seeds, frozen clocks, no network in unit/widget tests |
| Test naming | reads as behaviour: `shows_unsure_state_when_scorer_confidence_below_threshold` |
| Eval regression | any metric drop beyond tolerance blocks merge; report attached to card |

## Hard-stop verifications (must be proven by a test, not a statement)
| Hard stop | Test that proves it |
|---|---|
| No fabricated scores | fake-success lint + unit test: scorer unavailable ⇒ UI shows "unsure", stores no number |
| No placeholder content ships | placeholder lint over content packs and ARB; CI fails on `lorem`, `TODO`, `[verify]` in shipped strings |
| Native-verified rule | content validator rejects Expert/Native label without two sign-offs recorded |
| Licence register | build fails if a source id in content lacks a licence row |
| Guardian moderation before under-18 social | authz test: minor account hits social endpoint ⇒ 403 until G9 flag set |
| AI disclosure | widget test: every AI-generated surface renders the disclosure chip |
| Tone accuracy gate | eval: tonal TTS below threshold (D-threshold, Awaiting) ⇒ voice not enabled for that language |

## Tester outputs (capped)
- Report ≤15 lines in the exact block defined in `templates/tester_brief.md` (`AC<n>: PASS|FAIL`, coverage on touched domain files, mutation when required, No-Partial scan, budget).
- Mode A (Spec-Tests) must report which tests are red before build; a card whose Spec-Tests were never red is a Reviewer `FIX`.
- Any AC without a mapped test is a Reviewer `BLOCK`, never silently accepted.
- Visual evidence only when the card sets `visual_evidence_required: true`.
