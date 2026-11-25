import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/navigation/surfacing_rules.dart';

final SurfacingRules _rules = SurfacingRules.parse(
  File(kSurfacingRulesAsset).readAsStringSync(),
);

final DateTime _day = DateTime.utc(2026, 4, 2, 15);

SurfacingEvent _tone(DateTime at) {
  return SurfacingEvent(kind: kSurfacingToneError, at: at);
}

List<String> _ids(List<SurfacingOffer> offers) {
  return offers.map((SurfacingOffer offer) => offer.id).toList();
}

void main() {
  test('shipped table loads from the config file', () {
    final String raw = File(kSurfacingRulesAsset).readAsStringSync();
    expect(raw.contains('\u2014'), isFalse);
    expect(raw.toLowerCase().contains('world-class'), isFalse);
    expect(raw.toLowerCase().contains('world class'), isFalse);
    expect(RegExp(r'\belite\b', caseSensitive: false).hasMatch(raw), isFalse);
    expect(
      RegExp(r'\bseamless\b', caseSensitive: false).hasMatch(raw),
      isFalse,
    );
    expect(raw.toLowerCase().contains('confidence'), isFalse);
    expect(_rules.version, 1);
    expect(
      _rules.rules.map((SurfacingRule rule) => rule.id),
      containsAll(<String>[
        'lesson_recap',
        'word_card',
        'lens_point_say',
        'tone_struggle',
      ]),
    );
  });

  test('no moment and no events offers nothing', () {
    final List<SurfacingOffer> offers = _rules.evaluate(
      SurfacingQuery(now: _day),
    );
    expect(offers, isEmpty);
  });

  group('AC1 lesson recap', () {
    test(
      'a finished lesson with Lesson Recap open offers Say it and one game',
      () {
        final List<SurfacingOffer> offers = _rules.evaluate(
          SurfacingQuery(
            now: _day,
            lessonFinished: true,
            lessonRecapOpen: true,
          ),
        );
        expect(_ids(offers), <String>['say_it', 'tone_twins']);
        expect(offers.first.label, 'Say it');
        expect(offers.first.place, 'lesson_recap');
        expect(offers.first.isMatchingGame, isFalse);
        final List<SurfacingOffer> games = offers
            .where((SurfacingOffer offer) => offer.isMatchingGame)
            .toList();
        expect(games, hasLength(1));
        expect(games.single.label, 'Tone twins');
        expect(games.single.place, 'play');
      },
    );

    test('Lesson Recap without a finished lesson offers neither', () {
      final List<SurfacingOffer> offers = _rules.evaluate(
        SurfacingQuery(now: _day, lessonRecapOpen: true),
      );
      expect(offers, isEmpty);
    });

    test('a finished lesson with Lesson Recap closed offers neither', () {
      final List<SurfacingOffer> offers = _rules.evaluate(
        SurfacingQuery(now: _day, lessonFinished: true),
      );
      expect(offers, isEmpty);
    });
  });

  group('AC2 word card', () {
    test(
      'a long-press that opens the card offers dictionary, save, practise',
      () {
        final List<SurfacingOffer> offers = _rules.evaluate(
          SurfacingQuery(now: _day, wordLongPressed: true, wordCardOpen: true),
        );
        expect(_ids(offers), <String>['living_dictionary', 'save', 'practise']);
        expect(offers.map((SurfacingOffer offer) => offer.label), <String>[
          'Living Dictionary',
          'Save',
          'Practise',
        ]);
        expect(
          offers.every((SurfacingOffer offer) => offer.place == 'word_card'),
          isTrue,
        );
      },
    );

    test('a long-press with the card closed offers nothing', () {
      final List<SurfacingOffer> offers = _rules.evaluate(
        SurfacingQuery(now: _day, wordLongPressed: true),
      );
      expect(offers, isEmpty);
    });

    test('an open card without a long-press offers nothing', () {
      final List<SurfacingOffer> offers = _rules.evaluate(
        SurfacingQuery(now: _day, wordCardOpen: true),
      );
      expect(offers, isEmpty);
    });
  });

  group('AC3 Lens', () {
    test('an object lesson offers Lens Point & Say', () {
      final List<SurfacingOffer> offers = _rules.evaluate(
        SurfacingQuery(now: _day, objectLesson: true),
      );
      final SurfacingOffer lens = offers.singleWhere(
        (SurfacingOffer offer) => offer.id == 'lens_point_say',
      );
      expect(lens.label, 'Point & Say');
      expect(lens.place, 'lens');
      expect(_ids(offers), <String>['lens_point_say', 'find_three_at_home']);
      expect(offers.last.label, 'Find 3 of these at home');
      expect(offers.last.place, 'lesson');
    });

    test('the camera button offers Lens Point & Say', () {
      final List<SurfacingOffer> offers = _rules.evaluate(
        SurfacingQuery(now: _day, cameraButtonUsed: true),
      );
      expect(_ids(offers), <String>['lens_point_say']);
      expect(offers.single.label, 'Point & Say');
      expect(offers.single.place, 'lens');
    });

    test('object lesson and camera button offer Point & Say once', () {
      final List<SurfacingOffer> offers = _rules.evaluate(
        SurfacingQuery(now: _day, objectLesson: true, cameraButtonUsed: true),
      );
      expect(
        offers.where((SurfacingOffer offer) => offer.id == 'lens_point_say'),
        hasLength(1),
      );
    });

    test('neither an object lesson nor the camera offers Lens', () {
      final List<SurfacingOffer> offers = _rules.evaluate(
        SurfacingQuery(now: _day),
      );
      expect(
        offers.where((SurfacingOffer offer) => offer.place == 'lens'),
        isEmpty,
      );
    });
  });

  group('AC4 tones', () {
    final List<SurfacingEvent> repeated = <SurfacingEvent>[
      SurfacingEvent(
        kind: kSurfacingToneError,
        at: DateTime.utc(2026, 4, 2, 9),
      ),
      SurfacingEvent(
        kind: kSurfacingToneError,
        at: DateTime.utc(2026, 4, 2, 12),
      ),
    ];

    SurfacingQuery query({
      List<SurfacingEvent>? events,
      List<SurfacingShown>? lastShown,
      DateTime? now,
    }) {
      return SurfacingQuery(
        now: now ?? _day,
        events: events ?? repeated,
        lastShown: lastShown ?? const <SurfacingShown>[],
      );
    }

    test('repeated supplied tone errors offer Tone Gym and Tone Forge', () {
      final List<SurfacingOffer> offers = _rules.evaluate(query());
      final SurfacingOffer gym = offers.singleWhere(
        (SurfacingOffer offer) => offer.id == 'tone_gym',
      );
      final SurfacingOffer forge = offers.singleWhere(
        (SurfacingOffer offer) => offer.id == 'tone_forge',
      );
      expect(gym.label, 'Tone Gym');
      expect(gym.place, 'today');
      expect(gym.maxPerDay, 1);
      expect(forge.label, 'Tone Forge');
      expect(forge.place, 'play');
      expect(forge.maxPerDay, 1);
      final SurfacingOffer drum = offers.singleWhere(
        (SurfacingOffer offer) => offer.id == 'talking_drum',
      );
      expect(drum.label, 'Talking Drum');
      expect(drum.place, 'play');
      expect(drum.maxPerDay, 1);
      expect(_ids(offers), <String>['tone_gym', 'tone_forge', 'talking_drum']);
    });

    test('no supplied events does not fabricate a tone offer', () {
      expect(_rules.evaluate(query(events: const <SurfacingEvent>[])), isEmpty);
    });

    test('one tone error is not repeated', () {
      expect(
        _rules.evaluate(query(events: <SurfacingEvent>[_tone(_day)])),
        isEmpty,
      );
    });

    test('events of another kind do not count', () {
      final List<SurfacingOffer> offers = _rules.evaluate(
        query(
          events: <SurfacingEvent>[
            SurfacingEvent(kind: 'segmental_error', at: _day),
            SurfacingEvent(kind: 'segmental_error', at: _day),
          ],
        ),
      );
      expect(offers, isEmpty);
    });

    test('supplied errors count without a hidden time window', () {
      final List<SurfacingOffer> offers = _rules.evaluate(
        query(
          events: <SurfacingEvent>[
            _tone(DateTime.utc(2020, 1, 1)),
            _tone(DateTime.utc(2024, 8, 1)),
          ],
        ),
      );
      expect(_ids(offers), containsAll(<String>['tone_gym', 'tone_forge']));
    });

    test(
      'a second evaluation the same day does not offer that surface again',
      () {
        final List<SurfacingOffer> first = _rules.evaluate(query());
        expect(first, isNotEmpty);
        final List<SurfacingShown> shown = <SurfacingShown>[
          for (final SurfacingOffer offer in first)
            SurfacingShown(offerId: offer.id, at: _day),
        ];
        final DateTime later = _day.add(const Duration(hours: 4));
        final List<SurfacingOffer> second = _rules.evaluate(
          query(now: later, lastShown: shown),
        );
        expect(second, isEmpty);
      },
    );

    test('capping Tone Gym leaves Tone Forge for the same day', () {
      final List<SurfacingOffer> offers = _rules.evaluate(
        query(
          lastShown: <SurfacingShown>[
            SurfacingShown(offerId: 'tone_gym', at: _day),
          ],
        ),
      );
      expect(_ids(offers), <String>['tone_forge', 'talking_drum']);
    });

    test('the next day can offer a surface that was shown yesterday', () {
      final List<SurfacingOffer> offers = _rules.evaluate(
        query(
          now: DateTime.utc(2026, 4, 3, 8),
          lastShown: <SurfacingShown>[
            SurfacingShown(offerId: 'tone_gym', at: _day),
            SurfacingShown(offerId: 'tone_forge', at: _day),
            SurfacingShown(offerId: 'talking_drum', at: _day),
          ],
        ),
      );
      expect(_ids(offers), <String>['tone_gym', 'tone_forge', 'talking_drum']);
    });

    test('the supplied clock decides the day, not the device clock', () {
      final DateTime deviceToday = DateTime.now();
      final DateTime queryNow = DateTime(
        deviceToday.year,
        deviceToday.month,
        deviceToday.day,
      ).subtract(const Duration(days: 3));
      final List<SurfacingOffer> offers = _rules.evaluate(
        query(
          now: queryNow,
          lastShown: <SurfacingShown>[
            SurfacingShown(offerId: 'tone_gym', at: deviceToday),
            SurfacingShown(offerId: 'tone_forge', at: deviceToday),
            SurfacingShown(offerId: 'talking_drum', at: deviceToday),
          ],
        ),
      );
      expect(_ids(offers), containsAll(<String>['tone_gym', 'tone_forge']));
    });
  });

  test('partial moments do not offer', () {
    final List<SurfacingOffer> offers = _rules.evaluate(
      SurfacingQuery(
        now: _day,
        lessonFinished: true,
        wordLongPressed: true,
        events: <SurfacingEvent>[_tone(_day)],
      ),
    );
    expect(offers, isEmpty);
  });

  test('the table, not a hard-coded label, decides the offer', () {
    const String source = '''
{
  "version": 1,
  "rules": [
    {
      "id": "custom_tone",
      "when": {"event": "tone_error", "min_count": 3},
      "offers": [
        {
          "id": "tone_gym",
          "label": "Custom gym",
          "place": "today",
          "max_per_day": 1
        }
      ]
    }
  ]
}
''';
    final SurfacingRules rules = SurfacingRules.parse(source);
    final List<SurfacingEvent> two = <SurfacingEvent>[_tone(_day), _tone(_day)];
    expect(rules.evaluate(SurfacingQuery(now: _day, events: two)), isEmpty);
    final List<SurfacingOffer> offers = rules.evaluate(
      SurfacingQuery(now: _day, events: <SurfacingEvent>[...two, _tone(_day)]),
    );
    expect(offers.single.label, 'Custom gym');
    final List<SurfacingOffer> again = rules.evaluate(
      SurfacingQuery(
        now: _day,
        events: <SurfacingEvent>[...two, _tone(_day)],
        lastShown: <SurfacingShown>[
          SurfacingShown(offerId: 'tone_gym', at: _day),
        ],
      ),
    );
    expect(again, isEmpty);
  });

  test('a cap is applied only when the table sets one', () {
    const String source = '''
{
  "version": 1,
  "rules": [
    {
      "id": "open",
      "when": {"all": ["camera_button"]},
      "offers": [
        {"id": "lens_point_say", "label": "Point & Say", "place": "lens"}
      ]
    }
  ]
}
''';
    final SurfacingRules rules = SurfacingRules.parse(source);
    final SurfacingQuery second = SurfacingQuery(
      now: _day,
      cameraButtonUsed: true,
      lastShown: <SurfacingShown>[
        SurfacingShown(offerId: 'lens_point_say', at: _day),
      ],
    );
    expect(rules.evaluate(second).single.id, 'lens_point_say');
  });

  test('a label with an em dash is refused', () {
    const String source =
        '{"version":1,"rules":[{"id":"bad","when":{"all":["camera_button"]},"offers":[{"id":"lens_point_say","label":"Point \u2014 Say","place":"lens"}]}]}';
    expect(() => SurfacingRules.parse(source), throwsFormatException);
  });

  test('an unknown flag is refused', () {
    const String source =
        '{"version":1,"rules":[{"id":"bad","when":{"all":["not_a_flag"]},"offers":[{"id":"save","label":"Save","place":"word_card"}]}]}';
    expect(() => SurfacingRules.parse(source), throwsFormatException);
  });

  group('P3-050 AC1 scenario', () {
    test('a reached market unit offers Scenario Theatre and Market Haggle', () {
      final List<SurfacingOffer> offers = _rules.evaluate(
        SurfacingQuery(now: _day, scenarioUnit: 'market'),
      );
      expect(_ids(offers), <String>['scenario_theatre', 'market_haggle']);
      expect(offers.first.label, 'Scenario Theatre');
      expect(offers.first.place, 'scenario');
      expect(offers.first.social, isFalse);
      expect(offers.last.label, 'Market Haggle');
      expect(offers.last.place, 'play');
      expect(offers.last.social, isFalse);
    });

    test('the supplied unit is matched after trimming and lowercasing', () {
      final List<SurfacingOffer> offers = _rules.evaluate(
        SurfacingQuery(now: _day, scenarioUnit: ' Market '),
      );
      expect(_ids(offers), <String>['scenario_theatre', 'market_haggle']);
    });

    test('a different scenario unit offers neither market surface', () {
      final List<SurfacingOffer> offers = _rules.evaluate(
        SurfacingQuery(now: _day, scenarioUnit: 'clinic'),
      );
      expect(offers, isEmpty);
    });

    test('no scenario unit offers neither market surface', () {
      final List<SurfacingOffer> offers = _rules.evaluate(
        SurfacingQuery(now: _day),
      );
      expect(
        offers.where(
          (SurfacingOffer offer) =>
              offer.id == 'scenario_theatre' || offer.id == 'market_haggle',
        ),
        isEmpty,
      );
    });
  });

  group('P3-050 AC2 weekend', () {
    final DateTime saturday = DateTime.utc(2026, 4, 4, 11);
    final DateTime sunday = DateTime.utc(2026, 4, 5, 18);
    final DateTime friday = DateTime.utc(2026, 4, 3, 23);
    final DateTime monday = DateTime.utc(2026, 4, 6);

    test(
      'a Saturday offers Circle Clash, a Radio show, and festival events',
      () {
        final List<SurfacingOffer> offers = _rules.evaluate(
          SurfacingQuery(now: saturday),
        );
        expect(_ids(offers), <String>[
          'circle_clash',
          'village_radio',
          'festival_event',
        ]);
        expect(offers.map((SurfacingOffer offer) => offer.label), <String>[
          'Circle Clash',
          'Village Radio show',
          'Festival event',
        ]);
        expect(offers.every((SurfacingOffer offer) => offer.social), isTrue);
        expect(offers.map((SurfacingOffer offer) => offer.place), <String>[
          'village',
          'radio',
          'events',
        ]);
      },
    );

    test('a Sunday offers the same weekend surfaces', () {
      final List<SurfacingOffer> offers = _rules.evaluate(
        SurfacingQuery(now: sunday),
      );
      expect(_ids(offers), <String>[
        'circle_clash',
        'village_radio',
        'festival_event',
      ]);
    });

    test('Friday and Monday do not offer weekend surfaces', () {
      expect(_rules.evaluate(SurfacingQuery(now: friday)), isEmpty);
      expect(_rules.evaluate(SurfacingQuery(now: monday)), isEmpty);
    });

    test('the supplied clock decides the weekend, not the device clock', () {
      final DateTime deviceToday = DateTime.now();
      var saturdayClock = DateTime(
        deviceToday.year,
        deviceToday.month,
        deviceToday.day,
      );
      while (saturdayClock.weekday != DateTime.saturday) {
        saturdayClock = saturdayClock.add(const Duration(days: 1));
      }
      if (saturdayClock.year == deviceToday.year &&
          saturdayClock.month == deviceToday.month &&
          saturdayClock.day == deviceToday.day) {
        saturdayClock = saturdayClock.add(const Duration(days: 7));
      }
      final List<SurfacingOffer> offers = _rules.evaluate(
        SurfacingQuery(now: saturdayClock),
      );
      expect(_ids(offers), contains('circle_clash'));
      final DateTime mondayClock = saturdayClock.add(const Duration(days: 2));
      expect(mondayClock.weekday, DateTime.monday);
      expect(_rules.evaluate(SurfacingQuery(now: mondayClock)), isEmpty);
    });
  });

  group('P3-050 AC3 adult A2', () {
    SurfacingQuery adultAt(
      String? level, {
      bool adult = true,
      bool active = true,
      bool minor = false,
      DateTime? now,
    }) {
      return SurfacingQuery(
        now: now ?? _day,
        adult: adult,
        active: active,
        minor: minor,
        level: level,
      );
    }

    test(
      'an active adult at A2 is offered Native Corrections and Post a Status',
      () {
        final List<SurfacingOffer> offers = _rules.evaluate(adultAt('A2'));
        expect(_ids(offers), <String>['native_corrections', 'post_status']);
        expect(offers.first.label, 'Try Native Corrections');
        expect(offers.first.place, 'corrections');
        expect(offers.last.label, 'Post a Status');
        expect(offers.last.place, 'status');
        expect(offers.every((SurfacingOffer offer) => offer.social), isTrue);
      },
    );

    test('A2+, B1, and C2 count as A2 or above', () {
      for (final String level in <String>['A2+', 'a2', 'B1', 'C2']) {
        expect(_ids(_rules.evaluate(adultAt(level))), <String>[
          'native_corrections',
          'post_status',
        ], reason: level);
      }
    });

    test('A1 is below the gate', () {
      expect(_rules.evaluate(adultAt('A1')), isEmpty);
    });

    test('an unknown level is not treated as A2', () {
      expect(_rules.evaluate(adultAt('beginner')), isEmpty);
      expect(_rules.evaluate(adultAt(null)), isEmpty);
    });

    test('an adult who is not active is not offered the prompts', () {
      expect(_rules.evaluate(adultAt('A2', active: false)), isEmpty);
    });

    test('an active A2 account that is not an adult is not offered them', () {
      expect(_rules.evaluate(adultAt('A2', adult: false)), isEmpty);
    });
  });

  group('P3-050 AC5 minor', () {
    final DateTime saturday = DateTime.utc(2026, 4, 4, 11);

    test('a minor account is offered none of the social prompts', () {
      final List<SurfacingOffer> offers = _rules.evaluate(
        SurfacingQuery(
          now: saturday,
          scenarioUnit: 'market',
          minor: true,
          adult: true,
          active: true,
          level: 'A2',
          lessonFinished: true,
          lessonRecapOpen: true,
          wordLongPressed: true,
          wordCardOpen: true,
          objectLesson: true,
          cameraButtonUsed: true,
          events: <SurfacingEvent>[
            _tone(DateTime.utc(2026, 4, 4, 9)),
            _tone(DateTime.utc(2026, 4, 4, 10)),
          ],
        ),
      );
      expect(offers.where((SurfacingOffer offer) => offer.social), isEmpty);
      expect(_ids(offers), isNot(contains('native_corrections')));
      expect(_ids(offers), isNot(contains('post_status')));
      expect(_ids(offers), isNot(contains('circle_clash')));
      expect(_ids(offers), isNot(contains('village_radio')));
      expect(_ids(offers), isNot(contains('festival_event')));
      expect(_ids(offers), <String>[
        'say_it',
        'tone_twins',
        'living_dictionary',
        'save',
        'practise',
        'lens_point_say',
        'find_three_at_home',
        'tone_gym',
        'tone_forge',
        'talking_drum',
        'scenario_theatre',
        'market_haggle',
      ]);
    });

    test('weekend alone offers a minor nothing', () {
      expect(
        _rules.evaluate(SurfacingQuery(now: saturday, minor: true)),
        isEmpty,
      );
    });

    test('any other social offer is withheld from a minor', () {
      const String source = '''
{
  "version": 1,
  "rules": [
    {
      "id": "extra_social",
      "when": {"weekend": true},
      "offers": [
        {
          "id": "village_chat",
          "label": "Village chat",
          "place": "village",
          "social": true
        },
        {"id": "say_it", "label": "Say it", "place": "lesson_recap"}
      ]
    }
  ]
}
''';
      final SurfacingRules rules = SurfacingRules.parse(source);
      final List<SurfacingOffer> minor = rules.evaluate(
        SurfacingQuery(now: saturday, minor: true),
      );
      expect(_ids(minor), <String>['say_it']);
      expect(minor.single.social, isFalse);
      final List<SurfacingOffer> open = rules.evaluate(
        SurfacingQuery(now: saturday),
      );
      expect(_ids(open), <String>['village_chat', 'say_it']);
      expect(open.first.social, isTrue);
    });
  });

  test('lesson, word, camera, and tone rules stay non-social', () {
    const Set<String> kept = <String>{
      'lesson_recap',
      'word_card',
      'lens_point_say',
      'object_lesson_at_home',
      'tone_struggle',
    };
    final Iterable<SurfacingRule> rules = _rules.rules.where(
      (SurfacingRule rule) => kept.contains(rule.id),
    );
    expect(rules.map((SurfacingRule rule) => rule.id), containsAll(kept));
    for (final SurfacingRule rule in rules) {
      expect(
        rule.offers.every((SurfacingOffer offer) => !offer.social),
        isTrue,
        reason: rule.id,
      );
    }
  });
}
