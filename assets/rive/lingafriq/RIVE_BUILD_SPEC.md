# RIVE_BUILD_SPEC · lingafriq_cast.riv (v3)

The file is built by a generator, not by hand:
- `v2/build_cast.py` holds the ViewModel, state machine and assembly.
- `v2/parts.py` holds the Character rig art.
- `v2/partsart.py` holds the part artboards.
- `v2/presets.json` holds the instances.
- `v2/rml.py` is the RML writer.

To rebuild:
```
python3 v2/build_cast.py && cd v2/out && ~/.rive/bin/rive . --once
python3 v2/assemble.py      # preview.html
```

## 1. Rive CLI 1.6 feature check (done before building)
| Feature | RML/CLI 1.6 | Notes |
|---|---|---|
| ViewModel + exported instances | **Supported** | 16 instances export; the runtime lists them all |
| Custom enums (`DataEnumCustom`) | **Supported** | enum values have ids, and transitions compare against them |
| Artboard properties (`ViewModelPropertyArtboard`) | **Supported** | binds `NestedArtboard.artboardId` (key 197); runtime swap works |
| Nested artboards | **Supported** | colour binds inside nested parts resolve against the host's CharacterVM |
| Layer separation | **Supported** | 5 layers, disjoint property ownership |
| VM-driven transitions / BlendState1DViewModel | **Supported** | Number blends go through a RangeMapper converter (0..1 to 0..100) |
| Pointer listener writes a VM trigger | **Supported** | `tapped` fires on pointer down |
| Bones + skinning | **Supported** | 2-bone arms with a skinned sleeve |
| **Nested state-machine inputs (`NestedBool`)** | **Did not take effect** | Workaround: the hair artboard is placed twice, as a back slot and as a front slot clipped above the hairline. The result is faithful but the hair costs 2 draws. |
| Nesting a full rig artboard (Bust) | **Supported** | Character is marked isComponent; the nested CharacterSM runs from the shared VM |

## 2. Artboards
- `Character` 400×560:
  - Body > Chest (two arm bone chains with Hand nodes, PropSlot in the left hand, skinned sleeves).
  - NeckNod > HeadTilt > HeadTurn (HairBackSlot, face, eyes ×4 lids, brows, mouths, HairFrontSlot clipped, HeadwearSlot, AccessorySlot).
  - BottomSlot, TopSlot, FX_*, HitArea.
- `CharacterChip` 128×128: a separate simplified head. Strokes are 3–3.5 px, the mouths come in 7 bold shapes, and the hair and headwear are the same part artboards nested at 0.5×.
- `Bust` 400×400: Character nested at 1.25× with its own CharacterSM running, clipped to a disc.
- Parts are 400×560 and share the Character frame, so a part draws in the right place in any slot with no offsets. Each part with motion has `PartSM` (sway ↔ still, switched on `reducedMotion`).

## 3. CharacterSM: layer ownership (no overlaps)
| Layer | Drives | States |
|---|---|---|
| L1 Body | Body y/scale, Chest rot/scaleY/y, NeckNod, 4 arm bones, 8 hand-pose opacities, SleepLid, FX_*, HairSwayBack | 8 activities × {normal, reduced}; idle normal = blend on `energy` (calm↔lively); 7 trigger one-shots from AnyState that return through exit time to the matching activity state |
| L2 Face | brows, MoodLid, LowerLid, eye scale, cheeks, MM_* mouths | 8 expression blends (neutral↔expr on `intensity`); FaceJoy on correct/celebrate/levelUp, FaceKind on incorrect |
| L3 Gaze/Head | HeadTurn.x, PupilX (blend on gazeX), PupilY.y = bind(gazeY), HeadTilt.rotation = bind(headTilt, ±12°) | 1 blend |
| L4 Blink | BlinkLid scaleY | slow / normal (double-blink) / fast, banded by `blinkRate` <.33 / .33–.66 / >.66 |
| L6 Build | Body_<type> torso-group opacities (8 drawn torsos with shade, rim and detail), Build.sy (height), HeadScale, TorsoW.sx (top overlay fit), ArmThickL/R.sx with ShoulderL/R.x re-anchoring, HipFit.sx (bottoms and legs), NeckGrp.sx, Stoop rot/y | 8 bodyType states, 200 ms |
| L7 Face Shape | Face_* variant opacities | 6 faceShape states, instant |
| L5 Mouth | RestMouth + V_* opacities; Jaw.scaleY = bind(jawOpen, 0.78–1.3) | 15 viseme states, full pairwise transitions, 60 ms |

Every L1 animation keys **all** L1 properties, falling back to rest values. The same rule applies to L2 and L5, so a state change can never leave a stale value behind.

## 4. Gesture angles (absolute degrees; 0 = right, 90 = down)
| Gesture | Bone angles | Hand |
|---|---|---|
| rest | R1 84 / R2 +10; L1 96 / L2 −10 | — |
| wave | R1 −40, with R2 swinging −40 ↔ +5 three times | — |
| correct (pump) | R1 30 / R2 −125 ↔ −105 | fist |
| encouraging | R1 45 / R2 −130 | thumbs-up |
| hinting | R1 −55 / R2 −15 | point |
| shrug | R1 60 / R2 −70; L1 120 / L2 70; Chest y −4 | — |
| thinking | R1 139 / R2 130 | fist under the chin |
| listening | L1 −105 / L2 8 | open hand at the ear |
| celebrate / levelUp | R1 −60 / R2 −20; L1 −120 / L2 20, with a jump and squash | — |
| sleeping | NeckNod 10°, SleepLid closed, Zzz | — |

## 5. Verification (`v2/verify_cast.js`, log in `out/verify_log.json`)
- VM properties (31, unchanged in this pass), their order, types and all 3 enums match `contract.json` exactly, on all 3 artboards.
- Each of the 8 activities enters its state and changes pixels.
- Each of the 7 triggers enters its one-shot (plus the face reaction) and changes pixels.
- All 21 visemes enter the right state, including the aliases.
- With `reducedMotion` on, idle is static and blink keeps going.
- `blinkRate` switches the blink band. gaze, headTilt, artboard swap and colour each change pixels.
- A pointer click fires `tapped` once.
- All 8 bodyType and 6 faceShape values enter their state and change pixels, on Character and on the chip.


## v3.2 additions
- L8 Seated (wheelchair): SeatDrop.y +56, Chair/ChairFront opacity 1. Bottom part artboards carry PartSM with layers Body (bodyType → B_<t>/S_<t>) and Seated (wheelchair → Stand/Sit), driven through the inherited view model.
- L5, L6, L7, chip L6/L7 and the bottom Body layer use AnyState transitions (0ms, except visemes 60ms). L1 transitions are activity-only within the same reducedMotion family, plus twin transitions. The final keys are linear. Together these took the file from 337KB to 298,228 bytes.
