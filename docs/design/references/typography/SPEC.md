# LingAfriq type system: SPEC (2026-10-30)

**Display: Nunito** (Version 3.602, google/fonts `ofl/nunito`). Static instances weighing 700/800/900, subset to Latin + African.
**Body: Noto Sans** (Version 2.015, `ofl/notosans`). Static 400/500/600/700, wdth=100, subset to Latin + African.
**Arabic (Hausa Ajami): Noto Sans Arabic** (Version 2.012). Static 400/700.
All are SIL OFL 1.1 with no Reserved Font Names, so subsetting and redistributing them is allowed. Licence files are in `licenses/`.

## Why
- On 2026-10-30, Noto Sans was the only body face of 20 OFL candidates that has every test glyph and correct mark stacking (FONT_CHECK.md). Andika came equal on coverage but looks childish for adults.
- Nunito is the closest open match to Duolingo's DIN Next Rounded: rounded terminals, a heavy 800/900, and it stacks ọ̀ ụ́ ẹ̀ correctly through GPOS mark attachment.
  - Its 21 missing letters (ɛ ɔ ƙ ɖ ɣ ɲ ʋ ǹ ḿ ǐ ǒ and their capitals) fall back cleanly to Noto Sans through `fontFamilyFallback`.
- The finalists lost on that same test:
  - M PLUS Rounded 1c (2015 build) has full cmap coverage but **does not position combining marks after a dot-below letter**. The grave of ọ̀ rendered detached on the sheet, and HarfBuzz gave a 0 offset.
  - Baloo 2 has no GPOS `mark` feature and misses 27 African letters.
- What top apps use (checked 2026-10-30):
  - Duolingo: custom Feather Bold plus DIN Next Rounded.
  - Speak: Axiforma.
  - Babbel: Graphik + Feature Text.
  - Memrise: Boing.
  - Finch: Rubik.
  - Headspace: Apercu.
  - Busuu: Nista.
  - Calm web: Roboto.
  - In short, a friendly rounded display face with a neutral sans, which this pairing reproduces with free fonts.

## Files to add: `assets/fonts/lingafriq/` (copy from `fonts/`)
| File | KB |
|-|-|
| Nunito-Bold/ExtraBold/Black-LatinAfrica.ttf | 79 each |
| NotoSans-Regular/Medium/SemiBold/Bold-LatinAfrica.ttf | 207 each |
| NotoSansArabic-Regular/Bold.ttf | 135 each |
| Fallbacks: NotoSansEthiopic-Regular 354 · NotoSansTifinagh 115 · NotoSansNKo 78 · NotoSansVai 126 · NotoSansAdlam 86 · NotoSansOsmanya 56 · NotoSansBamum 177 | |
Core total is **1.37 MB**. With fallbacks it is **2.38 MB**.
That is less than the 2.0 MB of the bundled Nunito statics plus Lato (1.5 MB) that it can replace.

## pubspec.yaml
```yaml
flutter:
  fonts:
    - family: LingAfriqDisplay
      fonts:
        - {asset: assets/fonts/lingafriq/Nunito-Bold-LatinAfrica.ttf, weight: 700}
        - {asset: assets/fonts/lingafriq/Nunito-ExtraBold-LatinAfrica.ttf, weight: 800}
        - {asset: assets/fonts/lingafriq/Nunito-Black-LatinAfrica.ttf, weight: 900}
    - family: LingAfriqText
      fonts:
        - {asset: assets/fonts/lingafriq/NotoSans-Regular-LatinAfrica.ttf, weight: 400}
        - {asset: assets/fonts/lingafriq/NotoSans-Medium-LatinAfrica.ttf, weight: 500}
        - {asset: assets/fonts/lingafriq/NotoSans-SemiBold-LatinAfrica.ttf, weight: 600}
        - {asset: assets/fonts/lingafriq/NotoSans-Bold-LatinAfrica.ttf, weight: 700}
    - family: LingAfriqArabic
      fonts:
        - {asset: assets/fonts/lingafriq/NotoSansArabic-Regular.ttf, weight: 400}
        - {asset: assets/fonts/lingafriq/NotoSansArabic-Bold.ttf, weight: 700}
    - {family: NotoSansEthiopic, fonts: [{asset: assets/fonts/lingafriq/NotoSansEthiopic-Regular.ttf}]}
    - {family: NotoSansTifinagh, fonts: [{asset: assets/fonts/lingafriq/NotoSansTifinagh-Regular.ttf}]}
    - {family: NotoSansNKo, fonts: [{asset: assets/fonts/lingafriq/NotoSansNKo-Regular.ttf}]}
    - {family: NotoSansVai, fonts: [{asset: assets/fonts/lingafriq/NotoSansVai-Regular.ttf}]}
    - {family: NotoSansAdlam, fonts: [{asset: assets/fonts/lingafriq/NotoSansAdlam-Regular.ttf}]}
    - {family: NotoSansOsmanya, fonts: [{asset: assets/fonts/lingafriq/NotoSansOsmanya-Regular.ttf}]}
    - {family: NotoSansBamum, fonts: [{asset: assets/fonts/lingafriq/NotoSansBamum-Regular.ttf}]}
```
**Fallback list:** `const kFallback = ['LingAfriqText','LingAfriqArabic','NotoSansEthiopic','NotoSansTifinagh','NotoSansNKo','NotoSansVai','NotoSansAdlam','NotoSansOsmanya','NotoSansBamum'];`
Use it as `fontFamilyFallback` on every display style, and with `LingAfriqText` removed on body styles.

