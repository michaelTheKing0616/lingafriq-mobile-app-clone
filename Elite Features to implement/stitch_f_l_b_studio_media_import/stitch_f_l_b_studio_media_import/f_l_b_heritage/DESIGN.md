# Design System Specification: Editorial Heritage & High-Tech Precision

## 1. Overview & Creative North Star: "The Digital Curator"

This design system is built to bridge the gap between ancestral storytelling and futuristic education. Our Creative North Star is **"The Digital Curator."** We are moving away from the "disposable app" aesthetic toward a permanent, high-end editorial experience. 

The system operates on a dual-modality principle:
- **The Archives (Reading/Cultural Content):** Uses a sophisticated, paper-like palette (`surface`) and serif typography to evoke the feeling of a prestige magazine like *Àṣà*.
- **The Studio (Learning/Interactive Tools):** Transitions into deep, high-tech environments (`inverse_surface`) with monospaced accents to provide a focused, "laboratory" feel for language acquisition.

We break the "template" look through **intentional asymmetry**. Headlines are never just centered; they are offset. Content overflows its containers slightly to suggest depth. This is not a flat interface; it is a curated collection of knowledge.

---

## 2. Colors & Surface Philosophy

Our palette is rooted in earth and industry. We utilize the Material 3 tonal system but apply it through a high-end editorial lens.

### The "No-Line" Rule
**Explicit Instruction:** Designers are prohibited from using 1px solid borders to define sections. Boundaries must be defined solely through background color shifts. For example, a `surface_container_low` card sitting on a `surface` background provides all the separation required. If you feel the need for a line, use whitespace (`spacing-8`) instead.

### Surface Hierarchy & Nesting
Treat the UI as a series of physical layers—like stacked sheets of fine parchment or slabs of polished indigo stone.
- **Lowest Tier:** `surface_container_lowest` (#ffffff) – Used for the most elevated interactive elements.
- **Base Tier:** `surface` (#fcf9f2) – The "Paper" foundation for all reading sections.
- **High Tier:** `surface_container_high` (#ebe8e1) – Used for recessed decorative elements or secondary groupings.

### The "Glass & Gradient" Rule
To avoid a "flat" digital feel, use **Glassmorphism** for floating navigation bars or modal headers. Use `surface_tint` at 10% opacity with a 20px backdrop blur. 
**Signature Texture:** Main Call-to-Action (CTA) elements should use a subtle linear gradient from `primary` (#9f3e07) to `primary_container` (#c05621) at a 135-degree angle to provide a "Terracotta" sheen.

---

### 3. Typography: The Intellectual Dialogue

The typography system is a conversation between the organic (`newsreader`) and the technical (`spaceGrotesk` & `manrope`).

| Level | Token | Font Family | Size | Intent |
| :--- | :--- | :--- | :--- | :--- |
| **Display** | `display-lg` | Newsreader | 3.5rem | High-impact cultural headlines. |
| **Headline** | `headline-md` | Newsreader | 1.75rem | Section headers in "The Archives." |
| **Title** | `title-lg` | Manrope | 1.375rem | Bold, authoritative functional labels. |
| **Body** | `body-lg` | Manrope | 1rem | Highly legible reading text. |
| **Label** | `label-md` | Space Grotesk | 0.75rem | "Studio" data, counters, and technical tags. |

**Editorial Note:** Use `newsreader` for any text that carries cultural weight or storytelling. Use `spaceGrotesk` for anything that implies progress, data, or navigation.

---

## 4. Elevation & Depth: Tonal Layering

Traditional drop shadows are too "software-standard." We achieve depth through **Tonal Layering**.

- **The Layering Principle:** Place a `surface_container_lowest` card on a `surface_container_low` section. The slight shift in hex code creates a soft, natural lift that feels like physical paper stacking.
- **Ambient Shadows:** If a floating effect is mandatory (e.g., a FAB), use an extra-diffused shadow: `box-shadow: 0 20px 40px rgba(28, 28, 24, 0.06);`. The shadow color must be a tinted version of `on_surface` (#1c1c18), never pure black.
- **The "Ghost Border" Fallback:** If accessibility requires a border, use `outline_variant` at 15% opacity. High-contrast, 100% opaque borders are strictly forbidden.

---

## 5. Components

### Buttons: The Tactile Command
- **Primary:** No rounded corners—use `rounded-sm` (0.125rem). Fill with the Terracotta gradient. Text is `label-md` in uppercase with 0.05em tracking.
- **Secondary:** Transparent background with a "Ghost Border" of `outline`.
- **Tertiary:** Text only, using `tertiary` (#735c00) to draw the eye to "Sand/Gold" accents.

### Cards & Lists: The No-Divider Rule
- **Cards:** Forbid the use of divider lines. Separate list items using `spacing-4` (1.4rem) of vertical whitespace. 
- **The "High-Tech" List:** In the Studio section, list items should use `surface_dim` backgrounds with `label-sm` (Space Grotesk) prefixes to denote lesson numbers (e.g., 01, 02, 03).

### Inputs: The Sophisticated Form
- **Text Fields:** Use "Bottom-Line-Only" styling for a minimalist, editorial feel. When focused, the line transitions from `outline` to `primary` (#9f3e07) with a 2px thickness.
- **Selection Chips:** Use `secondary_container` (#d6e0f6) with `rounded-full` for a "pill" look that contrasts against the sharp-edged buttons.

### Specialized App Components
- **The Audio Weaver:** A bespoke audio player for pronunciations. Use a `surface_container_highest` background with a waveform rendered in `primary`. No "Play" button—instead, the entire container is a trigger, changing to `tertiary_container` on tap.
- **The "Àṣà" Header:** A sticky top navigation that uses Glassmorphism (backdrop-blur 16px) and transitions from `surface` (Reading mode) to `inverse_surface` (Studio mode) as the user enters interactive drills.

---

## 6. Do's and Don'ts

### Do:
- **Use "Signature Whitespace":** Use `spacing-12` (4rem) between major sections to let the typography breathe.
- **Mix Typefaces:** Place a `label-sm` (Space Grotesk) technical tag directly above a `display-sm` (Newsreader) headline.
- **Embrace Asymmetry:** Align descriptions to the right while headlines stay left to create a "grid-breaking" editorial look.

### Don't:
- **Don't use 1px dividers.** Use background tonal shifts or whitespace.
- **Don't use standard icons.** Use custom, thin-stroke (1px) icons that match the `outline` weight.
- **Don't use vibrant "app-store" blues or greens.** Stick to the muted, earthy `secondary` (#555f71) and `tertiary` (#735c00) tones.
- **Don't use high-radius corners.** Except for Chips, keep corners at `rounded-sm` or `none` to maintain a premium, architectural feel.