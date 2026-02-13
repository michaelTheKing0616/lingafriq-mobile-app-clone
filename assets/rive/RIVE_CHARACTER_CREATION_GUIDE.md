# Rive Character Creation Guide -- LingAfriq

Complete step-by-step instructions for creating all 13 avatar `.riv` files
using the free Rive editor. No animator required. No paid plan required.

---

## Table of Contents

1. [Setup](#1-setup)
2. [Understanding the Flutter Integration](#2-understanding-the-flutter-integration)
3. [Building the BASE_RIG](#3-building-the-base_rig)
4. [Creating Animations](#4-creating-animations)
5. [Wiring the State Machine](#5-wiring-the-state-machine)
6. [Per-Character Spec Sheets](#6-per-character-spec-sheets)
7. [Exporting and Placing Files](#7-exporting-and-placing-files)
8. [Testing Checklist](#8-testing-checklist)
9. [Performance Guidelines](#9-performance-guidelines)
10. [Troubleshooting](#10-troubleshooting)

---

## 1. Setup

### 1.1 Create a Free Rive Account

1. Go to https://rive.app
2. Click "Get Started" (top right)
3. Sign up with Google or email -- the free plan is sufficient
4. You get: unlimited files, state machines, and exports

### 1.2 Install Rive Desktop (Optional but Recommended)

- Download from https://rive.app/downloads
- Desktop version is faster and works offline
- Web editor works fine if you prefer it

### 1.3 Orientation -- Rive Editor Layout

When you open a new file, you see:

```
+---------------------------------------------------+
|  TOOLBAR (top)                                     |
|  Shape tools, pen tool, bone tool, etc.            |
+----------+------------------------+---------------+
|          |                        |               |
| HIERARCHY|    STAGE / CANVAS      | INSPECTOR     |
| (left)   |    (center)            | (right)       |
| Layers   |    Where you draw      | Properties    |
| Groups   |    and see the         | Colors        |
| Bones    |    character            | Transforms    |
|          |                        |               |
+----------+------------------------+---------------+
|  TIMELINE (bottom)                                 |
|  Animations and state machine editor               |
+---------------------------------------------------+
```

Key concepts:
- **Artboard**: The canvas your character lives on (like a frame)
- **Hierarchy**: Tree of shapes, groups, and bones (left panel)
- **Timeline**: Where you create animation keyframes (bottom panel)
- **State Machine**: Visual graph that controls which animation plays when
- **Inputs**: Variables that Flutter sends to control the state machine

---

## 2. Understanding the Flutter Integration

### 2.1 How Flutter Loads Your Files

The app loads `.riv` files from `assets/rive/avatars/`. The code in
`lib/avatars/avatar_engine.dart` does the following:

1. Loads the `.riv` file from the asset path
2. Gets the **main artboard** (the default/first artboard in the file)
3. Finds the **first state machine** on that artboard
4. Iterates over all **inputs** on that state machine
5. Binds to inputs **by name** (exact string match, case-sensitive)

This means:
- Your state machine can have ANY name (the code uses the first one found)
- Your input names must match EXACTLY (see section 5)
- You should have only ONE artboard per file (it uses the main artboard)
- You should have only ONE state machine per artboard

### 2.2 Required Files (Exact Filenames)

Place all files in `assets/rive/avatars/`. These filenames are
hardcoded in `AvatarAssets.getAssetPath()`:

| # | Filename                | Character          | Role                |
|---|-------------------------|--------------------|---------------------|
| 1 | `elder.riv`             | Pa LingAfriq       | Village Elder       |
| 2 | `weaver.riv`            | Adisa              | The Weaver          |
| 3 | `pathfinder.riv`        | Zuri               | The Pathfinder      |
| 4 | `timekeeper.riv`        | Kofi               | The Timekeeper      |
| 5 | `griot.riv`             | Amara              | The Griot           |
| 6 | `rhythm_master.riv`     | Nuru               | Rhythm Master       |
| 7 | `malaika.riv`           | Malaika            | Vocabulary Guide    |
| 8 | `baba.riv`              | Baba               | Cultural Elder      |
| 9 | `okonkwo.riv`           | Okonkwo            | Tone Master         |
|10 | `nneka.riv`             | Nneka              | Grammar Teacher     |
|11 | `polie_avatar.riv`      | Polie              | AI Companion        |
|12 | `user_avatar_base.riv`  | User Custom        | Player Avatar       |
|13 | `game_guide.riv`        | Generic Guide      | Fallback Character  |

**Start with `game_guide.riv`** -- it is the fallback used when any other
character file is missing. Build it first.

### 2.3 State Machine Inputs (EXACT Names)

The Flutter code binds to these inputs by exact string name. If you misspell
them, the input will silently be ignored (no crash, but no animation).

**Boolean Inputs (2):**

| Input Name     | Type | Purpose                                    |
|----------------|------|--------------------------------------------|
| `isSpeaking`   | Bool | True while character is talking             |
| `isListening`  | Bool | True while character is listening to user   |

**Number Inputs (6):**

| Input Name      | Type   | Range    | Purpose                                       |
|-----------------|--------|----------|-----------------------------------------------|
| `emotion`       | Number | 0-18     | Emotion state (see emotion table below)        |
| `confidence`    | Number | 0.0-1.0  | How confident the character appears            |
| `energy`        | Number | 0.0-1.0  | Animation speed/intensity multiplier           |
| `mouthOpenness` | Number | 0.0-1.0  | Lip sync: how open the mouth is                |
| `lipRounding`   | Number | 0.0-1.0  | Lip sync: how rounded the lips are             |
| `mouthShape`    | Number | 0-8      | Lip sync: viseme shape index                   |

**Trigger Inputs (3):**

| Input Name  | Type    | Purpose                           |
|-------------|---------|-----------------------------------|
| `celebrate` | Trigger | Fire once to play celebration      |
| `wave`      | Trigger | Fire once to play wave greeting    |
| `nod`       | Trigger | Fire once to play approval nod     |

### 2.4 Emotion Values

The `emotion` input receives a number representing the current emotion.
These map to the `AvatarEmotion` enum indices:

| Value | Emotion       | Visual Expression                          |
|-------|---------------|--------------------------------------------|
| 0     | idle          | Neutral, relaxed, gentle breathing          |
| 1     | thinking      | Hand to chin, eyes up-left                  |
| 2     | encouraging   | Warm smile, slight lean forward             |
| 3     | proud         | Big smile, chest up, slight glow            |
| 4     | disappointed  | Slight frown, gentle head tilt down         |
| 5     | happy         | Wide smile, bright eyes                     |
| 6     | excited       | Big smile, bouncy, wide eyes               |
| 7     | curious       | Head tilt, raised brow, leaning forward     |
| 8     | focused       | Narrowed eyes, still body                   |
| 9     | sleepy        | Half-closed eyes, slow blinks               |
| 10    | celebrating   | Arms up, huge smile, bounce                 |
| 11    | empathetic    | Soft eyes, gentle nod, slight lean          |
| 12    | playful       | Wink or smirk, bouncy                       |
| 13    | listening     | Attentive eyes, slight head tilt            |
| 14    | speaking      | Mouth movement, expressive brows            |
| 15    | surprised     | Wide eyes, raised brows, open mouth         |
| 16    | confused      | Furrowed brow, head tilt, squint            |
| 17    | determined    | Set jaw, focused eyes, forward lean         |
| 18    | relieved      | Exhale, relaxed shoulders, soft smile       |

**Practical tip:** You do NOT need to animate all 19 emotions at first.
Start with these 6 core emotions (0-5) and add more later:
- idle (0), thinking (1), encouraging (2), proud (3), disappointed (4), happy (5)

The state machine can map ranges: 0 = idle, 1-2 = thinking/encouraging,
3-5 = positive reactions. Remaining values fall back to the nearest state.

---

## 3. Building the BASE_RIG

You will build ONE base character, then duplicate and re-skin it 12 times.
This section creates the template.

### 3.1 Create a New File

1. In Rive, click **New File** (or File > New)
2. Name it `base_rig_template` (this is your working file, not exported)
3. Set artboard size: **256 x 256 pixels**
   - Click the artboard name in the hierarchy
   - In the Inspector (right panel), set Width: 256, Height: 256
   - This is optimal for mobile: small enough for performance, large enough for detail

### 3.2 Layer/Hierarchy Structure

Build this exact hierarchy. In Rive, use **Groups** to organize layers.
Right-click in the hierarchy panel to create groups, then add shapes inside.

```
Character (Group)
  Head (Group)
    Face (Ellipse -- the head shape)
    Eyes (Group)
      LeftEye (Ellipse -- small, dark)
      RightEye (Ellipse -- small, dark)
      LeftEyeHighlight (Ellipse -- tiny white dot on each eye)
      RightEyeHighlight (Ellipse -- tiny white dot on each eye)
    Mouth (Group)
      MouthNeutral (Path -- slight curve, default visible)
      MouthSmile (Path -- wider upward curve, default hidden)
      MouthOpen (Ellipse -- small vertical oval, default hidden)
    Brows (Group)
      LeftBrow (Path -- short curved line above left eye)
      RightBrow (Path -- short curved line above right eye)
    Headwear (Group -- leave empty, used per-character)
  Body (Group)
    Torso (Rounded Rectangle -- character's body/clothing)
    LeftArm (Group)
      UpperArm (Rounded Rectangle -- rotates from shoulder)
      Hand (Ellipse -- at end of arm)
    RightArm (Group)
      UpperArm (Rounded Rectangle -- rotates from shoulder)
      Hand (Ellipse -- at end of arm)
  Outfit (Group -- overlays on torso, customized per character)
  Accessories (Group -- leave empty, used per-character)
  Shadow (Ellipse -- below character, low opacity gray)
```

### 3.3 Drawing the Character Step-by-Step

**Step 1: The Head**

1. Select the **Ellipse** tool (press O)
2. Draw an ellipse roughly 90px wide, 100px tall, centered at top of artboard
3. Set fill color to a placeholder skin tone (e.g., `#8B6914`)
4. No stroke needed (flat style)
5. Name this layer `Face` in the hierarchy

**Step 2: The Eyes**

1. Create a Group called `Eyes`
2. Draw two small ellipses (12x14px each) inside, positioned as eyes
3. Fill: dark brown or black (`#1A1A2E`)
4. Add two tiny white ellipses (3x3px) as highlight dots -- position
   at top-right of each eye (gives life to the character)

**Step 3: The Mouth**

1. Create a Group called `Mouth`
2. Use the **Pen** tool (press P) to draw three mouth shapes:
   - `MouthNeutral`: A gentle curved line (like a relaxed smile)
   - `MouthSmile`: A wider, more upward curve
   - `MouthOpen`: Use an ellipse, 15x20px, vertical orientation
3. Set `MouthSmile` and `MouthOpen` opacity to 0% (hidden by default)
4. During animations, you toggle visibility between these shapes

**Step 4: The Brows**

1. Create a Group called `Brows`
2. Use the **Pen** tool to draw two short curved lines above the eyes
3. Stroke: 2-3px, dark color matching the hair/skin
4. No fill

**Step 5: The Body**

1. Draw a rounded rectangle for the torso, roughly 80px wide, 80px tall
2. Position below the head with slight overlap
3. Fill with a placeholder outfit color (e.g., blue `#2980B9`)

**Step 6: The Arms**

1. For each arm, create a rounded rectangle (~15x40px)
2. Position at the sides of the torso
3. The pivot point (rotation origin) should be at the top (shoulder)
   - Select the arm shape
   - In the Inspector, adjust the origin point to the top-center
4. Add a small ellipse at the bottom of each arm for hands

**Step 7: The Shadow**

1. Draw a horizontal ellipse below the character (~70x15px)
2. Fill: black at 10-15% opacity
3. This grounds the character visually

### 3.4 Adding Bones (Optional but Recommended)

Bones let you rotate body parts smoothly. For a simple character:

1. Select the **Bone** tool (press B)
2. Create bones for:
   - **HeadBone**: From neck to top of head (controls head tilt)
   - **BodyBone**: From bottom of torso to neck (controls body sway)
   - **LeftArmBone**: From shoulder to hand
   - **RightArmBone**: From shoulder to hand
3. **Bind** each shape to its bone:
   - Select the shape (e.g., Head group)
   - In the Inspector, find "Bind" and select the HeadBone
4. Now rotating the bone rotates the entire head group

**If bones feel complex**, skip them. You can animate by directly
keyframing position/rotation on the groups. Bones just make it smoother.

### 3.5 Key Proportions

Keep characters **chibi-style** (cute, simplified proportions):

```
+--------+
| 256px  |
|        |
|  HEAD  |  ~40% of height (large head = friendly, approachable)
|  ----  |
|  BODY  |  ~35% of height
|  ARMS  |  ~attached to sides of body
| SHADOW |  ~5% of height, at bottom
+--------+
  256px
```

---

## 4. Creating Animations

### 4.1 How Animations Work in Rive

1. At the bottom of the screen, you see the **Timeline** panel
2. Click the **+** button next to "Animations" to create a new animation
3. Name it exactly as specified below
4. Set the animation as **Looping** or **One-Shot** as noted
5. Move the playhead to different times and set **keyframes** by changing
   properties (position, rotation, opacity, scale)

### 4.2 Animation List (Create All of These)

Create these animations on your base rig. Name them EXACTLY as shown.

---

**Animation: `idle`**
- Duration: 2 seconds
- Type: Looping
- Description: The default resting state. Character breathes gently.
- Keyframes:
  ```
  0.0s  Body Y = 0       (normal position)
  0.5s  Body Y = -2px    (slight rise -- breathing in)
  1.0s  Body Y = 0       (back to normal -- breathing out)
  1.5s  Body Y = -1px    (subtle variation)
  2.0s  Body Y = 0       (loop point)

  0.0s  Eyes opacity = 100%
  1.4s  Eyes opacity = 100%
  1.5s  Eyes opacity = 0%   (blink)
  1.6s  Eyes opacity = 100%
  ```
- Keep it subtle. This plays most of the time.

---

**Animation: `listen`**
- Duration: 1.5 seconds
- Type: Looping
- Description: Character tilts head slightly, showing attention.
- Keyframes:
  ```
  0.0s  Head rotation = 0 degrees
  0.75s Head rotation = -5 degrees    (slight tilt right)
  1.5s  Head rotation = 0 degrees     (back to center)

  Eyes: slightly wider than idle (scale eyes to 105%)
  Brows: raised 2px
  ```

---

**Animation: `speak`**
- Duration: 0.8 seconds
- Type: Looping
- Description: Mouth opens and closes rhythmically.
- Keyframes:
  ```
  0.0s  MouthNeutral opacity = 100%, MouthOpen opacity = 0%
  0.2s  MouthNeutral opacity = 0%,   MouthOpen opacity = 100%
  0.4s  MouthNeutral opacity = 100%, MouthOpen opacity = 0%
  0.6s  MouthNeutral opacity = 0%,   MouthOpen opacity = 100%
  0.8s  MouthNeutral opacity = 100%, MouthOpen opacity = 0%

  Head: subtle nod movement (Y -1px at 0.2s and 0.6s)
  ```
- Note: The Flutter code also drives `mouthOpenness` and `mouthShape`
  directly for finer lip-sync. The `speak` animation provides the
  base motion; the number inputs override mouth details at runtime.

---

**Animation: `think`**
- Duration: 2 seconds
- Type: Looping
- Description: Hand to chin, eyes look up.
- Keyframes:
  ```
  0.0s  RightArm rotation = 0 degrees (resting)
  0.5s  RightArm rotation = -45 degrees (hand moves toward chin)
  0.5s  RightHand position = near chin

  0.0s  Eyes Y = 0
  0.5s  Eyes Y = -3px (looking up)

  1.0s  Head rotation = 3 degrees (slight tilt)
  2.0s  Head rotation = 0 degrees
  ```

---

**Animation: `encourage`**
- Duration: 1.5 seconds
- Type: One-Shot (plays once, then state machine returns to idle)
- Description: Thumbs up or small clap with a warm smile.
- Keyframes:
  ```
  0.0s   MouthNeutral visible, MouthSmile hidden
  0.3s   MouthSmile visible, MouthNeutral hidden
  0.3s   RightArm raised (rotation -30 degrees, hand at chest height)
  0.8s   Hold
  1.2s   RightArm back to rest
  1.5s   MouthSmile hidden, MouthNeutral visible
  ```

---

**Animation: `correct`**
- Duration: 1 second
- Type: One-Shot
- Description: Quick approving nod with a smile.
- Keyframes:
  ```
  0.0s  Head Y = 0, MouthNeutral visible
  0.15s Head Y = 3px (nod down)
  0.3s  Head Y = -1px (nod up)
  0.3s  MouthSmile visible, MouthNeutral hidden
  0.5s  Head Y = 0
  0.7s  Body scale = 1.03 (subtle bounce)
  0.85s Body scale = 1.0
  1.0s  MouthNeutral visible, MouthSmile hidden
  ```

---

**Animation: `incorrect`**
- Duration: 1.5 seconds
- Type: One-Shot
- Description: Gentle head shake, sympathetic expression.
- Keyframes:
  ```
  0.0s  Head rotation = 0
  0.2s  Head rotation = 5 degrees (turn right)
  0.5s  Head rotation = -5 degrees (turn left)
  0.8s  Head rotation = 3 degrees (smaller turn right)
  1.0s  Head rotation = 0

  Brows: slight furrow (move inner edges down 1-2px)
  Eyes: slightly narrowed
  Mouth: neutral or slight frown
  ```

---

**Animation: `celebrate`**
- Duration: 2 seconds
- Type: One-Shot
- Description: Arms up, big smile, bounce. Triggered by `celebrate` input.
- Keyframes:
  ```
  0.0s  Arms at rest, MouthNeutral visible
  0.3s  Both arms raised up (-70 degree rotation)
  0.3s  MouthSmile visible, MouthNeutral hidden
  0.3s  Body Y = -5px (jump up)
  0.5s  Body Y = 0 (land)
  0.7s  Body Y = -3px (smaller bounce)
  0.85s Body Y = 0
  1.5s  Arms back to rest
  2.0s  MouthNeutral visible, MouthSmile hidden
  ```

---

**Animation: `wave`**
- Duration: 1.5 seconds
- Type: One-Shot
- Description: Friendly wave. Triggered by `wave` input.
- Keyframes:
  ```
  0.0s  RightArm rotation = 0
  0.3s  RightArm rotation = -60 degrees (arm raised)
  0.5s  RightHand rotation = -15 degrees (wave left)
  0.7s  RightHand rotation = 15 degrees (wave right)
  0.9s  RightHand rotation = -15 degrees (wave left again)
  1.1s  RightHand rotation = 0
  1.3s  RightArm rotation = 0 (arm down)

  MouthSmile visible from 0.3s to 1.3s
  ```

---

**Animation: `nod`**
- Duration: 0.8 seconds
- Type: One-Shot
- Description: Single approval nod. Triggered by `nod` input.
- Keyframes:
  ```
  0.0s  Head Y = 0
  0.15s Head Y = 4px (nod down)
  0.35s Head Y = -1px (slight overshoot up)
  0.5s  Head Y = 0

  MouthSmile visible from 0.15s to 0.5s (brief smile with nod)
  ```

---

**Animation: `enter`**
- Duration: 0.5 seconds
- Type: One-Shot
- Description: Character appears (scale in with overshoot).
- Keyframes:
  ```
  0.0s  Character group scale = 0%, opacity = 0%
  0.3s  Character group scale = 105%, opacity = 100%
  0.4s  Character group scale = 98%
  0.5s  Character group scale = 100%
  ```

---

**Animation: `exit`**
- Duration: 0.3 seconds
- Type: One-Shot
- Description: Character disappears.
- Keyframes:
  ```
  0.0s  Character group scale = 100%, opacity = 100%
  0.2s  Character group scale = 95%, opacity = 50%
  0.3s  Character group scale = 90%, opacity = 0%
  ```

---

### 4.3 Emotion-Driven Expressions

In addition to the main animations, create subtle expression changes
driven by the `emotion` number input. The easiest way:

1. In your state machine (section 5), create **blend states** that
   interpolate between expressions based on the `emotion` value
2. Alternatively, handle it via timeline animations:
   - `emotion_idle` (emotion 0): neutral face
   - `emotion_happy` (emotion 5): wide smile, bright eyes
   - `emotion_thinking` (emotion 1): hand to chin, eyes up
   - `emotion_proud` (emotion 3): big smile, chest puffed
   - `emotion_disappointed` (emotion 4): slight frown, droopy posture

These can blend ON TOP of the main animations (idle, speak, listen).

---

## 5. Wiring the State Machine

### 5.1 Create the State Machine

1. At the bottom of the Rive editor, find the **Timeline** panel
2. Click the **+** button and select **State Machine** (not Animation)
3. Name it anything you like (the Flutter code uses the first state machine
   found, regardless of name). Recommended: `MainStateMachine`

### 5.2 Add Inputs

In the State Machine editor, find the **Inputs** panel (usually left side).
Click **+** to add each input. **Names must be EXACT (case-sensitive):**

1. Click + > **Boolean** > name it `isSpeaking`
2. Click + > **Boolean** > name it `isListening`
3. Click + > **Number** > name it `emotion` > default value: 0
4. Click + > **Number** > name it `confidence` > default value: 0.5
5. Click + > **Number** > name it `energy` > default value: 0.5
6. Click + > **Number** > name it `mouthOpenness` > default value: 0
7. Click + > **Number** > name it `lipRounding` > default value: 0
8. Click + > **Number** > name it `mouthShape` > default value: 0
9. Click + > **Trigger** > name it `celebrate`
10. Click + > **Trigger** > name it `wave`
11. Click + > **Trigger** > name it `nod`

### 5.3 Add States

In the state machine graph canvas, you will see an **Entry** node and
an **Exit** node. Add animation states:

1. Right-click on the canvas > **Add State** > select `idle` animation
2. Right-click on the canvas > **Add State** > select `listen` animation
3. Right-click on the canvas > **Add State** > select `speak` animation
4. Right-click on the canvas > **Add State** > select `think` animation
5. Right-click on the canvas > **Add State** > select `encourage` animation
6. Right-click on the canvas > **Add State** > select `correct` animation
7. Right-click on the canvas > **Add State** > select `incorrect` animation
8. Right-click on the canvas > **Add State** > select `celebrate` animation
9. Right-click on the canvas > **Add State** > select `wave` animation
10. Right-click on the canvas > **Add State** > select `nod` animation
11. Right-click on the canvas > **Add State** > select `enter` animation

### 5.4 Wire Transitions

Connect the nodes with transitions. Click and drag from one state to another.

**Entry transitions:**
- Entry --> `enter` (immediately plays the enter animation)
- `enter` --> `idle` (after enter completes, go to idle)

**From idle (the hub state):**
- `idle` --> `listen`: Condition: `isListening` == true
- `idle` --> `speak`: Condition: `isSpeaking` == true
- `idle` --> `celebrate`: Condition: `celebrate` trigger fires
- `idle` --> `wave`: Condition: `wave` trigger fires
- `idle` --> `nod`: Condition: `nod` trigger fires

**Return to idle:**
- `listen` --> `idle`: Condition: `isListening` == false
- `speak` --> `idle`: Condition: `isSpeaking` == false
- `celebrate` --> `idle`: When animation completes (set "Exit Time" to 100%)
- `wave` --> `idle`: When animation completes (set "Exit Time" to 100%)
- `nod` --> `idle`: When animation completes (set "Exit Time" to 100%)

**Emotion-driven transitions from idle:**

For handling the `emotion` number input, you have two approaches:

**Approach A (Simple -- Recommended for first pass):**
- Keep emotion expressions as part of the `idle` animation
- Use a **Blend State** in `idle` that interpolates between:
  - `emotion_idle` (when emotion = 0)
  - `emotion_happy` (when emotion = 5)
  - `emotion_thinking` (when emotion = 1)
- This keeps the state machine simple

**Approach B (Advanced -- More expressive):**
- Add separate states for `think`, `encourage`, `correct`, `incorrect`
- Wire transitions from `idle`:
  - `idle` --> `think`: when `emotion` == 1
  - `idle` --> `encourage`: when `emotion` == 2
  - `idle` --> `correct`: when `emotion` == 3 (proud)
  - `idle` --> `incorrect`: when `emotion` == 4 (disappointed)
- Wire all back to `idle` when `emotion` == 0

### 5.5 State Machine Diagram

```
                     +-------+
                     | Entry |
                     +---+---+
                         |
                    +----v----+
                    |  enter  |
                    +----+----+
                         |  (completes)
                    +----v----+
      +------------>|  idle   |<--------------+
      |             +----+----+               |
      |                  |                    |
      |     +------------+----------+         |
      |     |            |          |         |
      |  isSpeaking  isListening  triggers    |
      |     |            |          |         |
      | +---v---+  +-----v-----+   |         |
      | | speak |  |  listen   |   |         |
      | +---+---+  +-----+-----+   |         |
      |     |             |         |         |
      |  !isSpeaking  !isListening  |         |
      |     |             |         |         |
      +-----+-------------+    +---v-------+ |
                                | celebrate | |
                                | wave      |-+
                                | nod       |
                                +-----------+
                                 (on complete)
```

### 5.6 Lip-Sync Setup

The `mouthOpenness`, `lipRounding`, and `mouthShape` inputs are driven
by Flutter at runtime for real-time lip sync. To make them work:

1. In the `speak` animation, the base mouth movement provides a fallback
2. Create **listeners** (or use constraints in Rive) that:
   - When `mouthOpenness` > 0.5, scale MouthOpen to visible
   - When `mouthOpenness` < 0.2, show MouthNeutral
3. Or simply: let the `speak` animation handle mouth movement,
   and accept that lip-sync inputs will be a future enhancement.

**For v1, I recommend ignoring the lip-sync inputs.** The `speak` animation
with basic mouth open/close looks good enough. You can add fine-grained
lip-sync later.

---

## 6. Per-Character Spec Sheets

For each character, duplicate your base rig file in Rive (File > Duplicate),
then modify ONLY the visual appearance. Do NOT rename layers, animations,
or state machine inputs.

### Character 1: Pa LingAfriq -- Village Elder

**File:** `elder.riv`
**Personality:** Wise, calm, grounding
**Used in:** Welcome screen, profile creation, completion milestones

| Property         | Value                          |
|------------------|--------------------------------|
| Skin tone        | Warm dark brown `#6B4226`      |
| Outfit primary   | Flowing white/cream `#F5F0E1`  |
| Outfit accent    | Gold trim `#D4AF37`            |
| Headwear         | Small rounded cap (kufi)       |
| Accessories      | Walking staff, beaded necklace |
| Facial hair      | Short white beard (small path) |
| Eye style        | Slightly narrowed, warm        |

**Animation tweaks:**
- `idle`: Slow all keyframes to 3s duration (70% speed) -- elder moves slowly
- `speak`: Add longer pauses between mouth movements
- `celebrate`: Smaller, more dignified -- reduce arm raise angle to -40 degrees
- `wave`: Slow, regal hand raise instead of energetic wave

**Color palette:**
```
Primary:   #D4AF37 (gold)
Secondary: #A67C00 (deep gold)
Skin:      #6B4226 (warm brown)
Outfit:    #F5F0E1 (cream)
Accent:    #8B7355 (warm gray-brown)
```

---

### Character 2: Adisa -- The Weaver

**File:** `weaver.riv`
**Personality:** Creative, expressive
**Used in:** Language selection screen

| Property         | Value                          |
|------------------|--------------------------------|
| Skin tone        | Medium brown `#8B6914`         |
| Outfit primary   | Colorful kente-inspired pattern `#00D4AA` |
| Outfit accent    | Deep teal `#008B6A`            |
| Headwear         | Head wrap (gele style)         |
| Accessories      | Woven bracelet, pattern on outfit |
| Facial hair      | None                           |
| Eye style        | Bright, wide, expressive       |

**Animation tweaks:**
- `idle`: Add slight rhythmic sway (rotate body +/- 2 degrees)
- `speak`: More expressive hand movement -- both arms move slightly
- `encourage`: Flowing arm gesture (arms spread outward)
- Arms: More fluid movement with wider arcs

**Color palette:**
```
Primary:   #00D4AA (teal)
Secondary: #00A88A (deep teal)
Skin:      #8B6914 (warm medium brown)
Outfit:    #00D4AA (teal) with #FFD700 (gold) accents
Accent:    #E74C3C (warm red strip)
```

---

### Character 3: Zuri -- The Pathfinder

**File:** `pathfinder.riv`
**Personality:** Motivational, adventurous
**Used in:** Goal-setting onboarding step

| Property         | Value                          |
|------------------|--------------------------------|
| Skin tone        | Deep brown `#5C3317`           |
| Outfit primary   | Explorer vest `#9B59B6`        |
| Outfit accent    | Dark purple `#7D3C98`          |
| Headwear         | None (natural hair, short)     |
| Accessories      | Compass pendant, map scroll    |
| Facial hair      | None                           |
| Eye style        | Alert, forward-looking         |

**Animation tweaks:**
- `idle`: Forward-leaning posture (body tilted 3 degrees forward)
- `encourage`: Pointing gesture (right arm extends forward)
- `celebrate`: Fist pump instead of both arms up
- `speak`: Confident, direct head movement

**Color palette:**
```
Primary:   #9B59B6 (purple)
Secondary: #7D3C98 (deep purple)
Skin:      #5C3317 (deep brown)
Outfit:    #9B59B6 (purple vest) over #2C3E50 (dark shirt)
Accent:    #F39C12 (golden compass)
```

---

### Character 4: Kofi -- The Timekeeper

**File:** `timekeeper.riv`
**Personality:** Structured, reassuring
**Used in:** Study schedule setup

| Property         | Value                          |
|------------------|--------------------------------|
| Skin tone        | Medium-dark brown `#7B5B3A`    |
| Outfit primary   | Neat tunic `#3498DB`           |
| Outfit accent    | Navy `#2980B9`                 |
| Headwear         | None (neat hair)               |
| Accessories      | Hourglass pendant or watch     |
| Facial hair      | None or thin mustache          |
| Eye style        | Calm, precise                  |

**Animation tweaks:**
- `idle`: Very still, minimal sway -- precise character
- `speak`: Measured head nods, evenly spaced
- `encourage`: Single confident nod
- `think`: Finger tapping gesture (subtle hand movement)

**Color palette:**
```
Primary:   #3498DB (blue)
Secondary: #2980B9 (deep blue)
Skin:      #7B5B3A (warm brown)
Outfit:    #3498DB (blue tunic)
Accent:    #F1C40F (gold hourglass)
```

---

### Character 5: Amara -- The Griot

**File:** `griot.riv`
**Personality:** Warm, expressive storyteller
**Used in:** Story-based onboarding and lessons

| Property         | Value                          |
|------------------|--------------------------------|
| Skin tone        | Rich dark brown `#4A2800`      |
| Outfit primary   | Warm red/orange `#E74C3C`      |
| Outfit accent    | Deep red `#C0392B`             |
| Headwear         | Storyteller's cap or headband  |
| Accessories      | Talking drum (small), kora     |
| Facial hair      | None                           |
| Eye style        | Wide, expressive, animated     |

**Animation tweaks:**
- `idle`: Rhythmic body movement -- like sitting with a drum
- `speak`: Most expressive -- big mouth movements, hand gestures
- `encourage`: Expansive arm spread (storyteller opening a tale)
- `celebrate`: Drum-beating gesture

**Color palette:**
```
Primary:   #E74C3C (warm red)
Secondary: #C0392B (deep red)
Skin:      #4A2800 (rich brown)
Outfit:    #E74C3C (red) with #F39C12 (gold) trim
Accent:    #F5CBA7 (warm beige drum)
```

---

### Character 6: Nuru -- The Rhythm Master

**File:** `rhythm_master.riv`
**Personality:** Energetic, playful
**Used in:** Learning style selection

| Property         | Value                          |
|------------------|--------------------------------|
| Skin tone        | Medium brown `#8B5E3C`         |
| Outfit primary   | Vibrant orange `#FF6B35`       |
| Outfit accent    | Deep orange `#E85D26`          |
| Headwear         | Headband with pattern          |
| Accessories      | Drumsticks, rhythm beads       |
| Facial hair      | None                           |
| Eye style        | Bright, bouncy                 |

**Animation tweaks:**
- `idle`: Bouncy! Add extra vertical movement (+/- 4px instead of 2px)
- `speak`: Head bobs to a beat
- `encourage`: Clap to rhythm (both hands clap 2x)
- `celebrate`: Dance-like bounce, arms and body move together
- All animations: 120% speed (faster than base)

**Color palette:**
```
Primary:   #FF6B35 (vibrant orange)
Secondary: #E85D26 (deep orange)
Skin:      #8B5E3C (warm brown)
Outfit:    #FF6B35 (orange) with #FFFFFF (white) pattern
Accent:    #2ECC71 (green beads)
```

---

### Character 7: Malaika -- Vocabulary Guide

**File:** `malaika.riv`
**Personality:** Playful, encouraging
**Used in:** Vocabulary games

| Property         | Value                          |
|------------------|--------------------------------|
| Skin tone        | Light-medium brown `#A0764A`   |
| Outfit primary   | Bright green `#2ECC71`         |
| Outfit accent    | Emerald `#27AE60`              |
| Headwear         | Flower or star hair clip       |
| Accessories      | Word bubble near head          |
| Facial hair      | None                           |
| Eye style        | Big, sparkly, cheerful         |

**Animation tweaks:**
- `correct`: Extra enthusiastic -- add a small sparkle effect (star shape that scales in/out)
- `encourage`: Big cheer with both hands
- `celebrate`: Jump with spin (rotate body 10 degrees and back)
- `incorrect`: Gentle "try again" gesture -- hands in "almost!" position

**Color palette:**
```
Primary:   #2ECC71 (green)
Secondary: #27AE60 (emerald)
Skin:      #A0764A (light-medium brown)
Outfit:    #2ECC71 (green dress/tunic)
Accent:    #F1C40F (gold star clip)
```

---

### Character 8: Baba -- Cultural Elder

**File:** `baba.riv`
**Personality:** Deep wisdom, respect
**Used in:** Cultural games

| Property         | Value                          |
|------------------|--------------------------------|
| Skin tone        | Very dark brown `#3B1F0B`      |
| Outfit primary   | Earth-tone brown `#8B4513`     |
| Outfit accent    | Deep burgundy `#7B2D26`        |
| Headwear         | Elaborate elder's cap          |
| Accessories      | Beaded staff, ancestral cloth  |
| Facial hair      | Full white beard               |
| Eye style        | Deep, wise, half-lidded        |

**Animation tweaks:**
- `idle`: Even slower than Pa LingAfriq -- 4s duration (50% speed)
- `speak`: Minimal mouth movement, weighty pauses
- `correct`: Very subtle nod -- barely moves but it means a lot
- `encourage`: Single slow hand gesture
- `celebrate`: Slow approving nod, hands together

**Color palette:**
```
Primary:   #8B4513 (saddle brown)
Secondary: #7B2D26 (burgundy)
Skin:      #3B1F0B (very dark brown)
Outfit:    #8B4513 (brown robe) with #D4AF37 (gold) embroidery
Accent:    #F5F5DC (ivory beads)
```

---

### Character 9: Okonkwo -- Tone Master

**File:** `okonkwo.riv`
**Personality:** Disciplined, precise
**Used in:** Pronunciation/tone games

| Property         | Value                          |
|------------------|--------------------------------|
| Skin tone        | Dark brown `#5C3D1E`           |
| Outfit primary   | Crisp indigo `#34495E`         |
| Outfit accent    | Dark navy `#2C3E50`            |
| Headwear         | None (shaved or very short)    |
| Accessories      | Sound wave symbol near ear     |
| Facial hair      | Clean-shaven, strong jawline   |
| Eye style        | Sharp, focused, evaluating     |

**Animation tweaks:**
- `idle`: Very still, alert posture
- `speak`: Precise, deliberate mouth shapes (each shape held slightly longer)
- `correct`: Sharp approving nod with brief smile
- `incorrect`: Quick head tilt, finger correction gesture (wag finger gently)
- `think`: Ear-cupping gesture (hand near ear, listening to tone)

**Color palette:**
```
Primary:   #34495E (indigo gray)
Secondary: #2C3E50 (dark navy)
Skin:      #5C3D1E (dark brown)
Outfit:    #34495E (indigo tunic) with clean lines
Accent:    #1ABC9C (teal sound wave)
```

---

### Character 10: Nneka -- Grammar Teacher

**File:** `nneka.riv`
**Personality:** Patient, methodical
**Used in:** Grammar games

| Property         | Value                          |
|------------------|--------------------------------|
| Skin tone        | Medium brown `#9B7B5B`         |
| Outfit primary   | Warm coral `#E17055`           |
| Outfit accent    | Deep coral `#D35400`           |
| Headwear         | Elegant head wrap              |
| Accessories      | Book or scroll, glasses (opt)  |
| Facial hair      | None                           |
| Eye style        | Patient, warm, focused         |

**Animation tweaks:**
- `idle`: Calm with occasional thoughtful head tilt
- `speak`: Step-by-step gestures -- one hand moves as if listing points
- `correct`: Warm approving nod with micro-smile
- `incorrect`: Patient shake, then encouraging lean forward
- `encourage`: Hands in "building" position (layered gesture)

**Color palette:**
```
Primary:   #E17055 (coral)
Secondary: #D35400 (deep coral)
Skin:      #9B7B5B (medium brown)
Outfit:    #E17055 (coral) with #FFF8DC (cornsilk) undershirt
Accent:    #8E44AD (purple book/scroll)
```

---

### Character 11: Polie -- AI Language Companion

**File:** `polie_avatar.riv`
**Personality:** Afro-futurist, adaptive, slightly non-human

This character should look and feel DIFFERENT from all others.

| Property         | Value                             |
|------------------|-----------------------------------|
| Skin tone        | Smooth dark with subtle sheen     |
| Outfit primary   | Deep charcoal/black `#1A1A2E`     |
| Outfit accent    | Glowing cyan edge `#00FFFF`       |
| Headwear         | None (smooth, geometric head)     |
| Accessories      | Subtle glow outline, floating elements |
| Facial hair      | None                              |
| Eye style        | Geometric, glowing pupils         |

**Visual approach for Polie:**
- Use FLAT shapes only, no gradients (gradients are expensive on mobile)
- Add a subtle glowing outline: duplicate the head/body shapes, make them
  slightly larger, set to cyan or teal at 30% opacity
- Eyes: geometric shapes (hexagons or diamonds instead of circles)
- Movement should have slight delay -- non-human timing
- Floating "data particles" around the head (2-3 tiny circles that orbit slowly)

**Animation tweaks:**
- `idle`: Floating motion instead of breathing (Y oscillates +/- 5px, smooth)
- `speak`: Geometric mouth (square/diamond opening instead of round)
- `think`: Data visualization gesture (small dots appear around head)
- `celebrate`: Glow intensifies, brief pulse of outline
- All: Ease-in/ease-out on everything -- never abrupt stops

**Color palette:**
```
Primary:   #1A1A2E (deep indigo/black)
Secondary: #16213E (midnight blue)
Skin:      #2D2D44 (dark with purple undertone)
Glow:      #00FFFF (cyan) at 30% opacity for outline
Alt glow:  #FF00FF (magenta) or #FFD700 (gold) -- switch per mode
Eyes:      #00FFFF (cyan glow)
```

---

### Character 12: User Custom Avatar

**File:** `user_avatar_base.riv`
**Personality:** Neutral, customizable

This is the simplest character. It serves as a base that the app could
theoretically customize (skin tone, hair, outfit). For now, create a
generic, friendly character.

| Property         | Value                          |
|------------------|--------------------------------|
| Skin tone        | Medium neutral `#B8860B`       |
| Outfit primary   | Simple blue `#5DADE2`          |
| Outfit accent    | Darker blue `#3498DB`          |
| Headwear         | None                           |
| Accessories      | None                           |
| Facial hair      | None                           |
| Eye style        | Friendly, neutral              |

**Animation tweaks:**
- Use 100% default speed for everything (no personality modifications)
- This is the "vanilla" character

**Color palette:**
```
Primary:   #5DADE2 (sky blue)
Secondary: #3498DB (blue)
Skin:      #B8860B (neutral warm)
Outfit:    #5DADE2 (simple blue)
```

---

### Character 13: Generic Game Guide (Fallback)

**File:** `game_guide.riv`
**Personality:** Friendly, generic

This is the **fallback** character used when any other `.riv` is missing.
It should be the FIRST file you create and the most thoroughly tested.

| Property         | Value                          |
|------------------|--------------------------------|
| Skin tone        | Warm medium `#A0764A`          |
| Outfit primary   | LingAfriq brand green `#2ECC71`|
| Outfit accent    | Deep green `#27AE60`           |
| Headwear         | None                           |
| Accessories      | Small star or badge             |
| Facial hair      | None                           |
| Eye style        | Bright, welcoming              |

**Animation tweaks:**
- Use 100% default speed
- Extra polish on `idle`, `speak`, and `encourage` since these play most often
- This is the character everyone sees if their specific avatar isn't ready

**Color palette:**
```
Primary:   #2ECC71 (LingAfriq green)
Secondary: #27AE60 (deep green)
Skin:      #A0764A (warm medium)
Outfit:    #2ECC71 (green) with #F1C40F (gold) star
```

---

## 7. Exporting and Placing Files

### 7.1 Export from Rive

For each character file:

1. Open the file in Rive
2. Go to **File > Export** (or click the download/export button)
3. Select format: **Rive (.riv)**
   - Do NOT select Lottie or GIF -- you need the native `.riv` format
4. Click **Export**
5. Save with the EXACT filename from the table in section 2.2

### 7.2 Place Files in Flutter Project

1. Copy all `.riv` files to:
   ```
   C:\Users\HP\Desktop\LingAfriqMobile\mobile-app-main\assets\rive\avatars\
   ```

2. Your directory should look like:
   ```
   assets/rive/avatars/
     game_guide.riv         (fallback -- create first)
     elder.riv
     weaver.riv
     pathfinder.riv
     timekeeper.riv
     griot.riv
     rhythm_master.riv
     malaika.riv
     baba.riv
     okonkwo.riv
     nneka.riv
     polie_avatar.riv
     user_avatar_base.riv
   ```

3. Run `flutter pub get` to refresh the asset bundle.
   No changes to `pubspec.yaml` needed -- `assets/rive/` is already declared.

### 7.3 Build Order (Recommended)

1. `game_guide.riv` -- fallback, test integration first
2. `elder.riv` -- used on welcome/completion screens (most visible)
3. `polie_avatar.riv` -- used in all AI chat modes (most used)
4. Remaining onboarding characters: weaver, pathfinder, timekeeper, griot, rhythm_master
5. Game characters: malaika, baba, okonkwo, nneka
6. `user_avatar_base.riv` -- lowest priority

---

## 8. Testing Checklist

After placing each `.riv` file, test it in the app:

### 8.1 Quick Smoke Test

- [ ] App launches without crash
- [ ] Navigate to the screen where the character appears
- [ ] Character is visible (not a blank space or fallback emoji)
- [ ] `idle` animation plays (gentle breathing/movement)

### 8.2 State Machine Test

- [ ] When entering a chat: character plays `wave` or `enter`
- [ ] When AI is responding: character plays `speak` (mouth moves)
- [ ] When waiting for user input: character plays `listen` (head tilted)
- [ ] When user gets answer correct: character plays `correct` or `celebrate`
- [ ] When user gets answer wrong: character plays `incorrect`
- [ ] Character returns to `idle` after one-shot animations

### 8.3 Per-Character Test Points

| Character | Test Screen                        |
|-----------|------------------------------------|
| elder     | Onboarding: Welcome, Profile, Complete |
| weaver    | Onboarding: Language Selection     |
| pathfinder| Onboarding: Goals                  |
| timekeeper| Onboarding: Schedule               |
| griot     | Onboarding: Story                  |
| rhythm_master | Onboarding: Learning Style     |
| malaika   | Games: Vocabulary games            |
| baba      | Games: Cultural games              |
| okonkwo   | Games: Pronunciation games         |
| nneka     | Games: Grammar games               |
| polie     | AI Chat: all modes                 |
| user_avatar_base | Profile screen               |
| game_guide | Any screen where specific char is missing |

### 8.4 Performance Test

- [ ] App does not stutter when character appears
- [ ] Memory usage does not spike significantly
- [ ] On an older Android device (if available): animations are smooth
- [ ] File size: each `.riv` should be under 500KB

---

## 9. Performance Guidelines

### 9.1 File Size Targets

| Category       | Max Size | Why                           |
|----------------|----------|-------------------------------|
| Per character   | 500KB    | Fast load, low memory         |
| Total all 13   | 5MB      | Reasonable app bundle impact  |

### 9.2 Shape Optimization

- Use **vector shapes only** (ellipses, rectangles, paths)
- Do NOT use raster images (PNG/JPG) inside Rive files
- Avoid heavy gradients -- use flat colors with opacity
- Keep path complexity low (fewer anchor points = better performance)
- Target under **50 nodes** per character

### 9.3 Animation Optimization

- Use **simple easing** (cubic ease-in-out, not spring physics)
- Avoid blur effects (very expensive on low-end GPUs)
- Limit simultaneous moving parts to 3-4 at most
- Reuse the same animation structure across characters

### 9.4 Mobile-Specific Tips

- Characters render inside 80-120px circles in the app
- Fine details under ~5px will be invisible -- keep it bold and simple
- Test on a real device, not just the emulator
- The Rive Flutter runtime is optimized but still uses GPU -- simpler = faster

---

## 10. Troubleshooting

### "Character doesn't animate -- just static"

- Check that your State Machine has the `idle` animation as the default state
- Make sure Entry node connects to your first state
- Verify the state machine is not named with special characters

### "Character is invisible"

- Check the artboard size matches (256x256)
- Make sure the character shapes are within the artboard bounds
- Check that `enter` animation starts at scale 100% (not scale 0)
- Or remove the `enter` animation and start directly at `idle`

### "Flutter shows fallback emoji instead of Rive"

- Verify the `.riv` file is in `assets/rive/avatars/` (not `assets/rive/`)
- Verify the filename matches EXACTLY (case-sensitive)
- Run `flutter pub get` after adding files
- Check debug console for "Avatar: Could not load" messages

### "State machine inputs don't respond"

- Input names are CASE-SENSITIVE: `isSpeaking` not `IsSpeaking` or `isspeaking`
- Check you used the correct type: Bool for `isSpeaking`, Number for `emotion`, Trigger for `celebrate`
- Make sure transitions have conditions wired to the inputs

### "Animation is too fast/slow in Flutter"

- Check the animation duration in Rive (it plays at the authored speed)
- The `energy` input can scale speed if you wire it as a speed multiplier
- Flutter's `Rive` widget respects the authored frame rate

### "File is too large"

- Remove unused animations
- Simplify paths (fewer anchor points)
- Remove any embedded raster images
- Flatten unnecessary groups

---

## Quick Reference Card

### Filenames
```
assets/rive/avatars/game_guide.riv
assets/rive/avatars/elder.riv
assets/rive/avatars/weaver.riv
assets/rive/avatars/pathfinder.riv
assets/rive/avatars/timekeeper.riv
assets/rive/avatars/griot.riv
assets/rive/avatars/rhythm_master.riv
assets/rive/avatars/malaika.riv
assets/rive/avatars/baba.riv
assets/rive/avatars/okonkwo.riv
assets/rive/avatars/nneka.riv
assets/rive/avatars/polie_avatar.riv
assets/rive/avatars/user_avatar_base.riv
```

### State Machine Inputs (copy-paste these names exactly)
```
Bool:    isSpeaking
Bool:    isListening
Number:  emotion
Number:  confidence
Number:  energy
Number:  mouthOpenness
Number:  lipRounding
Number:  mouthShape
Trigger: celebrate
Trigger: wave
Trigger: nod
```

### Core Animations (name exactly)
```
idle        (2s, loop)
listen      (1.5s, loop)
speak       (0.8s, loop)
think       (2s, loop)
encourage   (1.5s, one-shot)
correct     (1s, one-shot)
incorrect   (1.5s, one-shot)
celebrate   (2s, one-shot)
wave        (1.5s, one-shot)
nod         (0.8s, one-shot)
enter       (0.5s, one-shot)
exit        (0.3s, one-shot)
```

### Emotion Values
```
0=idle  1=thinking  2=encouraging  3=proud  4=disappointed  5=happy
6=excited  7=curious  8=focused  9=sleepy  10=celebrating
11=empathetic  12=playful  13=listening  14=speaking
15=surprised  16=confused  17=determined  18=relieved
```
