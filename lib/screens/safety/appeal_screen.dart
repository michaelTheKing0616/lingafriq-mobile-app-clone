import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/responsive_safe_area.dart';

/// Copy keys: appeal.title, appeal.submitted, appeal.decided (P9-932).
/// Reference: Meta Account Status appeal + Instagram moderation appeal sheet.
abstract final class AppealCopy {
  static const title = 'Appeal a moderation decision';
  static const reasonLabel = 'Tell us what we missed';
  static const reasonHint =
      'Share anything that helps a different moderator review within 72 hours.';
  static const submit = 'Send appeal';
  static const submittedTitle = 'Appeal received';
  static const submittedBody =
      'A different moderator will review your case within 72 hours. We will notify you here when there is an update.';
  static const decidedUpheld = 'We reviewed your appeal and the original decision stands.';
  static const decidedOverturned =
      'We reviewed your appeal and updated your account status.';
  static const decidedDismissed = 'We reviewed your appeal and closed the case.';
  static const emptyTitle = 'No decisions to appeal';
  static const emptyBody =
      'If we take action on your account, you will see the reason here and can ask for a second look.';
  static const offlineBanner = 'You are offline. Connect to send an appeal.';
  static const errorGeneric = 'We could not load your appeal status. Try again in a moment.';
  static const appealButton = 'Appeal this decision';
}

class AppealModerationNotice {
  AppealModerationNotice({
    required this.actionId,
    required this.action,
    required this.reason,
    required this.decidedAt,
    required this.appealOpen,
    this.pendingAppealId,
    this.reviewDueAt,
  });

  final String actionId;
  final String action;
  final String reason;
  final DateTime decidedAt;
  final bool appealOpen;
  final String? pendingAppealId;
  final DateTime? reviewDueAt;

  factory AppealModerationNotice.fromJson(Map<String, dynamic> json) {
    DateTime? parse(String? raw) {
      if (raw == null || raw.isEmpty) return null;
      return DateTime.tryParse(raw);
    }

    return AppealModerationNotice(
      actionId: json['action_id']?.toString() ?? '',
      action: json['action']?.toString() ?? 'warn',
      reason: json['reason']?.toString() ?? '',
      decidedAt: parse(json['decided_at']?.toString()) ?? DateTime.now(),
      appealOpen: json['appeal_open'] == true,
      pendingAppealId: json['pending_appeal_id']?.toString(),
      reviewDueAt: parse(json['review_due_at']?.toString()),
    );
  }
}

typedef AppealGet = Future<Map<String, dynamic>> Function(String path);
typedef AppealPost = Future<Map<String, dynamic>> Function(
  String path, {
  Map<String, Object?>? data,
});

class AppealService {
  AppealService({
    AppealGet? get,
    AppealPost? post,
    Future<bool> Function()? isOnline,
  })  : _get = get ?? _defaultGet,
        _post = post ?? _defaultPost,
        _isOnline = isOnline ?? (() async => true);

  final AppealGet _get;
  final AppealPost _post;
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

  Future<List<AppealModerationNotice>> fetchNotices() async {
    if (!await _isOnline()) {
      throw const AppealOfflineException();
    }
    final json = await _get('/api/safety/appeals/notices');
    if (json['ok'] != true) {
      throw AppealLoadException(json['code']?.toString() ?? 'LOAD_FAILED');
    }
    final raw = json['notices'];
    if (raw is! List) return const [];
    final list = <AppealModerationNotice>[];
    for (final entry in raw) {
      if (entry is Map) {
        list.add(AppealModerationNotice.fromJson(Map<String, dynamic>.from(entry)));
      }
    }
    return list;
  }

  Future<String> submitAppeal({
    required String actionId,
    required String reason,
  }) async {
    if (!await _isOnline()) {
      throw const AppealOfflineException();
    }
    final json = await _post(
      '/api/safety/appeals',
      data: {'action_id': actionId, 'reason': reason.trim()},
    );
    if (json['ok'] != true) {
      throw AppealSubmitException(json['code']?.toString() ?? 'APPEAL_FAILED');
    }
    return json['appeal_id']?.toString() ?? '';
  }

