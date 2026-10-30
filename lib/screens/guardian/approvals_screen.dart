import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/services/guardian_link_service.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/responsive_safe_area.dart';

/// Copy keys: guardian.approvals.title, guardian.approvals.empty (P9-914).
/// Reference pack: docs/design/references/guardian-approvals (recoloured, own copy).
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
    this.childName,
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

  /// The learner's first name (or username) from the guardian's own link; null if unknown.
  final String? childName;

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
      childName: (json['child_name']?.toString().trim().isNotEmpty ?? false)
          ? json['child_name'].toString().trim()
          : null,
    );
  }

  bool get isPending => status == 'pending' || status == 'needs_reapproval';
  bool get isApproved => status == 'approved';
}

typedef GuardianApprovalGet =
    Future<Map<String, dynamic>> Function(String path);
typedef GuardianApprovalPost =
    Future<Map<String, dynamic>> Function(
      String path, {
      Map<String, Object?>? data,
    });

class GuardianApprovalService {
  GuardianApprovalService({
    GuardianApprovalGet? get,
    GuardianApprovalPost? post,
    Future<bool> Function()? isOnline,
  }) : _get = get ?? _defaultGet,
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
        .map(
          (e) => GuardianGroupJoinRequestRow.fromJson(
            Map<String, dynamic>.from(e),
          ),
        )
        .where((r) => r.requestId.isNotEmpty)
        .toList();
  }

  Future<bool> approve(String requestId) async {
    if (!await _isOnline()) return false;
    final json = await _post(
      '$guardianApiBasePath/approvals/$requestId/approve',
    );
    return json['ok'] == true;
  }

  Future<bool> deny(String requestId) async {
    if (!await _isOnline()) return false;
    final json = await _post('$guardianApiBasePath/approvals/$requestId/deny');
    return json['ok'] == true;
  }

  Future<bool> revoke(String requestId) async {
    if (!await _isOnline()) return false;
    final json = await _post(
      '$guardianApiBasePath/approvals/$requestId/revoke',
    );
    return json['ok'] == true;
  }
}

enum GuardianApprovalsUiState { loading, empty, loaded, error, offline }

enum _Decision { approve, deny, revoke }

class GuardianApprovalsScreen extends HookConsumerWidget {
  const GuardianApprovalsScreen({super.key, this.approvalService});

  final GuardianApprovalService? approvalService;

