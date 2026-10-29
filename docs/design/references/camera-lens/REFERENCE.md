# Camera / Lens (point-and-say) reference pack (LingAfriq) · checked 2026-10-28 (Africa/Lagos, UTC+1)
Layout and pattern inspiration only. Do not copy logos, icons, illustrations, exact copy or code. Recolour with brand/lingafriq (Gold #FFC53D, Coral #E5603B, Nunito Black); Polie is the mascot.

## Picks (App Store US lookup, 2026-10-28)
| App | Ver | Rating | Why |
|-|-|-|-|
| Google (Lens) | 444.2 | 4.65 / 5.3M | The benchmark for "search what you see": a viewfinder with corner brackets, a result sheet sliding up, multisearch (photo + words) |
| Seek by iNaturalist | 2.18.2 | 4.75 / 31k | The best learning-led camera: live ID that sharpens step by step, then a "learn" card and badges. Made for kids and families |
| PictureThis | 5.74.0 | 4.80 / 1.1M | A clear result card (big photo, name, facts) and a "diagnosis" pattern for when it's unsure |

## Screenshots per element
Viewfinder: 01 · result sheet / object match: 02, 04 · photo + text query: 03 · learn/save card: 05 · unsure/compare state: 06.
**Gaps, with no real screenshot:** translate-in-place text overlay, the camera permission ask, and the low-light/failure states. Google Translate's camera mode and Apple Live Text aren't in their listing images. Pattern-based below.

## Recipe
- **Viewfinder:** full-bleed camera with a 4-corner bracket in the middle. Top bar: ✕, flash, and the language chip (English → Yoruba). Bottom: shutter (72 px), gallery, and a "Text" / "Objects" toggle.
- **Object chips:** live dots on objects found (fade in at 200 ms). Each has a chip with its name in the target language, e.g. "ìgò (bottle)". Tap a chip to freeze the frame.
- **Translate in place:** on Text mode, the original words are covered by a matching-colour patch with the translated text set into the photo. Toggle original/translated.
- **Result sheet (02, 04):** slides up to 45% height (300 ms, spring). It shows the word large, tone marks, the speaker button, "Say it" (opens the pack 5 scorer inline) and "Save to my words" (+ fly-to-tab animation, 500 ms).
- **Learn card (05):** Polie with an example sentence, plural/related words and a cultural note.
- **Permission:** a pre-prompt ("Point at things around you to learn their names. Photos stay on your phone"), then the OS dialog. If declined, offer "Pick from gallery".
- **Low light:** a banner "Too dark — turn on the flash" plus a flash button pulse. **Not sure (06):** show the top 3 guesses as cards, "Which one is it?". **Failure / offline:** "Can't name this yet" plus "Try another angle". With no network, use the on-device list of common household words (about 300) and queue the rest.
Upgrades for LingAfriq: a starter set of common things in homes and markets (yam, kettle, danfo), works offline, no photo upload by default, safe for children (no web results).

## Second pass (2026-10-28): real vs pattern-based
- **No new captures.** Google Lens / Translate Play shots repeat the App Store ones. The Apple Live Text guide and Google Translate camera help pages were fetched, but their images load by script or are icons only, so none were captured.
- **Pattern-based:** camera permission, live text overlay on a sign, freeze-frame + tap-word, low-light state.
