# Design System Specification: The Digital Earth & Sky

## 1. Overview & Creative North Star
**Creative North Star: "The Modern Griot"**
The design system moves away from the sterile, clinical feel of Western EdTech. Instead, it embraces "The Modern Griot"—a philosophy that blends ancestral storytelling with futuristic digital precision. We break the "template" look by using **Organic Asymmetry**: layouts should feel like a communal gathering, where elements overlap naturally like woven textiles, rather than sitting in rigid, isolated boxes. High-contrast typography scales and intentional "breathing room" transform the app from a tool into a cultural destination.

## 2. Colors
Our palette is rooted in the soil and elevated by the sun. We utilize a tonal layering system to define hierarchy without ever resorting to "walls" or lines.

### The "No-Line" Rule
**Explicit Instruction:** Do not use 1px solid borders to section content. Boundaries must be defined solely through background color shifts. For example, a `surface-container-low` card sitting on a `surface` background provides all the definition a user needs.

### Surface Hierarchy & Nesting
Treat the UI as a series of physical layers—stacked sheets of fine, hand-pressed paper.
- **Base:** `surface` (#fff8f5)
- **Secondary Content:** `surface-container-low` (#fff1e8)
- **Interactive Cards:** `surface-container` (#ffeada)
- **High-Emphasis Pop-ups:** `surface-container-highest` (#ffdcbf)

### The "Glass & Gradient" Rule
To inject "soul" into the interface, use **Glassmorphism** for floating action buttons and navigation bars. Use semi-transparent versions of `primary` (#a73400) with a `backdrop-blur` of 20px. 
- **Signature Textures:** For Hero sections or primary CTAs, apply a subtle linear gradient from `primary` (#a73400) to `primary-container` (#c94c1a) at a 135-degree angle.

## 3. Typography
We utilize a dual-typeface strategy to balance modern clarity with rhythmic personality.

*   **Display & Headlines (Plus Jakarta Sans):** Used for big moments. The wide apertures and modern geometric feel provide an authoritative, "Editorial" look.
    *   *Headline-LG (2rem):* For village names and major milestones.
*   **Body & Titles (Lexend/Dosis):** 'Dosis' provides the friendly, rounded character requested for the brand, while 'Lexend' (per the spec scale) ensures maximum readability for language learners.
    *   *Title-MD (1.125rem):* For vocabulary terms.
    *   *Body-MD (0.875rem):* For translations and descriptions.

The typography hierarchy conveys the brand identity by using extreme scale—pairing a massive `display-lg` headline with a quiet `label-md` metadata tag to create a sense of premium intentionality.

## 4. Elevation & Depth
Depth is achieved through **Tonal Layering**, not structural shadows.

*   **The Layering Principle:** Stack `surface-container-lowest` cards on `surface-container-low` backgrounds. This creates a soft, natural lift.
*   **Ambient Shadows:** For floating elements (like Tribe Totems), use an extra-diffused shadow: `offset: 0 20px, blur: 40px, color: rgba(45, 22, 0, 0.06)`. The tint is a dark version of the surface color, never pure grey.
*   **The "Ghost Border" Fallback:** If a container needs extra definition (e.g., in Dark Mode), use the `outline-variant` token (#e0bfb5) at **15% opacity**. 100% opaque borders are strictly forbidden.

## 5. Components

### Message Bubbles (Social Modes)
*   **Private (WhatsApp Style):** Use `secondary-container` (#7cf994) for outgoing and `surface-container-highest` for incoming. Use `DEFAULT` (1rem) roundedness, but sharpen the corner pointing toward the user's avatar to 0.25rem.
*   **Global (X Style):** Use a "Glass" effect. Semi-transparent `surface-container` with a `secondary` (#006e2d) left-accent bar for threaded conversations. No borders.

### Audio Room Speaker Cards
*   **The "Spaces" Layout:** Cards use `surface-container-high`. The active speaker is indicated by a 3px "pulsing" glow of `tertiary` (#7b5500) rather than a solid ring. Use `lg` (2rem) roundedness for a friendly, communal feel.

### Tribe Totems & Badges
*   **Visual Identity:** These are the only elements allowed to break the grid. Totems should use `tertiary-fixed` (#ffdeab) and overlap the edges of their parent containers.
*   **Badges:** Use `Gold` (#C8922A) as a background for high-tier achievements, paired with `on-tertiary-fixed` text.

### Interactive Map Elements (The Village)
*   **The Village Path:** Use a custom-shaped SVG path using `outline-variant` as a guide. Interactive buildings (Learning Nodes) use `surface-container-lowest` with a high ambient shadow to appear "raised" from the earth.

### Learning-Specific UI
*   **Vocabulary Cards:** Massive `headline-sm` text. Use `surface-bright` backgrounds. No dividers; separate the word from the translation using a `spacing-8` (2rem) vertical gap.
*   **Exercise Blocks:** Selection states use `primary-fixed` (#ffdbcf). Success states use `secondary-fixed` (#7ffc97) with a subtle haptic-like bounce animation.

## 6. Do's and Don'ts

### Do:
*   **Use Asymmetry:** Place images or totems slightly off-center or overlapping container edges to create a "woven" feel.
*   **Embrace Negative Space:** Use `spacing-12` or `spacing-16` between major sections to let the "Editorial" typography breathe.
*   **Use Tonal Shifts:** If a button feels lost, change the background of the section to `surface-container-low` instead of adding a border to the button.

### Don't:
*   **Don't use 1px Borders:** Never use a solid line to separate a list item or a header.
*   **Don't use Pure Grey Shadows:** Always tint shadows with a hint of the Earthy/Orange brand tones to keep the UI "warm."
*   **Don't use Standard Grids:** Avoid the "3-column card row" look. Try 1.5 columns where the second card is partially cut off to encourage horizontal exploration.