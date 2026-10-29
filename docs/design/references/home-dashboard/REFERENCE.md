# Home / dashboard reference pack (LingAfriq) · checked 2026-10-28 (Africa/Lagos, UTC+1)
Layout and pattern inspiration only. Do not copy logos, icons, illustrations, exact copy or code. Recolour with brand/lingafriq (Gold #FFC53D, Coral #E5603B, Nunito Black). Polie is the mascot.

## Picks (App Store US lookup, 2026-10-28)
| App | Ver | Rating | Why |
|-|-|-|-|
| Headspace | 8.38.0 | 4.84 / 974k | Best "today" home: a time-of-day greeting, then a short ordered list for today, with one item highlighted |
| Calm | 7.4 | 4.77 / 2.0M | One big daily practice card above the fold; calm spacing with few choices |
| Monzo | 8.6.0 | 4.75 / 5.7k (US; huge in the UK) | Summary-first home: one big number, then small chips, then a list. Very clear hierarchy |
| Revolut | 10.153 | 4.72 / 74k | A huge hero number with its action buttons right under it; dense but tidy cards |
| Strava | 487.0.0 | 4.81 / 379k | Social proof on the home screen (friends' activity, kudos) |
| Finch | 3.73.231 | 4.95 / 769k | Daily goals shown as a checklist with soft progress: the model for daily quests |
| Busuu / Babbel | 30.31.0 / 22.20.0 | 4.71 / 4.72 | A continue-chapter card with "n/N", and a weekly habit or reminder card |

## Screenshots per element
Greeting + today (01, 03) · summary/hero number (04, 05) · recommended next (02) · social (06) · quests checklist (07) · continue card (08) · habit/week goal (09).
**Gaps:** the Duolingo home is the path, already covered in pack 2. Duolingo's quests screen and a first-day empty state aren't in any official listing (no real screenshot). Notifications entry: only seen as a small header icon. The recipe is pattern-based for these.

## Recipe (top to bottom, 16 px side margins, 12 px gaps)
1. **Header (56 px):** "Ẹ kú àárọ̀, Ada" plus a small Polie face. On the right: streak flame + count, coins, and a bell with an unread dot (opens the inbox, 44 px).
2. **Today's goal ring (Monzo/Revolut hero):** a big ring showing "8 of 10 min", with "1 lesson to keep your streak" below it. A week strip with 7 dots under it.
3. **Continue card (Calm/Busuu):** the unit picture, "Unit 2 · Greetings · 3 of 5", and a full-width "Continue" button. It's the only main button on the screen.
4. **Daily quests (Finch):** 3 rows, each with an icon, a plain task ("Say 5 words out loud"), a progress bar and the reward chest. Done rows tick and fade to 60%.
5. **Recommended (Headspace):** a sideways scroll of 2–3 small cards (Review weak words, Story of the day, Practise speaking).
6. **Friends (Strava):** an optional strip ("Tunde finished Unit 3", Clap button). Hidden until the user has friends.
**First-day state:** in place of the quests and friends sections, Polie says "Your first lesson takes 2 minutes" next to a single Start card. No zeros or empty charts.

## Motion
The ring fills on open (600 ms, ease-out, only once a day). A quest tick plays a check plus +XP that flies to the header coins (500 ms arc). The streak flame flickers (from pack 2). Cards rise in with a 40 ms stagger the first time only. Reduce Motion swaps these for fades.

## Upgrades for LingAfriq
Shows the cached home instantly with no network (an "Offline, synced 2 h ago" chip). A data-saver toggle turns off auto-playing audio and images. Today's goal can be met with audio only, for low-bandwidth days. Greeting in the language being learned. Quest rewards can be "Unlock a proverb". Everything works on a 360 px wide Android at 200% text size.

## Second pass (2026-10-28): real vs pattern-based
- **Real (Duolingo web):** 10 path home + Super promo + quests rail, 11 home with 0 hearts in the header, 12 quests page (daily + monthly challenge), 13 path home (light), 14 daily quests complete, 15 gems reward, 16 guest shop with create-profile overlay.
- **Pattern-based:** a mobile-native bottom tab bar (web uses a left rail), offline banner, low-data mode.
- Recipe fix: the header stat row (streak · gems · hearts) is always visible, and quests sit in a side rail on web. On mobile, put the stat row at the top and quests as a card under the "continue" button.
