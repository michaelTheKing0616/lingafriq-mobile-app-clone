import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/screens/guardian/messaging_explainer_screen.dart';
import 'package:lingafriq/services/guardian_link_service.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/responsive_safe_area.dart';

/// Copy keys: guardian.limits.title, guardian.limits.reached (P9-915).
/// Reference: Apple Screen Time / Google Family Link daily limit + activity summary.
class GuardianChildProgressRow {
  GuardianChildProgressRow({
    required this.childUserId,
    required this.minutesLearnedToday,
    required this.dailyMinutesLimit,
    required this.canDoVerifiedCount,
    required this.approvedGroups,
    this.childDisplayName,
  });

  final int childUserId;
  final int minutesLearnedToday;
  final int? dailyMinutesLimit;
  final int canDoVerifiedCount;
  final List<GuardianApprovedGroupRow> approvedGroups;

  /// Optional learner name surfaced by the API. Falls back to a stable
  /// "Learner #id" label when the backend has not populated it yet, so the
  /// screen degrades gracefully instead of inventing a fake name.
  final String? childDisplayName;

  String displayName() {
    final name = childDisplayName?.trim();
    if (name != null && name.isNotEmpty) return name;
    return 'Learner #$childUserId';
  }

  factory GuardianChildProgressRow.fromJson(Map<String, dynamic> json) {
    final groupsRaw = json['approved_groups'];
    final groups = <GuardianApprovedGroupRow>[];
    if (groupsRaw is List) {
      for (final item in groupsRaw) {
        if (item is Map) {
          groups.add(GuardianApprovedGroupRow.fromJson(Map<String, dynamic>.from(item)));
        }
      }
    }
    return GuardianChildProgressRow(
      childUserId: (json['child_user_id'] as num?)?.toInt() ?? 0,
      minutesLearnedToday: (json['minutes_learned_today'] as num?)?.toInt() ?? 0,
      dailyMinutesLimit: (json['daily_minutes_limit'] as num?)?.toInt(),
      canDoVerifiedCount: (json['can_do_verified_count'] as num?)?.toInt() ?? 0,
      approvedGroups: groups,
      childDisplayName: json['child_display_name']?.toString(),
    );
  }
}

class GuardianApprovedGroupRow {
  GuardianApprovedGroupRow({
    required this.groupKind,
    required this.groupName,
    required this.groupId,
  });

  final String groupKind;
  final String groupName;
  final String groupId;

  factory GuardianApprovedGroupRow.fromJson(Map<String, dynamic> json) {
    return GuardianApprovedGroupRow(
      groupKind: json['group_kind']?.toString() ?? 'circle',
      groupName: json['group_name']?.toString() ?? 'Group',
      groupId: json['group_id']?.toString() ?? '',
    );
  }
}

class GuardianChildLimitStatus {
  GuardianChildLimitStatus({
    required this.dailyMinutesLimit,
    required this.minutesUsedToday,
    required this.sessionBlocked,
    required this.policyRevision,
    required this.localDayKey,
    required this.timezone,
  });

  final int? dailyMinutesLimit;
  final int minutesUsedToday;
  final bool sessionBlocked;
  final int policyRevision;
  final String localDayKey;
  final String timezone;

  factory GuardianChildLimitStatus.fromJson(Map<String, dynamic> json) {
    final limitRaw = json['daily_minutes_limit'];
    return GuardianChildLimitStatus(
      dailyMinutesLimit: limitRaw == null ? null : (limitRaw as num).toInt(),
      minutesUsedToday: (json['minutes_used_today'] as num?)?.toInt() ?? 0,
      sessionBlocked: json['session_blocked'] == true,
      policyRevision: (json['policy_revision'] as num?)?.toInt() ?? 0,
      localDayKey: json['local_day_key']?.toString() ?? '',
      timezone: json['timezone']?.toString() ?? 'UTC',
    );
  }
}

typedef GuardianLimitsGet = Future<Map<String, dynamic>> Function(String path);
typedef GuardianLimitsPut = Future<Map<String, dynamic>> Function(
  String path, {
  Map<String, Object?>? data,
});

/// Offline-first cache: server policy wins within 60s poll (AC3).
class GuardianLimitsPolicyCache {
  GuardianLimitsPolicyCache._();

  static GuardianChildLimitStatus? lastStatus;
  static DateTime? lastFetchedAt;
  static int lastPolicyRevision = 0;

