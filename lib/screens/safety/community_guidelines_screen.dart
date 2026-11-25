import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/responsive_safe_area.dart';

const String kCommunityGuidelinesMdAsset = 'docs/safety/community_guidelines.md';
const int kCommunityGuidelineRuleCount = 6;

/// Stable clause ids used in markdown anchors and report-flow deep links.
abstract final class CommunityGuidelinesCatalog {
  static const List<String> clauseIds = [
    'kind',
    'hate',
    'spam',
    'learning',
    'safety',
    'respect',
  ];

  static const Map<String, int> _clauseToRule = {
    'kind': 1,
    'hate': 2,
    'spam': 3,
    'learning': 4,
    'safety': 5,
    'respect': 6,
  };

  static String? socialReportClauseId(String reason) {
    return switch (reason) {
      'harassment' => 'kind',
      'hate' => 'hate',
      'spam' => 'spam',
      'other' => 'respect',
      _ => null,
    };
  }

  static String? contentFlagClauseId(String categoryApiValue) {
    return switch (categoryApiValue) {
      'offensive' => 'safety',
      'wrong_meaning' || 'tone_spelling' || 'audio' || 'unnatural' => 'learning',
      _ => null,
    };
  }

  static int? ruleIndexForClause(String clauseId) => _clauseToRule[clauseId];

}

/// P9-933 — plain-language community guidelines (Meta Transparency Center pattern).
class CommunityGuidelinesScreen extends HookConsumerWidget {
  const CommunityGuidelinesScreen({super.key, this.focusClauseId});

  final String? focusClauseId;

  static const String guidelinesTitleKey = 'community_guidelines_title';

  static Future<void> open(BuildContext context, {String? focusClauseId}) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => CommunityGuidelinesScreen(focusClauseId: focusClauseId),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ruleKeys = useMemoized(
      () => {
        for (var i = 1; i <= kCommunityGuidelineRuleCount; i++) i: GlobalKey(),
      },
      const [],
    );
    final colorScheme = Theme.of(context).colorScheme;
    final locale = Localizations.localeOf(context);
    final retryGeneration = useState(0);
    final bundleFuture = useMemoized(
      () => CommunityGuidelinesLoader.loadBundle(locale),
      [locale.languageCode, focusClauseId, retryGeneration.value],
    );
    final snapshot = useFuture(bundleFuture);
    final scrollController = useScrollController();

    useEffect(() {
      if (snapshot.connectionState != ConnectionState.done || snapshot.hasError) {
        return null;
      }
      final focus = focusClauseId;
      if (focus == null) {
        return null;
      }
      final index = CommunityGuidelinesCatalog.ruleIndexForClause(focus);
      if (index == null) {
        return null;
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = ruleKeys[index]?.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            alignment: 0.08,
          );
        }
      });
      return null;
    }, [snapshot.connectionState, focusClauseId]);

    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final strings = snapshot.data?.strings ?? const <String, String>{};
    final version = snapshot.data?.meta.version;
    final effectiveDate = snapshot.data?.meta.effectiveDate;

    return Scaffold(
      appBar: AppBar(
        leading: Semantics(
          label: 'Back',
          button: true,
          child: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: colorScheme.onPrimary),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
          ),
        ),
        title: Semantics(
          label: strings['guidelines.title'] ?? 'Community guidelines',
          header: true,
          child: Text(
            strings['guidelines.title'] ?? 'Community guidelines',
            key: const Key(CommunityGuidelinesScreen.guidelinesTitleKey),
            style: PanAfricanTypography.titleLarge(context)
                .copyWith(color: colorScheme.onPrimary),
          ),
        ),
        backgroundColor: PanAfricanColors.primary,
      ),
      body: ResponsiveSafeArea(
        child: switch (snapshot.connectionState) {
          ConnectionState.waiting => const Center(child: CircularProgressIndicator()),
          ConnectionState.none || ConnectionState.active => const Center(
              child: CircularProgressIndicator(),
            ),
          ConnectionState.done when snapshot.hasError => Center(
              child: Padding(
                padding: EdgeInsets.all(PanAfricanSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      strings['guidelines.loadError'] ?? 'We could not load the guidelines offline.',
                      style: PanAfricanTypography.bodyLarge(context),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: PanAfricanSpacing.md),
                    FilledButton(
                      onPressed: () => retryGeneration.value++,
                      style: FilledButton.styleFrom(
                        minimumSize: Size.fromHeight(48.h),
                      ),
                      child: Text(strings['guidelines.retry'] ?? 'Try again'),
                    ),
                  ],
                ),
              ),
            ),
          ConnectionState.done => Scrollbar(
              controller: scrollController,
              child: SingleChildScrollView(
                controller: scrollController,
                physics: reduceMotion
                    ? const ClampingScrollPhysics()
                    : const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  PanAfricanSpacing.md,
                  PanAfricanSpacing.sm,
                  PanAfricanSpacing.md,
                  PanAfricanSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      _formatVersionLine(
                        strings,
                        version,
                        effectiveDate,
                      ),
                      style: PanAfricanTypography.labelLarge(context),
                    ),
                    SizedBox(height: PanAfricanSpacing.sm),
                    Text(
                      strings['guidelines.intro'] ?? '',
                      style: PanAfricanTypography.bodyLarge(context),
                    ),
                    SizedBox(height: PanAfricanSpacing.lg),
                    for (var i = 1; i <= kCommunityGuidelineRuleCount; i++)
                      _RuleCard(
                        key: ruleKeys[i],
                        ruleIndex: i,
                        title: strings['guidelines.rule.$i.title'] ?? '',
                        body: strings['guidelines.rule.$i.body'] ?? '',
                        example: strings['guidelines.rule.$i.example'] ?? '',
                      ),
                  ],
                ),
              ),
            ),
        },
      ),
    );
  }

  static String formatVersionLine(
    Map<String, String> strings,
    String? version,
    String? date,
  ) {
    final template = strings['guidelines.versionLine'];
    if (template == null) {
      return 'Version ${version ?? '—'} · ${date ?? '—'}';
    }
    return template
        .replaceAll('{version}', version ?? '—')
        .replaceAll('{date}', date ?? '—');
  }
}

