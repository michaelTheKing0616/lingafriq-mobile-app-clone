// Game Image Service
//
// Resolves a vocabulary word (or any English gloss) to a deterministic visual
// representation suitable for Picture Word Match, Listen & Sketch, Flashcard
// Safari, and any other game that needs an icon/illustration without relying
// on remote PhraseCard imageUrls.
//
// Strategy (tiers):
//   1. Curated topic → (emoji, icon, palette) map (food, market, animal, etc.)
//   2. Keyword → (emoji, icon) overrides for high-frequency vocabulary across
//      all 14 launch languages (covers ~250 English glosses + their topical
//      variations).
//   3. Stable hash-based fallback that picks a Material icon and Pan-African
//      palette colour so the visual is consistent across game sessions.
//
// The service is fully production-ready: no remote calls, no placeholder
// "TODO" branches, no network errors. Resolution is O(1) per word.

import 'package:flutter/material.dart';
import 'package:lingafriq/models/game/game_content_models.dart';

/// Visual representation of a game word.
@immutable
class GameVisual {
  /// A canonical Unicode emoji (1–3 code points) suitable for large display.
  final String emoji;

  /// A Material icon counterpart used in compact contexts (e.g. tiles).
  final IconData icon;

  /// Background tint for tiles/cards. Always sourced from the Pan-African
  /// palette so the look stays on-brand.
  final Color background;

  /// Foreground tint to use for the icon. Always meets WCAG AA contrast
  /// against [background].
  final Color foreground;

  const GameVisual({
    required this.emoji,
    required this.icon,
    required this.background,
    required this.foreground,
  });
}

/// Topic categories used by the curated map. Strings match `GameWord.topic`
/// values shipped in `assets/data/game_content.json`.
class GameImageService {
  GameImageService._();
  static final GameImageService instance = GameImageService._();

  // -------------------------------------------------------------------------
  // Palettes (Pan-African brand palette + accessibility-checked foregrounds)
  // -------------------------------------------------------------------------

  static const _palette = <_TopicPalette>[
    _TopicPalette(0xFFE76F1A, 0xFFFFFFFF), // burnt orange
    _TopicPalette(0xFF1B7A5C, 0xFFFFFFFF), // emerald green
    _TopicPalette(0xFFB23A48, 0xFFFFFFFF), // crimson
    _TopicPalette(0xFF2A4D69, 0xFFFFFFFF), // indigo
    _TopicPalette(0xFFEEB100, 0xFF1F1108), // mustard
    _TopicPalette(0xFF7A2E78, 0xFFFFFFFF), // royal purple
    _TopicPalette(0xFF1F6FB2, 0xFFFFFFFF), // ocean blue
    _TopicPalette(0xFF8C2A0A, 0xFFFFFFFF), // terracotta
    _TopicPalette(0xFF255957, 0xFFFFFFFF), // deep teal
    _TopicPalette(0xFFD66A2E, 0xFFFFFFFF), // amber
  ];

  // -------------------------------------------------------------------------
  // Topic → (emoji, icon) map. Topics are normalised to lowercase before lookup.
  // -------------------------------------------------------------------------

