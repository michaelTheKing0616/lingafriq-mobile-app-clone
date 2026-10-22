# LingAfriq cast

`lingafriq_cast.riv` is the only character file the app loads. `lingafriq_cast.contract.json` is the source of truth for CharacterVM: 32 properties, the enums, and the part lists.

Screens talk to `CastDirector` / `CastSession`. They do not read state-machine inputs. Writes go through the ViewModel (`activity`, `expression`, triggers, `viseme`, `jawOpen`, part artboards). `reducedMotion` follows `MediaQuery.disableAnimations`. A semantics live region says the name, expression, and activity, for example "Polie looks proud and is listening".

`CastStage` keeps one `RiveWidgetController` per visible character and sets `active` false when the widget leaves the scroll viewport. Long lists use `CastChip` at 32, 48, or 64 px on the `CharacterChip` artboard. The file is decoded once in `CastFileCache`. Part swaps call `artboardToBind` on that file.

Lip sync takes forced-alignment phonemes and a per-language table (`yo`, `zu`, `am`/`ti`, plus a shared IPA table). Jaw openness is smoothed RMS (30 ms attack, 80 ms release) on the audio clock. With no alignment, the mouth is `aa` above the RMS gate and `sil` below. Letters are not visemes.

The reference notes under `assets/rive/lingafriq/` are not bundled. Do not edit the `.riv` here. Thandi's headwear and on-device frame time are still open.

Runtime: rive 0.14.11 and rive_native. `main` calls `RiveNative.init()`. The app decodes with `Factory.rive`. Widget tests and the chip goldens use `Factory.flutter`, because the shipped native library has no headless GPU. Goldens are recorded per host OS under `test/avatar/goldens/`.
