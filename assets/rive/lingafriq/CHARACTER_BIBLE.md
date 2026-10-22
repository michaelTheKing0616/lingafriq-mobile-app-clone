# LingAfriq Character Bible · v3 (cast + contract edition)

Source of truth for `lingafriq_cast.riv`. This version replaces v1 and v2. The v1 nation packs (§9) carry over unchanged in substance.
Every visual claim here can be checked in `contact_sheet.png`. That sheet is rendered by the web runtime from the real `.riv` and driven only through `CharacterVM`.

## 1. Principles
1. **One rig, many people.** Polie, the village archetypes, the hosts and the learner's own avatar all run the same skeleton, state machine and ViewModel. A new character is a ViewModel instance, not a new file.
2. **Dignity before decoration.** Cultural items are worn the way their owners wear them. Nothing is a costume. Each item carries a one-line cultural note (§7) and goes through review.
3. **Read at 32 px.** Every character must be recognisable as a 1-bit chip silhouette (§3, `silhouettes/`).
4. **Motion earns its place.** Idle is quiet. Big motion is reserved for things the learner did. Reduced motion is always respected.
5. **Kids never pay to look better** (§8).

## 2. Visual language
- **Line:** ink `#1D1B26` at 70% on clothes and hands, 2 px. Face features are solid ink (lashes and brows taper). Chip lines are 3–3.5 px at 128, so ≥1.5 px at 64.
- **Shading:** one cel-shadow plate (`#1A0820` at 18% alpha) on the side away from the key light (upper left). A rim light (`#FFF0D8` at 24%) on the lit edge. A deep plate for nostrils and mouth. All shading uses alpha overlays, so it stays correct on **every skin tone** with no per-tone art.
- **Eyes:** sclera, iris with lower bounce light, pupil, two highlights. Four separate lids: lower, mood, blink and sleep, each owned by a different layer (§5).
- **Hands:** four finger poses (Open, Fist, Thumb, Point), swapped by L1. Thumbs-up and point read clearly at 400 px. They simplify away at the chip size.
- **Hair:** built as strands, not blobs:
  - Braids are plaited outlines with chevrons.
  - Locs are tapered ropes with ridges.
  - Coils are scalloped silhouettes with a coil-mark texture.
  - Each style sways with its own phase.

## 3. Cast (one page each)
Each character has a body and a 64 px silhouette in `silhouettes/<Name>_body_64.png` and a chip in `contact_sheet.png`. Palettes are the preset instance values.

### Polie: the guide (rig spike, built first)
- **Role:** guide on every screen; afro-futurist and slightly not human.
- **Personality:** warm, curious, a little cheeky. Never sarcastic. Celebrates effort, not speed.
- **Voice:** even pitch with a bright lift at the end of sentences; slight synth shimmer; pan-African English with code-switch greetings.
- **Region:** of everywhere; speaks every course language.
- **Palette:** skin `#2D2D44`, suit `#1A1A2E`/`#16213E`, glow `#22E3E3`, gold `#F2B33D`.
- **Kit:** PolieCrest, PolieSuit (circuit lines, core gem), PolieHover (floats; no legs), PolieOrbit (particle ring).
- **Silhouette test:** crest plus orbit plus tapering hover cone. This is the most distinct silhouette in the cast.
- **Deviation:** the brief asks for geometric glowing eyes and a geometric mouth. Polie currently uses the shared eye and mouth rig so lip-sync and expressions come for free. Proposal: a `Accessory/PolieVisor` glow overlay. Not built.

### Village archetypes and hosts: one ethnic group each (rule from Tope)
Each preset belongs to **one** ethnic group. The name, hair, headwear, outfit, textile and prop all come from that group, and cues from different groups are never mixed.
The same outfit art (for example `Kaftan` or `WovenWrap`) can stand for different garments when it is recoloured to the group's cloth. Where that is only an approximation, it is listed in §3c.

