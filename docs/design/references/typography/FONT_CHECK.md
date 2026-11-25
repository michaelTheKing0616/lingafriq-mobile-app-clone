# Glyph coverage (fontTools cmap + HarfBuzz shaping, 2026-10-30)

**Test set:** ẹ ọ ṣ ɛ ɔ ŋ ɓ ɗ ƙ ǹ ń ḿ ɲ ị ụ ṅ ƒ ʋ ɖ ɣ ƴ ʼ ’ ñ ë, together with their capitals. It also includes áàâāǎã for every vowel, ňŇ, combining U+0300 0301 0302 0303 0304 030C 0323 0331, and Arabic U+0621–0652 plus the Ajami letters ٻ ڢ ڧ ڽ ۋ and digits.

| Font (version) | Latin/African missing | Combining missing | Arabic missing | GPOS mark |
|-|-|-|-|-|
| **Noto Sans 2.015 (shipped subset)** | none | none | n/a | yes |
| **Nunito 3.602 (shipped subset)** | Ɔ Ɖ Ɛ Ƒ Ɣ Ƙ ƙ Ɲ Ʋ ǐ ǒ Ǹ ǹ ɔ ɖ ɛ ɣ ɲ ʋ Ḿ ḿ (falls back to Noto Sans) | none | n/a | yes |
| **Noto Sans Arabic 2.012** | (Latin by fallback) | U+0323 U+0331 | 0 of 58 | yes |
| M PLUS Rounded 1c 1.059 (finalist) | none | none | n/a | listed, but marks after ọ/ụ/ẹ get **0 offset**, so they render detached |
| Baloo 2 1.700 (finalist) | Ɓ Ɔ Ɖ Ɗ Ɛ Ƒ Ɣ Ƙ ƙ Ɲ Ʋ Ƴ ƴ Ǹ ǹ ɓ ɔ ɖ ɗ ɛ ɣ ɲ ʋ Ḿ ḿ | none | n/a | **no** (kern only) |
| Andika 6.101 (finalist body) | none | none | n/a | yes |
| Baloo Bhaijaan 2 1.701 | same as Baloo 2 | none | 10 (U+063B–063F, ٻ ڢ ڧ ڽ ۋ) | yes |
| Others screened (all miss several of ɛ ɔ ɓ ɗ ƙ): Fredoka, Rubik, Readex Pro, Quicksand, Comfortaa, Varela Round, Mali, Lexend, Gabarito, Figtree, DynaPuff, Grandstander, Sniglet, Balsamiq Sans, Nunito Sans, Atkinson Hyperlegible Next. Inter is complete apart from U+0331. | | | | |

**HarfBuzz mark-offset test (x_offset of the combining mark):**
- Nunito ExtraBold places ọ̀ at -295, ụ́ at -296 and ẹ̀ at -262, so the mark sits over the base. ✔
- M PLUS Rounded 1c places ọ̀, ụ́ and ẹ̀ at 0. ✘
- Noto Sans uses a correct anchor for every test string. ✔

Nunito returns glyph 0 for ɛ́ and ɔ̀; in Flutter the whole cluster then renders from the LingAfriqText (Noto Sans) fallback.

**Visual check:** `contact-sheet.png` shows the 3 finalists at 100% and 200%, with a headline, body text, Yoruba, Igbo, Hausa/Ewe/Akan and RTL Arabic. A, B and C are the three finalist pairings, and B is the pick:
- A shows the detached grave.
- B (Nunito + Noto Sans) and C are clean. Ɛ and ɔ appear in the body lines.