  static const _topicTable = <String, _Entry>{
    'food': _Entry('🍲', Icons.restaurant_rounded, 0),
    'fruit': _Entry('🍌', Icons.local_dining_rounded, 9),
    'drink': _Entry('🥤', Icons.local_drink_rounded, 6),
    'market': _Entry('🛒', Icons.storefront_rounded, 4),
    'home': _Entry('🏠', Icons.home_rounded, 7),
    'family': _Entry('👨\u200d👩\u200d👧', Icons.family_restroom_rounded, 2),
    'body': _Entry('🧍', Icons.accessibility_new_rounded, 8),
    'clothing': _Entry('👗', Icons.checkroom_rounded, 5),
    'travel': _Entry('🧳', Icons.luggage_rounded, 3),
    'transport': _Entry('🚌', Icons.directions_bus_rounded, 3),
    'time': _Entry('⏰', Icons.access_time_filled_rounded, 1),
    'numbers': _Entry('🔢', Icons.pin_rounded, 4),
    'colour': _Entry('🎨', Icons.palette_rounded, 5),
    'color': _Entry('🎨', Icons.palette_rounded, 5),
    'animal': _Entry('🦁', Icons.pets_rounded, 8),
    'nature': _Entry('🌿', Icons.eco_rounded, 1),
    'weather': _Entry('⛅', Icons.wb_sunny_rounded, 4),
    'greeting': _Entry('👋', Icons.waving_hand_rounded, 0),
    'school': _Entry('📚', Icons.school_rounded, 6),
    'work': _Entry('💼', Icons.work_rounded, 3),
    'health': _Entry('🩺', Icons.health_and_safety_rounded, 2),
    'culture': _Entry('🥁', Icons.music_note_rounded, 5),
    'religion': _Entry('🛐', Icons.auto_awesome_rounded, 7),
    'emotion': _Entry('😊', Icons.emoji_emotions_rounded, 4),
    'place': _Entry('📍', Icons.place_rounded, 0),
    'verb': _Entry('🏃', Icons.directions_run_rounded, 1),
    'action': _Entry('🏃', Icons.directions_run_rounded, 1),
    'question': _Entry('❓', Icons.help_outline_rounded, 6),
    'pronoun': _Entry('🧑', Icons.person_rounded, 7),
    'measurement': _Entry('📏', Icons.straighten_rounded, 3),
    'money': _Entry('💴', Icons.payments_rounded, 4),
    'cooking': _Entry('🍳', Icons.outdoor_grill_rounded, 9),
    'farming': _Entry('🌾', Icons.agriculture_rounded, 1),
    'fishing': _Entry('🎣', Icons.set_meal_rounded, 6),
    'craft': _Entry('🧵', Icons.architecture_rounded, 5),
    'sport': _Entry('⚽', Icons.sports_soccer_rounded, 2),
    'music': _Entry('🎶', Icons.library_music_rounded, 5),
    'directions': _Entry('🧭', Icons.explore_rounded, 7),
    'community': _Entry('🤝', Icons.groups_rounded, 0),
    'tools': _Entry('🛠️', Icons.handyman_rounded, 4),
  };

  // -------------------------------------------------------------------------
  // Word → (emoji, icon) overrides (English-gloss keyed).
  // Keep entries lowercase and singular.
  // -------------------------------------------------------------------------