| Preset | Role | Group · language | Build (hair · headwear · top/textile · bottom · prop) | Palette (skin · primary · secondary) |
|---|---|---|---|---|
| PaLingAfriq | Elder | **Igbo** · Igbo | grey ShortCoils · red elder's cap (Kufi art in red, standing in for *okpu ododo*) · white ElderRobe with coral-red bead strands · trousers · walking staff · beard | #6B4226 · #F4EDE1 · #B5221E |
| Adisa | Weaver | **Yoruba** · Yorùbá | (under gele) · gele · aṣọ-òkè strip-weave (WovenWrap) · ìró wrapper · weaving shuttle | #8A5A3C · #2E9E6B · #E5603B |
| Zuri | Pathfinder | **Swahili (Waswahili)** · Kiswahili | locs · none · utility jacket with compass · trousers · map scroll | #5C3317 · #C8893F · #3D5A40 |
| Kofi | Timekeeper | **Akan (Asante)** · Twi | ShortCoils · none · kente in Asante gold/green (WovenWrap) · trousers · glasses, hourglass | #7B5B3A · #2E7D46 · #E2A72E |
| Lamine | Griot | **Mandinka** · Mandinka | ShortCoils · cap · grand boubou (Kaftan) · trousers · kora | #3A2215 · #F4EDE1 · #7A2E6B |
| Ayanwale | Rhythm Master | **Yoruba** · Yorùbá | ShortCoils · fìlà · bùbá (Kaftan) · ṣòkòtò · dùndún talking drum | #8B5E3C · #2B4C7E · #C8893F |
| Amara | Story friend | **Igbo** · Igbo | ShortCoils · Igbo-style gele · akwete-style woven top (WovenWrap) · george-red wrapper · none (udu or ogene prop queued) | #4A2800 · #7A1F2B · #E9B949 |
| Tolu_Lagos | Host, Yorùbá course | **Yoruba** | irun kíkó · none · àdìrẹ tee · wrapper | #7A4A2E · #3FA7D6 · #14365A |
| Ama_Accra | Host, Twi course | **Akan (Fante/Asante)**; the city is Ga land, the character is Akan | none · duku · blouse (Kaftan standing in for *kaba*) · slit wrapper | #5E3A22 · #F2B33D · #B4332E |
| Otieno_Nairobi | Host, Kiswahili course | **Luo** · Dholuo (speaks Kiswahili) | ShortCoils · none · utility · trousers · hearing aids | #3B2216 · #B4332E · #1D1B26 |
| Thandi_Durban | Host, isiZulu course | **Zulu** · isiZulu | Bantu knots · none · black top with red/white beadwork collar (ElderRobe art) · black wrapper (standing in for *isidwaba*) · vitiligo | #6A4130 · #1D1B26 · #B5221E |
| Liya_Addis | Host, Amharic course | **Amhara** · Amharic | albaso · none · white habesha kemis with green tibeb neckline (Kaftan) · wrapper | #9A6A48 · #F4EDE1 · #2E9E6B |
| Moussa_Dakar | Host, Wolof course | **Wolof** · Wolof | ShortCoils · cap · grand boubou · trousers · beard | #2E1A12 · #3D5AA8 · #F4EDE1 |
| Funmilayo_Ibadan | Sample | **Yoruba** | ṣùkú · none · àdìrẹ tee · ìró wrapper | #6B4226 · #7A2E6B · #F2B33D |
| Fuseini_Tamale | Sample | **Dagomba** · Dagbani | ShortCoils · cap (standing in for *zupligu*) · fugu / bin'gbaŋ smock (the right group for this smock) · trousers | #5C3317 · #F4EDE1 · #2A3A6B |
| Polie | Guide | **none: not human**, belongs to all courses | Afro-futurist kit only; no ethnic cues | see the Polie page |
| Learner | user | **user's choice**; the default has no group assigned, and the builder never auto-assigns one | — | — |


### 3d. Drawn bodies and faces per preset (v3.2)
**Body types are drawn, not scaled.** Each bodyType has its own torso outline: shoulder width and slope, chest, waist, belly and hips. Each also has its own:
- limb thickness (arms re-attach at the new shoulder)
- neck thickness
- hip width, which the legs and every Bottom artboard fit
- head proportion
- posture

