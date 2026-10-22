charter: v2

# UNVERIFIED.md — claims that stay marked until verified

Every `[verify] [purchase] [quote] [Unverified] [estimate]` tag in the sources is an RTM row (`UNV-*`) and becomes a **verification card** (`P0-VER-nn`, T0/T1, S). Nothing here is promoted to fact without the card's evidence.

| RTM id | Anchor | Claim to verify | Verification card does | Owner |
|---|---|---|---|---|
| UNV-E01 | ELEVATION §2:L583 | which live-translate path is live in prod | read deployed config/env (EXT-23) | Tope |
| UNV-E02 | ELEVATION §2:L652 | social audio rooms status | route + socket trace on staging | agent |
| UNV-E03 | ELEVATION §3.2:L786 | Yoruba diacritics mis-render in fallback fonts on device | golden test on reference device with bundled font off/on | agent |
| UNV-E04 | ELEVATION §6.1:L1124 | `assets/audio` absent from pubspec; media stripped | check pubspec + asset manifest | agent (T0) |
| UNV-E05 | ELEVATION §7.4:L1447 | Omnilingual 300M on-device performance | benchmark on Tecno/Infinix class | agent |
| UNV-E06 | ELEVATION §13.2:L1881 | DPIA thresholds for voice data | counsel (EXT-18) | Tope |
| UNV-E07 | ELEVATION §17.6:L2366 | Latin-only OCR mangles stacked diacritics | device test with ọ̀/ẹ́ samples | agent |
| UNV-E08 | ELEVATION §18.4:L4270 | same, in Point & Say | covered by UNV-E07 | agent |
| UNV-E09 | ELEVATION §18.5:L4573 | whether Pronunciation Game records audio | code trace + device test | agent |
| UNV-E10 | ELEVATION §18.6:L5260 | micro-mentor verification/safeguarding/payment flow | route + model inspection | agent |
| UNV-E11 | ELEVATION §18.6:L5402 | consent/licensing of UGC recordings | ToS + model inspection; counsel if unclear | Tope |
| UNV-E12 | ELEVATION §18.7:L5608 | content of the wait/loading screen | code read | agent (T1) |
| UNV-E13 | ELEVATION §18.7:L5637 | role checks on staff tooling | authz test | agent |
| UNV-C01 | CURRICULUM §2.4:L312 | Igbo Ọnwụ orthography citation | linguist (EXT-11) | external |
| UNV-C02…C06 | CURRICULUM §2.4 | grammar purchases (Newman, Faraclas, Ashton, Poulos & Msimang, Emenanjo) | purchase list (EXT-22) | Tope |
| UNV-C04 | CURRICULUM §2.4:L392 | BAKITA Kiswahili Sanifu citation | linguist | external |
| UNV-C07 | CURRICULUM §2.4:L461 | no mature open Xhosa analyser | literature/tool scan (capped search) | agent |
| UNV-C08 | CURRICULUM §9.1:L789 | Studio effort 10–14 eng-weeks [estimate] | re-estimate from cards | agent |
| UNV-C09 | CURRICULUM §9.4:L840 | isiXhosa voice $10k–25k [quote] | RFQ (EXT-12) | Tope |
| UNV-C10 | CURRICULUM §9.4:L844 | data licence costs [quotes] | RFQs (EXT-04…10) | Tope |
| — | CURRICULUM §2.4 (in CP rows) | NERDC Yoruba edition; ZulMorph local-use terms; NSC licence; Leipzig corpus sizes; Zulu/Xhosa Common Voice hours; Peace Corps per-item PD status; classic-dictionary copyright | one verification card each (`P0-VER-*`), capped web check, result into the licence register | agent / counsel |
