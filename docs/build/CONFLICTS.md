charter: v2

# CONFLICTS.md — cross-document conflicts (resolve at G0; Tope decides)

| # | Elevation says | Curriculum says | Recommendation | Status |
|---|---|---|---|---|
| C1 | §6.6 L1326-1329: two independent native reviewers before publishing; AI-stack "curriculum audio is human-recorded" | §10-D1 L852-856, §5 L625-631: labelled Beta content and labelled synthetic audio allowed until native validators arrive | **Accept Curriculum rule as interim** (D1), bounded by: Beta never in checkpoints/placement/credentials/children's mode; grammar + culture never Beta; "Synthetic voice" tag on all TTS; Elevation rule becomes the *Native-verified* promotion criterion (H6). Record as ADR-001. | Resolved (D1 signed 2026-10-21; ADR-001) |
| C2 | §6.2/§7.4 principle "never AI-only tone/diacritics" (EP-§6.* tone rows; §7.4 honesty rules L1445-1447) | §3.4 L550-552 and §6 L674-679: Beta allowed for lexicon-anchored tokens with three-way agreement (lexicon = generator = restorer); unmatched tokens 100% linguist | **Reconcile as compatible**: a lexicon-anchored, three-way-agreed token is not "AI-only"; codify in the tone-claim linter (CP-§3.3) that any tone mark without lexicon anchor is a hard failure. Tone *teaching* notes remain Expert-reviewed minimum (never Beta). | Resolved (D6 signed 2026-10-21; ADR-002) |
| C3 | §16.2 L2061-2065: Stage-1 at L1 "with native audio for every item" in months 1–3 | §7 L703-705, L749-752: interim TTS per language, native recordings replace TTS by exposure rank; TTS stays for dynamic content | **Accept Curriculum policy**: L1 readiness is redefined as "every item has audio (human or gated, labelled TTS)"; "native audio for every item" moves to the Native-verified promotion (G6/G7) and the replacement plan (CP-§7). Tonal-language TTS only after the tone-accuracy gate (H9). | Resolved (D6 signed 2026-10-21; ADR-003) |
| C4 | §4.5/§4.6 pin `rive ^0.14.11` (+ `rive_native`); §4.2 says `≥ 0.14.11` | — (intra-Elevation) | Pin `^0.14.11` in cards; verify the current pub version at card time (T0). | Resolved by rule |
| C5 | §4.3 View Model `expression` enum L880 vs L930 differ (`thinking|encouraging` vs `playful|focused`) | — (intra-Elevation) | Union of both enums in the production contract; ADR with the avatar card. | Resolved by rule |

Rules: a conflict is never resolved silently; each gets an ADR or a DECISIONS.md line signed by Tope before the first card that depends on it reaches Ready.