  // Note on scope: this screen is guardian-only (never opened by the learner
  // account), so a "child mode" / "locked" state is not applicable here.

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context)!;
    final service = useMemoized(
      () => approvalService ?? GuardianApprovalService(),
      [approvalService],
    );
    final colorScheme = Theme.of(context).colorScheme;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);

    final uiState = useState(GuardianApprovalsUiState.loading);
    final rows = useState<List<GuardianGroupJoinRequestRow>>([]);
    final errorMessage = useState<String?>(null);
    final isOffline = useState(false);
    final actionBusy = useState<String?>(null);

    Future<void> load() async {
      // Keep the last good data visible while refreshing (no blanking).
      if (rows.value.isEmpty) uiState.value = GuardianApprovalsUiState.loading;
      errorMessage.value = null;
      isOffline.value = false;
      try {
        final fetched = await service.fetchApprovals();
        rows.value = fetched;
        uiState.value = fetched.isEmpty
            ? GuardianApprovalsUiState.empty
            : GuardianApprovalsUiState.loaded;
      } on GuardianOfflineException {
        isOffline.value = true;
        uiState.value = rows.value.isEmpty
            ? GuardianApprovalsUiState.offline
            : GuardianApprovalsUiState.loaded;
      } on GuardianApiException catch (e) {
        errorMessage.value = e.message;
        uiState.value = rows.value.isEmpty
            ? GuardianApprovalsUiState.error
            : GuardianApprovalsUiState.loaded;
      } catch (_) {
        uiState.value = rows.value.isEmpty
            ? GuardianApprovalsUiState.error
            : GuardianApprovalsUiState.loaded;
      }
    }

    useEffect(() {
      load();
      return null;
    }, const []);

    String childOf(GuardianGroupJoinRequestRow r) =>
        r.childName ?? l.gapLearnerFallback;

    Future<void> decide(GuardianGroupJoinRequestRow row, _Decision d) async {
      if (d == _Decision.deny) {
        final sure = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(l.gapDenyConfirmTitle),
            content: Text(l.gapDenyConfirmBody(childOf(row), row.groupName)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(l.gapCancel),
              ),
              FilledButton(
                key: const ValueKey('gap-deny-confirm'),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(l.gapDeny),
              ),
            ],
          ),
        );
        if (sure != true) return;
      }
      actionBusy.value = row.requestId;
      try {
        final ok = switch (d) {
          _Decision.approve => await service.approve(row.requestId),
          _Decision.deny => await service.deny(row.requestId),
          _Decision.revoke => await service.revoke(row.requestId),
        };
        if (context.mounted) {
          if (ok) HapticFeedback.lightImpact();
          final msg = ok
              ? switch (d) {
                  _Decision.approve => l.gapApprovedToast(row.groupName),
                  _Decision.deny => l.gapDeniedToast(row.groupName),
                  _Decision.revoke => l.gapRevokedToast(row.groupName),
                }
              : l.gapActionFailed;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(msg)));
        }
        await load();
      } finally {
        actionBusy.value = null;
      }
    }

    final pendingRows = rows.value.where((r) => r.isPending).toList();
    final decidedRows = rows.value.where((r) => !r.isPending).toList();

    Widget card(GuardianGroupJoinRequestRow row, {required bool pending}) =>
        _ApprovalCard(
          key: ValueKey('gap-card-${row.requestId}'),
          row: row,
          childName: childOf(row),
          busy: actionBusy.value == row.requestId,
          onApprove: pending ? () => decide(row, _Decision.approve) : null,
          onDeny: pending ? () => decide(row, _Decision.deny) : null,
          onRevoke: !pending && row.isApproved
              ? () => decide(row, _Decision.revoke)
              : null,
        );

    Widget buildSections() {
      return Column(
        key: const ValueKey('approvals-sections'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (pendingRows.isNotEmpty) ...[
            _SectionHeader(title: l.gapReview, count: pendingRows.length),
            SizedBox(height: PanAfricanSpacing.sm.h),
            ...pendingRows.map((r) => card(r, pending: true)),
          ],
          if (decidedRows.isNotEmpty) ...[
            if (pendingRows.isNotEmpty)
              SizedBox(height: PanAfricanSpacing.lg.h),
            _SectionHeader(title: l.gapDecided),
            SizedBox(height: PanAfricanSpacing.sm.h),
            ...decidedRows.map((r) => card(r, pending: false)),
          ],
        ],
      );
    }

    Widget buildContent() {
      switch (uiState.value) {
        case GuardianApprovalsUiState.loading:
          return const _LoadingPanel();
        case GuardianApprovalsUiState.error:
          return _ErrorPanel(
            message: errorMessage.value ?? l.gapLoadError,
            onRetry: load,
          );
        case GuardianApprovalsUiState.empty:
        case GuardianApprovalsUiState.offline:
          return rows.value.isEmpty
              ? _EmptyPanel(
                  title: l.gapEmptyTitle,
                  body: l.gapEmptyBody,
                  action: l.gapRefresh,
                  onAction: load,
                  animate: !reducedMotion,
                )
              : buildSections();
        case GuardianApprovalsUiState.loaded:
          return buildSections();
      }
    }

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(title: Text(l.gapTitle)),
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
                      key: const ValueKey('gap-offline'),
                      color: colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
                      child: ListTile(
                        leading: Icon(
                          Icons.cloud_off_outlined,
                          color: colorScheme.onSecondaryContainer,
                        ),
                        title: Text(
                          l.gapOffline,
                          style: PanAfricanTypography.bodyMedium(
                            context,
                          ).copyWith(color: colorScheme.onSecondaryContainer),
                        ),
                      ),
                    ),
                  ),
                ),
              AnimatedSwitcher(
                duration: reducedMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 220),
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

