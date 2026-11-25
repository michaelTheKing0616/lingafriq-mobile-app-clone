# Paywall / trial reference pack (LingAfriq) · checked 2026-10-28 (Africa/Lagos, UTC+1)
Layout and pattern inspiration only. Do not copy logos, icons, illustrations, exact copy or code. Recolour with brand/lingafriq (Gold #FFC53D, Coral #E5603B, Nunito Black); Polie is the mascot.

## Picks (pattern sources; App Store US lookup 2026-10-28)
| App | Ver | Why |
|-|-|-|
| Duolingo (Super) | 7.146.0 | The free path stays fully usable. The upgrade is offered at natural moments (out of hearts, after a lesson), never in the middle of an exercise |
| Headspace / Calm | 8.38.0 / 7.4 | Value-first: shows what you get (a calm list of benefits) before the price, with one plan highlighted, not pushed |
| Spotify | 9.1.94 | Honest local pricing. The live NG page shows "₦800/month for 6 months, ₦1,600/month after" and "cancel anytime" right next to the button |
| Finch (Plus) | 3.73.231 | The core app stays free, and Plus is framed as optional extras. A kind tone with no guilt |
**Real screenshots: 0.** None of these apps' listing images show their paywall. Everything here is pattern-based plus checked facts (see SOURCES.md).

## Rules (live check 2026-10-28)
- Apple 3.1.2 and the subscriptions page: show the trial length and the price after the trial; the renewal price must be clear; Restore Purchases must be visible.
- Google Play: before sign-up, show the trial length, the price, that it converts to paid automatically, how to cancel, and a clear way to close.
- Google Play in Nigeria: Google's help page lists cards only (Visa, Mastercard, JCB, Verve). No airtime or mobile money is listed, so don't promise them in-app. Offer a "Pay with a Nigerian card (Verve works)" hint.
- ux-copy-kb dark patterns to avoid: hidden close buttons, fake timers, "No, I don't want to learn" confirmshaming, a preselected yearly plan whose monthly price is hidden, and cancel buried in a maze.

## Recipe
1. **Value first (full screen):** Polie with a headline ("Learn faster with LingAfriq Plus"), then 4 benefit rows (offline downloads for every unit, unlimited hearts, speaking scores, no ads), each with an icon and plain words.
2. **Plan cards:** Monthly and Yearly (shows "₦X/month, billed ₦Y yearly"), plus Family (up to 6). Prices come from the store in local currency (₦). Never hard-code them. A "Best value" tag is allowed, but don't preselect a plan without showing its full price.
3. **Trial timeline (Blinkist-style pattern):** Today: full access → Day 5: we remind you → Day 7: ₦X charged. A reminder is promised and sent (push + email).
4. **Button + fine print:** "Start free 7-day trial", then directly under it "Then ₦X/year. Cancel anytime in Google Play / App Store settings." Restore purchases and Terms are visible. The ✕ is visible from the start (top left, 44 px).
5. **Gift / family:** "Give Plus to someone" (gift code); the family manager sees members.
6. **Kids (under 18 from the pack 1 age data):** show a parental gate (an adult question or the parent's device) before any purchase. No paywall shows on kid profiles until a parent enables it.
7. **After purchase:** Polie celebrates, with "Manage or cancel any time: Profile → Plus". Cancelling takes 2 taps to the store page and shows no guilt screen.
Motion: benefit rows rise in with a 50 ms stagger; the timeline dots fill left to right (600 ms) once. Reduce Motion swaps for fades.
Upgrade for LingAfriq: a "Free forever" promise for the first units of every language, so the paywall never blocks heritage learners.

## Second pass (2026-10-28): real vs pattern-based
- **Real (Duolingo web):** 01 out-of-hearts upsell (Super unlimited hearts / refill with gems), 02 Free vs Super comparison, 03 trial-reminder choice before payment, 04 shop (refill, power-ups, Super banner), 05 choose-a-plan + Super benefits, 06 guest shop overlay, 07 signed-in shop.
- **Real facts (Spotify NG plan page text):** ₦ pricing, intro offer with an end date, "cancel anytime" on every card, and the first full-charge date stated at checkout. See SOURCES.md.
- **Pattern-based:** Super prices (not shown before payment), Headspace / Calm / Finch plan screens (no genuine official images), mobile-money/USSD checkout.
- Recipe fix: (a) always offer a free path (practice to earn hearts, or refill with gems) next to the upgrade; (b) ask about the trial reminder before payment, as in 03; (c) show the first charge date in ₦, as Spotify does.