  Future<Map<String, dynamic>> fetchAppealStatus(String appealId) async {
    if (!await _isOnline()) {
      throw const AppealOfflineException();
    }
    final json = await _get('/api/safety/appeals/$appealId');
    if (json['ok'] != true) {
      throw AppealLoadException(json['code']?.toString() ?? 'LOAD_FAILED');
    }
    return json;
  }
}

class AppealOfflineException implements Exception {
  const AppealOfflineException();
}

class AppealLoadException implements Exception {
  AppealLoadException(this.code);
  final String code;
}

class AppealSubmitException implements Exception {
  AppealSubmitException(this.code);
  final String code;
}

enum AppealUiPhase { loading, ready, submitted, decided, empty, error, offline }

class AppealScreen extends StatefulWidget {
  const AppealScreen({
    super.key,
    this.initialActionId,
    this.appealService,
  });

  final String? initialActionId;
  final AppealService? appealService;

  @override
  State<AppealScreen> createState() => _AppealScreenState();
}

class _AppealScreenState extends State<AppealScreen> {
  AppealUiPhase _phase = AppealUiPhase.loading;
  List<AppealModerationNotice> _notices = const [];
  String? _selectedActionId;
  String? _errorCode;
  String? _decidedOutcome;
  final _reasonController = TextEditingController();

  AppealService get _service => widget.appealService ?? AppealService();

