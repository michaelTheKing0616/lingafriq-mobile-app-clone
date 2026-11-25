import 'dart:ui' show Color;

import 'package:lingafriq/avatars/contract/character_vm.dart';
import 'package:rive/rive.dart';

/// Undertone tags from [cultural_design_bible.md] §4 (P11-034).
enum AvatarSkinUndertone {
  warm('warm'),
  neutral('neutral'),
  warmGolden('warm golden'),
  warmRed('warm red'),
  olive('olive'),
  redWarm('red-warm'),
  cool('cool'),
  blueDeep('blue-deep'),
  warmDeep('warm deep'),
  warmPale('warm pale');

  const AvatarSkinUndertone(this.label);
  final String label;
}

/// One swatch in the 12-tone skin system (ids 1–12, bible order).
class AvatarSkinTone {
  const AvatarSkinTone({
    required this.id,
    required this.slug,
    required this.color,
    required this.undertone,
  });

  final int id;
  final String slug;
  final Color color;
  final AvatarSkinUndertone undertone;

  static const int minCount = 10;

  static const List<AvatarSkinTone> catalog = [
    AvatarSkinTone(
      id: 1,
      slug: 'porcelain-warm',
      color: Color(0xFFF1D3B8),
      undertone: AvatarSkinUndertone.warm,
    ),
    AvatarSkinTone(
      id: 2,
      slug: 'sand-neutral',
      color: Color(0xFFDDB28F),
      undertone: AvatarSkinUndertone.neutral,
    ),
    AvatarSkinTone(
      id: 3,
      slug: 'honey-golden',
      color: Color(0xFFC68D5E),
      undertone: AvatarSkinUndertone.warmGolden,
    ),
    AvatarSkinTone(
      id: 4,
      slug: 'caramel-warm',
      color: Color(0xFFA86F45),
      undertone: AvatarSkinUndertone.warmRed,
    ),
    AvatarSkinTone(
      id: 5,
      slug: 'bronze-olive',
      color: Color(0xFF8A5A3C),
      undertone: AvatarSkinUndertone.olive,
    ),
    AvatarSkinTone(
      id: 6,
      slug: 'cocoa-red',
      color: Color(0xFF7A4A2E),
      undertone: AvatarSkinUndertone.redWarm,
    ),
    AvatarSkinTone(
      id: 7,
      slug: 'chestnut-neutral',
      color: Color(0xFF6B4226),
      undertone: AvatarSkinUndertone.neutral,
    ),
    AvatarSkinTone(
      id: 8,
      slug: 'umber-cool',
      color: Color(0xFF5C3317),
      undertone: AvatarSkinUndertone.cool,
    ),
    AvatarSkinTone(
      id: 9,
      slug: 'espresso-warm',
      color: Color(0xFF4A2800),
      undertone: AvatarSkinUndertone.warmDeep,
    ),
    AvatarSkinTone(
      id: 10,
      slug: 'ebony-blue',
      color: Color(0xFF3B2216),
      undertone: AvatarSkinUndertone.blueDeep,
    ),
    AvatarSkinTone(
      id: 11,
      slug: 'onyx-deep',
      color: Color(0xFF2E1A12),
      undertone: AvatarSkinUndertone.neutral,
    ),
    AvatarSkinTone(
      id: 12,
      slug: 'albinism-pale',
      color: Color(0xFFEED9C6),
      undertone: AvatarSkinUndertone.warmPale,
    ),
  ];

  static AvatarSkinTone byId(int id) {
    for (final tone in catalog) {
      if (tone.id == id) return tone;
    }
    throw RangeError('skinTone id $id; valid 1–${catalog.length}');
  }
}

/// Natural hair colours bound to `hairColor` on CharacterVM (no .riv re-export).
class AvatarHairColor {
  const AvatarHairColor({
    required this.id,
    required this.name,
    required this.color,
  });

  final int id;
  final String name;
  final Color color;