| bodyType | Shoulders | Waist / belly | Hips | Limbs | Posture / height |
|---|---|---|---|---|---|
| average | 50 | 46 | 66 | 1.0 | upright, 1.0 |
| child | 40, narrow | 40, slight tummy | 50 | 0.82 | 0.78 height, 1.2× head |
| teen | 43 | 37 | 52 | 0.88 | 0.9 height, 1.08× head |
| slim | 43, sloped | 33 | 50 | 0.82 | upright, 1.02 |
| tall | 50 | 40 | 58 | 0.94 | 1.1 height, 0.96× head |
| broad | **66, square** (slope 1), chest planes | 48 | 60 (V-taper) | **1.3**, thick neck | upright |
| curvy | 45 | **32, defined waist crease** | **80** | 0.96 | upright; clearly hip-led, the opposite of broad's shoulder-led shape |
| elder | 47, **soft, sloped** (slope 15) | 52 with belly | 64 | 0.96 | **7° stoop**, 0.94 height |

**Clothing fit:**
- The garment base is the torso shape itself, filled with `outfitPrimary`, so every top fits every body by construction.
- Top pattern overlays scale with the torso width.
- Bottoms and legs sit in a `HipFit` group that matches the body's hip width.
- Tops and bottoms stay single artboards, so the contract is unchanged.

**faceShape on the chip:** the chip uses exaggerated outlines (near-circular round, flat-jawed square, pointed heart chin, sharp diamond cheekbones, narrow long). They read in colour at 32 px through the face outline and ear placement.

| Preset | bodyType | faceShape | Silhouette cues (hair · headwear · prop) |
|---|---|---|---|
| Polie | slim | round | None · PolieCrest · None |
| PaLingAfriq | elder | long | ShortCoils · Kufi · Staff |
| Adisa | elder | heart | None · Gele · Shuttle |
| Zuri | tall | oval | Locs · None · MapScroll |
| Kofi | average | round | Afro · None · Hourglass |
| Lamine | tall | long | ShortCoils · Kufi · Kora |
| Ayanwale | broad | square | ShortCoils · Fila · TalkingDrum |
| Amara | teen | round | ShortCoils · Gele · Udu |
| Tolu_Lagos | slim | oval | IrunKiko · None · None |
| Ama_Accra | curvy | round | None · Duku · None |
| Otieno_Nairobi | tall | diamond | ShortCoils · None · Nyatiti |
| Thandi_Durban | average | heart | ShortCoils · Isicholo · None |
| Liya_Addis | slim | oval | Albaso · None · None |
| Moussa_Dakar | broad | long | ShortCoils · Kufi · None |
| Funmilayo_Ibadan | child | round | Shuku · None · None |
| Fuseini_Tamale | average | diamond | ShortCoils · Kufi · None |
| Learner | child | oval | Afro · None · None |

**48 px separation (1-bit test, 17 bodies, 136 pairs):**
- The closest pair is now **Polie vs Tolu, at 100 of 1,536 px (6.5%)**. It was 71 before this pass.
- Target pairs:
  - Amara vs Tolu: 71 → **141** (Amara holds an Igbo udu; Tolu is now slim)
  - Ama vs Otieno: 74 → **165** (Ama is curvy; Otieno is tall and holds a Luo nyatiti)
  - Kofi vs Ayanwale: 76 → **247** (Kofi has Afro volume and an average build; Ayanwale is broad)
- The full table is in `silhouettes/_pairwise_48.json`.

**New items, culturally matched:**
- `Prop/Udu`: Igbo clay pot-drum, played by striking the side hole.
- `Prop/Nyatiti`: Luo eight-string lyre.
- `Headwear/Isicholo`: Zulu flared hat. ⚑ Traditionally worn by married women. The reviewer should confirm it suits Thandi, or swap it for an *umqhele* headband.

### 3a. Name table
Sources: I cited these from knowledge. **None were re-fetched this session**, so the reviewer should open each one. "⚑" marks an item I am unsure of; it goes to the reviewer rather than being guessed.

