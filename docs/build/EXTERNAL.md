charter: v2

# EXTERNAL.md — human-owned items

Each item: owner, due-by gate, the artefact an agent prepares, and the RTM rows it unblocks. Status: `Open | Requested | Received | Waived`.

| ID | Item | Owner | Due gate | Agent-prepared artefact | Unblocks (RTM) | Status |
|---|---|---|---|---|---|---|
| EXT-01 | Companion doc `docs/plan/LINGAFRIQ_AI_MODEL_STACK.md` (model/vendor choices, licences, pricing) | Tope | G0 (or per card) | §1.1 commercial replacements, §2, §2.4, §3.1, §3.5, §3.7, §3.8, §3.9, §4, §7, pricing | all `companion:` rows (EP-§4.3-33, EP-§6.4-07/69, EP-§7.2-01, EP-§7.5-18, EP-§7.6-10, CP-§3.1-25/26, CP-§7-09, CP-§9.4-17 …) | Done |
| EXT-02 | Companion `LINGAFRIQ_ELEVATION_PLAN.md` — superseded by `_3.pdf` (section numbers match); no action | — | — | — | CP-§pre-11, CP-§4-31, CP-§5-27/28 | Resolved |
| EXT-03 | Counsel sign-off on the licence register | Tope → counsel | G4 | register CSV + per-source compatibility checklist (arXiv 2606.28867 matrix) | CP-§pre-08, CP-§2.1-03, CP-§2.1-08, CP-§9.2-06 | Open |
| EXT-04 | Oxford Languages datasets (yo, ig, ha, xh; sw via API) quote + licence | Tope | G4 | RFQ: tone-marked headwords, examples, display rights, API terms | CP-§2.3 Oxford, CP-§2.4-*-lexicon, D2 | Open |
| EXT-05 | IgboAPI dataset licence (Nkọwa okwu) | Tope | G4 | RFQ + attribution clause | CP-§2.3-06, CP-§2.4-ig-02 | Open |
| EXT-06 | isiZulu dictionary licence (Doke–Vilakazi publisher / isiZulu NLU) [verify] | Tope | G4 | contact list + RFQ | CP-§2.4-zu-*, UNV-C06 | Open |
| EXT-07 | PanLex written permission | Tope | G4 (optional) | permission request email draft | CP-§2.3-04, CP-§2.3-17 | Open |
| EXT-08 | NaijaVoices commercial waiver ($5k+/yr) — optional | Tope | G8 | cost/benefit note vs Common Voice + FLEURS | CP-§2.3-05, CP-§9.4-10 | Open |
| EXT-09 | Helsinki Corpus of Swahili (ELRA €7.5k/15k) — optional | Tope | G5 | gap analysis after Oxford + Leipzig | CP-§2.3-08 | Open |
| EXT-10 | Kamusi licence — optional | Tope | G5 | gap analysis | CP-§2.3-07, CP-§2.4-sw-02 | Open |
| EXT-11 | 2 part-time linguists per Stage-1 language (14), consent + IP clause | Tope | G4 | role brief, calibration-set protocol (κ), payment-export spec, contract clause list | CP-§5-*, D4 | Open |
| EXT-12 | isiXhosa custom voice commission (2 actors, 5–10 h, buy-out) [quote] | Tope | G8 | voice brief, script list, buy-out clause list | CP-§7-xh-*, D3, UNV-C09 | Open |
| EXT-13 | Native validators and voice talent (≥2 voices L0/L1, ≥4 L2 per language) | Tope | G6 | recording brief, consent/IP template, exposure-ranked script | EP-§6.4-40, EP-§6.4-47, EP-§6.4-60, EP-§6.6-04 | Open |
| EXT-14 | Cultural consultant (patterns, avatars, imagery) | Tope | G3 | review checklist + credit policy | EP-§3.4 art direction, EP-§4.2-07 | Open |
| EXT-15 | Historians per persona (5 at v1) | Tope | G11 | dossier template + review rubric | EP-§8.2-19, EP-§8.3-02, EP-§8.3-24, EP-§8.4-19 | Open |
| EXT-16 | Rive / illustration artists (`.riv`, illustration packs, music, sounds) | Tope | G3/G11 | character bible, rig spec (View Model contract), chip sizes, budgets | AV-step1…7, EP-§4.* | Open |
| EXT-17 | Third-party penetration test | Tope | G9 (before any school/child launch) | scope doc: routes, sockets, auth, minors' surfaces | EP-§13.1-40 | Open |
| EXT-18 | NDPC registration check + DPIA (incl. voice data thresholds [verify with counsel]) | Tope → counsel | G12 | DPIA draft, data map, retention schedule | EP-§13.2-*, UNV-E06 | Open |
| EXT-19 | App-store and payment set-up (RevenueCat webhooks secret, Play/App Store) | Tope | G1 (webhook secret) / G12 | webhook config checklist | P0-27 | Open |
| EXT-20 | Efficacy-study partner | Tope | G12 | study design brief | EP-§15-18, RM-P2-12 | Open |
| EXT-21 | Key revocation (Firebase SA, Apple .p8, 5 AI keys) and history purge — human-run | Tope | G1, day 1 | `scripts/security/purge_history.sh` (filter-repo plan), revocation checklist, gitleaks config | P0-1, P0-2, P0-3 | Open |
| EXT-22 | Reference grammars/dictionaries [purchase]: Bámgbóṣé, Emenanjo, Newman, Faraclas, Ashton, Poulos & Msimang | Tope | G4 | purchase list with editions | UNV-C02…C06 | Open |
| EXT-23 | Live-server facts marked [Unverified]: PM2 double scheduler, RevenueCat key injection, live translate path | Tope | G1 | 3-line checklist of what to look at | P0-23, P0-27, UNV-E01 | Open |
| EXT-24 | Professional UI translation + native sign-off of ARB strings with diacritics (20 locales) | Tope | G3 | ARB export, glossary, reviewer brief | EP-§13.8-01, RM-P1-11 | Open |
| EXT-25 | CSAM hash-matching vendor account (e.g. PhotoDNA/Safer-class) and hotline / law-enforcement reporting contacts | Tope | G9 | vendor shortlist, integration checklist, escalation runbook | EP-§9.4-15, EP-§9.4-21 | Open |
| EXT-26 | Native-moderator lexicons and moderator panel per Stage-1 language | Tope | G9 | lexicon schema, recruiting brief, SLA table | EP-§9.4-11 | Open |
| EXT-27 | Accessibility audit with disabled users (WCAG 2.2 AA) | Tope | G12 | audit scope, recruiting brief, device list | RM-P2-13 | Open |
| EXT-28 | Paid contributors for the open tone corpus (moonshot) | Tope | G13 | contributor brief, consent/IP template, licence choice | RM-MS-02 | Open |
| EXT-29 | Museum / university partners for living history and AR scenes (moonshot) | Tope | G13 | partnership one-pager | RM-MS-04 | Open |
| EXT-30 | Verified native tutors for the teacher marketplace (moonshot) | Tope | G13 | vetting criteria, revenue-share clause list | RM-MS-07 | Open |
