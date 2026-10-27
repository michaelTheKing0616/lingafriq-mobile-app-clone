charter: v2

# Avatar cultural design bible (P11-034)

Status: **Accepted** (builder default, 2026-10-27). Implements ELEVATION §4.2 L899–L905 and §4.4 L967–L969. **EXT-14** (cultural consultant) must sign off each region-authentic outfit row before learner-facing release; until then items ship as `expert_reviewed` draft in Studio only.

Runtime art follows `assets/rive/lingafriq/CHARACTER_BIBLE.md` and `lingafriq_cast.riv`. This document is the product-facing policy for hair, headwear, textiles, skin, disability, and review gates.

## 1. Regional hair styles (named)

| Style | Regions / groups | Avatar artboard | Cultural note (1 line) | Consultant review |
| --- | --- | --- | --- | --- |
| Fulani braids | Fulani, Hausa-adjacent | `Hair/FulaniBraids` | Centre braid with side braids; cowries and beads are optional adornment, not random loot. | EXT-14 pending |
| Shuku | Yoruba | `Hair/Shuku` | Braided crown (“basket”) style documented in Yorùbá hair art. | EXT-14 pending |
| Bantu knots | isiZulu, southern Bantu | `Hair/BantuKnots` | Coiled knots; confirm host context (e.g. Thandi) with native reviewers. | EXT-14 pending |
| Irun kiko | Yoruba | `Hair/IrunKiko` | Thread-wrapped protective style; spikes read at chip size via backing mass. | EXT-14 pending |
| Cornrows | Pan-African (via row styles) | `Hair/Shuku`, `Hair/Albaso` rows | Row braids; standalone `Cornrows` artboard queued. | EXT-14 pending |
| Albaso | Amhara / Ethiopian | `Hair/Albaso` | Cornrow rows finishing in a full puff. | EXT-14 pending |
| Locs | Diaspora-wide | `Hair/Locs` | Matted rope locks; not nation-locked in picker. | EXT-14 pending |
| Short coils / Afro | General | `Hair/ShortCoils`, `Hair/Afro` | Coil texture with scalloped silhouette; default learner preset uses Afro. | EXT-14 pending |

## 2. Headwear (named)

| Item | Regions | Artboard | Cultural note | Consultant review |
| --- | --- | --- | --- | --- |
| Gele | Yoruba, Igbo celebrations | `Headwear/Gele` | Tied wrap; height and knot are personal and occasion-driven. | EXT-14 pending |
| Fila | Yoruba | `Headwear/Fila` | Men’s cap; flop direction is wearer preference. | EXT-14 pending |
| Kufi | Wolof, Hausa, Mandinka (approx.) | `Headwear/Kufi` | Brimless cap; **⚑** separate artboards needed for Igbo *okpu ododo* and Dagomba *zupligu* (see CHARACTER_BIBLE §3c). | EXT-14 pending |
| Tignon | Diaspora / West African wrap tradition | *queued* | Headwrap lineage distinct from gele knot styles; not in v1 `.riv`. | EXT-14 pending |
| Duku | Akan (Ghana) | `Headwear/Duku` | Knotted Ghanaian wrap; fabric signals occasion. | EXT-14 pending |
| Maasai beadwork | Maasai | *queued motif cap* | Beaded crown/collar motifs ≤15% torso rule when added; never a costume default. | EXT-14 pending |
| Hausa hula | Hausa | *queued* | Traditional Hausa headwrap variant; distinct from generic gele art. | EXT-14 pending |
| Isicholo | Zulu | `Headwear/Isicholo` | Flared hat; traditionally married women—native sign-off before default on hosts. | EXT-14 pending |

## 3. Textiles and garments