| Name | Group | Language | Meaning | Say it | Gender · age fit | Source for meaning |
|---|---|---|---|---|---|---|
| Pa (LingAfriq) | — | Nigerian English / Pidgin honorific | "Pa" = respectful address for an elder man | PAH | M · elder | ⚑ "LingAfriq" is a brand name, not an Igbo name. Proposal for the reviewer: give him an Igbo given name, e.g. *Obiora* ("heart of the people"), and keep "Pa LingAfriq" as his title. |
| Adisa | Yoruba | Yorùbá | "one who makes himself/herself clear" | ah-DEE-sah | ⚑ mostly given to boys; the art is a woman | YorubaName.com (Yorùbá Names Project); ⚑ confirm gender use |
| Zuri | Swahili | Kiswahili | "beautiful, good" (adj. *-zuri*) | ZOO-ree | F · youth/adult | TUKI *Kamusi ya Kiswahili–Kiingereza* (UDSM); ⚑ mainly a diaspora given name, so confirm local use |
| Kofi | Akan | Twi | day name: male born on Friday (*Fiada*) | KOH-fee | M · any | Agyekum, K. (2006) "The Sociolinguistic of Akan Personal Names", *Nordic Journal of African Studies* 15(2) |
| Lamine | Mandinka | Mandinka (from Arabic *al-Amīn*) | "the trustworthy" | lah-MEEN | M · adult | Behind the Name, "Amin"; ⚑ the reviewer should confirm griot (jali) naming custom; jali lineage surnames are Kouyaté, Diabaté, Cissoko |
| Ayanwale | Yoruba | Yorùbá | "Àyàn (the drum spirit) has come home"; a drumming-lineage name | ah-yahn-WAH-leh (Àyànwálé) | M · adult | YorubaName.com |
| Amara | Igbo | Igbo | "grace" (*amara*) | ah-MAH-rah | F · youth/adult | Behind the Name, "Amara"; Igbo dictionary entry *amara*; ⚑ also a separate Mande/Mende name, so the build follows the Igbo reading |
| Tolu | Yoruba | Yorùbá | short for Tolúwalọ́pẹ́ / Tolúwanimí, "(it) belongs to God" | toh-LOO | F/M · youth | YorubaName.com |
| Ama | Akan | Twi/Fante | day name: female born on Saturday (*Memeneda*) | AH-mah | F · any | Agyekum (2006), as above |
| Otieno | Luo | Dholuo | "born at night" | oh-tee-EH-no | M · any | Behind the Name, "Otieno"; ⚑ add a Dholuo academic source |
| Thandi(we) | Zulu | isiZulu | "beloved" | TAHN-dee(-weh) | F · any | Behind the Name, "Thandiwe" |
| Liya | Amhara | Amharic | ⚑ commonly glossed "special/distinguished"; **uncertain** | LEE-yah | F | ⚑ no reliable source to hand; reviewer to confirm, or replace with a better-documented name such as *Meron* or *Hana* |
| Moussa | Wolof | Wolof (from Arabic *Mūsā*, Moses) | Moses | MOO-sah | M · adult | Behind the Name, "Musa" |
| Funmilayo | Yoruba | Yorùbá | "give me joy" (Fúnmiláyọ̀) | foon-mee-LAH-yaw | F · any | YorubaName.com |
| Fuseini | Dagomba | Dagbani (from Arabic *Ḥusayn*) | "good, handsome" (diminutive of *ḥasan*) | foo-SAY-nee | M · adult | Behind the Name, "Husayn"; ⚑ confirm the Dagbani spelling and usage |
| Polie | — | invented | brand name from the guide | POH-lee | any | ⚑ brand, not a cultural name |

### 3b. Changes made for this rule
- **Amara** was rebuilt as Igbo. Removed: Fulani braids (Fulani), kaftan and kora (Mande). Added: Igbo-style gele, an akwete-style woven top, and a george-red wrapper. Her griot role moved to Lamine.
- **Lamine (new, Mandinka griot)** now carries the kora and a grand boubou. This replaces the guide's "Amara the Griot".
- **Nuru** was removed. The name is Swahili, but the talking drum is Yoruba/Akan. The rhythm role now belongs to **Ayanwale** (Yoruba drum-lineage name, dùndún, fìlà, bùbá).
- **Kofi**: removed the fugu smock, which is northern Ghanaian (Dagomba/Mamprusi) and not Asante. He now wears Asante kente colours.
- **Pa LingAfriq** is now an Igbo elder: red cap, coral beads (the bead colour is now bound to the outfit colour), white robe. His name is flagged above.
- **Thandi**: replaced the kente-style check and the adire tee with a Zulu beadwork collar and a black skirt-wrap.
- **Fila_Sample** became **Fuseini_Tamale** (Dagomba), the right owner of the fugu. **Shuku_Sample** became **Funmilayo_Ibadan** (Yoruba).
- The ViewModel instance list changed (17 instances). Property and enum names are unchanged.