/// Skeleton cards at the final card height (no spinner-only screen).
class _LoadingPanel extends StatelessWidget {
  const _LoadingPanel();

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    Widget bar(double w, double h) => Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(6),
      ),
    );
    return Semantics(
      key: const ValueKey('gap-loading'),
      label: l.gapLoading,
      liveRegion: true,
      child: ExcludeSemantics(
        child: Column(
          children: List.generate(
            3,
            (_) => Card(
              margin: EdgeInsets.only(bottom: PanAfricanSpacing.md.h),
              child: Padding(
                padding: EdgeInsets.all(PanAfricanSpacing.md.w),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: scheme.surfaceContainerHighest,
                    ),
                    SizedBox(width: PanAfricanSpacing.md.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          bar(160, 16),
                          const SizedBox(height: 10),
                          bar(220, 12),
                          const SizedBox(height: 14),
                          bar(double.infinity, 44),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
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
      label: showBadge ? '$title, $count' : title,
      child: ExcludeSemantics(
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: PanAfricanTypography.titleMedium(
                  context,
                ).copyWith(fontWeight: FontWeight.w700),
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
                  style: PanAfricanTypography.labelMedium(
                    context,
                  ).copyWith(color: colorScheme.onPrimaryContainer),
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
    required this.action,
    required this.onAction,
    required this.animate,
  });

  final String title;
  final String body;
  final String action;
  final Future<void> Function() onAction;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final content = Padding(
      key: const ValueKey('gap-empty'),
      padding: EdgeInsets.symmetric(vertical: PanAfricanSpacing.xl.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.verified_user_outlined,
                size: 48,
                color: colorScheme.primary,
              ),
            ),
          ),
          SizedBox(height: PanAfricanSpacing.lg.h),
          Semantics(
            header: true,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: PanAfricanTypography.titleLarge(context),
            ),
          ),
          SizedBox(height: PanAfricanSpacing.sm.h),
          Text(
            body,
            textAlign: TextAlign.center,
            style: PanAfricanTypography.bodyLarge(
              context,
            ).copyWith(color: colorScheme.onSurfaceVariant, height: 1.45),
          ),
          SizedBox(height: PanAfricanSpacing.lg.h),
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: OutlinedButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.refresh),
                label: Text(action),
              ),
            ),
          ),
        ],
      ),
    );
    if (!animate) return content;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      builder: (_, t, child) => Opacity(opacity: t, child: child),
      child: content,
    );
  }
}