String _formatVersionLine(
  Map<String, String> strings,
  String? version,
  String? date,
) =>
    CommunityGuidelinesScreen.formatVersionLine(strings, version, date);

class CommunityGuidelinesRuleLink extends StatelessWidget {
  const CommunityGuidelinesRuleLink({
    super.key,
    required this.clauseId,
    this.label,
  });

  final String clauseId;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final text = label ?? 'Read the matching community rule';
    return Semantics(
      button: true,
      label: text,
      child: TextButton(
        onPressed: () => CommunityGuidelinesScreen.open(context, focusClauseId: clauseId),
        style: TextButton.styleFrom(
          minimumSize: const Size(48, 48),
          alignment: Alignment.centerLeft,
        ),
        child: Text(text),
      ),
    );
  }
}

class _RuleCard extends StatelessWidget {
  const _RuleCard({
    super.key,
    required this.ruleIndex,
    required this.title,
    required this.body,
    required this.example,
  });

  final int ruleIndex;
  final String title;
  final String body;
  final String example;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: PanAfricanSpacing.md),
      child: Semantics(
        container: true,
        label: '$title. $body $example',
        child: Material(
          color: colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(PanAfricanSpacing.sm),
          child: Padding(
            padding: EdgeInsets.all(PanAfricanSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$ruleIndex. $title',
                  style: PanAfricanTypography.titleMedium(context),
                ),
                SizedBox(height: PanAfricanSpacing.xs),
                Text(body, style: PanAfricanTypography.bodyMedium(context)),
                SizedBox(height: PanAfricanSpacing.sm),
                Text(
                  example,
                  style: PanAfricanTypography.bodySmall(context).copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class CommunityGuidelinesMeta {
  const CommunityGuidelinesMeta({required this.version, required this.effectiveDate});

  final String version;
  final String effectiveDate;
}

class CommunityGuidelinesBundle {
  const CommunityGuidelinesBundle({
    required this.strings,
    required this.meta,
  });

  final Map<String, String> strings;
  final CommunityGuidelinesMeta meta;
}

abstract final class CommunityGuidelinesLoader {
  static final List<String> _requiredKeys = <String>[
    'guidelines.title',
    'guidelines.intro',
    for (var i = 1; i <= kCommunityGuidelineRuleCount; i++) ...[
      'guidelines.rule.$i.title',
      'guidelines.rule.$i.body',
      'guidelines.rule.$i.example',
    ],
    'guidelines.linkLabel',
    'guidelines.loadError',
    'guidelines.retry',
    'guidelines.versionLine',
  ];

  static Future<CommunityGuidelinesBundle> loadBundle(Locale locale) async {
    final strings = await load(locale);
    final meta = await loadMeta();
    return CommunityGuidelinesBundle(strings: strings, meta: meta);
  }

  static Future<Map<String, String>> load(Locale locale) async {
    final codes = <String>[
      locale.languageCode,
      'en',
    ];
    Object? lastError;
    for (final code in codes.toSet()) {
      try {
        final raw = await rootBundle.loadString('lib/l10n/guidelines/community_guidelines_$code.arb');
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        final strings = <String, String>{};
        for (final key in _requiredKeys) {
          final value = decoded[key];
          if (value is! String || value.trim().isEmpty) {
            throw FormatException('missing key $key in community_guidelines_$code.arb');
          }
          strings[key] = value;
        }
        return strings;
      } catch (e) {
        lastError = e;
      }
    }
    Error.throwWithStackTrace(
      FormatException('community guidelines ARB missing for ${locale.languageCode}: $lastError'),
      StackTrace.current,
    );
  }

  static Future<CommunityGuidelinesMeta> loadMeta() async {
    final raw = await rootBundle.loadString(kCommunityGuidelinesMdAsset);
    const fmStart = '---\n';
    if (!raw.startsWith(fmStart)) {
      throw const FormatException('missing front matter');
    }
    final end = raw.indexOf('\n---\n', fmStart.length);
    if (end < 0) {
      throw const FormatException('unclosed front matter');
    }
    final yamlText = raw.substring(fmStart.length, end);
    final versionMatch =
        RegExp(r'^version:\s*"?([^"\n]+)"?\s*$', multiLine: true).firstMatch(yamlText);
    final dateMatch = RegExp(r'^effective_date:\s*"?([^"\n]+)"?\s*$', multiLine: true)
        .firstMatch(yamlText);
    final version = versionMatch?.group(1)?.trim();
    final effectiveDate = dateMatch?.group(1)?.trim();
    if (version == null || version.isEmpty || effectiveDate == null || effectiveDate.isEmpty) {
      throw const FormatException('version or effective_date missing');
    }
    return CommunityGuidelinesMeta(version: version, effectiveDate: effectiveDate);
  }

  /// Build fails in CI when any supported UI locale is missing guideline keys.
  static Future<void> assertAllSupportedLocalesPresent() async {
    for (final locale in AppLocalizations.supportedLocales) {
      await load(locale);
    }
  }
}