  static void apply(GuardianChildLimitStatus status) {
    if (status.policyRevision >= lastPolicyRevision) {
      lastStatus = status;
      lastPolicyRevision = status.policyRevision;
      lastFetchedAt = DateTime.now();
    }
  }

  static GuardianChildLimitStatus? effectiveNow() {
    final cached = lastStatus;
    if (cached == null) return null;
    return cached;
  }
}

class GuardianLimitsService {
  GuardianLimitsService({
    GuardianLimitsGet? get,
    GuardianLimitsPut? put,
    Future<bool> Function()? isOnline,
  })  : _get = get ?? _defaultGet,
        _put = put ?? _defaultPut,
        _isOnline = isOnline ?? (() async => true);

  final GuardianLimitsGet _get;
  final GuardianLimitsPut _put;
  final Future<bool> Function() _isOnline;

  static Future<Map<String, dynamic>> _defaultGet(String path) async {
    await ApiService.initialize();
    final response = await ApiService.get(path);
    final json = response.data;
    if (json is Map<String, dynamic>) return json;
    return <String, dynamic>{'ok': false};
  }

  static Future<Map<String, dynamic>> _defaultPut(
    String path, {
    Map<String, Object?>? data,
  }) async {
    await ApiService.initialize();
    final response = await ApiService.put(path, data: data);
    final json = response.data;
    if (json is Map<String, dynamic>) return json;
    return <String, dynamic>{'ok': false};
  }

  Future<List<GuardianChildProgressRow>> fetchProgress() async {
    if (!await _isOnline()) {
      throw const GuardianOfflineException();
    }
    final json = await _get('$guardianApiBasePath/limits/progress');
    if (json['ok'] != true) {
      throw GuardianApiException(
        code: json['code']?.toString(),
        message: json['message']?.toString(),
      );
    }
    final list = json['children'];
    if (list is! List) return [];
    return list
        .whereType<Map>()
        .map((e) => GuardianChildProgressRow.fromJson(Map<String, dynamic>.from(e)))
        .where((r) => r.childUserId > 0)
        .toList();
  }

  Future<bool> saveDailyLimit({
    required int childUserId,
    required int dailyMinutes,
    required String timezone,
  }) async {
    if (!await _isOnline()) return false;
    final json = await _put(
      '$guardianApiBasePath/limits',
      data: {
        'child_user_id': childUserId,
        'daily_minutes': dailyMinutes,
        'timezone': timezone,
      },
    );
    return json['ok'] == true;
  }

  Future<GuardianChildLimitStatus?> pollChildStatus({bool forceRefresh = false}) async {
    final cached = GuardianLimitsPolicyCache.effectiveNow();
    final fetchedAt = GuardianLimitsPolicyCache.lastFetchedAt;
    if (!forceRefresh &&
        cached != null &&
        fetchedAt != null &&
        DateTime.now().difference(fetchedAt).inSeconds < 55) {
      return cached;
    }
    if (!await _isOnline()) {
      return cached;
    }
    final json = await _get('$guardianApiBasePath/limits/status');
    if (json['ok'] != true) return cached;
    final status = GuardianChildLimitStatus.fromJson(json);
    GuardianLimitsPolicyCache.apply(status);
    return status;
  }
}

enum GuardianLimitsUiState { loading, empty, loaded, error, offline }

class GuardianLimitsProgressScreen extends HookConsumerWidget {
  const GuardianLimitsProgressScreen({
    super.key,
    this.limitsService,
  });

  final GuardianLimitsService? limitsService;

  static const String guardianLimitsTitle = 'Time and progress';
  static const String guardianLimitsSectionHeading = "Today's activity";
  static const String guardianLimitsEmptyTitle = 'No linked learners yet';
  static const String guardianLimitsEmptyBody =
      'When you link a learner account, their practice minutes, can-do progress, '
      'and approved groups show up here. You can set a calm daily limit too.';
  static const String guardianLimitsOfflineEmptyTitle = 'No synced progress yet';
  static const String guardianLimitsOfflineEmptyBody =
      'Reconnect to see today\'s minutes, can-do progress, and approved groups.';
  static const String guardianLimitsReachedTitle = 'You reached today\'s limit';
  static const String guardianLimitsReachedBody =
      'Your parent or guardian set a daily learning window. Rest up — '
      'you can start a fresh session tomorrow.';
  static const String offlineBanner =
      'You are offline. Limits and progress sync when you reconnect.';
  static const String saveLimitSuccess = 'Daily limit saved. It applies right away.';
  static const String saveLimitFailure = 'We could not save that limit. Try again.';
  static const String guardianLimitsSlowLoadHint =
      'Still checking — this can take a moment on a slow connection.';

