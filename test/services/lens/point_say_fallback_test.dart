import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/services/lens/object_set_mapper.dart';
import 'package:lingafriq/services/lens/on_device_object_classifier.dart';
import 'package:lingafriq/services/lens/point_say_fallback.dart';

Widget _wrap(Widget child) {
  return ScreenUtilInit(
    designSize: const Size(390, 844),
    builder: (_, __) => MaterialApp(home: child),
  );
}

AfricanObjectSet _fixtureSet() {
  final path = File('assets/lens/african_object_set.json').absolute;
  final json = jsonDecode(path.readAsStringSync()) as Map<String, dynamic>;
  return AfricanObjectSet.fromJson(json);
}

void main() {
  late ObjectSetMapper mapper;
  late AfricanObjectSet set;

  setUp(() {
    set = _fixtureSet();
    mapper = ObjectSetMapper(set);
  });

  group('pointSayNeedsGatewayFallback', () {
    test('low top score triggers fallback', () {
      expect(
        pointSayNeedsGatewayFallback([
          const ObjectClassificationLabel(label: 'Cup', score: 0.1),
        ]),
        isTrue,
      );
      expect(
        pointSayNeedsGatewayFallback([
          const ObjectClassificationLabel(label: 'Cup', score: 0.9),
        ]),
        isFalse,
      );
    });
  });

  group('PointSaySiglipClient', () {
    test('airplane mode path never posts when offline coordinator skips', () async {
      var posts = 0;
      final coordinator = PointSayFallbackCoordinator(
        mapper: mapper,
        objectSet: set,
        hasInternet: () async => false,
      );
      final outcome = await coordinator.maybeRunSiglip(
        onDeviceTop3: [
          const ObjectClassificationLabel(label: 'x', score: 0.01),
        ],
        post: (_, __) async {
          posts++;
          return Response(
            requestOptions: RequestOptions(path: kPointSaySiglipMatchPath),
            statusCode: 200,
          );
        },
        learnerOptedInToUpload: true,
        imageBase64: 'aGVsbG8=',
      );
      expect(outcome, isNull);
      expect(posts, 0);
    });

    test('opt-in gate blocks upload without consent', () async {
      var posts = 0;
      final coordinator = PointSayFallbackCoordinator(
        mapper: mapper,
        objectSet: set,
        hasInternet: () async => true,
      );
      final outcome = await coordinator.maybeRunSiglip(
        onDeviceTop3: [
          const ObjectClassificationLabel(label: 'x', score: 0.01),
        ],
        post: (_, __) async {
          posts++;
          return Response(
            requestOptions: RequestOptions(path: kPointSaySiglipMatchPath),
            statusCode: 200,
          );
        },
        learnerOptedInToUpload: false,
        imageBase64: 'aGVsbG8=',
      );
      expect(outcome?.phase, PointSaySiglipPhase.optInRequired);
      expect(posts, 0);
    });

    test('maps gateway glosses to dictionary labels only', () async {
      final client = PointSaySiglipClient();
      final outcome = await client.matchFrame(
        post: (_, __) async => Response(
          requestOptions: RequestOptions(path: kPointSaySiglipMatchPath),
          statusCode: 200,
          data: {
            'ok': true,
            'matches': [
              {'gloss': 'Cup', 'score': 0.91},
              {'gloss': 'n01440764 tench', 'score': 0.88},
            ],
          },
        ),
        imageBase64: 'aGVsbG8=',
        glosses: ['Cup', 'Chair'],
        imageOptIn: true,
      );
      expect(outcome.phase, PointSaySiglipPhase.matches);
      final dictionary = livingDictionaryMatchesFromSiglip(
        matches: outcome.matches,
        mapper: mapper,
      );
      expect(dictionary, isNotEmpty);
      expect(dictionary.first.gloss, 'Cup');
      expect(
        dictionary.every((m) => m.objectSetId.startsWith('afr.')),
        isTrue,
      );
      expect(
        dictionary.any((m) => m.gloss.contains('tench')),
        isFalse,
      );
    });

    test('discards frame after reply when finetune not opted in', () {
      final buffer = PointSayFrameBuffer();
      buffer.setFrame('abc', finetuneOptIn: false);
      buffer.clearAfterReply();
      expect(buffer.takeForGateway(), isNull);
    });
  });

  group('PointSay fallback widgets', () {
    testWidgets('ask opt-in dialog announces and offers 48dp targets', (tester) async {
      await tester.pumpWidget(
        _wrap(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => showPointSayOptInDialog(context),
              child: const Text('open'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(find.text(lensPointSayAskOptInTitle), findsOneWidget);
      expect(find.text(lensPointSayAskOptInConfirm), findsOneWidget);
    });

    testWidgets('dictionary matches sheet lists curated glosses', (tester) async {
      await tester.pumpWidget(
        _wrap(
          Scaffold(
            body: PointSayDictionaryMatchesSheet(
              matches: [
                PointSayDictionaryGlossMatch(
                  gloss: 'Cup',
                  mlKitLabel: 'Cup',
                  objectSetId: 'afr.cup',
                  score: 0.9,
                ),
              ],
              onPick: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(lensPointSayDictionaryMatchesTitle), findsOneWidget);
      expect(find.text('Cup'), findsOneWidget);
    });
  });
}
