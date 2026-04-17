```markdown
# Design System Specification: Modern Heritage

## 1. Overview & Creative North Star
The Creative North Star for this design system is **"The Digital Griot."** Much like a traditional storyteller who preserves history while adapting to the present, this system balances academic precision with celebratory warmth. 

We move beyond the "template" look by rejecting rigid, boxy grids in favor of **Intentional Editorial Asymmetry**. The layout should feel like a high-end curated journal—using overlapping elements, staggered card placements, and significant shifts in typographic scale to create a rhythmic, melodic flow. This is not a utility-first interface; it is a culturally rich experience where negative space is as communicative as the content itself.

---

## 2. Colors & Surface Architecture
Our palette is rooted in the earth (Terracotta, Ochre) and the infinite (Deep Indigo), polished with the prestige of Emerald and Gold.

### The "No-Line" Rule
**Strict Mandate:** 1px solid borders are prohibited for sectioning or containment. 
Boundaries must be defined through:
1.  **Background Color Shifts:** A `surface-container-low` section sitting against a `surface` background.
2.  **Tonal Transitions:** Using the depth of the Indigo (`primary`) to transition into `primary-container`.

### Surface Hierarchy & Nesting
Treat the UI as a series of physical layers—like stacked sheets of fine, handmade paper. 
- **Base:** `surface` (#fafaf5)
- **Secondary Level:** `surface-container-low` (#f4f4ef)
- **Action/Focus Level:** `surface-container-highest` (#e3e3de)

### Glass & Gradient Signature
To avoid a flat "Material" feel, use **Atmospheric Gradients** for hero sections and CTAs, transitioning from `primary` (#333697) to `primary-container` (#4b4fb0). 
- **Glassmorphism:** For floating navigation or modal overlays, use semi-transparent `surface` colors with a `backdrop-blur` of 12px-20px. This allows the richness of the background textiles to bleed through, softening the interface.

---

## 3. Typography: The Editorial Voice
We pair the geometric clarity of **Plus Jakarta Sans** with the hand-crafted, high-contrast soul of **Epilogue**.

*   **Display & Headlines (Epilogue):** These are our "expressive" moments. Use `display-lg` (3.5rem) with tight letter-spacing (-0.02em) to create an authoritative, academic presence.
*   **Body & Labels (Plus Jakarta Sans):** Reserved for high-readability tasks. The generous x-height of Jakarta ensures that even at `body-sm`, the information feels accessible.

**Hierarchy Strategy:** 
Always pair a `display-md` headline in `secondary` (Terracotta) with `label-md` uppercase text in `tertiary` (Ochre) to create a sophisticated, multi-tonal typographic block.

---

## 4. Elevation & Depth
In this system, depth is a feeling, not a drop-shadow effect.

*   **Tonal Layering:** Achieve hierarchy by "stacking" tiers. A `surface-container-lowest` card placed on a `surface-container-low` background creates a natural, soft lift.
*   **Ambient Shadows:** When a physical lift is required (e.g., a primary action card), use a shadow with a blur radius of 32px and 4% opacity, tinted with the `on-surface` color. Never use pure black shadows.
*   **The Ghost Border:** If accessibility requires a stroke, use `outline-variant` at 15% opacity. It should be felt, not seen.
*   **Textural Depth:** Integrate subtle SVG patterns (Kente/Adinkra) into `surface-variant` containers at 5% opacity. These should act as "watermarks" of heritage rather than distracting patterns.

---

## 5. Component Logic

### Cards & Collections
*   **Constraint:** Forbid divider lines.
*   **Solution:** Use the **Spacing Scale `6` (2rem)** to separate content blocks. 
*   **Styling:** Apply `DEFAULT` (0.5rem) or `lg` (1rem) roundedness. Cards should use `surface-container-low` backgrounds to distinguish themselves from the main `surface`.

### Buttons (The "Heritage" CTA)
*   **Primary:** `primary` background with `on-primary` text. Use `xl` (1.5rem) rounding for a modern, friendly feel.
*   **Secondary:** `secondary` background (Terracotta) for cultural actions (e.g., "Explore History").
*   **Tertiary:** No background; `primary` text with an `underline` that uses the `tertiary` (Gold) color at 3px thickness.

### Inputs & Fields
*   **Style:** Filled states using `surface-container-high`. 
*   **Focus State:** Instead of a heavy border, use a 2px bottom-border in `tertiary` (Gold) and a subtle `primary` tint to the background.

### Expressive Components (The "Artifact" Chip)
*   **Chips:** Used for filtering "Eras" or "Regions." These should use `secondary-container` with `on-secondary-container` text, utilizing the `full` (9999px) roundedness scale.

---

## 6. Do’s and Don’ts

### Do:
*   **Do** overlap an image over a background textile pattern to create a sense of three-dimensional layers.
*   **Do** use `tertiary` (Ochre/Gold) as a highlight for academic "notes" or "citations."
*   **Do** embrace asymmetry. It is acceptable for a right-hand column to be offset from the left-hand hero text.

### Don’t:
*   **Don’t** use pure black (#000000) for text. Use `on-surface` (#1a1c19) to maintain the "Modern Heritage" warmth.
*   **Don’t** use standard 1px dividers. If you need to separate content, use a color-block or a 24px vertical gap.
*   **Don’t** crowd the patterns. If a textile texture is used, the surrounding 100px must be free of competing icons or complex illustrations.

---

## 7. Spacing & Rhythm
We follow a 0.7rem-base grid (using the provided Spacing Scale). 

*   **Section Padding:** Use `16` (5.5rem) for vertical breathing room between major editorial blocks.
*   **Component Padding:** Use `4` (1.4rem) for internal card padding to ensure a "Premium" sense of space.
*   **Micro-spacing:** Use `1.5` (0.5rem) for relating labels to their parent inputs.

This system is designed to feel curated, not automated. Use the tokens as your palette, but use the "Digital Griot" philosophy as your guide.```