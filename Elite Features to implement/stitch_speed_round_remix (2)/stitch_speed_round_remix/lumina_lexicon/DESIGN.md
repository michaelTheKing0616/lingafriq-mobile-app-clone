# Design System Strategy: The Polyglot Atelier

## 1. Overview & Creative North Star
The Creative North Star for this design system is **"The Academic Playground."** 

We are rejecting the cluttered, childish aesthetic of traditional gamified apps in favor of a "High-End Editorial" experience. This system balances the precision of a premium fintech dashboard with the soul and vibrancy of a world-class educational institution. We achieve this through **intentional asymmetry**, where content isn't just "placed" but "curated." By utilizing large-scale typography and overlapping "floating" containers, we create a sense of rhythmic movement that guides the learner’s eye through complex linguistic data with ease.

## 2. Colors: Tonal Depth & Vibrancy
Our palette is rooted in a deep Indigo (`primary`) to establish authority, balanced by a fresh Teal (`secondary`) and warm Amber/Coral (`tertiary`) to inject energy.

### The "No-Line" Rule
**Strict Mandate:** Prohibit the use of 1px solid borders for sectioning content. To define boundaries, you must use background color shifts. For example, a `surface-container-low` section should sit directly on a `background` surface. If a boundary feels "lost," increase the contrast between the surface tiers rather than adding a stroke.

### Surface Hierarchy & Nesting
Treat the UI as a physical stack of fine paper.
- **Base Layer:** `surface` (#f8f9fa)
- **Content Blocks:** `surface-container-low` (#f3f4f5)
- **Interactive Cards:** `surface-container-lowest` (#ffffff) to provide a "pop" against the background.
- **Active States:** Use `primary-fixed` (#dee1ff) for subtle highlighting within a container.

### The "Glass & Gradient" Rule
To avoid a flat "template" look, utilize **Glassmorphism** for navigation bars and floating action buttons. Apply a `surface` color at 80% opacity with a `20px` backdrop blur. 
**Signature Texture:** Main CTAs and Progress Hero cards should use a linear gradient: `primary` (#002fbb) to `primary-container` (#284ad8) at a 135° angle. This adds "visual soul" and depth that flat hex codes cannot replicate.

## 3. Typography: Editorial Authority
We utilize a dual-font strategy to balance character with readability.

*   **Display & Headlines (Plus Jakarta Sans):** Used for "Hero" moments, level headers, and achievement screens. The wide apertures of Plus Jakarta Sans provide a modern, high-end feel.
    *   *Example:* `display-md` for "Daily Streak" counters.
*   **Body & Titles (Inter):** The workhorse for the actual learning content. Its high x-height ensures maximum legibility during intense focus sessions.
    *   *Example:* `body-lg` for translated text strings.

**The Hierarchy Rule:** Never use two font sizes that are adjacent in the scale (e.g., don't put `title-md` next to `title-sm`). Jump at least two levels to create a clear, editorial "stagger" that feels intentional.

## 4. Elevation & Depth
We convey importance through **Tonal Layering** rather than structural scaffolding.

### The Layering Principle
Depth is achieved by "stacking" surface tiers. Place a `surface-container-lowest` card on a `surface-container-low` section. This creates a soft, organic lift that feels premium and tactile.

### Ambient Shadows
Shadows must feel like light passing through glass, not heavy ink. 
- **Token:** `Shadow-Lg`
- **Specs:** Blur: 24px, Spread: -4px, Opacity: 6% of `on-surface` (#191c1d).
- **Tinting:** Always tint your shadows with the primary hue (Indigo) to ensure the "black" doesn't muddy the vibrant palette.

### The "Ghost Border" Fallback
If accessibility requires a container definition, use a "Ghost Border": `outline-variant` (#c5c5d4) at **15% opacity**. 100% opaque borders are strictly forbidden as they interrupt the visual flow.

## 5. Components: Gamified Precision

### Buttons
*   **Primary:** Indigo Gradient (Primary to Primary-Container), `xl` (1.5rem) roundedness. No border.
*   **Secondary:** Teal (`secondary`) text on `secondary-container` (#70f8e8) background.
*   **Interaction:** On tap, the button should scale down to 96% and increase shadow diffusion to simulate physical "pressing."

### Rhythmic Progress Bars
*   **Track:** `surface-container-highest` (#e1e3e4).
*   **Indicator:** Gradient of `secondary` to `secondary-fixed-dim`. 
*   **UX Detail:** The indicator should have a "pulse" glow using a soft shadow of its own color to show the "active" lesson progress.

### Gamified Learning Cards
*   **Layout:** Forbid divider lines. Use `1.4rem` (`spacing-4`) of vertical white space to separate the native word from the translation.
*   **Selection State:** Instead of a checkbox, use a `2px` "Ghost Border" that transitions to `primary` (#002fbb) and shifts the card background to `primary-fixed`.

### Sleek Modal Overlays
*   **Style:** Partial-height bottom sheets with `xl` (1.5rem) top-radius. 
*   **Blur:** Background dimming must use a blur effect (`10px`) rather than just a dark grey overlay to maintain the "Glassmorphism" theme.

## 6. Do's and Don'ts

### Do
*   **Do** use `spacing-10` (3.5rem) or higher for top-of-page padding to give the "High-End" feel room to breathe.
*   **Do** use `tertiary` (Amber/Coral) exclusively for "Delight" moments—streaks, gems, and rewards.
*   **Do** favor asymmetric icon placement (e.g., an icon slightly overlapping the edge of a card) to break the "fintech" rigidity.

### Don't
*   **Don't** use 100% black (#000000) for text. Always use `on-surface` (#191c1d) to keep the contrast "expensive" and soft.
*   **Don't** use standard Material dividers. If you need a separator, use a `surface-variant` horizontal rule at 30% opacity, or preferably, more white space.
*   **Don't** use "bounce" animations. Use "decelerated" or "standard" cubic-bezier curves for a more professional, sleek feel.