### 3c. Open approximations for the cultural reviewer ⚑
- **Kufi art used as other caps:** it stands in for the Igbo *okpu ododo*, the Mandinka cap and the Dagomba *zupligu*. Each needs its own cap artboard.
- **Kaftan art used as other garments:** it stands in for the Yoruba bùbá, the Akan kaba, the Amhara kemis and the Wolof/Mandinka boubou. Silhouettes and embroidery differ, so each needs its own top artboard.
- **WovenWrap check used for three cloths:** it stands in for aṣọ-òkè, kente and akwete. Real motifs differ, so per-cloth patterns are needed, and kente motifs need meaning checks.
- **Specific cue attributions:**
  - Bantu knots as a Zulu style: commonly attributed, confirm.
  - Albaso as an Amhara style: confirm region.
  - Locs on a Swahili character: locs are not group-specific in East Africa; confirm the reviewer is comfortable.
- **Missing Igbo props:** add udu and ogene, and an isiagu top. With those, Amara and Pa would carry fully Igbo cues.
### Learner avatar
Same rig, built in the app's avatar builder (preview.html shows the full builder). The default preset `Learner` is an Afro, Tee and Shorts.

**Honest assessment of distinctiveness:**
- Silhouettes differ through hair, headwear, props and lower garments.
- Resolved in v3.1: `bodyType` and `faceShape` are added (§3d).
- Kofi, Otieno and Ama are the least distinct at 64 px.


## 4. Customisation v1 (all exported part artboards)
- **Hair (8 plus None; braids and locs carry a solid backing mass so they read as one shape at 32 px):**
  - ShortCoils
  - Shuku (Yoruba crown braids into a top bun)
  - FulaniBraids (centre braid, side braids with beads and cowries)
  - BantuKnots
  - IrunKiko (threaded spikes)
  - Locs
  - Albaso (Ethiopian cornrows into a puff)
  - Afro
  - Cornrows render through Shuku and Albaso rows. A standalone Cornrows artboard is next in the queue.
- **Headwear (6 plus None):** Gele, Fila (Yoruba cap, flopped), Kufi, Duku (Ghanaian knotted wrap), Headband, PolieCrest.
- **Top:** Tee (adire diamonds), Kaftan (embroidered neckline), WovenWrap (kente-style check, trim), Utility, ElderRobe, Fugu (smock stripes), PolieSuit.
- **Bottom** (each includes legs and shoes): Trousers, Wrapper, Shorts, PolieHover.
- **Accessory:** Glasses, HearingAids, Beard, Vitiligo, PolieOrbit.
- **Prop:** Staff, Shuttle, Kora, Hourglass, TalkingDrum, MapScroll.
- **Skin tones:** 12 swatches with warm, neutral, olive, red and blue undertones, including an albinism-appropriate pale tone. Swatches are listed in preview.html and `SKINS` in `assemble.py`. Shading is alpha-based, so the lighting stays correct on every tone. Skin range is never restricted by nation.

## 5. Rig and motion summary
See `RIVE_BUILD_SPEC.md` for full detail. In short:
- Five layers that never key the same property (L1 Body, L2 Face, L3 Gaze/Head, L4 Blink, L5 Mouth).
- Arms are a 2-bone chain with a skinned sleeve (true bones and skin weights, 50/50 at the elbow).
- Every gesture has an anticipation dip, an elastic overshoot, and follow-through on the hair-back group.
- Part artboards carry their own sway loop (braids, locs, gele fan, beads, compass needle, scroll), which freezes under `reducedMotion`.

