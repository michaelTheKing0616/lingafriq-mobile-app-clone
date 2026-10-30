# Guardian approvals — reference
_Goal: Approve/deny a child's contact, classroom-join or circle request. Built 2026-10-30. Inspired by patterns only: never copy logos, art, copy or code._

**Real captures:** 4 (see SOURCES.md).

## Recipe
1. Request card: child avatar+name, **what** (contact / class / circle), **who** (requester display name, school or circle, member count, how they're connected), when (WAT).
2. Context block: "Why you're seeing this", e.g. "Ada wants to join *JSS2 Yoruba* by Mrs. A. (teacher, verified school)".
3. Actions: **Approve** · **Deny** · *Not now*; an optional note to the child.
4. Footer: "You're approving as **[guardian name] (Parent)**". Show other guardians and who already decided.
5. Result: a toast plus an audit row ("Approved by Mum · 10:42 WAT · this phone").
## Upgrades over refs
- One-tap from the push notification, with biometric/PIN confirmation for the decision (shared phones).
- A first-decision-wins rule with live "Dad already approved" state; expiry ("expires in 7 days").
- A reason picker on Deny, with gentle child-facing copy (no blame).

## States (pattern-based unless a numbered shot shows it)
- **Loading:** skeleton rows at the final height; no spinner-only screens.
- **Empty:** one line explaining why the list is empty, plus one primary action.
- **Error:** inline banner with Retry; keep the last good data visible.
- **Offline:** "Saved offline — will send when you're back online" chip. Queue the decision locally and mark it *Pending sync*. Never show an approval as done before the server confirms it.
## RTL / Arabic + 200% text
- Mirror the layout and chevrons; status pills sit at the leading edge; keep numerals/codes LTR (`<bdi>`). Use Noto Sans Arabic at +2sp with line-height 1.6.
- At 200%: rows wrap to two lines and the actions stack vertically. Targets ≥48dp. No truncated names/reasons; put the timestamp below the text.
## Type & colour
Nunito 700/800 for titles, Noto Sans 400/600 for body, Noto Sans Arabic (typography/SPEC.md). Navy `0xFF2E3A87` is for primary actions and the selected state. Approve = navy filled, Deny = outlined (never red-vs-green alone; always add a label and an icon).

## Nigeria / child-safety (checked live 2026-10-30)
- NDPA 2023 s.31 (cert.gov.ng Act PDF; ndpc.gov.ng/ndp-act-2023): for a child, the controller must get **parent/legal-guardian consent** and use appropriate **age and consent verification**. Government-approved ID counts as appropriate. Education processing by a professional with a duty of confidentiality is exempt from s.31(1). For ages 13+, the NDPC has still to make regulations. Under the NDPA a child is anyone **under 18** (Aluko & Oyebode summary).
- NDPC GAID 2025 Art.18: consent is required to process a child's personal data. Log who approved, when and on which device (an audit trail).
- Design for shared family phones, intermittent data/power and low-end Android. Keep approvals small (no media autoload). Use WAT (UTC+1) timestamps. Write copy that a parent with English as a second language can read, and leave room for Yorùbá/Hausa/Igbo strings.
