import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = approvalService ?? GuardianApprovalService();
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
        final pending = fetched.where((r) => r.isPending).toList();
        uiState.value = pending.isEmpty && fetched.isEmpty
            ? GuardianApprovalsUiState.empty
            : GuardianApprovalsUiState.loaded;
      } on GuardianOfflineException {
        isOffline.value = true;
        uiState.value = rows.value.isEmpty
            ? GuardianApprovalsUiState.offline
            : GuardianApprovalsUiState.loaded;
      } on GuardianApiException catch (e) {
        errorMessage.value = e.message ?? 'We could not load approvals. Try again.';
        uiState.value = GuardianApprovalsUiState.error;
      } catch (_) {
        errorMessage.value = 'We could not load approvals. Try again.';
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
        if (!ok && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('We could not approve that request. Try again.')),
          );
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
        if (!ok && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('We could not revoke that approval. Try again.')),
          );
        }
        await load();
      } finally {
        actionBusy.value = null;
      }
    }

    return Scaffold(
      backgroundColor: isDark ? PanAfricanColors.surfaceDark : PanAfricanColors.surfaceLight,
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
              if (uiState.value == GuardianApprovalsUiState.loading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (uiState.value == GuardianApprovalsUiState.error)
                _ErrorPanel(
                  message: errorMessage.value ?? 'Something went wrong.',
                  onRetry: load,
                )
              else if (uiState.value == GuardianApprovalsUiState.empty ||
                  uiState.value == GuardianApprovalsUiState.offline && rows.value.isEmpty)
                _EmptyPanel(
                  title: guardianApprovalsEmptyTitle,
                  body: guardianApprovalsEmptyBody,
                  animate: !reducedMotion,
                )
              else ...[
                Text(
                  'Review before they join',
                  style: PanAfricanTypography.titleMedium(context).copyWith(fontWeight: FontWeight.w700),
                ),
                SizedBox(height: PanAfricanSpacing.sm.h),
                ...rows.value.map(
                  (row) => _ApprovalCard(
                    row: row,
                    busy: actionBusy.value == row.requestId,
                    onApprove: row.isPending ? () => onApprove(row) : null,
                    onRevoke: row.isApproved ? () => onRevoke(row) : null,
                    colorScheme: colorScheme,
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

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({
    required this.title,
    required this.body,
    required this.animate,
  });

  final String title;
  final String body;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.groups_outlined, size: 48, color: Theme.of(context).colorScheme.primary),
        SizedBox(height: PanAfricanSpacing.md.h),
        Text(title, style: PanAfricanTypography.titleLarge(context)),
        SizedBox(height: PanAfricanSpacing.sm.h),
        Text(body, style: PanAfricanTypography.bodyLarge(context)),
      ],
    );
    if (!animate) return content;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.92, end: 1),
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
      builder: (_, scale, child) => Transform.scale(scale: scale, child: child),
      child: content,
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(message, style: PanAfricanTypography.bodyLarge(context)),
        SizedBox(height: PanAfricanSpacing.md.h),
        SizedBox(
          height: 48.h,
          child: FilledButton(onPressed: onRetry, child: const Text('Try again')),
        ),
      ],
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

    return Semantics(
      label: semanticsLabel,
      button: onApprove != null || onRevoke != null,
      child: Card(
        margin: EdgeInsets.only(bottom: PanAfricanSpacing.md.h),
        child: Padding(
          padding: EdgeInsets.all(PanAfricanSpacing.md.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                row.groupName,
                style: PanAfricanTypography.titleMedium(context).copyWith(fontWeight: FontWeight.w700),
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
              if (onApprove != null || onRevoke != null) ...[
                SizedBox(height: PanAfricanSpacing.md.h),
                Row(
                  children: [
                    if (onApprove != null)
                      Expanded(
                        child: SizedBox(
                          height: 48.h,
                          child: FilledButton(
                            onPressed: busy ? null : onApprove,
                            child: busy
                                ? SizedBox(
                                    width: 22.w,
                                    height: 22.w,
                                    child: const CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text('Approve join'),
                          ),
                        ),
                      ),
                    if (onRevoke != null) ...[
                      SizedBox(width: PanAfricanSpacing.sm.w),
                      Expanded(
                        child: SizedBox(
                          height: 48.h,
                          child: OutlinedButton(
                            onPressed: busy ? null : onRevoke,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colorScheme.error,
                              side: BorderSide(color: colorScheme.error),
                            ),
                            child: const Text('Revoke access'),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
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