## 6. Disability representation
| Need | Status |
|---|---|
| Glasses | Built (`Accessory/Glasses`) |
| Hearing aids | Built (`Accessory/HearingAids`); host Otieno (Luo) wears them by default |
| Vitiligo | Built (`Accessory/Vitiligo` overlay); host Thandi |
| Albinism | Pale skin swatch plus light hair colour. A sun-hat headwear item and low-vision glasses are queued. |
| Wheelchair-seated pose | **Spec only.** Needs a `Bottom/Wheelchair` artboard with seated legs plus a `pose` contract value (or `bodyType=seated`). L1 gestures already work from the chest up, so the upper-body animation carries over unchanged. |

Rule: disability items are never unlockables and never cost anything. They are available from the first screen and are never used as a punchline.

## 7. Economy and cultural notes
- Items unlock by **demonstrated skill**, for example "hold a 3-minute conversation in Yoruba" unlocks the Gele. Streak length alone and payment never unlock items.
- **Children:**
  - no real-money cosmetics
  - no "premium looks better" items
  - every skin tone, hair texture and disability item is free from day one
- **Adults:** optional real-money cosmetics are allowed, but only for celebration skins such as aso-ebi colourways, never for core identity items.
- **No loot boxes, ever.** No random or paid item draws.

| Item | Unlock skill | Cultural note (1 line, reviewed) |
|---|---|---|
| Gele | Yoruba unit 3 dialogue | Tied headwrap worn for celebrations across Nigeria; its height and shape are personal style. |
| Fila | Yoruba greetings mastery | Yoruba men's cap; the direction of the flop is traditionally a matter of taste. |
| Kufi | Wolof or Hausa unit 2 | Brimless cap worn widely in West Africa, often for prayer and elders' gatherings. |
| Duku | Twi unit 2 | Ghanaian headwrap; knots and fabric choice signal occasion. |
| Shuku | Yoruba proverbs set | Braided "basket" crown style, centuries old in Yorùbá hair art. |
| Irun kiko | Yoruba tone drills | Thread-wrapped hair, a protective style documented in 1960s–70s Nigerian photography. |
| Fulani braids | Fula or Hausa unit 3 | Fulani-origin braids with a centre braid and adornments such as cowries and beads. |
| Bantu knots | isiZulu unit 2 | Coiled knots tracing back to Bantu-speaking peoples of southern Africa. |
| Albaso | Amharic unit 2 | Ethiopian braided pattern with rows that finish in a full puff. |
| Locs | Swahili listening set | Matted rope locks worn across the continent and its diaspora. |
| Kora | Griot story track | 21-string harp-lute of the Mande griot tradition. |
| Udu | Igbo unit 3 | Igbo clay pot-drum; the player strikes and cups the side hole to bend the tone. |
| Nyatiti | Dholuo listening set | Luo eight-string bowl lyre, played seated with a toe-ring rattle. |
| Isicholo | isiZulu unit 3 | Flared Zulu hat traditionally worn by married women; ⚑ check context before it becomes a default item. |
| Talking drum | Rhythm track | Pressure drum (dùndún, gangan) that imitates tonal speech. |

## 8. Scarification and tribal marks policy
- **Opt-in only, adults only (18+), and never shown on hosts or guides by default.**
- Each mark pattern ships only after review by at least two people from that community, plus a cultural advisor sign-off. The reviewer is recorded in the item manifest.
- Delivery: an `Accessory/Marks_<Community>_<Pattern>` overlay artboard using the same alpha-overlay technique as Vitiligo, so it works on every tone.
- Never randomised, never in loot or in "surprise" items, never used for villains or jokes. A mark can be removed at any time with one tap.
- None ship in v1.

## 9. Nation variant rules
The v1 packs carry over: Nigeria, Ghana, Kenya, South Africa, Senegal and Ethiopia, each with names, greetings, motif limits, an avoid-list and the "add a nation" checklist. Under the cast system:
- A **nation pack** is data: a list of preset instances (hosts), unlock notes and greetings. It never adds rig changes.
- New hair and headwear go into the shared library. They are never nation-locked and every user can pick every style.
- A motif covers no more than about 15% of the torso and uses brand colours. Two native-speaker reviewers sign off before release.

