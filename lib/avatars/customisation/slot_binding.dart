import 'package:flutter/foundation.dart';
import 'package:rive/rive.dart';

/// Max nested part options shipped inside [lingafriq_cast.riv] per slot (ELEVATION §4.2).
const int kMaxInlinePartOptionsPerSlot = 10;

/// CharacterVM artboard property names for nested Hair/Headwear/Top/Bottom/Accessory/Prop.
abstract final class AvatarPartSlots {
  static const hair = 'hair';
  static const headwear = 'headwear';
  static const top = 'top';
  static const bottom = 'bottom';
  static const accessory = 'accessory';
  static const prop = 'prop';

  static const all = <String>[
    hair,
    headwear,
    top,
    bottom,
    accessory,
    prop,
  ];
}

enum AvatarPartSource { inlineMainFile, streamedPack }

@immutable
class AvatarSlotDefinition {
  const AvatarSlotDefinition({
    required this.vmPropertyName,
    required this.category,
    required this.inlineOptions,
    required this.streamedOptions,
  });

  final String vmPropertyName;
  final String category;
  final List<String> inlineOptions;
  final List<String> streamedOptions;

  List<String> get allOptions => [...inlineOptions, ...streamedOptions];

  bool contains(String artboardId) => allOptions.contains(artboardId);

  AvatarPartSource sourceFor(String artboardId) {
    if (inlineOptions.contains(artboardId)) return AvatarPartSource.inlineMainFile;
    if (streamedOptions.contains(artboardId)) {
      return AvatarPartSource.streamedPack;
    }
    throw SlotBindingException(
      SlotBindingError.unknownOption,
      slot: vmPropertyName,
      artboardId: artboardId,
    );
  }
}

@immutable
class AvatarPartCatalog {
  const AvatarPartCatalog(this.slots);

  final Map<String, AvatarSlotDefinition> slots;

  factory AvatarPartCatalog.fromContractJson(Map<String, dynamic> contract) {
    final parsed = <String, AvatarSlotDefinition>{};
    for (final entry in contract['properties'] as List) {
      final property = entry as Map<String, dynamic>;
      if (property['type'] != 'Artboard') continue;
      final name = property['name'] as String;
      final options = (property['options'] as List).cast<String>();
      final split = _splitInlineAndStreamed(options);
      parsed[name] = AvatarSlotDefinition(
        vmPropertyName: name,
        category: property['category'] as String? ?? name,
        inlineOptions: split.inline,
        streamedOptions: split.streamed,
      );
    }
    return AvatarPartCatalog(parsed);
  }

  AvatarSlotDefinition slot(String vmPropertyName) {
    final def = slots[vmPropertyName];
    if (def == null) {
      throw SlotBindingException(
        SlotBindingError.unknownSlot,
        slot: vmPropertyName,
      );
    }
    return def;
  }

  void validateLibraryMinimums() {
    final hair = slot(AvatarPartSlots.hair);
    final headwear = slot(AvatarPartSlots.headwear);
    final hairStyles = hair.allOptions
        .where((id) => id.startsWith('Hair/') && id != 'Hair/None')
        .length;
    final headwearOptions = headwear.allOptions
        .where((id) => id.startsWith('Headwear/') && id != 'Headwear/None')
        .length;
    if (hairStyles < 6) {
      throw SlotBindingException(
        SlotBindingError.libraryTooSmall,
        slot: AvatarPartSlots.hair,
        detail: 'need >=6 hair styles, got $hairStyles',
      );
    }
    if (headwearOptions < 4) {
      throw SlotBindingException(
        SlotBindingError.libraryTooSmall,
        slot: AvatarPartSlots.headwear,
        detail: 'need >=4 headwear, got $headwearOptions',
      );
    }
  }
}

/// OOB part packs: `assets/rive/avatars/parts/{category}/{artboardLeaf}.riv`.
String streamedPartAssetPath(String artboardId) {
  final parts = artboardId.split('/');
  if (parts.length != 2) {
    throw SlotBindingException(
      SlotBindingError.invalidArtboardId,
      artboardId: artboardId,
    );
  }
  final category = parts.first;
  final leaf = parts.last;
  return 'assets/rive/avatars/parts/$category/$leaf.riv';
}

class SlotBinding {
  SlotBinding({
    required this.catalog,
    this.streamedFiles = const {},
  });

  final AvatarPartCatalog catalog;
  final Map<String, File> streamedFiles;

  /// Binds nested parts through CharacterVM Artboard properties (never visibility toggles).
  void applyParts({
    required ViewModelInstance instance,
    required File mainFile,
    required Map<String, String> parts,
  }) {
    for (final entry in parts.entries) {
      final slotName = entry.key;
      final artboardId = entry.value;
      final def = catalog.slot(slotName);
      if (!def.contains(artboardId)) {
        throw SlotBindingException(
          SlotBindingError.unknownOption,
          slot: slotName,
          artboardId: artboardId,
        );
      }
      final source = def.sourceFor(artboardId);
      final file = switch (source) {
        AvatarPartSource.inlineMainFile => mainFile,
        AvatarPartSource.streamedPack => streamedFiles[artboardId],
      };
      if (file == null) {
        throw SlotBindingException(
          SlotBindingError.streamPackMissing,
          slot: slotName,
          artboardId: artboardId,
          detail: streamedPartAssetPath(artboardId),
        );
      }
      final artboard = file.artboardToBind(artboardId);
      if (artboard == null) {
        throw SlotBindingException(
          SlotBindingError.artboardMissingOnFile,
          slot: slotName,
          artboardId: artboardId,
        );
      }
      final property = instance.artboard(slotName);
      if (property == null) {
        throw SlotBindingException(
          SlotBindingError.vmPropertyMissing,
          slot: slotName,
        );
      }
      property.value = artboard;
    }
  }
}

enum SlotBindingError {
  unknownSlot,
  unknownOption,
  invalidArtboardId,
  streamPackMissing,
  artboardMissingOnFile,
  vmPropertyMissing,
  libraryTooSmall,
}

class SlotBindingException implements Exception {
  SlotBindingException(
    this.code, {
    this.slot,
    this.artboardId,
    this.detail,
  });

  final SlotBindingError code;
  final String? slot;
  final String? artboardId;
  final String? detail;

  @override
  String toString() =>
      'SlotBindingException($code slot=$slot artboard=$artboardId $detail)';
}

class _SplitOptions {
  const _SplitOptions({required this.inline, required this.streamed});

  final List<String> inline;
  final List<String> streamed;
}

_SplitOptions _splitInlineAndStreamed(List<String> options) {
  if (options.length <= kMaxInlinePartOptionsPerSlot) {
    return _SplitOptions(inline: List<String>.from(options), streamed: const []);
  }
  return _SplitOptions(
    inline: options.sublist(0, kMaxInlinePartOptionsPerSlot),
    streamed: options.sublist(kMaxInlinePartOptionsPerSlot),
  );
}