  /// How long the initial load can run before we reassure the guardian this
  /// isn't frozen. Chosen to sit above typical API latency but well before
  /// anyone would reasonably start to doubt the app.
  static const Duration _slowLoadThreshold = Duration(seconds: 4);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = limitsService ?? GuardianLimitsService();
    final colorScheme = Theme.of(context).colorScheme;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);

    final uiState = useState(GuardianLimitsUiState.loading);
    final rows = useState<List<GuardianChildProgressRow>>([]);
    final errorMessage = useState<String?>(null);
    final isOffline = useState(false);
    final saveBusy = useState<int?>(null);
    final limitDrafts = useState<Map<int, int>>({});
    final isSlowLoad = useState(false);

    // Reassures the guardian on a slow connection instead of leaving a bare
    // spinner that could otherwise be mistaken for a frozen screen.
    useEffect(() {
      if (uiState.value != GuardianLimitsUiState.loading) {
        isSlowLoad.value = false;
        return null;
      }
      final timer = Timer(_slowLoadThreshold, () {
        isSlowLoad.value = true;
      });
      return timer.cancel;
    }, [uiState.value]);

    Future<void> load() async {
      uiState.value = GuardianLimitsUiState.loading;
      errorMessage.value = null;
      isOffline.value = false;
      try {
        final fetched = await service.fetchProgress();
        rows.value = fetched;
        final drafts = <int, int>{};
        for (final row in fetched) {
          drafts[row.childUserId] = row.dailyMinutesLimit ?? 45;
        }
        limitDrafts.value = drafts;
        uiState.value =
            fetched.isEmpty ? GuardianLimitsUiState.empty : GuardianLimitsUiState.loaded;
      } on GuardianOfflineException {
        isOffline.value = true;
        uiState.value =
            rows.value.isEmpty ? GuardianLimitsUiState.offline : GuardianLimitsUiState.loaded;
      } on GuardianApiException catch (e) {
        errorMessage.value = e.message ?? 'We could not load progress. Try again.';
        uiState.value = GuardianLimitsUiState.error;
      } catch (_) {
        errorMessage.value = 'We could not load progress. Try again.';
        uiState.value = GuardianLimitsUiState.error;
      }
    }

    useEffect(() {
      load();
      return null;
    }, const []);

    Future<void> onSaveLimit(int childUserId) async {
      final minutes = limitDrafts.value[childUserId] ?? 45;
      saveBusy.value = childUserId;
      try {
        final tz = DateTime.now().timeZoneName;
        final ok = await service.saveDailyLimit(
          childUserId: childUserId,
          dailyMinutes: minutes,
          timezone: tz.isNotEmpty ? tz : 'UTC',
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(ok ? saveLimitSuccess : saveLimitFailure),
            ),
          );
        }
        await load();
      } finally {
        saveBusy.value = null;
      }
    }

    Widget buildLoadedList() {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(
            header: true,
            child: Text(
              GuardianLimitsProgressScreen.guardianLimitsSectionHeading,
              style: PanAfricanTypography.titleMedium(context)
                  .copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          SizedBox(height: PanAfricanSpacing.sm.h),
          const GuardianMessagingExplainerHubTile(),
          SizedBox(height: PanAfricanSpacing.lg.h),
          ...rows.value.map(
            (row) => _ChildProgressCard(
              row: row,
              limitMinutes: limitDrafts.value[row.childUserId] ?? row.dailyMinutesLimit ?? 45,
              reducedMotion: reducedMotion,
              onLimitChanged: (value) {
                limitDrafts.value = {
                  ...limitDrafts.value,
                  row.childUserId: value,
                };
              },
              onSave: () => onSaveLimit(row.childUserId),
              saving: saveBusy.value == row.childUserId,
            ),
          ),
        ],
      );
    }

    Widget buildContent() {
      switch (uiState.value) {
        case GuardianLimitsUiState.loading:
          return Padding(
            padding: EdgeInsets.all(PanAfricanSpacing.xl.w),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Semantics(
                    label: 'Loading your learners\' progress',
                    child: const CircularProgressIndicator(),
                  ),
                  if (isSlowLoad.value) ...[
                    SizedBox(height: PanAfricanSpacing.md.h),
                    Text(
                      guardianLimitsSlowLoadHint,
                      textAlign: TextAlign.center,
                      style: PanAfricanTypography.bodySmall(context).copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        case GuardianLimitsUiState.error:
          return _ErrorState(
            message: errorMessage.value ?? 'Something went wrong.',
            onRetry: load,
          );
        case GuardianLimitsUiState.empty:
          return const _EmptyState(isOffline: false);
        case GuardianLimitsUiState.offline:
          return rows.value.isEmpty ? const _EmptyState(isOffline: true) : buildLoadedList();
        case GuardianLimitsUiState.loaded:
          return buildLoadedList();
      }
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text(guardianLimitsTitle),
      ),
      body: ResponsiveSafeArea(
        child: RefreshIndicator(
          onRefresh: load,
          child: ListView(
            padding: EdgeInsets.symmetric(
              horizontal: PanAfricanSpacing.lg.w,
              vertical: PanAfricanSpacing.md.h,
            ),
            children: [
              if (isOffline.value)
                Padding(
                  padding: EdgeInsets.only(bottom: PanAfricanSpacing.md.h),
                  child: _OfflineBanner(colorScheme: colorScheme),
                ),
              AnimatedSwitcher(
                duration: reducedMotion ? Duration.zero : const Duration(milliseconds: 220),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: KeyedSubtree(
                  key: ValueKey(uiState.value),
                  child: buildContent(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Screen Time / Family Link style end-of-session gate shown to the learner.
class GuardianDailyLimitReachedScreen extends StatelessWidget {
  const GuardianDailyLimitReachedScreen({super.key});

  /// 40sp reads clearly as a calm, centred "night" glyph inside the
  /// primaryContainer circle without crowding the surrounding copy.
  static const double _iconSize = 40;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: PanAfricanSpacing.lg.w,
            vertical: PanAfricanSpacing.xl.h,
          ),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: reducedMotion ? 1 : 0, end: 1),
            duration: reducedMotion ? Duration.zero : const Duration(milliseconds: 420),
            curve: Curves.easeOutCubic,
            builder: (context, t, child) {
              return Opacity(
                opacity: t,
                child: Transform.translate(
                  offset: Offset(0, (1 - t) * 12.h),
                  child: child,
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(PanAfricanSpacing.md.w),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.nightlight_round,
                    size: _iconSize.sp,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                SizedBox(height: PanAfricanSpacing.lg.h),
                Text(
                  GuardianLimitsProgressScreen.guardianLimitsReachedTitle,
                  style: PanAfricanTypography.headlineSmall(context),
                ),
                SizedBox(height: PanAfricanSpacing.sm.h),
                Text(
                  GuardianLimitsProgressScreen.guardianLimitsReachedBody,
                  style: PanAfricanTypography.bodyLarge(context).copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                SizedBox(height: PanAfricanSpacing.xxl.h),
                Semantics(
                  button: true,
                  label: 'Go back home',
                  child: SizedBox(
                    width: double.infinity,
                    height: AdaptiveLayout.minTouchTarget.h,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).maybePop(),
                      child: const Text('Go back'),
                    ),
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

class GuardianSessionLimitGate extends HookWidget {
  const GuardianSessionLimitGate({
    super.key,
    required this.childBuilder,
    this.limitsService,
  });

  final Widget Function(BuildContext context) childBuilder;
  final GuardianLimitsService? limitsService;

  @override
  Widget build(BuildContext context) {
    final service = limitsService ?? GuardianLimitsService();
    final blocked = useState(false);
    final checking = useState(true);

    useEffect(() {
      var cancelled = false;
      Future<void> tick() async {
        final status = await service.pollChildStatus();
        if (cancelled) return;
        checking.value = false;
        blocked.value = status?.sessionBlocked ?? false;
      }

      tick();
      final timer = Stream.periodic(const Duration(seconds: 45)).listen((_) => tick());
      return () {
        cancelled = true;
        timer.cancel();
      };
    }, const []);

    if (checking.value) {
      return Center(
        child: Semantics(
          label: 'Checking today\'s learning time',
          child: const CircularProgressIndicator(),
        ),
      );
    }
    if (blocked.value) {
      return const GuardianDailyLimitReachedScreen();
    }
    return childBuilder(context);
  }
}

class _OfflineBanner extends StatelessWidget {
  const _OfflineBanner({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: GuardianLimitsProgressScreen.offlineBanner,
      child: Material(
        color: colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
        child: Padding(
          padding: EdgeInsets.all(PanAfricanSpacing.md.w),
          child: Row(
            children: [
              ExcludeSemantics(
                child: Icon(Icons.cloud_off_outlined, color: colorScheme.onErrorContainer),
              ),
              SizedBox(width: PanAfricanSpacing.sm.w),
              Expanded(
                child: Text(
                  GuardianLimitsProgressScreen.offlineBanner,
                  style: PanAfricanTypography.bodyMedium(context).copyWith(
                    color: colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isOffline});

  final bool isOffline;

  @override
  Widget build(BuildContext context) {
    final title = isOffline
        ? GuardianLimitsProgressScreen.guardianLimitsOfflineEmptyTitle
        : GuardianLimitsProgressScreen.guardianLimitsEmptyTitle;
    final body = isOffline
        ? GuardianLimitsProgressScreen.guardianLimitsOfflineEmptyBody
        : GuardianLimitsProgressScreen.guardianLimitsEmptyBody;
    return Semantics(
      container: true,
      label: '$title. $body',
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: PanAfricanSpacing.xl.h),
        child: Column(
          children: [
            ExcludeSemantics(
              child: Icon(
                isOffline ? Icons.cloud_off_outlined : Icons.family_restroom_outlined,
                size: 64.sp,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            SizedBox(height: PanAfricanSpacing.md.h),
            Text(
              title,
              textAlign: TextAlign.center,
              style: PanAfricanTypography.titleMedium(context),
            ),
            SizedBox(height: PanAfricanSpacing.sm.h),
            Text(
              body,
              textAlign: TextAlign.center,
              style: PanAfricanTypography.bodyMedium(context).copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: PanAfricanSpacing.xl.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: PanAfricanTypography.bodyMedium(context),
          ),
          SizedBox(height: PanAfricanSpacing.md.h),
          SizedBox(
            height: AdaptiveLayout.minTouchTarget.h,
            child: FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ),
        ],
      ),
    );
  }
}

/// Screen Time-style daily ring: outer track + animated progress arc with the
/// minutes used at the centre. Respects reduced-motion by skipping the fill
/// animation and jumping straight to the final value.
class _MinutesRing extends StatelessWidget {
  const _MinutesRing({
    required this.minutesUsed,
    required this.minutesLimit,
    required this.reducedMotion,
  });

  final int minutesUsed;
  final int minutesLimit;
  final bool reducedMotion;

  /// No shared design-system token exists yet for a progress-ring diameter
  /// or stroke width (see pan_african_design_system.dart). Named locally so
  /// the two usages below stay in lock-step instead of repeating literals;
  /// a `PanAfricanRing` token family would be a reasonable follow-up.
  static const double _diameterBase = 64;
  static const double _strokeWidthBase = 6;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ratio = minutesLimit <= 0 ? 0.0 : (minutesUsed / minutesLimit).clamp(0.0, 1.0);
    final atLimit = minutesLimit > 0 && minutesUsed >= minutesLimit;
    final diameter = _diameterBase.w;
    final strokeWidth = _strokeWidthBase.w;

    return Semantics(
      label: atLimit
          ? '$minutesUsed of $minutesLimit minutes used today. Daily limit reached.'
          : '$minutesUsed of $minutesLimit minutes used today',
      child: SizedBox(
        width: diameter,
        height: diameter,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: ratio),
          duration: reducedMotion ? Duration.zero : const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          builder: (context, value, _) {
            return Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: diameter,
                  height: diameter,
                  child: CircularProgressIndicator(
                    value: 1,
                    strokeWidth: strokeWidth,
                    color: colorScheme.surfaceContainerHighest,
                  ),
                ),
                SizedBox(
                  width: diameter,
                  height: diameter,
                  child: CircularProgressIndicator(
                    value: value,
                    strokeWidth: strokeWidth,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      atLimit ? colorScheme.error : colorScheme.primary,
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(PanAfricanSpacing.xxs.w),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      '$minutesUsed',
                      maxLines: 1,
                      style: PanAfricanTypography.labelLarge(context).copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ChildProgressCard extends StatelessWidget {
  const _ChildProgressCard({
    required this.row,
    required this.limitMinutes,
    required this.onLimitChanged,
    required this.onSave,
    required this.saving,
    required this.reducedMotion,
  });

  final GuardianChildProgressRow row;
  final int limitMinutes;
  final ValueChanged<int> onLimitChanged;
  final VoidCallback onSave;
  final bool saving;
  final bool reducedMotion;

  /// Local, named stand-ins for sizes the shared design system does not yet
  /// tokenise (see the gap note on `_MinutesRing`): the approved-group row
  /// icon and the inline save-button busy spinner.
  static const double _groupIconSize = 20;
  static const double _savingSpinnerSize = 22;
  static const double _canDoBadgeIconSize = 14;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final displayName = row.displayName();
    final cardSemanticsLabel = '$displayName, ${row.minutesLearnedToday} of '
        '$limitMinutes minutes used today, ${row.canDoVerifiedCount} can-dos verified';

    return Semantics(
      container: true,
      label: cardSemanticsLabel,
      child: Card(
        margin: EdgeInsets.only(bottom: PanAfricanSpacing.md.h),
        child: Padding(
          padding: EdgeInsets.all(PanAfricanSpacing.lg.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // The outer Semantics(label: cardSemanticsLabel) above already
              // speaks name + minutes + can-dos as one clean sentence. Without
              // excluding this row's own text/ring semantics, a screen reader
              // re-announces the same numbers a second time in a jumbled,
              // concatenated node right after the clean summary (confirmed via
              // a semantics-tree probe). ExcludeSemantics keeps the single
              // summary as the only thing announced for this part of the
              // card, matching the pattern used in approvals_screen's
              // _ApprovalCard.
              ExcludeSemantics(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _MinutesRing(
                      minutesUsed: row.minutesLearnedToday,
                      minutesLimit: limitMinutes,
                      reducedMotion: reducedMotion,
                    ),
                    SizedBox(width: PanAfricanSpacing.md.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: PanAfricanTypography.titleMedium(context)
                                .copyWith(fontWeight: FontWeight.w700),
                          ),
                          SizedBox(height: PanAfricanSpacing.xxxs.h),
                          Text(
                            '${row.minutesLearnedToday} of $limitMinutes min today',
                            style: PanAfricanTypography.bodyMedium(context).copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        SizedBox(height: PanAfricanSpacing.xs.h),
                        // Can-do mastery is a LingAfriq curriculum concept
                        // with no Screen Time/Family Link equivalent — a
                        // small badge (not a plain progress line) gives it
                        // its own visual identity instead of reading as
                        // "just another usage stat".
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: PanAfricanSpacing.xs.w,
                            vertical: PanAfricanSpacing.xxxs.h,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.secondaryContainer,
                            borderRadius: PanAfricanRadius.roundBR,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                PanAfricanIcons.badge,
                                size: _canDoBadgeIconSize.sp,
                                color: colorScheme.onSecondaryContainer,
                              ),
                              SizedBox(width: PanAfricanSpacing.xxs.w),
                              Flexible(
                                child: Text(
                                  '${row.canDoVerifiedCount} can-dos verified',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: PanAfricanTypography.labelSmall(context).copyWith(
                                    color: colorScheme.onSecondaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
              if (row.approvedGroups.isNotEmpty) ...[
                SizedBox(height: PanAfricanSpacing.md.h),
                Semantics(
                  header: true,
                  child: Text(
                    'Approved groups',
                    style: PanAfricanTypography.labelLarge(context),
                  ),
                ),
                ...row.approvedGroups.map(
                  (g) => ListTile(
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                      leading: ExcludeSemantics(
                      child: Icon(
                        g.groupKind == 'classroom' ? Icons.school_outlined : Icons.groups_outlined,
                        size: _groupIconSize.sp,
                      ),
                    ),
                    title: Text(g.groupName),
                  ),
                ),
              ],
              SizedBox(height: PanAfricanSpacing.md.h),
              Text('Daily limit', style: PanAfricanTypography.labelLarge(context)),
              SizedBox(height: PanAfricanSpacing.xxs.h),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: limitMinutes.toDouble().clamp(15, 180),
                      min: 15,
                      max: 180,
                      divisions: 11,
                      label: '$limitMinutes min',
                      semanticFormatterCallback: (value) => '${value.round()} minutes a day',
                      onChanged: saving ? null : (v) => onLimitChanged(v.round()),
                    ),
                  ),
                  SizedBox(width: PanAfricanSpacing.sm.w),
                  Text(
                    '$limitMinutes min',
                    style: PanAfricanTypography.labelLarge(context),
                  ),
                ],
              ),
              SizedBox(height: PanAfricanSpacing.xs.h),
              Semantics(
                button: true,
                label: 'Save daily limit for $displayName',
                child: SizedBox(
                  width: double.infinity,
                  height: AdaptiveLayout.minTouchTarget.h,
                  child: FilledButton(
                    onPressed: saving ? null : onSave,
                    child: saving
                        ? SizedBox(
                            width: _savingSpinnerSize.w,
                            height: _savingSpinnerSize.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Save limit'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