## 10. Runtime, performance and a11y contract
| Rule | Target | Status |
|---|---|---|
| Size per character file | ≤ 300 KB | **237.1 KB for the whole cast** (Verified) |
| Out-of-band assets | images, fonts and audio not embedded | none embedded; all vector (Verified) |
| Frame cost | ≤ 2 ms per frame on a Tecno/Infinix-class phone, 60 fps target | advance 0.147 ms mean (CLI bench, desktop). **Device render not measured; open item.** |
| Offscreen | pause when not visible | preview pauses on `visibilitychange`; the app must use a visibility detector |
| Reduced motion | idle loops and sway stop, blink continues | Verified |
| Semantics | live label "Polie looks proud and is listening" | preview `aria-live`; Flutter `Semantics(liveRegion)` per the integration note |
| Transitions | ≤ 300 ms | all authored transitions are 0–280 ms (Inspected) |

## 11. Lip-sync pipeline
1. **Forced alignment** of audio and transcript gives phoneme timings. Use MFA with per-language acoustic models, or TTS phoneme marks.
2. Apply the **per-language phoneme→viseme table**. Each language maps its own inventory, for example:
   - Yoruba: gb and kp → `GB`/`KP`, which alias to `PP`
   - Yoruba nasal vowels → `Nnasal`, which aliases to `nn`
   - isiZulu clicks → `C`, which aliases to `CH`
   - Ethiopian ejectives → `Q`, which aliases to `U`
   - Tone does not change the viseme.
3. **jawOpen** is the smoothed RMS of the same audio, multiplied by the viseme's openness.
4. **Fallback** when there is no alignment: RMS only (`aa` above the gate, `sil` below).
5. **Never** map letters to visemes. Orthography does not track sound in these languages.

The viseme enum holds 21 values. The file renders 15 unique mouths, and the aliases are listed in contract.json `visemeAliases`.

## 12. Naming
- Artboards: `Character`, `CharacterChip`, `Bust`, and `Category/Item` for parts.
- ViewModel `CharacterVM` and state machine `CharacterSM`. The state machine has these layers: `L1 Body`, `L2 Face`, `L3 Gaze/Head`, `L4 Blink`, `L5 Mouth`.
- Instances use PascalCase names, with hosts written as `Name_City`.


## 3e. Pass v3.2 changes (2026-10-21)
- Bottoms (Trousers, Wrapper, Shorts) are drawn per bodyType, standing and seated, in nested part artboards; PartSM switches them from the inherited CharacterVM (no stretching).
- Sleeves: one skinned sleeve per bodyType (Sleeve_<side>_<type>), bound to the arm bones, so raised arms bend instead of distorting.
- Chip: each face carries a #F4EDE1 halo rim plus a light hairline stroke; tested at 32px in colour and 1-bit on light (#F4EDE1) and dark (#1D1B26) — see chip_32_tests.png.
- `wheelchair` Boolean (appended last, property 32): L8 Seated drops the body, shows the chair and seated bottoms. Works on every bodyType.
- Culture-specific art replaces stand-ins: Igbo okpu (red cap) + isiagu (Pa), Mandinka embroidered cap + boubou (Lamine), Dagomba cap (Fuseini), bùbá (Ayanwale), kaba (Ama), kemis with tibeb (Liya), boubou (Moussa), aṣọ-òkè (Adisa), kente (Kofi), akwete (Amara). Ogene prop added to the library (unassigned).
- Thandi: default headwear is now umqhele; isicholo stays in the library. ⚑ Reviewer flag: umqhele (leopard-skin band) is traditionally worn by men/amabutho; on a woman it may read as wrong. Needs Zulu cultural sign-off — the alternative is a beaded headband (umnqwazi-style) or isicholo for married women.
- Thandi bodyType average→broad, Polie stays tall: Polie/Tolu 48px distance 100→149. Closest pair now Ayanwale/Thandi 90.
- Stand-in flags in §3c for caps, tops and weaves are resolved; ⚑ the new drawings themselves still need cultural review.
