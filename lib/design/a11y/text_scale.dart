import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:lingafriq/design/tokens.g.dart';
import 'package:lingafriq/design/typography.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';

/// Catalogue frame width. The 200 percent surface uses this or [textScaleNarrowWidth].
const double textScaleCatalogueWidth = 390;

/// Narrow phone width. Primary actions stay on this surface at 200 percent.
const double textScaleNarrowWidth = 360;

/// Catalogue frame height. The surface is this tall so a control can sit fully on screen.
const double textScaleSurfaceHeight = 640;

/// Paints [child] at 200 percent text on a 390-wide or 360-wide surface.
///
/// After layout, [report] lists every RenderFlex that overflowed and every
/// paragraph whose text was clipped.
class LingTextScale extends StatelessWidget {
  const LingTextScale({
    required this.child,
    this.width = textScaleCatalogueWidth,
    super.key,
  }) : assert(
         width == textScaleCatalogueWidth || width == textScaleNarrowWidth,
         'width is 390 or 360',
       );

  final Widget child;
  final double width;

  /// Finder key for the fixed surface.
  static const Key surfaceKey = ValueKey<String>('text-scale-surface');

  /// Overflow and clipped text under [root].
  static LingTextScaleReport report(RenderObject root) {
    final List<String> overflows = <String>[];
    final List<String> clipped = <String>[];
    void visit(RenderObject node) {
      if (node is RenderFlex && _flexOverflowed(node)) {
        overflows.add(
          '${node.toStringShort()} ${node.size.width}x${node.size.height}',
        );
      }
      if (node is RenderParagraph && _textClipped(node)) {
        final String text = node.text.toPlainText().trim();
        clipped.add(text.isEmpty ? node.toStringShort() : text);
      }
      node.visitChildren(visit);
    }

    visit(root);
    return LingTextScaleReport(overflows: overflows, clipped: clipped);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: LingAfriqTokens.navy,
      brightness: Brightness.light,
    );
    final ThemeData theme = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      fontFamily: LingAfriqType.bodyFamily,
    );
    return SizedBox(
      key: surfaceKey,
      width: width,
      height: textScaleSurfaceHeight,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        builder: (BuildContext context, Widget? child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: const TextScaler.linear(2),
              disableAnimations: true,
            ),
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: Scaffold(
          body: Align(alignment: Alignment.topCenter, child: child),
        ),
      ),
    );
  }
}

/// What [LingTextScale.report] found after layout.
class LingTextScaleReport {
  const LingTextScaleReport({required this.overflows, required this.clipped});

  final List<String> overflows;
  final List<String> clipped;

  bool get isClean => overflows.isEmpty && clipped.isEmpty;

  /// Failure text that names [useCaseId].
  String failure(String useCaseId) {
    final StringBuffer buffer = StringBuffer(useCaseId);
    for (final String overflow in overflows) {
      buffer.write(' RenderFlex overflow: $overflow');
    }
    for (final String text in clipped) {
      buffer.write(' clipped text: $text');
    }
    return buffer.toString();
  }
}

bool _flexOverflowed(RenderFlex flex) {
  if (flex.debugNeedsLayout) return false;
  return flex.toStringShort().contains('OVERFLOWING');
}

bool _textClipped(RenderParagraph paragraph) {
  if (paragraph.debugNeedsLayout) return false;
  if (paragraph.text.toPlainText().trim().isEmpty) return false;
  if (paragraph.didExceedMaxLines) return true;
  if (paragraph.overflow == TextOverflow.visible) return false;
  const double epsilon = 0.01;
  final Size text = paragraph.textSize;
  final Size box = paragraph.size;
  return text.width > box.width + epsilon || text.height > box.height + epsilon;
}
