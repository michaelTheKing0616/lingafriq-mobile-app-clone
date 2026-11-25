import 'dart:convert';
import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:rive/rive.dart';

/// Typed CharacterVM contract (ADR-030 / P11-035). Binds only through Rive data VM.
enum CharacterVmActivity {
  idle('idle'),
  listening('listening'),
  thinking('thinking'),
  speaking('speaking'),
  celebrating('celebrating'),
  encouraging('encouraging'),
  hinting('hinting'),
  sleeping('sleeping');

  const CharacterVmActivity(this.riveName);
  final String riveName;
}

/// Face expression values present on `lingafriq_cast.riv`.
enum CharacterVmExpression {
  neutral('neutral'),
  happy('happy'),
  proud('proud'),
  curious('curious'),
  concerned('concerned'),
  surprised('surprised'),
  playful('playful'),
  focused('focused');

  const CharacterVmExpression(this.riveName);
  final String riveName;
}

/// ADR-030 persona `emotion` union (P11-003); may exceed Rive enum until art catches up.
enum CharacterVmPersonaExpression {
  neutral('neutral'),
  happy('happy'),
  proud('proud'),
  curious('curious'),
  concerned('concerned'),
  surprised('surprised'),
  thinking('thinking'),
  encouraging('encouraging'),
  playful('playful'),
  focused('focused');

  const CharacterVmPersonaExpression(this.riveName);
  final String riveName;

  static CharacterVmPersonaExpression? tryParse(String raw) {
    final key = raw.trim().toLowerCase();
    for (final v in CharacterVmPersonaExpression.values) {
      if (v.riveName == key) return v;
    }
    if (key == 'calm') return CharacterVmPersonaExpression.neutral;
    return null;
  }
}

/// Lesson / UI triggers wired on CharacterVM (not legacy isListening booleans).
enum CharacterVmTrigger {
  correct('correct'),
  celebrate('celebrate'),
  levelUp('levelUp'),
  wave('wave'),
  nod('nod'),
  shrug('shrug'),
  tapped('tapped'),
  incorrect('incorrect');

  const CharacterVmTrigger(this.riveName);
  final String riveName;

  static const lessonTriggers = <CharacterVmTrigger>[
    CharacterVmTrigger.celebrate,
    CharacterVmTrigger.levelUp,
    CharacterVmTrigger.wave,
    CharacterVmTrigger.nod,
    CharacterVmTrigger.shrug,
    CharacterVmTrigger.tapped,
  ];
}

@immutable
class CharacterVmOutOfRangeEvent {
  const CharacterVmOutOfRangeEvent({
    required this.property,
    required this.attempted,
    required this.clamped,
    required this.min,
    required this.max,
  });

  final String property;
  final double attempted;
  final double clamped;
  final double min;
  final double max;
}

@immutable
class CharacterVmState {
  const CharacterVmState({
    this.activity = CharacterVmActivity.idle,
    this.expression = CharacterVmExpression.neutral,
    this.intensity = CharacterVmContract.intensityDefault,
    this.energy = 0.5,
    this.gazeX = 0,
    this.gazeY = 0,
    this.headTilt = 0,
    this.viseme = 'sil',
    this.jawOpen = 0,
    this.blinkRate = 0.5,
    this.skinTone,
    this.hairColor,
    this.outfitPrimary,
    this.outfitSecondary,
    this.reducedMotion = false,
    this.wheelchair = false,
    this.bodyType = 'average',
    this.faceShape = 'oval',
  });

  final CharacterVmActivity activity;
  final CharacterVmExpression expression;
  final double intensity;
  final double energy;
  final double gazeX;
  final double gazeY;
  final double headTilt;
  final String viseme;
  final double jawOpen;
  final double blinkRate;
  final Color? skinTone;
  final Color? hairColor;
  final Color? outfitPrimary;
  final Color? outfitSecondary;
  final bool reducedMotion;
  final bool wheelchair;
  final String bodyType;
  final String faceShape;
}

/// Loads `character_vm.schema.json` and exposes CI parity helpers.
class CharacterVmContract {
  CharacterVmContract._(this._raw);

