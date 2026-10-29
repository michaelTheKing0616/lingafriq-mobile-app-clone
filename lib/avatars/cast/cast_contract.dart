import 'dart:convert';

import 'package:flutter/services.dart';

import '../a11y/avatar_semantics.dart';
import '../customisation/slot_binding.dart';

class CastPartSlot {
  const CastPartSlot({required this.name, required this.options});

  final String name;
  final List<String> options;
}

class CastContract {
  const CastContract({
    required this.artboards,
    required this.partSlots,
    required this.enums,
    required this.instances,
    required this.budgetBytes,
  });

  final List<String> artboards;
  final List<CastPartSlot> partSlots;
  final Map<String, List<String>> enums;
  final List<String> instances;
  final int budgetBytes;

  static const assetPath = 'assets/rive/lingafriq_cast.contract.json';

  static Future<CastContract> load() async {
    final raw = await rootBundle.loadString(assetPath);
    return parse(jsonDecode(raw) as Map<String, dynamic>);
  }

  static Future<AvatarPartCatalog> loadPartCatalog() async {
    final raw = await rootBundle.loadString(assetPath);
    final catalog =
        AvatarPartCatalog.fromContractJson(jsonDecode(raw) as Map<String, dynamic>);
    catalog.validateLibraryMinimums();
    return catalog;
  }

  static CastContract parse(Map<String, dynamic> json) {
    final slots = <CastPartSlot>[];
    for (final entry in json['properties'] as List) {
      final property = entry as Map<String, dynamic>;
      if (property['type'] != 'Artboard') continue;
      slots.add(
        CastPartSlot(
          name: property['name'] as String,
          options: (property['options'] as List).cast<String>(),
        ),
      );
    }
    final enums = <String, List<String>>{};
    (json['enums'] as Map).forEach((key, value) {
      enums[key as String] = (value as List).cast<String>();
    });
    return CastContract(
      artboards: (json['artboards'] as Map).keys.cast<String>().toList(),
      partSlots: slots,
      enums: enums,
      instances: (json['instances'] as List).cast<String>(),
      budgetBytes: (json['budget'] as Map)['bytesPerCharacterFile'] as int,
    );
  }
}

String castSpokenName(String preset) {
  const names = {
    'Polie': 'Polie',
    'PaLingAfriq': 'Pa LingAfriq',
    'Adisa': 'Adisa',
    'Zuri': 'Zuri',
    'Kofi': 'Kofi',
    'Lamine': 'Lamine',
    'Ayanwale': 'Ayanwale',
    'Amara': 'Amara',
    'Tolu_Lagos': 'Tolu',
    'Ama_Accra': 'Ama',
    'Otieno_Nairobi': 'Otieno',
    'Thandi_Durban': 'Thandi',
    'Liya_Addis': 'Liya',
    'Moussa_Dakar': 'Moussa',
    'Funmilayo_Ibadan': 'Funmilayo',
    'Fuseini_Tamale': 'Fuseini',
    'Learner': 'Learner',
  };
  return names[preset] ?? preset.split('_').first;
}

String castSemanticsLabel({
  required String name,
  required String expression,
  required String activity,
}) =>
    avatarSemanticsLabel(
      name: name,
      expression: expression,
      activity: activity,
    );
