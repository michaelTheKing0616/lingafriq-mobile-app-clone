# AvatarDirector integration note: `lingafriq_cast.riv`

Target runtime: **rive ^0.14.11 (rive_native)**. I have not touched the repo. This note is for the engineer who wires it in.
Evidence labels: **Verified** means run in @rive-app/canvas 2.45 against the real file. **Inspected** means read in the CLI output. **Unverified** means the Flutter API has not been run here.

## 1. Asset
- `assets/rive/lingafriq_cast.riv` is 237,076 bytes and holds every character, part and preset (budget 300 KB, **Verified**). Ship `contract.json` next to it as `lingafriq_cast.contract.json`.
- No embedded images or fonts. Everything is vector, so no out-of-band assets are needed yet. If raster textures arrive later, load them as referenced assets.

## 2. Shape of the director
```dart
class AvatarDirector {
  AvatarDirector(this.file, {String preset = 'Polie', String artboard = 'Character'}) {
    final vm = file.viewModelByName('CharacterVM')!;
    vmi = vm.createInstanceByName(preset)!;          // exported instances: Polie, PaLingAfriq, Adisa, ...
    ab = file.artboard(artboard)!;                   // Character | CharacterChip | Bust
    sm = ab.stateMachine('CharacterSM')!;
    sm.bindViewModelInstance(vmi);                   // ONE instance can drive the Character and its Chip at once
    vmi.trigger('tapped')!.addListener(_onTapped);   // rive→app
  }
  // app→rive: always write the ViewModel, never legacy inputs
  void activity(String a) => vmi.enumerator('activity')!.value = a;      // idle|listening|thinking|speaking|celebrating|encouraging|hinting|sleeping
  void expression(String e, [double i = .6]) { vmi.enumerator('expression')!.value = e; vmi.number('intensity')!.value = i; }
  void fire(String t) => vmi.trigger(t)!.trigger();                       // correct|incorrect|celebrate|levelUp|wave|nod|shrug
  void gaze(double x, double y) { vmi.number('gazeX')!.value = x; vmi.number('gazeY')!.value = y; }
  void viseme(String v, double jaw) { vmi.enumerator('viseme')!.value = v; vmi.number('jawOpen')!.value = jaw; }
  void body(String bodyType, String faceShape) { vmi.enumerator('bodyType')!.value = bodyType; vmi.enumerator('faceShape')!.value = faceShape; }
  void reducedMotion(bool on) => vmi.boolean('reducedMotion')!.value = on; // from MediaQuery.disableAnimations
  void wear(String slot, String artboardName) =>                           // slot: hair|headwear|top|bottom|accessory|prop
      vmi.artboard(slot)!.value = file.artboardToBind(artboardName)!;     // e.g. 'Hair/Locs' (exact API name: Unverified)
}
```
The Flutter method names are **Unverified**. The same calls in JS are **Verified**:
- `vi.enum()`, `.number()`, `.trigger()`
- `.artboard(slot).value = rive.getBindableArtboard('Hair/Locs')`
- `trigger('tapped').on(cb)`

## 3. Legacy map (old inputs → contract)
| Old | New |
|---|---|
| isListening / isSpeaking / isThinking | `activity` = listening / speaking / thinking (set back to `idle` when done) |
| correctAnswer / incorrectAnswer | trigger `correct` / `incorrect` |
| celebrate / levelUp | trigger `celebrate` / `levelUp` |
| lessonComplete | trigger `celebrate`, then `activity=celebrating` |
| hint | `activity=hinting` |
| 0–100 numeric codes | gone. Enums only. |

One-shot triggers play over the current activity and then return to it, with a ≤300 ms blend (**Verified**: os_* states return through exit-time transitions).

## 4. Lip-sync wiring
1. TTS or recorded audio goes through forced alignment (MFA, or the TTS vendor's phoneme marks) to get `[phoneme, start, end]`.
2. Map each phoneme to a viseme with the **per-language table** (`LIPSYNC` section of the bible). Never map letters.
3. On each frame, set `viseme` to the active entry and `jawOpen` to the smoothed RMS of the audio (attack 30 ms, release 80 ms, clamped 0..1).
4. Fallback when there is no alignment: keep `viseme=aa` while RMS is above the gate, `sil` below, and drive `jawOpen` from RMS alone.

## 5. Performance and a11y
- Pause offscreen: stop advancing when the widget is not visible (VisibilityDetector), or use `RiveWidgetController` pause.
- CLI bench, 600 frames of `celebrating`, desktop software GL: advance mean **0.147 ms** (p95 0.18). Render mean 4.2 ms on software rasterisation. **The Tecno/Infinix ≤2 ms/frame target is not yet measured on a device**; run the bench on a Helio G85-class phone before sign-off.
- Semantics: wrap the widget in `Semantics(label: '${name} looks ${expression}', liveRegion: true)` and update it whenever the director changes expression or activity. preview.html shows this with an aria-live label.
- With `reducedMotion` on, idle loops and part sway freeze but blink keeps running (**Verified**: two frames 700 ms apart are pixel-identical while idle_calm_rm is active).

## 6. Chip usage
`CharacterChip` is 128×128 and is built to be drawn at 32, 48 or 64 px. Bind the **same** ViewModel instance. Expressions, blink and talk (any non-`sil` viseme) follow it automatically.


## v3.2
File 298,228 bytes (≤300KB). New app→rive Boolean `wheelchair` (last property). Flutter contract_test passes headless (see header of contract_test.dart for LD_LIBRARY_PATH setup).
