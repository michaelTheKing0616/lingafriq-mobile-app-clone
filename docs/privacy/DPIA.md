---
card: P10-919
status: draft
version: "1.0.0"
effective_date: 2026-10-27
counsel_signoff: pending
ext18_open: true
---

# Data Protection Impact Assessment — voice data and minors

> **Draft for counsel review (EXT-18).** Not legal advice. Do not treat this document as NDPC filing or registration until counsel signs off.

Related artefacts: [`DATA_MAP.md`](./DATA_MAP.md), [`RETENTION.yaml`](./RETENTION.yaml). Controls implemented in `node-backend` (P10-922 voice storage consent, P10-923 training contribution, P10-921 retention purge, P10-925 export/delete).

## 1. Scope and controller

| Field | Value |
|---|---|
| Controller | LingAfriq Ltd (Nigeria) **[verify legal entity with counsel]** |
| Assessment trigger | Systematic processing of voice biometrics–adjacent data; children’s data; cross-border AI subprocessors |
| In scope | Learner practice audio, pronunciation scoring, Polie/realtime voice, Lens point-and-say events, passport proctoring audio, social audio rooms |
| Out of scope (v1) | Payment card data (processor-hosted), marketing lists without learning account |

## 2. Processing activities (voice and minors)

| ID | Purpose | Data categories | Legal basis (NDPA 2023) | Retention / deletion control |
|---|---|---|---|---|
| V-01 | Pronunciation scoring and tone feedback | Short audio utterances, derived scores, F0 contours | Legitimate interests / contract (learning service) **[counsel to confirm]** | Default **delete raw audio after scoring** (`delete_raw_audio_after_scoring_unless_training_opt_in` in RETENTION.yaml); no server retention unless opt-in |
| V-02 | Optional voice replay library | Stored practice clips, consent version, timestamps | **Consent** (explicit opt-in; `VOICE_STORAGE_CONSENT_VERSION`) | Max 365 days when enabled; purge within 30 days after withdraw (`voice-consent.service.ts`) |
| V-03 | Optional model-training contribution | Stored clips flagged for training queue | **Consent** (separate from V-02; minors not offered) | Withdraw stops new training use; removal queue (`training-consent.service.ts`) |
| V-04 | Realtime tutor / Polie voice turns | Ephemeral audio buffers, transcripts (scrubbed logs) | Contract / legitimate interests **[counsel]** | Session-scoped; telemetry excludes raw audio (`ai-gateway` logging policy) |
| V-05 | Lens / point-and-say | On-device frames optional; event metadata | Contract | Events per RETENTION; uploads gated by Lens privacy policy |
| M-01 | Minor accounts | Birth year, guardian linkage, restricted social features | Contract / legal obligation (child safety) | Account deletion erases learner state (`erase_on_account_deletion_and_guardian_request`) |
| M-02 | Minor voice storage | Same as V-02 | Consent **only with recorded guardian consent** | `minorNeedsGuardianForVoiceStorage`; blocked without guardian flag |

## 3. Risks and mitigations

| Risk | Likelihood | Severity | Mitigation | Residual |
|---|---|---|---|---|
| Retained voice used beyond stated purpose | Medium | High | Separate consents V-02 vs V-03; audit fields; purge jobs (P10-921) | Counsel review EXT-18 |
| Minor opts in without guardian | Low | High | Server rejects opt-in; `VOICE_STORAGE_GUARDIAN_REQUIRED` | Tested in P10-922 |
| Cross-border transfer without safeguards | Medium | High | DPA/SCC with each AI vendor; map in data map **[verify list with counsel]** | Open: adequacy per vendor |
| Re-identification from voice in village/social audio | Medium | Medium | Face blur, minor village gates, retention limits | Ongoing moderation |
| Over-collection for analytics | Low | Medium | On-device aggregates where possible (P10-933 planned); no raw audio in analytics events | — |

## 4. NDPA 2023 / NDPC directive duty map

| Duty / theme | Control or artefact | Status |
|---|---|---|
| Lawful basis documented | §2 table above | Draft |
| Data minimisation | Delete-after-scoring default; opt-in storage | Implemented (P10-922) |
| Purpose limitation | Training consent scoped to `voice_recordings_model_improvement` | Implemented (P10-923) |
| Storage limitation | RETENTION.yaml + purge job | Implemented (P10-920, P10-921) |
| Security | TLS, server-side AI keys only, no client LLM keys | ADR-007 / gateway |
| Cross-border transfer | Vendor DPAs; NDPA transfer tools **[counsel]** | **Open (EXT-18)** |
| Data subject rights | Export + delete in-app (P10-925) | Implemented |
| DPIA for high-risk processing | This document | Draft pending counsel |
| Register as controller of major importance | Thresholds unconfirmed | **Open (EXT-18, P10-926)** |
| Breach notification | Incident runbook **[verify exists]** | **Open** |
| Children’s data | Guardian gate, training not offered to minors | Implemented |

## 5. Subprocessors (voice / speech path)

Processors receive data only as needed for the learning feature. Routing cites `docs/plan/LINGAFRIQ_AI_MODEL_STACK.md` (EXT-01). Intron remains **disabled** behind server flag until licensed and enabled.

| Processor | Processing | Location | DPA status |
|---|---|---|---|
| Google Cloud (STT/TTS/Translation) | Transcription, synthesis | Multi-region | **[counsel: verify DPA]** |
| Microsoft Azure (TTS) | zu/xh/sw fallback voices | EU/US | **[counsel]** |
| OpenAI / Groq (gateway) | Text only in standard modes; realtime path gated | US | **[counsel]** |
| LiveKit | Realtime transport | **[verify region]** | **[counsel]** |
| Spitch / ElevenLabs | TTS when routed | EU/US | **[counsel]** |

## 6. Open items (EXT-18)

1. Counsel sign-off on legal bases for V-01, V-04, and cross-border transfers.
2. Confirm whether LingAfriq meets **data controller of major importance** registration thresholds (feeds P10-926).
3. Confirm voice-data volume/processing thresholds for mandatory DPIA filing with NDPC.
4. Breach notification playbook owner and 72-hour workflow.
5. Finalise legal entity name and NDPC registration contact.

## 7. Revision log

| Version | Date | Author | Summary |
|---|---|---|---|
| 1.0.0 | 2026-10-27 | Builder agent | Initial draft from data map and P10-922/923 controls |

## CI checklist (machine-readable)

The gate `scripts/privacy/dpia_check.py --gate` requires every `dpia_required_section` below to appear as an `##` heading.

```yaml
dpia_required_sections:
  - "1. Scope and controller"
  - "2. Processing activities (voice and minors)"
  - "3. Risks and mitigations"
  - "4. NDPA 2023 / NDPC directive duty map"
  - "5. Subprocessors (voice / speech path)"
  - "6. Open items (EXT-18)"
  - "7. Revision log"
dpia_required_frontmatter:
  - status
  - version
  - effective_date
  - counsel_signoff
  - ext18_open
dpia_required_phrases:
  - "delete raw audio after scoring"
  - "guardian"
  - "EXT-18"
  - "minors not offered"
```
