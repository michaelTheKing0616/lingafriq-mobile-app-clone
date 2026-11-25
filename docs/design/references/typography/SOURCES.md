# Sources (checked 2026-10-30)
## Fonts (official source: github.com/google/fonts, main branch, fetched 2026-10-30)
Each family comes from https://github.com/google/fonts/tree/main/ofl/<dir> with its licence at …/ofl/<dir>/OFL.txt, copied into `licenses/OFL-<dir>.txt`.
- **Shipped:** nunito (Nunito[wght].ttf, v3.602), notosans (NotoSans[wdth,wght].ttf, v2.015), notosansarabic (v2.012), notosansethiopic (v2.102), notosanstifinagh (v2.006), notosansnko (v2.004), notosansvai (v2.001), notosansadlam (v3.001), notosansosmanya (v2.001), notosansbamum (v2.002).
- **Screened, not shipped:** baloo2 1.700, baloobhaijaan2 1.701, mplusrounded1c 1.059, andika 6.101, fredoka 2.001, and the others listed in FONT_CHECK.md.
- **Processing:** fontTools varLib.instancer to make static instances, then fontTools.subset with all layout features kept. Latin set: U+0000-024F, 0250-02FF, 0300-036F, 1D00-1DBF, 1E00-1EFF, 2000-206F, 20A0-20CF (₦), A720-A7FF.
- **Flutter stable:** 3.47.9, released 2026-10-29, from https://storage.googleapis.com/flutter_infra_release/releases/releases_linux.json. The Mac has 3.47.2.

## What top apps use
Font-family values were read from live website CSS on 2026-10-28/30 (curl of the homepage HTML plus its linked CSS):
- https://www.speak.com: Axiforma (with Pretendard for CJK).
- https://www.babbel.com: "Graphik Babbel LCG", "Feature Text LC".
- https://www.memrise.com: Boing.
- https://finchcare.com: Rubik (plus Nanum Pen Script).
- https://www.headspace.com: "Headspace Apercu".
- https://www.busuu.com: Nista.
- https://www.calm.com: Roboto (SSR shell only).

Duolingo's homepage CSS wasn't readable by curl (it renders client-side), so its fonts come from published sources:
- https://www.monotype.com/resources/duolingo-custom-font-inspired-their-owl-mascot-duo: Feather Bold, a custom face by Fontsmith/Johnson Banks (published 2022-08-09).
- https://www.fontsinuse.com/uses/59497/duolingo-app: the app UI uses DIN Next Rounded.
- https://www.kristaradoeva.com/work/duolingo: type designer credit.
