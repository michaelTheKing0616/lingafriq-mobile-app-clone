import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/services/guardian_link_service.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/responsive_safe_area.dart';

/// Copy keys: guardian.messaging.explainer.title, guardian.messaging.explainer.body (P9-920).
/// Reference: Apple Communication Safety + Google Family Link supervised messaging copy.
class GuardianMessagingExplainer {
  GuardianMessagingExplainer({
    required this.title,
    required this.body,
    required this.moderatorsSee,
    required this.e2eeTradeoff,
  });

  final String title;
  final String body;
  final List<String> moderatorsSee;
  final String e2eeTradeoff;

  factory GuardianMessagingExplainer.fromJson(Map<String, dynamic> json) {
    final rawList = json['moderators_see'];
    final items = <String>[];
    if (rawList is List) {
      for (final entry in rawList) {
        if (entry is String && entry.trim().isNotEmpty) items.add(entry);
      }
    }
    return GuardianMessagingExplainer(
      title:
          json['title']?.toString() ??
          GuardianMessagingExplainerScreen.fallbackTitle,
      body:
          json['body']?.toString() ??
          GuardianMessagingExplainerScreen.fallbackBody,
      moderatorsSee: items.isEmpty
          ? GuardianMessagingExplainerScreen.fallbackModeratorsSee
          : items,
      e2eeTradeoff:
          json['e2ee_tradeoff']?.toString() ??
          GuardianMessagingExplainerScreen.fallbackTradeoff,
    );
  }
}

class GuardianMessagingExplainerService {
  GuardianMessagingExplainerService({
    Future<Map<String, dynamic>> Function(String path)? get,
  }) : _get = get ?? _defaultGet;

  final Future<Map<String, dynamic>> Function(String path) _get;

  static Future<Map<String, dynamic>> _defaultGet(String path) async {
    await ApiService.initialize();
    final response = await ApiService.get(path);
    final json = response.data;
    if (json is Map<String, dynamic>) return json;
    return <String, dynamic>{'ok': false};
  }

  Future<GuardianMessagingExplainer> fetchExplainer() async {
    final json = await _get('/api/v2/messaging-policy/explainer');
    if (json['ok'] != true) {
      throw GuardianApiException(message: json['message']?.toString());
    }
    final explainer = json['explainer'];
    if (explainer is Map<String, dynamic>) {
      return GuardianMessagingExplainer.fromJson(explainer);
    }
    return GuardianMessagingExplainer(
      title: GuardianMessagingExplainerScreen.fallbackTitle,
      body: GuardianMessagingExplainerScreen.fallbackBody,
      moderatorsSee: GuardianMessagingExplainerScreen.fallbackModeratorsSee,
      e2eeTradeoff: GuardianMessagingExplainerScreen.fallbackTradeoff,
    );
  }
}

enum _ExplainerUiState { loading, loaded, error }

/// Hub entry tile (P9-920 AC4) — embed in Family hub progress view.
class GuardianMessagingExplainerHubTile extends StatelessWidget {
  const GuardianMessagingExplainerHubTile({super.key, this.explainerService});

  final GuardianMessagingExplainerService? explainerService;