  static const intensityDefault = 0.6;
  static const schemaRelativePath = 'lib/avatars/contract/character_vm.schema.json';

  final Map<String, dynamic> _raw;

  static CharacterVmContract? _cached;

  static CharacterVmContract loadFromJson(Map<String, dynamic> raw) {
    _cached = CharacterVmContract._(raw);
    return _cached!;
  }

  static CharacterVmContract loadFromJsonString(String text) =>
      loadFromJson(jsonDecode(text) as Map<String, dynamic>);

  List<String> get boundPropertyNames => (properties)
      .map((p) => p['name'] as String)
      .toList(growable: false);

  List<Map<String, dynamic>> get properties =>
      (_raw['properties'] as List).cast<Map<String, dynamic>>();

  Map<String, List<String>> get enums {
    final raw = _raw['enums'] as Map<String, dynamic>;
    return raw.map(
      (k, v) => MapEntry(k, (v as List).cast<String>()),
    );
  }

  List<String> get lessonTriggerNames =>
      ((_raw['triggers'] as Map)['lessonTriggers'] as List).cast<String>();

  /// Fails CI when Dart schema names a property missing from the decoded .riv.
  static List<String> missingOnRive(
    File file,
    CharacterVmContract contract,
  ) {
    final vm = file.viewModelByName('CharacterVM');
    if (vm == null) return contract.boundPropertyNames;
    final onRive = vm.properties.map((p) => p.name).toSet();
    return contract.boundPropertyNames
        .where((name) => !onRive.contains(name))
        .toList();
  }
}

/// Writes [CharacterVmState] to a bound Rive VM instance with range clamping.
class CharacterVmWriter {
  CharacterVmWriter({
    required ViewModelInstance instance,
    void Function(CharacterVmOutOfRangeEvent event)? onOutOfRange,
  })  : _instance = instance,
        _onOutOfRange = onOutOfRange;

  final ViewModelInstance _instance;
  final void Function(CharacterVmOutOfRangeEvent event)? _onOutOfRange;

  void apply(CharacterVmState state) {
    _instance.enumerator('activity')?.value = state.activity.riveName;
    _instance.enumerator('expression')?.value = state.expression.riveName;
    _setNumber('intensity', state.intensity, 0, 1);
    _setNumber('energy', state.energy, 0, 1);
    _setNumber('gazeX', state.gazeX, -1, 1);
    _setNumber('gazeY', state.gazeY, -1, 1);
    _setNumber('headTilt', state.headTilt, -1, 1);
    _instance.enumerator('viseme')?.value = state.viseme;
    _setNumber('jawOpen', state.jawOpen, 0, 1);
    _setNumber('blinkRate', state.blinkRate, 0, 1);
    if (state.skinTone != null) {
      _instance.color('skinTone')?.value = state.skinTone!;
    }
    if (state.hairColor != null) {
      _instance.color('hairColor')?.value = state.hairColor!;
    }
    if (state.outfitPrimary != null) {
      _instance.color('outfitPrimary')?.value = state.outfitPrimary!;
    }
    if (state.outfitSecondary != null) {
      _instance.color('outfitSecondary')?.value = state.outfitSecondary!;
    }
    _instance.boolean('reducedMotion')?.value = state.reducedMotion;
    _instance.boolean('wheelchair')?.value = state.wheelchair;
    _instance.enumerator('bodyType')?.value = state.bodyType;
    _instance.enumerator('faceShape')?.value = state.faceShape;
  }

  void fire(CharacterVmTrigger trigger) {
    _instance.trigger(trigger.riveName)?.trigger();
  }

  void _setNumber(String name, double value, double min, double max) {
    final clamped = _clamp(name, value, min, max);
    _instance.number(name)?.value = clamped;
  }

  double _clamp(String name, double value, double min, double max) {
    if (value < min || value > max) {
      final clamped = value.clamp(min, max);
      _onOutOfRange?.call(
        CharacterVmOutOfRangeEvent(
          property: name,
          attempted: value,
          clamped: clamped,
          min: min,
          max: max,
        ),
      );
      return clamped;
    }
    return value;
  }
}