  @override
  void initState() {
    super.initState();
    _loadNotices();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _loadNotices() async {
    setState(() {
      _phase = AppealUiPhase.loading;
      _errorCode = null;
    });
    try {
      final rows = await _service.fetchNotices();
      if (!mounted) return;
      if (rows.isEmpty) {
        setState(() {
          _notices = rows;
          _phase = AppealUiPhase.empty;
        });
        return;
      }
      final initial = widget.initialActionId ??
          rows.firstWhere((row) => row.appealOpen, orElse: () => rows.first).actionId;
      final selected = rows.firstWhere((row) => row.actionId == initial);
      if (!selected.appealOpen && selected.pendingAppealId != null) {
        final status = await _service.fetchAppealStatus(selected.pendingAppealId!);
        if (!mounted) return;
        final outcome = status['outcome']?.toString() ?? 'pending';
        setState(() {
          _notices = rows;
          _selectedActionId = initial;
          _decidedOutcome = outcome != 'pending' ? outcome : null;
          _phase = outcome != 'pending' ? AppealUiPhase.decided : AppealUiPhase.submitted;
        });
        return;
      }
      setState(() {
        _notices = rows;
        _selectedActionId = initial;
        _phase = AppealUiPhase.ready;
      });
    } on AppealOfflineException {
      if (!mounted) return;
      setState(() => _phase = AppealUiPhase.offline);
    } on AppealLoadException catch (err) {
      if (!mounted) return;
      setState(() {
        _errorCode = err.code;
        _phase = AppealUiPhase.error;
      });
    }
  }

  Future<void> _submit() async {
    final actionId = _selectedActionId;
    if (actionId == null || _reasonController.text.trim().length < 8) {
      HapticFeedback.lightImpact();
      return;
    }
    try {
      await _service.submitAppeal(
        actionId: actionId,
        reason: _reasonController.text,
      );
      if (!mounted) return;
      setState(() => _phase = AppealUiPhase.submitted);
      HapticFeedback.mediumImpact();
    } on AppealOfflineException {
      if (!mounted) return;
      setState(() => _phase = AppealUiPhase.offline);
    } on AppealSubmitException catch (err) {
      if (!mounted) return;
      setState(() {
        _errorCode = err.code;
        _phase = AppealUiPhase.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reducedMotion = MediaQuery.disableAnimationsOf(context);

    return ResponsiveSafeArea(
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          title: Text(AppealCopy.title, style: theme.textTheme.titleLarge),
          centerTitle: false,
        ),
        body: AnimatedSwitcher(
          duration: reducedMotion ? Duration.zero : const Duration(milliseconds: 220),
          child: _bodyForPhase(context),
        ),
      ),
    );
  }

  Widget _bodyForPhase(BuildContext context) {
    switch (_phase) {
      case AppealUiPhase.loading:
        return const Center(key: ValueKey('loading'), child: CircularProgressIndicator());
      case AppealUiPhase.offline:
        return _MessagePanel(
          key: const ValueKey('offline'),
          title: AppealCopy.offlineBanner,
          body: AppealCopy.emptyBody,
          actionLabel: 'Try again',
          onAction: _loadNotices,
          isError: true,
        );
      case AppealUiPhase.error:
        return _MessagePanel(
          key: ValueKey('error-$_errorCode'),
          title: AppealCopy.errorGeneric,
          body: _errorCode ?? '',
          actionLabel: 'Try again',
          onAction: _loadNotices,
          isError: true,
        );
      case AppealUiPhase.empty:
        return _MessagePanel(
          key: const ValueKey('empty'),
          title: AppealCopy.emptyTitle,
          body: AppealCopy.emptyBody,
          actionLabel: 'Refresh',
          onAction: _loadNotices,
        );
      case AppealUiPhase.submitted:
        return _MessagePanel(
          key: const ValueKey('submitted'),
          title: AppealCopy.submittedTitle,
          body: AppealCopy.submittedBody,
          actionLabel: 'Done',
          onAction: () => Navigator.maybePop(context),
        );
      case AppealUiPhase.decided:
        final body = switch (_decidedOutcome) {
          'overturned' => AppealCopy.decidedOverturned,
          'dismissed' => AppealCopy.decidedDismissed,
          _ => AppealCopy.decidedUpheld,
        };
        return _MessagePanel(
          key: ValueKey('decided-$_decidedOutcome'),
          title: AppealCopy.title,
          body: body,
          actionLabel: 'Close',
          onAction: () => Navigator.maybePop(context),
        );
      case AppealUiPhase.ready:
        final selected = _notices.firstWhere(
          (row) => row.actionId == _selectedActionId,
          orElse: () => _notices.first,
        );
        return SingleChildScrollView(
          key: const ValueKey('ready'),
          padding: EdgeInsets.all(PanAfricanSpacing.lg.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Decision', style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: PanAfricanSpacing.sm.h),
              Card(
                child: Padding(
                  padding: EdgeInsets.all(PanAfricanSpacing.md.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selected.action.toUpperCase(),
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: Theme.of(context).colorScheme.error,
                            ),
                      ),
                      SizedBox(height: PanAfricanSpacing.xs.h),
                      Text(selected.reason, style: Theme.of(context).textTheme.bodyLarge),
                    ],
                  ),
                ),
              ),
              SizedBox(height: PanAfricanSpacing.lg.h),
              Text(AppealCopy.reasonLabel, style: Theme.of(context).textTheme.titleSmall),
              SizedBox(height: PanAfricanSpacing.sm.h),
              Semantics(
                label: AppealCopy.reasonLabel,
                child: TextField(
                  controller: _reasonController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: InputDecoration(
                    hintText: AppealCopy.reasonHint,
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              SizedBox(height: PanAfricanSpacing.lg.h),
              SizedBox(
                width: double.infinity,
                height: 48.h,
                child: FilledButton(
                  key: const Key('appeal_submit'),
                  onPressed: selected.appealOpen ? _submit : null,
                  child: Text(selected.appealOpen ? AppealCopy.submit : AppealCopy.submittedTitle),
                ),
              ),
            ],
          ),
        );
    }
  }
}

class _MessagePanel extends StatelessWidget {
  const _MessagePanel({
    super.key,
    required this.title,
    required this.body,
    required this.actionLabel,
    required this.onAction,
    this.isError = false,
  });

  final String title;
  final String body;
  final String actionLabel;
  final VoidCallback onAction;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(PanAfricanSpacing.lg.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError ? Icons.cloud_off_outlined : Icons.fact_check_outlined,
            size: 40,
            color: isError
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.primary,
          ),
          SizedBox(height: PanAfricanSpacing.md.h),
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          SizedBox(height: PanAfricanSpacing.sm.h),
          Text(body, style: Theme.of(context).textTheme.bodyLarge),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            height: 48.h,
            child: FilledButton(onPressed: onAction, child: Text(actionLabel)),
          ),
        ],
      ),
    );
  }
}