  static const String tileTitle = 'How learner messages stay safe';
  static const String tileSubtitle =
      'Why chats are moderated and not encrypted';

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final l = AppLocalizations.of(context);
    final title = l?.gmeTileTitle ?? tileTitle;
    final subtitle = l?.gmeTileSubtitle ?? tileSubtitle;
    return Semantics(
      button: true,
      label: '$title. $subtitle',
      child: Material(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(PanAfricanRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(PanAfricanRadius.md),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => GuardianMessagingExplainerScreen(
                  explainerService: explainerService,
                ),
              ),
            );
          },
          child: Padding(
            padding: EdgeInsets.all(PanAfricanSpacing.md.w),
            child: Row(
              children: [
                Icon(
                  Icons.shield_outlined,
                  color: colorScheme.primary,
                  size: 28.sp,
                ),
                SizedBox(width: PanAfricanSpacing.md.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: PanAfricanTypography.titleSmall(
                          context,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                      SizedBox(height: PanAfricanSpacing.xs.h),
                      Text(
                        subtitle,
                        style: PanAfricanTypography.bodySmall(context).copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GuardianMessagingExplainerScreen extends HookConsumerWidget {
  const GuardianMessagingExplainerScreen({super.key, this.explainerService});

  final GuardianMessagingExplainerService? explainerService;

  static const String fallbackTitle = 'How messages work for young learners';
  static const String fallbackBody =
      'Messages from learners under 18 are not end-to-end encrypted so automated checks '
      'and moderators can help before harmful content is delivered.';
  static const List<String> fallbackModeratorsSee = [
    'Message text in chats you approved',
    'Safety signals from automated screening',
    'Reports from learners or guardians',
  ];
  static const String fallbackTradeoff =
      'Adult encrypted chats hide content from moderation; child accounts stay on moderated messaging.';

  static const String loadError =
      'We could not load this guide right now. Pull to refresh or try again when you are online.';
  static const String offlineBanner =
      'You are offline. Showing the last saved explanation.';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = explainerService ?? GuardianMessagingExplainerService();
    final colorScheme = Theme.of(context).colorScheme;
    final uiState = useState(_ExplainerUiState.loading);
    final explainer = useState<GuardianMessagingExplainer?>(null);
    final errorText = useState<String?>(null);
    final offline = useState(false);

    Future<void> load() async {
      uiState.value = _ExplainerUiState.loading;
      errorText.value = null;
      offline.value = false;
      try {
        final data = await service.fetchExplainer();
        explainer.value = data;
        uiState.value = _ExplainerUiState.loaded;
      } on GuardianOfflineException {
        offline.value = true;
        explainer.value ??= GuardianMessagingExplainer(
          title: fallbackTitle,
          body: fallbackBody,
          moderatorsSee: fallbackModeratorsSee,
          e2eeTradeoff: fallbackTradeoff,
        );
        uiState.value = _ExplainerUiState.loaded;
      } on GuardianApiException catch (e) {
        errorText.value = e.message;
        uiState.value = _ExplainerUiState.error;
      } catch (_) {
        uiState.value = _ExplainerUiState.error;
      }
    }

    useEffect(() {
      load();
      return null;
    }, const []);

    // One guide for every state and locale: the bundled, translated copy.
    // The server call only confirms the policy is reachable, so online and
    // offline show the same title and text.
    final l = AppLocalizations.of(context)!;
    final title = l.gmeTitle;
    final sections = <(IconData, String, String)>[
      (Icons.fact_check_outlined, l.gmeSecCheckedTitle, l.gmeBody),
      (Icons.photo_library_outlined, l.gmeSecHeldTitle, l.gmeSecHeldBody),
      (Icons.front_hand_outlined, l.gmeSecStopTitle, l.gmeSecStopBody),
      (Icons.school_outlined, l.gmeSecTeacherTitle, l.gmeSecTeacherBody),
    ];
    Widget section((IconData, String, String) s) => Padding(
      padding: EdgeInsets.only(bottom: PanAfricanSpacing.md.h),
      child: Card(
        margin: EdgeInsets.zero,
        child: Padding(
          padding: EdgeInsets.all(PanAfricanSpacing.md.w),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: colorScheme.primaryContainer,
                child: Icon(s.$1, color: colorScheme.onPrimaryContainer),
              ),
              SizedBox(width: PanAfricanSpacing.md.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        s.$2,
                        style: PanAfricanTypography.titleSmall(
                          context,
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                    SizedBox(height: PanAfricanSpacing.xs.h),
                    Text(
                      s.$3,
                      style: PanAfricanTypography.bodyMedium(
                        context,
                      ).copyWith(height: 1.45),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
    final loading = uiState.value == _ExplainerUiState.loading;
    return Scaffold(
      appBar: AppBar(),
      body: ResponsiveSafeArea(
        child: RefreshIndicator(
          onRefresh: load,
          child: ListView(
            padding: EdgeInsets.all(PanAfricanSpacing.lg.w),
            children: [
              // Title lives in the body so it wraps at 320dp / 200% / Arabic.
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: PanAfricanTypography.headlineSmall(
                    context,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              SizedBox(height: PanAfricanSpacing.md.h),
              if (offline.value)
                _OfflineBanner(label: l.gmeOffline, colorScheme: colorScheme),
              if (uiState.value == _ExplainerUiState.error)
                _ErrorPanel(message: l.gmeLoadError, onRetry: load),
              if (loading)
                Semantics(
                  key: const ValueKey('gme-loading'),
                  label: l.gmeLoading,
                  liveRegion: true,
                  child: ExcludeSemantics(
                    child: Column(
                      children: List.generate(
                        4,
                        (_) => Container(
                          height: 96,
                          margin: EdgeInsets.only(
                            bottom: PanAfricanSpacing.md.h,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(
                              PanAfricanRadius.md,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                )
              else ...[
                ...sections.map(section),
                SizedBox(height: PanAfricanSpacing.sm.h),
                Text(
                  l.gmeModHeading,
                  style: PanAfricanTypography.titleSmall(
                    context,
                  ).copyWith(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: PanAfricanSpacing.sm.h),
                ...[l.gmeMod1, l.gmeMod2, l.gmeMod3].map(
                  (line) => Padding(
                    padding: EdgeInsets.only(bottom: PanAfricanSpacing.sm.h),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.check_circle_outline,
                          size: 20,
                          color: colorScheme.primary,
                        ),
                        SizedBox(width: PanAfricanSpacing.sm.w),
                        Expanded(
                          child: Text(
                            line,
                            style: PanAfricanTypography.bodyMedium(
                              context,
                            ).copyWith(height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: PanAfricanSpacing.md.h),
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(PanAfricanSpacing.md.w),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lock_outline,
                          color: colorScheme.onSecondaryContainer,
                        ),
                        SizedBox(width: PanAfricanSpacing.sm.w),
                        Expanded(
                          child: Text(
                            l.gmeTradeoff,
                            style: PanAfricanTypography.bodyMedium(context)
                                .copyWith(
                                  height: 1.45,
                                  color: colorScheme.onSecondaryContainer,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.label, required this.colorScheme});

  final String label;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: PanAfricanSpacing.md.h),
      child: Semantics(
        label: label,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(PanAfricanSpacing.sm.w),
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(PanAfricanRadius.sm),
          ),
          child: Text(label, style: PanAfricanTypography.bodySmall(context)),
        ),
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: const ValueKey('gme-error'),
      margin: EdgeInsets.only(bottom: PanAfricanSpacing.md.h),
      padding: EdgeInsets.all(PanAfricanSpacing.md.w),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(PanAfricanRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            message,
            style: PanAfricanTypography.bodyMedium(
              context,
            ).copyWith(color: scheme.onErrorContainer),
          ),
          SizedBox(height: PanAfricanSpacing.sm.h),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: FilledButton(
              onPressed: onRetry,
              child: Text(
                AppLocalizations.of(context)?.gmeRetry ?? 'Try again',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