  static const List<AvatarHairColor> catalog = [
    AvatarHairColor(id: 0, name: 'jet', color: Color(0xFF0E0906)),
    AvatarHairColor(id: 1, name: 'soft-black', color: Color(0xFF17100C)),
    AvatarHairColor(id: 2, name: 'dark-brown', color: Color(0xFF1B120D)),
    AvatarHairColor(id: 3, name: 'brown', color: Color(0xFF3A2215)),
    AvatarHairColor(id: 4, name: 'chestnut', color: Color(0xFF6A4130)),
    AvatarHairColor(id: 5, name: 'auburn', color: Color(0xFF7A4A2E)),
    AvatarHairColor(id: 6, name: 'honey-brown', color: Color(0xFF9A6A48)),
    AvatarHairColor(id: 7, name: 'silver', color: Color(0xFFD9D4CC)),
    AvatarHairColor(
      id: 8,
      name: 'albinism-light',
      color: Color(0xFFEED9C6),
    ),
  ];

  static AvatarHairColor byId(int id) {
    for (final hair in catalog) {
      if (hair.id == id) return hair;
    }
    throw RangeError('hairColor id $id');
  }
}

/// Brand-safe garment fills (`outfitPrimary` / `outfitSecondary`).
class AvatarOutfitPalette {
  const AvatarOutfitPalette._();

  static const Color defaultPrimary = Color(0xFF1A1A2E);
  static const Color defaultSecondary = Color(0xFF16213E);

  static const List<Color> primarySwatches = [
    Color(0xFF1A1A2E),
    Color(0xFF2E9E6B),
    Color(0xFFC8893F),
    Color(0xFF2B4C7E),
    Color(0xFF7A1F2B),
    Color(0xFFF4EDE1),
    Color(0xFFE5603B),
  ];

  static const List<Color> secondarySwatches = [
    Color(0xFF16213E),
    Color(0xFFE5603B),
    Color(0xFFE2A72E),
    Color(0xFF3FA7D6),
    Color(0xFFF2B33D),
    Color(0xFF7A2E6B),
  ];
}

/// Learner-facing colour selection mapped to CharacterVM colour properties.
class AvatarAppearance {
  const AvatarAppearance({
    required this.skinToneId,
    this.hairColorId = 2,
    this.outfitPrimary = AvatarOutfitPalette.defaultPrimary,
    this.outfitSecondary = AvatarOutfitPalette.defaultSecondary,
  });

  final int skinToneId;
  final int hairColorId;
  final Color outfitPrimary;
  final Color outfitSecondary;

  AvatarSkinTone get skin => AvatarSkinTone.byId(skinToneId);

  AvatarHairColor get hair => AvatarHairColor.byId(hairColorId);

  CharacterVmState toVmState() => CharacterVmState(
        skinTone: skin.color,
        hairColor: hair.color,
        outfitPrimary: outfitPrimary,
        outfitSecondary: outfitSecondary,
      );
}

/// Binds bible-aligned tones and outfit colours onto a live ViewModel instance.
class AvatarColorPalette {
  const AvatarColorPalette._();

  static void bind(ViewModelInstance instance, AvatarAppearance appearance) {
    CharacterVmWriter(instance: instance).apply(appearance.toVmState());
  }

  static void bindSkinTone(ViewModelInstance instance, int skinToneId) {
    final color = AvatarSkinTone.byId(skinToneId).color;
    instance.color('skinTone')?.value = color;
  }

  static void bindHairColor(ViewModelInstance instance, int hairColorId) {
    instance.color('hairColor')?.value = AvatarHairColor.byId(hairColorId).color;
  }

  static void bindOutfit(
    ViewModelInstance instance, {
    required Color primary,
    required Color secondary,
  }) {
    instance.color('outfitPrimary')?.value = primary;
    instance.color('outfitSecondary')?.value = secondary;
  }
}