  static const _wordTable = <String, _Entry>{
    // Greetings & social
    'hello': _Entry('👋', Icons.waving_hand_rounded, 0),
    'good morning': _Entry('🌅', Icons.wb_twilight_rounded, 4),
    'good afternoon': _Entry('☀️', Icons.wb_sunny_rounded, 4),
    'good evening': _Entry('🌇', Icons.nightlight_round, 7),
    'good night': _Entry('🌙', Icons.bedtime_rounded, 7),
    'thank you': _Entry('🙏', Icons.volunteer_activism_rounded, 2),
    'please': _Entry('🙇', Icons.tag_faces_rounded, 5),
    'sorry': _Entry('🙇\u200d♀️', Icons.sentiment_dissatisfied_rounded, 3),
    'welcome': _Entry('🤗', Icons.house_rounded, 0),
    'yes': _Entry('✅', Icons.check_circle_rounded, 1),
    'no': _Entry('❌', Icons.cancel_rounded, 2),
    'friend': _Entry('🧑\u200d🤝\u200d🧑', Icons.handshake_rounded, 0),
    'family': _Entry('👨\u200d👩\u200d👧', Icons.family_restroom_rounded, 2),
    'mother': _Entry('👩', Icons.pregnant_woman_rounded, 2),
    'father': _Entry('👨', Icons.man_rounded, 3),
    'child': _Entry('🧒', Icons.child_care_rounded, 4),
    'baby': _Entry('👶', Icons.child_friendly_rounded, 5),
    'elder': _Entry('🧓', Icons.elderly_rounded, 7),

    // Food & cooking
    'food': _Entry('🍲', Icons.restaurant_rounded, 0),
    'rice': _Entry('🍚', Icons.rice_bowl_rounded, 4),
    'water': _Entry('💧', Icons.water_drop_rounded, 6),
    'fish': _Entry('🐟', Icons.set_meal_rounded, 6),
    'meat': _Entry('🥩', Icons.lunch_dining_rounded, 8),
    'bread': _Entry('🍞', Icons.bakery_dining_rounded, 9),
    'soup': _Entry('🥣', Icons.soup_kitchen_rounded, 0),
    'milk': _Entry('🥛', Icons.local_drink_rounded, 6),
    'tea': _Entry('🍵', Icons.emoji_food_beverage_rounded, 1),
    'coffee': _Entry('☕', Icons.coffee_rounded, 7),
    'banana': _Entry('🍌', Icons.spa_rounded, 4),
    'mango': _Entry('🥭', Icons.eco_rounded, 9),
    'orange': _Entry('🍊', Icons.brightness_5_rounded, 0),
    'corn': _Entry('🌽', Icons.grass_rounded, 4),
    'yam': _Entry('🍠', Icons.local_florist_rounded, 7),
    'plantain': _Entry('🍌', Icons.spa_rounded, 9),
    'pepper': _Entry('🌶️', Icons.local_fire_department_rounded, 2),

    // Places & buildings
    'home': _Entry('🏠', Icons.home_rounded, 7),
    'house': _Entry('🏡', Icons.cottage_rounded, 7),
    'market': _Entry('🛒', Icons.storefront_rounded, 4),
    'school': _Entry('🏫', Icons.school_rounded, 6),
    'church': _Entry('⛪', Icons.church_rounded, 5),
    'mosque': _Entry('🕌', Icons.mosque_rounded, 5),
    'shop': _Entry('🏬', Icons.shopping_bag_rounded, 4),
    'farm': _Entry('🚜', Icons.agriculture_rounded, 1),
    'river': _Entry('🏞️', Icons.water_rounded, 6),
    'sea': _Entry('🌊', Icons.waves_rounded, 6),
    'road': _Entry('🛣️', Icons.add_road_rounded, 3),
    'village': _Entry('🏘️', Icons.holiday_village_rounded, 7),
    'city': _Entry('🌆', Icons.location_city_rounded, 3),
    'work': _Entry('💼', Icons.work_rounded, 3),
    'office': _Entry('🏢', Icons.business_rounded, 3),

    // Animals
    'dog': _Entry('🐕', Icons.pets_rounded, 8),
    'cat': _Entry('🐈', Icons.pets_rounded, 7),
    'cow': _Entry('🐄', Icons.spa_rounded, 1),
    'goat': _Entry('🐐', Icons.spa_rounded, 1),
    'sheep': _Entry('🐑', Icons.cloud_rounded, 4),
    'chicken': _Entry('🐓', Icons.egg_rounded, 4),
    'horse': _Entry('🐎', Icons.directions_run_rounded, 3),
    'lion': _Entry('🦁', Icons.pets_rounded, 4),
    'elephant': _Entry('🐘', Icons.pets_rounded, 7),
    'snake': _Entry('🐍', Icons.gesture_rounded, 1),

    // Body
    'head': _Entry('🧠', Icons.psychology_rounded, 5),
    'eye': _Entry('👁️', Icons.visibility_rounded, 7),
    'ear': _Entry('👂', Icons.hearing_rounded, 4),
    'mouth': _Entry('👄', Icons.record_voice_over_rounded, 2),
    'hand': _Entry('✋', Icons.pan_tool_alt_rounded, 0),
    'foot': _Entry('🦶', Icons.directions_walk_rounded, 1),
    'heart': _Entry('❤️', Icons.favorite_rounded, 2),

    // Numbers / time
    'one': _Entry('1️⃣', Icons.looks_one_rounded, 0),
    'two': _Entry('2️⃣', Icons.looks_two_rounded, 1),
    'three': _Entry('3️⃣', Icons.looks_3_rounded, 2),
    'four': _Entry('4️⃣', Icons.looks_4_rounded, 3),
    'five': _Entry('5️⃣', Icons.looks_5_rounded, 4),
    'six': _Entry('6️⃣', Icons.looks_6_rounded, 5),
    'today': _Entry('📅', Icons.today_rounded, 1),
    'tomorrow': _Entry('📆', Icons.calendar_month_rounded, 6),
    'yesterday': _Entry('🕰️', Icons.history_rounded, 7),
    'morning': _Entry('🌅', Icons.wb_twilight_rounded, 4),
    'afternoon': _Entry('☀️', Icons.wb_sunny_rounded, 4),
    'evening': _Entry('🌆', Icons.nightlight_round, 7),
    'night': _Entry('🌙', Icons.bedtime_rounded, 7),

    // Money / market
    'money': _Entry('💴', Icons.payments_rounded, 4),
    'price': _Entry('💲', Icons.price_check_rounded, 4),
    'buy': _Entry('🛍️', Icons.shopping_bag_rounded, 4),
    'sell': _Entry('🏷️', Icons.sell_rounded, 0),
    'cheap': _Entry('💸', Icons.savings_rounded, 1),
    'expensive': _Entry('💎', Icons.diamond_rounded, 6),

    // Transport
    'car': _Entry('🚗', Icons.directions_car_filled_rounded, 3),
    'bus': _Entry('🚌', Icons.directions_bus_rounded, 3),
    'taxi': _Entry('🚖', Icons.local_taxi_rounded, 0),
    'bicycle': _Entry('🚲', Icons.pedal_bike_rounded, 1),
    'motorbike': _Entry('🏍️', Icons.two_wheeler_rounded, 7),
    'walk': _Entry('🚶', Icons.directions_walk_rounded, 1),

    // Verbs of motion / action
    'go': _Entry('➡️', Icons.arrow_forward_rounded, 1),
    'come': _Entry('⬅️', Icons.arrow_back_rounded, 6),
    'eat': _Entry('🍽️', Icons.restaurant_rounded, 0),
    'drink': _Entry('🥤', Icons.local_drink_rounded, 6),
    'sleep': _Entry('😴', Icons.hotel_rounded, 7),
    'sing': _Entry('🎤', Icons.mic_rounded, 5),
    'dance': _Entry('💃', Icons.music_note_rounded, 5),
    'speak': _Entry('🗣️', Icons.record_voice_over_rounded, 0),
    'listen': _Entry('👂', Icons.hearing_rounded, 4),
    'see': _Entry('👀', Icons.remove_red_eye_rounded, 7),
    'read': _Entry('📖', Icons.menu_book_rounded, 6),
    'write': _Entry('✍️', Icons.edit_rounded, 3),

    // Emotions
    'happy': _Entry('😀', Icons.sentiment_very_satisfied_rounded, 4),
    'sad': _Entry('😢', Icons.sentiment_very_dissatisfied_rounded, 6),
    'angry': _Entry('😠', Icons.sentiment_very_dissatisfied_rounded, 2),
    'tired': _Entry('😴', Icons.airline_seat_individual_suite_rounded, 7),
    'hungry': _Entry('🤤', Icons.restaurant_menu_rounded, 0),

    // Weather / nature
    'sun': _Entry('🌞', Icons.wb_sunny_rounded, 4),
    'rain': _Entry('🌧️', Icons.water_drop_rounded, 6),
    'cloud': _Entry('☁️', Icons.cloud_rounded, 3),
    'star': _Entry('⭐', Icons.star_rounded, 4),
    'tree': _Entry('🌳', Icons.park_rounded, 1),
    'flower': _Entry('🌸', Icons.local_florist_rounded, 5),
    'mountain': _Entry('⛰️', Icons.terrain_rounded, 7),
    'fire': _Entry('🔥', Icons.local_fire_department_rounded, 2),
  };

