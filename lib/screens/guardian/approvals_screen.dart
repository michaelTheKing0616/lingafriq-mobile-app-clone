import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/services/guardian_link_service.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/responsive_safe_area.dart';

/// Copy keys: guardian.approvals.title, guardian.approvals.empty (P9-914).
/// Reference: Apple Screen Time / Google Family Link app-approval list.
class GuardianGroupJoinRequestRow {
  GuardianGroupJoinRequestRow({
    required this.requestId,
    required this.childUserId,
    required this.groupKind,
    required this.groupName,
    required this.memberCount,
    required this.adultMemberCount,
    required this.moderationStatus,
    required this.status,
    this.expiresAt,
  });

  final String requestId;
  final int childUserId;
  final String groupKind;
  final String groupName;
  final int memberCount;
  final int adultMemberCount;
  final String moderationStatus;
  final String status;
  final DateTime? expiresAt;

  factory GuardianGroupJoinRequestRow.fromJson(Map<String, dynamic> json) {
    DateTime? parse(String? raw) {
      if (raw == null || raw.isEmpty) return null;
      return DateTime.tryParse(raw);
    }

    return GuardianGroupJoinRequestRow(
      requestId: json['request_id']?.toString() ?? '',
      childUserId: (json['child_user_id'] as num?)?.toInt() ?? 0,
      groupKind: json['group_kind']?.toString() ?? 'classroom',
      groupName: json['group_name']?.toString() ?? 'Group',
      memberCount: (json['member_count'] as num?)?.toInt() ?? 0,
      adultMemberCount: (json['adult_member_count'] as num?)?.toInt() ?? 0,
      moderationStatus: json['moderation_status']?.toString() ?? 'open',
      status: json['status']?.toString() ?? 'pending',
      expiresAt: parse(json['expires_at']?.toString()),
    );
  }

  bool get isPending => status == 'pending' || status == 'needs_reapproval';
  bool get isApproved => status == 'approved';
}

typedef GuardianApprovalGet = Future<Map<String, dynamic>> Function(String path);
typedef GuardianApprovalPost = Future<Map<String, dynamic>> Function(
  String path, {
  Map<String, Object?>? data,
});

class GuardianApprovalService {
  GuardianApprovalService({
    GuardianApprovalGet? get,
    GuardianApprovalPost? post,
    Future<bool> Function()? isOnline,
  })  : _get = get ?? _defaultGet,
        _post = post ?? _defaultPost,
        _isOnline = isOnline ?? (() async => true);

  final GuardianApprovalGet _get;
  final GuardianApprovalPost _post;
  final Future<bool> Function() _isOnline;

  static Future<Map<String, dynamic>> _defaultGet(String path) async {
    await ApiService.initialize();
    final response = await ApiService.get(path);
    final json = response.data;
    if (json is Map<String, dynamic>) return json;
    return <String, dynamic>{'ok': false};
  }

  static Future<Map<String, dynamic>> _defaultPost(
    String path, {
    Map<String, Object?>? data,
  }) async {
    await ApiService.initialize();
    final response = await ApiService.post(path, data: data);
    final json = response.data;
    if (json is Map<String, dynamic>) return json;
    return <String, dynamic>{'ok': false};
  }

  Future<List<GuardianGroupJoinRequestRow>> fetchApprovals() async {
    if (!await _isOnline()) {
      throw const GuardianOfflineException();
    }
    final json = await _get('$guardianApiBasePath/approvals');
    if (json['ok'] != true) {
      throw GuardianApiException(
        code: json['code']?.toString(),
        message: json['message']?.toString(),
      );
    }
    final list = json['requests'];
    if (list is! List) return [];
    return list
        .whereType<Map>()
        .map((e) => GuardianGroupJoinRequestRow.fromJson(Map<String, dynamic>.from(e)))
        .where((r) => r.requestId.isNotEmpty)
        .toList();
  }

  Future<bool> approve(String requestId) async {
    if (!await _isOnline()) return false;
    final json = await _post('$guardianApiBasePath/approvals/$requestId/approve');
    return json['ok'] == true;
  }

  Future<bool> revoke(String requestId) async {
    if (!await _isOnline()) return false;
    final json = await _post('$guardianApiBasePath/approvals/$requestId/revoke');
    return json['ok'] == true;
  }
}

enum GuardianApprovalsUiState { loading, empty, loaded, error, offline }

class GuardianApprovalsScreen extends HookConsumerWidget {
  const GuardianApprovalsScreen({
    super.key,
    this.approvalService,
  });

  final GuardianApprovalService? approvalService;

