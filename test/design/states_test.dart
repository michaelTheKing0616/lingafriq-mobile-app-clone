import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lingafriq/design/catalogue/registry.dart';
import 'package:lingafriq/design/components/ling_button.dart';
import 'package:lingafriq/design/components/ling_card.dart';
import 'package:lingafriq/design/components/ling_list_row.dart';
import 'package:lingafriq/design/components/ling_state.dart';
import 'package:lingafriq/design/states/empty_state.dart';
import 'package:lingafriq/design/states/skeleton.dart';
import 'package:lingafriq/design/tokens.g.dart';
import 'package:lingafriq/design/typography.dart';

const Key _surfaceKey = ValueKey<String>('state-surface');

Future<void> _loadFont(String family, String asset) async {
  final Future<ByteData> data = File(
    asset,
  ).readAsBytes().then(ByteData.sublistView);
  final FontLoader loader = FontLoader(family)..addFont(data);
  await loader.load();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await _loadFont(
      LingAfriqType.targetFamily,
      'assets/google_fonts/Andika-Regular.ttf',
    );
    await _loadFont(
      LingAfriqType.bodyFamily,
      'assets/fonts/lingafriq/NotoSans-Regular-LatinAfrica.ttf',
    );
  });

  test('skeleton and empty sources stay on token roles', () {
    for (final String path in <String>[
      'lib/design/states/skeleton.dart',
      'lib/design/states/empty_state.dart',
    ]) {
      final String source = File(path).readAsStringSync();
      expect(source.contains('Color(0x'), isFalse, reason: path);
      expect(RegExp(r'#[0-9A-Fa-f]{3,8}\b').hasMatch(source), isFalse);
      expect(RegExp(r'LingAfriqTokens\.surface\b').hasMatch(source), isFalse);
      expect(source.contains('ShaderMask'), isFalse, reason: path);
      expect(source.contains('LinearGradient'), isFalse, reason: path);
      expect(source.contains('SweepGradient'), isFalse, reason: path);
      expect(source.toLowerCase().contains('shimmer'), isFalse, reason: path);
    }
    final String skeleton = File(
      'lib/design/states/skeleton.dart',
    ).readAsStringSync();
    expect(skeleton.contains('LingAfriqTokens.motionProductSlow'), isTrue);
    expect(skeleton.contains('lingProductCurve'), isTrue);
    expect(skeleton.contains('AnimatedBuilder'), isTrue);
    expect(LingAfriqTokens.motionProductSlow, lessThanOrEqualTo(300));
  });

  test('empty sample is the deck copy', () {
    final String deck = File(
      'docs/build/design/COPY_DECK.md',
    ).readAsStringSync();
    expect(deck, contains(LingEmptyStateCopy.whatHappened));
    expect(deck, contains(LingEmptyStateCopy.why));
    expect(deck, contains(LingEmptyStateCopy.whatToDo));
    expect(deck, contains(LingEmptyStateCopy.actionLabel));
    final String today = File(
      'docs/build/design/screens/today_path_lesson.md',
    ).readAsStringSync();
    expect(today, contains(LingEmptyStateCopy.title));
  });

  testWidgets('skeleton bones stay within 4 dp of the loaded controls', (
    WidgetTester tester,
  ) async {
    await _bindSurface(tester);
    for (final double scale in <double>[1, 2]) {
      await tester.pumpWidget(
        _host(
          textScale: scale,
          disableAnimations: true,
          child: const LingListRow(
            label: lingSkeletonProbe,
            unavailableLabel: 'Unavailable',
            onPressed: _noop,
          ),
        ),
      );
      final double row = tester.getSize(find.byType(LingListRow)).height;

      await tester.pumpWidget(
        _host(
          textScale: scale,
          disableAnimations: true,
          child: const LingSkeletonList(itemCount: 1),
        ),
      );
      final double bone = tester
          .getSize(
            find.byKey(const ValueKey<String>('ling-skeleton-list-box-0')),
          )
          .height;
      expect(
        (bone - row).abs(),
        lessThanOrEqualTo(4),
        reason: 'list bone $bone row $row scale $scale',
      );

      await tester.pumpWidget(
        _host(
          textScale: scale,
          disableAnimations: true,
          child: const LingCard(
            semanticLabel: lingSkeletonProbe,
            unavailableLabel: 'Unavailable',
            onPressed: _noop,
            child: Text(
              lingSkeletonProbe,
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ),
        ),
      );
      final double card = tester.getSize(find.byType(LingCard)).height;

      await tester.pumpWidget(
        _host(
          textScale: scale,
          disableAnimations: true,
          child: const LingSkeletonCard(),
        ),
      );
      final double skeletonCard = tester
          .getSize(find.byType(LingSkeletonCard))
          .height;
      expect(
        (skeletonCard - card).abs(),
        lessThanOrEqualTo(4),
        reason: 'card bone $skeletonCard card $card scale $scale',
      );
    }
  });

  testWidgets('reduced motion holds a flat tone and the pulse does not sweep', (
    WidgetTester tester,
  ) async {
    await _bindSurface(tester);
    await tester.pumpWidget(
      _host(
        disableAnimations: true,
        child: const LingSkeletonList(itemCount: 1),
      ),
    );
    final SemanticsHandle handle = tester.ensureSemantics();
    expect(
      find.bySemanticsLabel(LingSkeletonList.semanticsLabel),
      findsOneWidget,
    );
    handle.dispose();

    final LingPalette palette = LingPalette.of(Brightness.light);
    expect(_bone(tester).color, palette.surfaceContainer);
    expect(find.byType(ShaderMask), findsNothing);
    await tester.pump(const Duration(milliseconds: 300));
    expect(_bone(tester).color, palette.surfaceContainer);

    await tester.pumpWidget(
      _host(
        disableAnimations: false,
        child: const LingSkeletonList(itemCount: 1),
      ),
    );
    expect(find.byType(ShaderMask), findsNothing);
    expect(find.byType(LinearProgressIndicator), findsNothing);
    final Color start = _bone(tester).color!;
    expect(start, isNot(palette.surfaceContainer));
    expect(_betweenRoles(start, palette), isTrue);

    await tester.pump(const Duration(milliseconds: 150));
    final Color mid = _bone(tester).color!;
    expect(mid, isNot(start));
    expect(mid, isNot(palette.surfaceContainer));
    expect(_betweenRoles(mid, palette), isTrue);
    expect(find.byType(ShaderMask), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('reduced motion skeleton golden', (WidgetTester tester) async {
    await _bindSurface(tester);
    await tester.pumpWidget(
      _host(
        disableAnimations: true,
        framed: true,
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            LingSkeletonList(),
            SizedBox(height: LingAfriqTokens.spacing16),
            Padding(
              padding: EdgeInsets.all(LingAfriqTokens.spacing16),
              child: LingSkeletonCard(),
            ),
          ],
        ),
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(_bone(tester).color, LingAfriqTokens.roleLightSurfaceContainer);
    await expectLater(
      find.byKey(_surfaceKey),
      matchesGoldenFile('../goldens/lingSkeleton_reduced_light_1.0.png'),
    );
  });

  testWidgets('empty state points forward with one verb button', (
    WidgetTester tester,
  ) async {
    await _bindSurface(tester);
    var taps = 0;
    await tester.pumpWidget(
      _host(
        disableAnimations: true,
        child: Padding(
          padding: const EdgeInsets.all(LingAfriqTokens.spacing16),
          child: LingEmptyState(
            title: LingEmptyStateCopy.title,
            whatHappened: LingEmptyStateCopy.whatHappened,
            why: LingEmptyStateCopy.why,
            whatToDo: LingEmptyStateCopy.whatToDo,
            actionLabel: LingEmptyStateCopy.actionLabel,
            onAction: () => taps++,
          ),
        ),
      ),
    );
    expect(find.text(LingEmptyStateCopy.title), findsOneWidget);
    expect(find.text(LingEmptyStateCopy.whatHappened), findsOneWidget);
    expect(find.text(LingEmptyStateCopy.why), findsOneWidget);
    expect(find.text(LingEmptyStateCopy.whatToDo), findsOneWidget);
    expect(find.byType(LingButton), findsOneWidget);
    expect(find.byType(TextButton), findsNothing);
    expect(find.byType(OutlinedButton), findsNothing);
    expect(find.byType(ElevatedButton), findsNothing);
    final LingButton button = tester.widget<LingButton>(
      find.byType(LingButton),
    );
    expect(button.role, LingButtonRole.accent);
    expect(button.label, LingEmptyStateCopy.actionLabel);
    final Size size = tester.getSize(find.byType(LingButton));
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
    await tester.tap(find.byType(LingButton));
    await tester.pump();
    expect(taps, 1);

    await tester.pumpWidget(
      _host(
        textScale: 2,
        disableAnimations: true,
        child: const Padding(
          padding: EdgeInsets.all(LingAfriqTokens.spacing16),
          child: LingEmptyState(
            title: LingEmptyStateCopy.title,
            whatHappened: LingEmptyStateCopy.whatHappened,
            why: LingEmptyStateCopy.why,
            whatToDo: LingEmptyStateCopy.whatToDo,
            actionLabel: LingEmptyStateCopy.actionLabel,
            onAction: _noop,
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    for (final Text text in tester.widgetList<Text>(find.byType(Text))) {
      expect(text.softWrap, isTrue);
      expect(text.maxLines, isNull);
      expect(text.overflow, isNot(TextOverflow.clip));
      expect(text.overflow, isNot(TextOverflow.ellipsis));
    }
    final double whyHeight = tester
        .getSize(find.text(LingEmptyStateCopy.why))
        .height;
    expect(
      whyHeight,
      greaterThan(LingAfriqType.bodySize * LingAfriqType.targetHeight * 2),
    );
    expect(
      tester.getSize(find.byType(LingEmptyState)).width,
      lessThanOrEqualTo(catalogueSurface.width),
    );
  });
}

void _noop() {}

Future<void> _bindSurface(WidgetTester tester) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = catalogueSurface;
  addTearDown(tester.view.reset);
  await tester.binding.setSurfaceSize(catalogueSurface);
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Widget _host({
  required Widget child,
  required bool disableAnimations,
  double textScale = 1,
  bool framed = false,
}) {
  final ThemeData theme = catalogueTheme(Brightness.light);
  final Color background = LingAfriqTokens.roleLightSurface;
  final Widget body = framed
      ? SizedBox(
          key: _surfaceKey,
          width: catalogueSurface.width,
          height: catalogueSurface.height,
          child: ColoredBox(
            color: background,
            child: Align(alignment: Alignment.topCenter, child: child),
          ),
        )
      : child;
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: theme,
    builder: (BuildContext context, Widget? built) {
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: TextScaler.linear(textScale),
          disableAnimations: disableAnimations,
        ),
        child: built ?? const SizedBox.shrink(),
      );
    },
    home: Scaffold(backgroundColor: background, body: body),
  );
}

Material _bone(WidgetTester tester) {
  return tester.widget<Material>(
    find
        .descendant(
          of: find.byType(LingSkeletonList),
          matching: find.byType(Material),
        )
        .first,
  );
}

bool _betweenRoles(Color color, LingPalette palette) {
  bool axis(double value, double a, double b) {
    final double low = a < b ? a : b;
    final double high = a < b ? b : a;
    return value >= low - 0.001 && value <= high + 0.001;
  }

  return axis(color.r, palette.surface.r, palette.surfaceContainer.r) &&
      axis(color.g, palette.surface.g, palette.surfaceContainer.g) &&
      axis(color.b, palette.surface.b, palette.surfaceContainer.b);
}
