import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
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
  });

  final int childUserId;
  final int minutesLearnedToday;
  final int? dailyMinutesLimit;
  final int canDoVerifiedCount;
  final List<GuardianApprovedGroupRow> approvedGroups;

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
  static const String guardianLimitsEmptyTitle = 'No linked learners yet';
  static const String guardianLimitsEmptyBody =
      'When you link a learner account, their practice minutes, can-do progress, '
      'and approved groups show up here. You can set a calm daily limit too.';
  static const String guardianLimitsReachedTitle = 'You reached today\'s limit';
  static const String guardianLimitsReachedBody =
      'Your parent or guardian set a daily learning window. Rest up — '
      'you can start a fresh session tomorrow.';
  static const String offlineBanner =
      'You are offline. Limits and progress sync when you reconnect.';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = limitsService ?? GuardianLimitsService();
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final uiState = useState(GuardianLimitsUiState.loading);
    final rows = useState<List<GuardianChildProgressRow>>([]);
    final errorMessage = useState<String?>(null);
    final isOffline = useState(false);
    final saveBusy = useState<int?>(null);
    final limitDrafts = useState<Map<int, int>>({});

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
        if (!ok && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('We could not save that limit. Try again.')),
          );
        }
        await load();
      } finally {
        saveBusy.value = null;
      }
    }

    return Scaffold(
      backgroundColor: isDark ? PanAfricanColors.surfaceDark : PanAfricanColors.surfaceLight,
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
                  child: Material(
                    color: colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
                    child: ListTile(
                      leading: Icon(Icons.cloud_off_outlined, color: colorScheme.onErrorContainer),
                      title: Text(
                        offlineBanner,
                        style: PanAfricanTypography.bodyMedium(context).copyWith(
                          color: colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ),
                ),
              if (uiState.value == GuardianLimitsUiState.loading)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (uiState.value == GuardianLimitsUiState.error)
                _ErrorState(message: errorMessage.value ?? 'Something went wrong.', onRetry: load)
              else if (uiState.value == GuardianLimitsUiState.empty ||
                  uiState.value == GuardianLimitsUiState.offline && rows.value.isEmpty)
                _EmptyState(isOffline: uiState.value == GuardianLimitsUiState.offline)
              else
                ...rows.value.map(
                  (row) => _ChildProgressCard(
                    row: row,
                    limitMinutes: limitDrafts.value[row.childUserId] ?? row.dailyMinutesLimit ?? 45,
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
          ),
        ),
      ),
    );
  }
}

class GuardianDailyLimitReachedScreen extends StatelessWidget {
  const GuardianDailyLimitReachedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: PanAfricanSpacing.lg.w,
            vertical: PanAfricanSpacing.xl.h,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.nightlight_round, size: 56.sp, color: colorScheme.primary),
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
                  height: 48.h,
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
      return const Center(child: CircularProgressIndicator());
    }
    if (blocked.value) {
      return const GuardianDailyLimitReachedScreen();
    }
    return childBuilder(context);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isOffline});

  final bool isOffline;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: GuardianLimitsProgressScreen.guardianLimitsEmptyTitle,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: PanAfricanSpacing.xl.h),
        child: Column(
          children: [
            Icon(Icons.family_restroom_outlined, size: 64.sp, color: Theme.of(context).colorScheme.primary),
            SizedBox(height: PanAfricanSpacing.md.h),
            Text(
              isOffline ? GuardianLimitsProgressScreen.offlineBanner : GuardianLimitsProgressScreen.guardianLimitsEmptyTitle,
              textAlign: TextAlign.center,
              style: PanAfricanTypography.titleMedium(context),
            ),
            SizedBox(height: PanAfricanSpacing.sm.h),
            if (!isOffline)
              Text(
                GuardianLimitsProgressScreen.guardianLimitsEmptyBody,
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
    return Column(
      children: [
        Text(message, style: PanAfricanTypography.bodyMedium(context)),
        SizedBox(height: PanAfricanSpacing.md.h),
        FilledButton(onPressed: onRetry, child: const Text('Try again')),
      ],
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
  });

  final GuardianChildProgressRow row;
  final int limitMinutes;
  final ValueChanged<int> onLimitChanged;
  final VoidCallback onSave;
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.only(bottom: PanAfricanSpacing.md.h),
      child: Padding(
        padding: EdgeInsets.all(PanAfricanSpacing.lg.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Learner #${row.childUserId}',
              style: PanAfricanTypography.titleMedium(context),
            ),
            SizedBox(height: PanAfricanSpacing.sm.h),
            Text(
              '${row.minutesLearnedToday} min practiced today',
              style: PanAfricanTypography.bodyLarge(context),
            ),
            Text(
              '${row.canDoVerifiedCount} can-dos verified',
              style: PanAfricanTypography.bodyMedium(context).copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            if (row.approvedGroups.isNotEmpty) ...[
              SizedBox(height: PanAfricanSpacing.sm.h),
              Text(
                'Approved groups',
                style: PanAfricanTypography.labelLarge(context),
              ),
              ...row.approvedGroups.map(
                (g) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    g.groupKind == 'classroom' ? Icons.school_outlined : Icons.groups_outlined,
                    size: 20.sp,
                  ),
                  title: Text(g.groupName),
                ),
              ),
            ],
            SizedBox(height: PanAfricanSpacing.md.h),
            Text('Daily limit (minutes)', style: PanAfricanTypography.labelLarge(context)),
            Row(
              children: [
                Expanded(
                  child: Slider(
                    value: limitMinutes.toDouble().clamp(15, 180),
                    min: 15,
                    max: 180,
                    divisions: 11,
                    label: '$limitMinutes min',
                    onChanged: saving ? null : (v) => onLimitChanged(v.round()),
                  ),
                ),
                Text('$limitMinutes'),
              ],
            ),
            Semantics(
              button: true,
              label: 'Save daily limit for learner ${row.childUserId}',
              child: SizedBox(
                width: double.infinity,
                height: 48.h,
                child: FilledButton(
                  onPressed: saving ? null : onSave,
                  child: saving
                      ? SizedBox(
                          width: 22.w,
                          height: 22.w,
                          child: const CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save limit'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
