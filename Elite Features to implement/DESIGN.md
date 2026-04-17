# Design System Strategy: The Modern Griot

## 1. Overview & Creative North Star
This design system is built upon the **"Modern Griot"** Creative North Star. In West African tradition, the Griot is a storyteller, historian, and weaver of culture. This system translates that oral tradition into a high-end digital editorial experience. 

We move away from the "template" look of modern SaaS by embracing **Organic Asymmetry**. The UI should feel like a curated gallery or a premium travel journal—intentional, warm, and deeply rhythmic. We achieve this through:
*   **Tonal Depth:** Replacing harsh lines with sophisticated color layering.
*   **Editorial Scale:** Using extreme typographic contrast to guide the user’s eye.
*   **Cultural Texture:** Utilizing gradients and organic shapes that mimic the natural flow of African landscapes and textiles.

## 2. Color Philosophy & Semantic Tokens
The palette is a sophisticated blend of earthy ochres, deep forest greens, and sun-drenched terracottas. 

### The "No-Line" Rule
To maintain a premium, bespoke feel, **1px solid borders are strictly prohibited** for sectioning or defining containers. Boundaries must be defined through:
1.  **Background Shifts:** Placing a `surface-container-low` (#f8f0e0) card on a `surface` (#fef6e7) background.
2.  **Tonal Transitions:** Using subtle variations in hue to indicate where one content area ends and another begins.

### Surface Hierarchy & Nesting
Treat the UI as a physical stack of fine papers. 
*   **Base:** `surface` (#fef6e7).
*   **Layer 1 (Nesting):** Use `surface-container` (#f0e7d6) for main content blocks.
*   **Layer 2 (Elevated):** Use `surface-container-lowest` (#ffffff) for high-priority interactive cards to create a "lifted" effect without heavy shadows.

### The "Glass & Gradient" Rule
Flat colors can feel static. To inject "soul" into the interface:
*   **Signature Gradients:** For primary CTAs and Hero sections, transition from `primary` (#9e3d00) to `primary_container` (#ff7a35). This mimics the glow of a setting sun.
*   **Glassmorphism:** For floating navigation or overlays, use `surface` (#fef6e7) at 80% opacity with a `24px` backdrop-blur.

## 3. Typography: The Editorial Voice
We use **Plus Jakarta Sans** for its geometric clarity and contemporary warmth. The hierarchy is designed to feel like a high-end magazine.

*   **Display (lg/md):** Used for "Welcome" states and major landmarks. These should feel authoritative and celebratory.
*   **Headline (lg/md):** Used for section titles. Ensure generous tracking and line height to allow the "Modern Griot" narrative to breathe.
*   **Body (lg/md):** Set in `on_surface_variant` (#605b50) for a softer, more sophisticated read than pure black.
*   **Labels:** Always uppercase with slight letter-spacing when used for categories or status chips (e.g., "BEGINNER").

## 4. Elevation & Depth: Tonal Layering
Traditional material elevation relies on grey shadows. This system uses **Tonal Layering** to create a more organic, sunlight-driven depth.

*   **Layering Principle:** Stack `surface-container-highest` (#e5dcc9) on top of `surface-dim` (#dcd4c0) to create a soft, natural lift.
*   **Ambient Shadows:** If a floating element (like a FAB) requires a shadow, it must be tinted. Use a blur of `30px-40px` with an 8% opacity of the `on_surface` (#322e25) color. It should feel like a soft glow, not a dark drop-shadow.
*   **The "Ghost Border":** For essential accessibility in input fields, use the `outline_variant` (#b3ac9f) at **15% opacity**. This provides a guide without breaking the "No-Line" rule.

## 5. Components

### Buttons
*   **Primary:** High-radius (`full` roundedness). Use the signature gradient (`primary` to `primary_container`). Text is `on_primary` (#fff0ea).
*   **Secondary:** `secondary` (#526124) background with `on_secondary` (#e8fbac) text. Use for secondary actions like "View Progress."
*   **Tertiary:** No background. Bold typography in `primary` (#9e3d00) with a slight `0.5rem` bottom padding shift on hover.

### Cards & Lists
*   **Prohibition:** Never use divider lines.
*   **Spacing:** Separate list items using `1.5rem` of vertical white space or a subtle toggle between `surface-container-low` and `surface-container-high`.
*   **Language Cards:** Use the `xl` (1.5rem) roundedness scale. Content should be bottom-aligned to feel grounded.

### Input Fields
*   **Styling:** Use `surface_container_highest` (#e5dcc9) as a solid background. 
*   **Focus State:** Instead of a thick border, use a `2px` underline in `primary` (#9e3d00) and a soft inner glow.

### Chips (Cultural Markers)
*   Used for difficulty levels (Beginner, Intermediate). 
*   **Style:** `surface_variant` (#e5dcc9) background with `label-md` typography. Use `full` roundedness to create a pill shape.

## 6. Do’s and Don’ts

### Do:
*   **Do** embrace negative space. If a layout feels crowded, increase the padding to the next tier in the spacing scale.
*   **Do** use asymmetrical image placements. Let images of landscapes or cultural patterns "bleed" off the edge of the screen.
*   **Do** use the `secondary` (#526124) green for success states or "growth" related metrics to reinforce the organic theme.

### Don’t:
*   **Don’t** use pure black (#000000) for text. Always use `on_surface` (#322e25) to maintain the warm, high-end tonal balance.
*   **Don’t** use standard `0.5rem` rounded corners for large containers. Go bold with `xl` (1.5rem) to emphasize the organic, friendly nature of the brand.
*   **Don’t** use generic system icons. If icons are required, ensure they have a slightly rounded, hand-drawn, or "weighted" feel that matches Plus Jakarta Sans.