  static const String guardianApprovalsTitle = 'Group approvals';
  static const String guardianApprovalsEmptyTitle = 'No group requests yet';
  static const String guardianApprovalsEmptyBody =
      'When your learner asks to join a circle or classroom, the details show up here '
      'so you can review members and moderation before they join.';
  static const String offlineBanner =
      'You are offline. Approvals will sync when you reconnect.';
  static const String reviewSectionTitle = 'Needs your review';
  static const String decidedSectionTitle = 'Already decided';

  // Note on scope: this screen is guardian-only (never opened by the learner
  // account), so a "child mode" / "locked" state is not applicable here —
  // locking belongs to learner-facing screens such as
  // GuardianDailyLimitReachedScreen in limits_progress_screen.dart.
  static const String _genericLoadError =
      'We could not load approvals. Try again in a moment.';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = approvalService ?? GuardianApprovalService();
    final colorScheme = Theme.of(context).colorScheme;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);

    final uiState = useState(GuardianApprovalsUiState.loading);
    final rows = useState<List<GuardianGroupJoinRequestRow>>([]);
    final errorMessage = useState<String?>(null);
    final isOffline = useState(false);
    final actionBusy = useState<String?>(null);

    Future<void> load() async {
      uiState.value = GuardianApprovalsUiState.loading;
      errorMessage.value = null;
      isOffline.value = false;
      try {
        final fetched = await service.fetchApprovals();
        rows.value = fetched;
        uiState.value =
            fetched.isEmpty ? GuardianApprovalsUiState.empty : GuardianApprovalsUiState.loaded;
      } on GuardianOfflineException {
        isOffline.value = true;
        uiState.value = rows.value.isEmpty
            ? GuardianApprovalsUiState.offline
            : GuardianApprovalsUiState.loaded;
      } on GuardianApiException catch (e) {
        errorMessage.value = e.message ?? _genericLoadError;
        uiState.value = GuardianApprovalsUiState.error;
      } catch (_) {
        errorMessage.value = _genericLoadError;
        uiState.value = GuardianApprovalsUiState.error;
      }
    }

    useEffect(() {
      load();
      return null;
    }, const []);

    Future<void> onApprove(GuardianGroupJoinRequestRow row) async {
      actionBusy.value = row.requestId;
      try {
        final ok = await service.approve(row.requestId);
        if (context.mounted) {
          if (ok) {
            HapticFeedback.lightImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Approved — ${row.groupName} can welcome your learner.')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('We could not approve that request. Try again.')),
            );
          }
        }
        await load();
      } finally {
        actionBusy.value = null;
      }
    }

    Future<void> onRevoke(GuardianGroupJoinRequestRow row) async {
      actionBusy.value = row.requestId;
      try {
        final ok = await service.revoke(row.requestId);
        if (context.mounted) {
          if (ok) {
            HapticFeedback.lightImpact();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Revoked — access to ${row.groupName} is off.')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('We could not revoke that approval. Try again.')),
            );
          }
        }
        await load();
      } finally {
        actionBusy.value = null;
      }
    }

    final pendingRows = rows.value.where((r) => r.isPending).toList();
    final decidedRows = rows.value.where((r) => !r.isPending).toList();

    Widget buildSections() {
      return Column(
        key: const ValueKey('approvals-sections'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pendingRows.isNotEmpty) ...[
            _SectionHeader(title: reviewSectionTitle, count: pendingRows.length),
            SizedBox(height: PanAfricanSpacing.sm.h),
            ...pendingRows.map(
              (row) => _ApprovalCard(
                row: row,
                busy: actionBusy.value == row.requestId,
                onApprove: () => onApprove(row),
                onRevoke: null,
                colorScheme: colorScheme,
              ),
            ),
          ],
          if (decidedRows.isNotEmpty) ...[
            if (pendingRows.isNotEmpty) SizedBox(height: PanAfricanSpacing.lg.h),
            const _SectionHeader(title: decidedSectionTitle, count: null),
            SizedBox(height: PanAfricanSpacing.sm.h),
            ...decidedRows.map(
              (row) => _ApprovalCard(
                row: row,
                busy: actionBusy.value == row.requestId,
                onApprove: null,
                onRevoke: row.isApproved ? () => onRevoke(row) : null,
                colorScheme: colorScheme,
              ),
            ),
          ],
        ],
      );
    }

    // Matches the house pattern in limits_progress_screen.dart /
    // guardian_link_screen.dart: a single switch resolves the current state
    // to one Widget, which is cross-faded in via AnimatedSwitcher below
    // (instead of jump-cutting between loading/error/empty/loaded).
    Widget buildContent() {
      switch (uiState.value) {
        case GuardianApprovalsUiState.loading:
          return const _LoadingPanel();
        case GuardianApprovalsUiState.error:
          return _ErrorPanel(
            message: errorMessage.value ?? _genericLoadError,
            onRetry: load,
          );
        case GuardianApprovalsUiState.empty:
          return _EmptyPanel(
            title: guardianApprovalsEmptyTitle,
            body: guardianApprovalsEmptyBody,
            animate: !reducedMotion,
          );
        case GuardianApprovalsUiState.offline:
          return rows.value.isEmpty
              ? _EmptyPanel(
                  title: guardianApprovalsEmptyTitle,
                  body: guardianApprovalsEmptyBody,
                  animate: !reducedMotion,
                )
              : buildSections();
        case GuardianApprovalsUiState.loaded:
          return buildSections();
      }
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text(guardianApprovalsTitle),
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
                  child: Semantics(
                    liveRegion: true,
                    child: Material(
                      color: colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
                      child: ListTile(
                        leading:
                            Icon(Icons.cloud_off_outlined, color: colorScheme.onErrorContainer),
                        title: Text(
                          offlineBanner,
                          style: PanAfricanTypography.bodyMedium(context).copyWith(
                            color: colorScheme.onErrorContainer,
                          ),
                        ),
                      ),
                    ),
                  ),
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

class _LoadingPanel extends StatelessWidget {
  const _LoadingPanel();

  static const double _verticalPadding = 48;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: _verticalPadding.h),
      child: Center(
        child: Semantics(
          label: 'Loading your approvals',
          child: const CircularProgressIndicator(),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.count});

  final String title;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final showBadge = count != null && count! > 0;
    return Semantics(
      header: true,
      label: showBadge
          ? '$title, $count request${count == 1 ? '' : 's'} waiting'
          : title,
      child: ExcludeSemantics(
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style:
                    PanAfricanTypography.titleMedium(context).copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            if (showBadge) ...[
              SizedBox(width: PanAfricanSpacing.xs.w),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: PanAfricanSpacing.sm.w,
                  vertical: PanAfricanSpacing.xxs.h,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: PanAfricanRadius.roundBR,
                ),
                child: Text(
                  '$count',
                  style: PanAfricanTypography.labelMedium(context)
                      .copyWith(color: colorScheme.onPrimaryContainer),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({
    required this.title,
    required this.body,
    required this.animate,
  });

  final String title;
  final String body;
  final bool animate;

  static const double _iconSize = 56;
  static const double _iconBadgeSize = 96;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final content = Padding(
      padding: EdgeInsets.symmetric(vertical: PanAfricanSpacing.xl.h),
      child: Column(
        children: [
          Container(
            width: _iconBadgeSize.w,
            height: _iconBadgeSize.w,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer.withValues(alpha: 0.5),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.groups_outlined,
              size: _iconSize.sp,
              color: colorScheme.primary,
            ),
          ),
          SizedBox(height: PanAfricanSpacing.lg.h),
          Text(
            title,
            textAlign: TextAlign.center,
            style: PanAfricanTypography.titleLarge(context),
          ),
          SizedBox(height: PanAfricanSpacing.sm.h),
          Text(
            body,
            textAlign: TextAlign.center,
            style: PanAfricanTypography.bodyLarge(context).copyWith(
              color: colorScheme.onSurfaceVariant,
              height: 1.45,
            ),
          ),
        ],
      ),
    );

    final labelledContent = Semantics(
      container: true,
      label: '$title. $body',
      child: ExcludeSemantics(child: content),
    );

    if (!animate) return labelledContent;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      builder: (_, t, child) => Opacity(
        opacity: t,
        child: Transform.scale(scale: 0.92 + (0.08 * t), child: child),
      ),
      child: labelledContent,
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: PanAfricanSpacing.lg.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline_rounded, color: colorScheme.error, size: 22.sp),
              SizedBox(width: PanAfricanSpacing.sm.w),
              Expanded(
                child: Text(message, style: PanAfricanTypography.bodyLarge(context)),
              ),
            ],
          ),
          SizedBox(height: PanAfricanSpacing.md.h),
          Semantics(
            button: true,
            label: 'Try loading approvals again',
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: 48.h),
              child: FilledButton(onPressed: onRetry, child: const Text('Try again')),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApprovalActionButton extends StatelessWidget {
  const _ApprovalActionButton({
    required this.label,
    required this.semanticLabel,
    required this.busy,
    required this.onPressed,
    required this.filled,
    this.color,
  });

  final String label;
  final String semanticLabel;
  final bool busy;
  final VoidCallback? onPressed;
  final bool filled;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final child = busy
        ? SizedBox(
            width: 22.w,
            height: 22.w,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: filled ? Colors.white : color,
            ),
          )
        : Text(label);

    final Widget button = filled
        ? FilledButton(onPressed: busy ? null : onPressed, child: child)
        : OutlinedButton(
            onPressed: busy ? null : onPressed,
            style: OutlinedButton.styleFrom(
              foregroundColor: color,
              side: BorderSide(color: color ?? Theme.of(context).colorScheme.outline),
            ),
            child: child,
          );

    return Semantics(
      button: true,
      enabled: !busy,
      label: semanticLabel,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: 48.h),
        child: button,
      ),
    );
  }
}

