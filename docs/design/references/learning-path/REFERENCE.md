# Learning path reference pack (LingAfriq) · checked 2026-10-28 (Africa/Lagos, UTC+1)
Layout and pattern inspiration only. Do not copy logos, icons, illustrations, exact copy or code. Recolour with brand/lingafriq (Gold #FFC53D, Coral #E5603B, Nunito Black). Build with the existing Rive assets in brand/lingafriq/path: path_node.riv, unit_banner.riv, polie_path.riv and path_scenery.riv.

## Picks (App Store US, iTunes lookup API, 2026-10-28)
| App | Ver (date, UTC) | Rating | Why it's here |
|-|-|-|-|
| Duolingo | 7.146.0 (10-26) | 4.72 / 5.5M | The benchmark winding path: one column of round nodes swinging left and right, a sticky unit banner, a slim stats header (streak, gems, hearts) |
| Candy Crush Saga | 1.339.0.2 (10-21) | 4.70 / 4.0M | The best "journey map": each area has its own scenery, levels are numbered, the avatar marks where you are, and it scrolls upward to move forward |
| Mimo | 12.33.0 (10-26) | 4.85 / 111k | The cleanest path for learning content: nodes grouped into units with a progress count and clear locked, current and done states |
| Busuu | 30.31.0 (10-23) | 4.71 / 101k | A chapter card with a checkpoint (unit test) node: shows "Chapter X · n/N" honestly |
| Finch | 3.73.231 (10-23) | 4.95 / 769k | A warm mascot progress world and a kind streak celebration (rewards and tone) |

## Screenshots (all real; see SOURCES.md)
01-02 duolingo path, header and unit banner · 03 candycrush winding map · 04-05 mimo path and units · 06 busuu chapter checkpoint · 07 finch adventure progress · 08-09 duolingo streak · 10 finch streak celebration.
Per element: winding path 4 (01, 02, 03, 04) · unit banner 3 (02, 05, 06) · streak/rewards header 1 in context (01), plus 3 streak screens (08, 09, 10) · scenery/world 2 (03, 07).
**Gaps:** these are still images only, with no motion capture. The timings below are recipe targets, not measured from the apps.

## Recipe
**Header (sticky, 56 px):** language flag chip on the left, then streak flame + count, coins and hearts on the right, each a 44 px tap target that opens its own sheet. The header fades its background in after 8 px of scrolling.
**Unit banner (sticky):** a full-width card (radius 16) in the unit's colour. "Unit 2 · Greetings" in Nunito Black, a one-line goal, and a "Guide" button that opens the phrase list. It is replaced when the next unit's banner reaches the top: push up, 250 ms, ease-out.
**Winding path:** one column of 72 px nodes, with each node shifted along a sine curve (0, +48, +72, +48, 0, −48 …), 24 px apart. States: locked (grey with a lock), current (brand colour, pulsing ring, a "Start" speech bubble and Polie standing beside it), done (gold with a check), and a chest or checkpoint every 5 nodes. On open, scroll to the current node and centre it at 40% of the screen height.
**Scenery:** side scenery from path_scenery.riv changes per unit (market, village, coast) as in 03. A parallax of 0.3 adds depth without moving the nodes.

## Motion notes (targets)
- **Node tap:** press scales to 0.94 in 80 ms, then springs back. A popover rises from the node (200 ms ease-out) showing "Lesson 3 of 5" and a Start button. Light haptic.
- **Completion:** after a lesson, return to the path. The done node fills gold (300 ms), a dotted trail draws to the next node (400 ms), and the next node fires path_node `unlock` (set state=current in the same frame, as the contract says). Polie hops to it (500 ms arc).
- **Unit complete:** unit_banner `unlock` plays with its shine sweep (the banner's single clip, 700 ms). Then a full-screen celebration, then back to the path.
- **Streak flame:** at rest a small looping flicker (2 s). On the day's first lesson, the count ticks up with a flame burst (600 ms) and the week dots fill in (as in 09). Reduce Motion swaps every effect for a 150 ms cross-fade.

## Upgrades for LingAfriq
1. Unit themes use real places and life moments (market, naming ceremony, danfo ride), as plain scenery with no sacred objects (follow the cultural flags in the path README).
2. Each node shows a small "Saved offline" tick, and units can be downloaded ahead on Wi-Fi.
3. A kind streak: one "freeze" per week, with low-data reminders. A missed day says "Welcome back", never shames.
4. Low-end phones: if frame time is over 2 ms (still untested on Tecno/Infinix), fall back to static nodes. Draw only the nodes on screen.
5. Accessibility: node states use shape and icon as well as colour, each node reads "Lesson 3, Greetings, current", and the path can also be shown as a list.
