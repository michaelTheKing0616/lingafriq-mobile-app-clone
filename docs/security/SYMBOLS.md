# Release symbols

Release builds use `flutter build --obfuscate --split-debug-info=build/symbols`.

The symbol directories are uploaded as GitHub Actions artifacts named `android-debug-symbols-<version>` and `ios-debug-symbols-<version>`. They are not attached to the GitHub release. Download the artifact for the version that produced the stack, then:

```bash
flutter symbolize -i stack.txt -d path/to/symbols
```

`stack.txt` is the obfuscated trace. The command prints the same frames with their original names. A stored DWARF file from `gen_snapshot --save-debugging-info` restored the frame `uniqueReadableFrame` (`main.dart:2`) from an obfuscated program counter. Keep the artifact private; it reverses the release binary.