class _ApprovalCard extends StatelessWidget {
  const _ApprovalCard({
    required this.row,
    required this.busy,
    required this.colorScheme,
    this.onApprove,
    this.onRevoke,
  });

  final GuardianGroupJoinRequestRow row;
  final bool busy;
  final ColorScheme colorScheme;
  final VoidCallback? onApprove;
  final VoidCallback? onRevoke;

  String get _statusLabel {
    switch (row.status) {
      case 'approved':
        return 'Approved';
      case 'expired':
        return 'Expired';
      case 'revoked':
        return 'Revoked';
      case 'needs_reapproval':
        return 'Needs your review again';
      default:
        return 'Waiting for you';
    }
  }

  @override
  Widget build(BuildContext context) {
    final moderationLabel = row.moderationStatus == 'moderated'
        ? 'Posts are moderated'
        : row.moderationStatus == 'approval_required'
            ? 'New members need approval'
            : 'Open community';
    final semanticsLabel =
        '${row.groupName}, learner ${row.childUserId}, ${row.memberCount} members, '
        '$moderationLabel, $_statusLabel';

    return Card(
      margin: EdgeInsets.only(bottom: PanAfricanSpacing.md.h),
      child: Padding(
        padding: EdgeInsets.all(PanAfricanSpacing.md.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informational content is exposed as a single readable summary so
            // screen readers announce the card once, rather than mixing it
            // with the two actionable buttons below (which keep their own
            // distinct Semantics so VoiceOver/TalkBack can target each one).
            Semantics(
              container: true,
              label: semanticsLabel,
              child: ExcludeSemantics(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.groupName,
                      style: PanAfricanTypography.titleMedium(context)
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: PanAfricanSpacing.xs.h),
                    Text(
                      'Learner #${row.childUserId} · ${row.groupKind == 'circle' ? 'Circle' : 'Classroom'}',
                      style: PanAfricanTypography.bodyMedium(context),
                    ),
                    SizedBox(height: PanAfricanSpacing.sm.h),
                    Wrap(
                      spacing: PanAfricanSpacing.sm.w,
                      runSpacing: PanAfricanSpacing.xs.h,
                      children: [
                        _Chip(label: '${row.memberCount} members'),
                        _Chip(label: '${row.adultMemberCount} adults'),
                        _Chip(label: moderationLabel),
                        _Chip(label: _statusLabel, emphasized: row.isPending),
                      ],
                    ),
                    if (row.isPending && row.expiresAt != null) ...[
                      SizedBox(height: PanAfricanSpacing.sm.h),
                      Text(
                        'Expires ${MaterialLocalizations.of(context).formatShortDate(row.expiresAt!)}',
                        style: PanAfricanTypography.bodySmall(context).copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (onApprove != null || onRevoke != null) ...[
              SizedBox(height: PanAfricanSpacing.md.h),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (onApprove != null)
                    Expanded(
                      child: _ApprovalActionButton(
                        label: 'Approve join',
                        semanticLabel:
                            'Approve ${row.groupName} join request for learner ${row.childUserId}',
                        busy: busy,
                        onPressed: onApprove,
                        filled: true,
                      ),
                    ),
                  if (onRevoke != null) ...[
                    SizedBox(width: PanAfricanSpacing.sm.w),
                    Expanded(
                      child: _ApprovalActionButton(
                        label: 'Revoke access',
                        semanticLabel:
                            'Revoke access to ${row.groupName} for learner ${row.childUserId}',
                        busy: busy,
                        onPressed: onRevoke,
                        filled: false,
                        color: colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, this.emphasized = false});

  final String label;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: PanAfricanSpacing.sm.w,
        vertical: PanAfricanSpacing.xs.h,
      ),
      decoration: BoxDecoration(
        color: emphasized ? scheme.primaryContainer : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(PanAfricanRadius.md),
      ),
      child: Text(
        label,
        style: PanAfricanTypography.labelMedium(context).copyWith(
          color: emphasized ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