/// Inline banner with Retry.
class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      key: const ValueKey('gap-error'),
      margin: EdgeInsets.symmetric(vertical: PanAfricanSpacing.lg.h),
      padding: EdgeInsets.all(PanAfricanSpacing.md.w),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(PanAfricanRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.error_outline_rounded, color: scheme.onErrorContainer),
              SizedBox(width: PanAfricanSpacing.sm.w),
              Expanded(
                child: Text(
                  message,
                  style: PanAfricanTypography.bodyLarge(
                    context,
                  ).copyWith(color: scheme.onErrorContainer),
                ),
              ),
            ],
          ),
          SizedBox(height: PanAfricanSpacing.md.h),
          Align(
            alignment: AlignmentDirectional.centerEnd,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: FilledButton(onPressed: onRetry, child: Text(l.gapRetry)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ApprovalCard extends StatelessWidget {
  const _ApprovalCard({
    super.key,
    required this.row,
    required this.childName,
    required this.busy,
    this.onApprove,
    this.onDeny,
    this.onRevoke,
  });

  final GuardianGroupJoinRequestRow row;
  final String childName;
  final bool busy;
  final VoidCallback? onApprove;
  final VoidCallback? onDeny;
  final VoidCallback? onRevoke;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final status = switch (row.status) {
      'approved' => l.gapStatusApproved,
      'expired' => l.gapStatusExpired,
      'revoked' => l.gapStatusRevoked,
      'denied' => l.gapStatusDenied,
      'needs_reapproval' => l.gapStatusReapprove,
      _ => l.gapStatusWaiting,
    };
    final moderation = switch (row.moderationStatus) {
      'moderated' => l.gapModerated,
      'approval_required' => l.gapApprovalRequired,
      _ => l.gapOpenCommunity,
    };
    final kind = row.groupKind == 'circle'
        ? l.gapKindCircle
        : l.gapKindClassroom;
    final why = row.groupKind == 'circle'
        ? l.gapWhyCircle(childName, row.groupName)
        : l.gapWhyClass(childName, row.groupName);
    final initial = childName.characters.isEmpty
        ? '?'
        : childName.characters.first.toUpperCase();
    final stack = MediaQuery.textScalerOf(context).scale(10) >= 15;

    Widget action(
      String label,
      IconData icon,
      VoidCallback? onTap, {
      required bool filled,
      Key? key,
    }) {
      final child = busy
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon);
      final b = filled
          ? FilledButton.icon(
              key: key,
              onPressed: busy ? null : onTap,
              icon: child,
              // Scoped for screen readers: "Approve, <group>".
              label: Text(label, semanticsLabel: '$label, ${row.groupName}'),
            )
          : OutlinedButton.icon(
              key: key,
              onPressed: busy ? null : onTap,
              icon: child,
              // Scoped for screen readers: "Approve, <group>".
              label: Text(label, semanticsLabel: '$label, ${row.groupName}'),
            );
      return ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48),
        child: b,
      );
    }

    final actions = <Widget>[
      if (onApprove != null)
        action(
          l.gapApprove,
          Icons.check,
          onApprove,
          filled: true,
          key: ValueKey('gap-approve-${row.requestId}'),
        ),
      if (onDeny != null)
        action(
          l.gapDeny,
          Icons.close,
          onDeny,
          filled: false,
          key: ValueKey('gap-deny-${row.requestId}'),
        ),
      if (onRevoke != null)
        action(
          l.gapRevoke,
          Icons.block,
          onRevoke,
          filled: false,
          key: ValueKey('gap-revoke-${row.requestId}'),
        ),
    ];

    return Card(
      margin: EdgeInsets.only(bottom: PanAfricanSpacing.md.h),
      child: Padding(
        padding: EdgeInsets.all(PanAfricanSpacing.md.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              container: true,
              label: '$why. $status',
              child: ExcludeSemantics(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 22,
                      backgroundColor: scheme.primaryContainer,
                      child: Text(
                        initial,
                        style: PanAfricanTypography.titleMedium(
                          context,
                        ).copyWith(color: scheme.onPrimaryContainer),
                      ),
                    ),
                    SizedBox(width: PanAfricanSpacing.md.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Chip(label: status, emphasized: row.isPending),
                          SizedBox(height: PanAfricanSpacing.xs.h),
                          Text(
                            why,
                            style: PanAfricanTypography.titleMedium(
                              context,
                            ).copyWith(fontWeight: FontWeight.w700),
                          ),
                          SizedBox(height: PanAfricanSpacing.xs.h),
                          Text(
                            '$kind · ${l.gapMembers(row.memberCount)} · '
                            '${l.gapAdults(row.adultMemberCount)}',
                            style: PanAfricanTypography.bodyMedium(context),
                          ),
                          SizedBox(height: PanAfricanSpacing.xs.h),
                          Row(
                            children: [
                              Icon(
                                Icons.shield_outlined,
                                size: 18,
                                color: scheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  moderation,
                                  style: PanAfricanTypography.bodySmall(
                                    context,
                                  ).copyWith(color: scheme.onSurfaceVariant),
                                ),
                              ),
                            ],
                          ),
                          if (row.isPending && row.expiresAt != null) ...[
                            SizedBox(height: PanAfricanSpacing.xs.h),
                            Text(
                              l.gapExpires(
                                MaterialLocalizations.of(
                                  context,
                                ).formatMediumDate(row.expiresAt!.toLocal()),
                              ),
                              style: PanAfricanTypography.bodySmall(
                                context,
                              ).copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (actions.isNotEmpty) ...[
              SizedBox(height: PanAfricanSpacing.md.h),
              if (stack)
                ...actions.expand((a) => [a, const SizedBox(height: 8)])
              else
                Row(
                  children: [
                    for (var i = 0; i < actions.length; i++) ...[
                      if (i > 0) const SizedBox(width: 12),
                      Expanded(child: actions[i]),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: emphasized
            ? scheme.primaryContainer
            : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(PanAfricanRadius.md),
      ),
      child: Text(
        label,
        style: PanAfricanTypography.labelMedium(context).copyWith(
          color: emphasized
              ? scheme.onPrimaryContainer
              : scheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
