import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/screens/quality_report_screen.dart';

void main() {
  group('P5-047 aggregation', () {
    test('parseQualityReportResponse reads per-language label buckets', () {
      final payload = parseQualityReportResponse({
        'ok': true,
        'report': {
          'min_sample_size': 30,
          'published_at': '2026-10-26T12:00:00.000Z',
          'languages': [
            {
              'language': 'sw',
              'labels': [
                {
                  'quality_label': 'Beta',
                  'sample_count': 40,
                  'error_count': 2,
                  'error_rate': 0.05,
                  'insufficient_data': false,
                  'as_of': '2026-10-25T00:00:00.000Z',
                },
              ],
            },
          ],
        },
      });
      expect(payload, isNotNull);
      expect(payload!.languages.single.language, 'sw');
      expect(payload.languages.single.labels.single.errorRate, 0.05);
    });

    test('formatPublishedErrorRate shows no_data when insufficient', () {
      const row = QualityLabelRate(
        qualityLabel: 'Beta',
        sampleCount: 2,
        errorCount: 0,
        errorRate: null,
        insufficientData: true,
      );
      expect(formatPublishedErrorRate(row), QualityReportCopy.noData);
    });

    test('formatSampleMeta includes sample size and date', () {
      const row = QualityLabelRate(
        qualityLabel: 'Reviewed',
        sampleCount: 35,
        errorCount: 1,
        errorRate: 0.028,
        insufficientData: false,
        asOf: '2026-10-20T08:00:00.000Z',
      );
      expect(formatSampleMeta(row), 'n=35 · 2026-10-20');
    });
  });

  testWidgets('P5-047 screen shows not enough data copy for insufficient bucket', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: QualityReportScreen(
          loader: () async => QualityReportPayload(
            minSampleSize: 30,
            publishedAt: '2026-10-26T00:00:00.000Z',
            languages: [
              LanguageQualityRates(
                language: 'yo',
                labels: [
                  const QualityLabelRate(
                    qualityLabel: 'Beta',
                    sampleCount: 5,
                    errorCount: 0,
                    errorRate: null,
                    insufficientData: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(QualityReportCopy.title), findsOneWidget);
    expect(find.text(QualityReportCopy.noData), findsWidgets);
    expect(find.text('YO'), findsOneWidget);
  });

  testWidgets('P5-047 screen shows rate sample and date when sufficient', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: QualityReportScreen(
          loader: () async => QualityReportPayload(
            minSampleSize: 30,
            publishedAt: '2026-10-26T00:00:00.000Z',
            languages: [
              LanguageQualityRates(
                language: 'sw',
                labels: [
                  const QualityLabelRate(
                    qualityLabel: 'Beta',
                    sampleCount: 40,
                    errorCount: 2,
                    errorRate: 0.05,
                    insufficientData: false,
                    asOf: '2026-10-25T00:00:00.000Z',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('5.0%'), findsOneWidget);
    expect(find.text('n=40 · 2026-10-25'), findsOneWidget);
  });
}
