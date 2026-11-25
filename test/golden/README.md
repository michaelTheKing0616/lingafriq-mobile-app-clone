# Golden harness

`golden_harness.dart` pins three things before a comparison:

- surface `160×72` logical pixels, or `64×64` for the Rive chip
- device pixel ratio `1.0`
- the bundled Dosis font, not the host font and not a downloaded face

A pixel diff above `0.01` fails. The comparator writes the master, test, and diff images under `test/golden/failures/`. CI uploads that directory when the test fails. Do not commit it.

Update a stored image only after a real visual change:

```
flutter test test/golden/golden_harness_test.dart --update-goldens
```

The design-system sample is `GriotChip` selected, label Yoruba. The Rive sample is the `CharacterChip` artboard with `CharacterSM` held on frame zero (`controller.active = false`), so blink and mouth do not advance.