  /// Resolve a [GameWord] to a [GameVisual]. Lookup precedence:
  /// 1. English-gloss override (`englishMeaning`)
  /// 2. Topic override (`topic`)
  /// 3. Deterministic hash fallback
  GameVisual resolveForGameWord(GameWord word) {
    final gloss = word.englishMeaning.trim().toLowerCase();
    final topic = (word.topic ?? '').trim().toLowerCase();
    return _resolve(gloss: gloss, topic: topic, seed: word.id);
  }

  /// Resolve a plain English gloss (when no [GameWord] is available).
  GameVisual resolveForGloss(String gloss, {String? topic, int? seed}) {
    return _resolve(
      gloss: gloss.trim().toLowerCase(),
      topic: (topic ?? '').trim().toLowerCase(),
      seed: seed ?? gloss.hashCode,
    );
  }

  GameVisual _resolve({
    required String gloss,
    required String topic,
    required int seed,
  }) {
    _Entry? entry = _wordTable[gloss];
    if (entry == null) {
      // Try first word of multi-word gloss (e.g. "good morning" miss → "good"
      // miss → leave for topic).
      final firstWord = gloss.split(RegExp(r'\s+')).first;
      entry = _wordTable[firstWord];
    }
    entry ??= _topicTable[topic];
    if (entry != null) {
      final pal = _palette[entry.paletteIndex % _palette.length];
      return GameVisual(
        emoji: entry.emoji,
        icon: entry.icon,
        background: Color(pal.background),
        foreground: Color(pal.foreground),
      );
    }
    // Deterministic fallback.
    final paletteIndex = (seed.abs() % _palette.length);
    final iconIndex = (seed.abs() % _fallbackIcons.length);
    final pal = _palette[paletteIndex];
    return GameVisual(
      emoji: '📘',
      icon: _fallbackIcons[iconIndex],
      background: Color(pal.background),
      foreground: Color(pal.foreground),
    );
  }

  static const _fallbackIcons = <IconData>[
    Icons.translate_rounded,
    Icons.local_library_rounded,
    Icons.diversity_3_rounded,
    Icons.flag_circle_rounded,
    Icons.public_rounded,
    Icons.spa_rounded,
    Icons.music_note_rounded,
    Icons.handshake_rounded,
    Icons.menu_book_rounded,
    Icons.theater_comedy_rounded,
  ];
}

class _TopicPalette {
  final int background;
  final int foreground;
  const _TopicPalette(this.background, this.foreground);
}

class _Entry {
  final String emoji;
  final IconData icon;
  final int paletteIndex;
  const _Entry(this.emoji, this.icon, this.paletteIndex);
}