| Textile / garment | Region | Artboard (current) | Cultural note | Consultant review |
| --- | --- | --- | --- | --- |
| Aṣọ-òkè | Yoruba | `Top/WovenWrap` (strip weave) | Handwoven strip cloth for celebrations. | EXT-14 pending |
| Kente | Akan | `Top/WovenWrap` (gold/green check) | Motifs carry meaning; per-motif review before production palettes. | EXT-14 pending |
| Akwete | Igbo | `Top/WovenWrap` (Igbo palette) | Woven top pattern; replace shared check with dedicated motif art. | EXT-14 pending |
| Àdìrẹ | Yoruba | `Top/Tee` diamond pattern | Resist-dyed cloth symbolism; colourways only after motif review. | EXT-14 pending |
| Grand boubou / kaftan | Wolof, Mandinka, Hausa | `Top/Kaftan` | **⚑** shared silhouette; per-garment artboards required (CHARACTER_BIBLE §3c). | EXT-14 pending |
| Fugu / smock | Dagomba | `Top/Fugu` | Northern Ghana smock stripes; worn by Fuseini preset only until general unlock rules pass review. | EXT-14 pending |
| George wrapper | Igbo | `Bottom/Wrapper` | Commonly paired with blouse and gele at events. | EXT-14 pending |
| Habesha kemis | Amhara | `Top/Kaftan` (white + tibeb) | White dress with coloured neckline embroidery. | EXT-14 pending |

Rule: motifs cover **≤15%** of torso, use brand-safe colours, and require **two native-speaker reviewers + EXT-14 advisor** before `native_verified` label.

## 4. Skin-tone system (≥10 tones)

Lighting: single key from **upper left**; cel shadow `#1A0820` @ 18% alpha; rim `#FFF0D8` @ 24% on lit edge. **No per-tone paint variants**—shading is alpha overlays on a flat `skinTone` fill so undertones stay truthful under the same light rig.

| ID | Name | Hex | Undertone | Use |
| --- | --- | --- | --- | --- |
| 1 | porcelain-warm | `#F1D3B8` | warm | albinism-adjacent pale; pair with sun-hat when added |
| 2 | sand-neutral | `#DDB28F` | neutral | |
| 3 | honey-golden | `#C68D5E` | warm golden | |
| 4 | caramel-warm | `#A86F45` | warm red | |
| 5 | bronze-olive | `#8A5A3C` | olive | |
| 6 | cocoa-red | `#7A4A2E` | red-warm | |
| 7 | chestnut-neutral | `#6B4226` | neutral | |
| 8 | umber-cool | `#5C3317` | cool | |
| 9 | espresso-warm | `#4A2800` | warm deep | |
| 10 | ebony-blue | `#3B2216` | blue-deep | |
| 11 | onyx-deep | `#2E1A12` | neutral deep | |
| 12 | albinism-pale | `#EED9C6` | warm pale | default for albinism representation; never a joke palette |

Swatch order matches `preview.html` / cast tooling. **Nation packs never restrict** which tone a learner may select.

## 5. Disability representation

| Need | Delivery | Status | Rules |
| --- | --- | --- | --- |
| Glasses | `Accessory/Glasses` | Built | Free day one; never paywalled |
| Hearing aids | `Accessory/HearingAids` | Built; Otieno default | Free; accurate side placement |
| Vitiligo | `Accessory/Vitiligo` overlay | Built; Thandi default | Alpha overlay on all tones |
| Albinism | Tone 12 + light hair | Built | Queued: sun-hat + low-vision glasses |
| Wheelchair-seated pose | `Bottom/Wheelchair` + `bodyType=seated` | Spec only | Upper-body gestures unchanged; never a punchline |

## 6. Scarification and marks (pointer)

Formal policy is **ADR-035** (P11-033). Marks are **opt-in, adults only, not in v1**, consultant-gated; see CHARACTER_BIBLE §8 until ADR-035 is filed.

## 7. Review workflow

1. Author proposes item in Studio with one-line cultural note (tables above).
2. Two native speakers from the relevant community review (EXT-13 talent pool when live).
3. EXT-14 cultural consultant signs the row (record `consultant_id`, `YYYY-MM-DD` in item manifest).
4. Until step 3 completes: `expert_reviewed` max; never `native_verified` on avatar cosmetics.

## References

- `assets/rive/lingafriq/CHARACTER_BIBLE.md` (cast instances, open approximations §3c)
- `docs/build/licence_register.csv` (commercial use only)
- ELEVATION §4.2 item 7 (gap this bible closes)