**Why static files and not variable:** Flutter stable is 3.47.9 (released 2026-10-29; your Mac has 3.47.2). Flutter can drive a variable font through `FontVariation('wght', …)`, but declaring a `weight:` in pubspec against one variable file does not set the axis. Static instances are reliable on Android, iOS and web, and are smaller after subsetting.

## TextTheme (sizes in logical px; height is the line-height multiplier; letterSpacing in px)
| Role | Family | Size | Weight | Height | Tracking |
|-|-|-|-|-|-|
| displayLarge (streak/hero number) | Display | 48 | 900 | 1.05 | -0.5 |
| headlineLarge (screen title) | Display | 28 | 800 | 1.15 | -0.3 |
| headlineSmall (question prompt) | Display | 22 | 800 | 1.25 | -0.2 |
| titleMedium (section) | Display | 18 | 800 | 1.25 | 0 |
| labelLarge (button, sentence case) | Display | 17 | 800 | 1.1 | 0.3 |
| bodyLarge (lesson text, target-language words) | Text | 17 | 400 | **1.5** | 0 |
| bodyMedium | Text | 15 | 400 | 1.45 | 0 |
| bodySmall / helper | Text | 13 | 500 | 1.4 | 0.1 |
| labelSmall (tab/meta) | Text | 12 | 600 | 1.3 | 0.2 |

## Large text (200% scale)
- Tone marks need room above and below the line: Yoruba ọ̀ has a dot below plus a mark above.
  - Keep body height at 1.45 or more.
  - Never set `height` below 1.1 on any text that can contain target-language words.
  - Use `TextHeightBehavior(applyHeightToFirstAscent: true)` so stacked marks aren't clipped.
- Respect `MediaQuery.textScaler`, but clamp display styles: `textScaler.clamp(maxScaleFactor: 1.6)` on displayLarge and headlineLarge. Body text scales to 2.0, and its containers must wrap (no fixed heights on answer tiles).
- Uppercase buttons get no hard caps: tone marks on capitals (Ẹ̀, Ọ́) collide with the line above, so keep buttons in sentence case.

## RTL (Arabic / Ajami)
- Wrap Arabic content in `Directionality(TextDirection.rtl)`, with `fontFamily: 'LingAfriqArabic'` and height 1.6 (Arabic needs extra line-height).
- Mixed Latin/Arabic text: keep the Latin fallback in the list, and use `TextAlign.start` rather than left/right.
- Mirror icons with `Directionality` and use `EdgeInsetsDirectional`.
- Noto Sans Arabic covers the Ajami extras tested: ٻ ڢ ڧ ڽ ۋ.

## What to remove from assets/google_fonts (13 MB, 97 files)
After migration, remove the Nunito statics (18 files, 2.0 MB), which these subsets replace. Then remove Lato (1.5 MB, still used in 44 lib files, so migrate those first) and the unused or decorative families.
- Dosis, Karla, Poppins and Rubik: no references found in `lib/`.
- Cinzel, Cormorant Garamond, IMFell English, Libre Baskerville, Philosopher and Playfair: 1–9 refs each; check whether they are themes before removing.
- Keep Andika (a literacy font with full African coverage) only if a "reading mode" uses it. Keep JetBrains Mono only if code or debug screens need it.
- Expected saving: 8–10 MB.
