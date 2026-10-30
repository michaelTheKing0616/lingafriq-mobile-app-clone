import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/screens/classroom/classroom_student_requests_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/gamification_services_provider.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/utils/roster_import_feedback.dart';

class ClassroomRosterScreen extends ConsumerStatefulWidget {
  final String tribeId;
  final String tribeName;

  const ClassroomRosterScreen({
    super.key,
    required this.tribeId,
    required this.tribeName,
  });

  @override
  ConsumerState<ClassroomRosterScreen> createState() =>
      _ClassroomRosterScreenState();
}

class _ClassroomRosterScreenState extends ConsumerState<ClassroomRosterScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _data;
  bool _shareEmails = true;
  bool _importing = false;
  List<Map<String, dynamic>> _importErrors = const [];
  String? _importSummary;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ref
          .read(classroomServiceProvider)
          .getRosterV2(widget.tribeId);
      if (!mounted) return;
      final classroom = Map<String, dynamic>.from(res['classroom'] ?? const {});
      final privacy = Map<String, dynamic>.from(
        classroom['privacy'] ?? const {},
      );
      setState(() {
        _data = res;
        _shareEmails = privacy['share_roster_emails'] == true;
        _loading = false;
      });
    } catch (e) {
      if (mounted) ErrorHandler.showError(context, e);
      setState(() {
        _error =
            'We couldn\'t load your class list. Pull to refresh or try again.';
        _loading = false;
      });
    }
  }

  Future<void> _importCsv() async {
    setState(() {
      _importErrors = const [];
      _importSummary = null;
    });
    final pick = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['csv'],
      withData: true,
    );
    if (pick == null || pick.files.isEmpty) return;
    final bytes = pick.files.single.bytes;
    if (bytes == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Could not read that file.',
              style: PanAfricanTypography.bodyMedium(context),
            ),
          ),
        );
      }
      return;
    }
    setState(() => _importing = true);
    try {
      final csv = String.fromCharCodes(bytes);
      final result = await ref
          .read(classroomServiceProvider)
          .importRosterCsvV2(widget.tribeId, csv);
      if (!mounted) return;
      final feedback = summarizeRosterImportResult(result);
      setState(() {
        _importErrors = List<Map<String, dynamic>>.from(
          feedback['errors'] as List,
        );
        _importSummary = feedback['summary'] as String;
        _importing = false;
      });
      await _load();
    } catch (e) {
      if (mounted) ErrorHandler.showError(context, e);
      setState(() => _importing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final roster = List<Map<String, dynamic>>.from(
      _data?['roster'] ?? const [],
    );
    final classroom = Map<String, dynamic>.from(
      _data?['classroom'] ?? const {},
    );
    final classroomCode = classroom['classroom_code']?.toString();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Roster: ${widget.tribeName}',
          style: PanAfricanTypography.titleLarge(context),
        ),
        actions: [
          IconButton(
            key: const ValueKey('roster-student-requests'),
            tooltip: AppLocalizations.of(context)!.gtpOpen,
            icon: const Icon(Icons.how_to_reg_outlined),
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => ClassroomStudentRequestsScreen(
                  tribeId: widget.tribeId,
                  tribeName: widget.tribeName,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Import roster CSV',
            icon: _importing
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  )
                : const Icon(Icons.upload_file_rounded),
            onPressed: _importing ? null : _importCsv,
          ),
          if (classroomCode != null && classroomCode.isNotEmpty)
            IconButton(
              tooltip: 'Copy class code',
              icon: const Icon(Icons.copy_rounded),
              onPressed: () {
                HapticFeedback.lightImpact();
                Clipboard.setData(ClipboardData(text: classroomCode));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Class code copied',
                      style: PanAfricanTypography.bodyMedium(context),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Padding(
                padding: EdgeInsets.all(PanAfricanSpacing.lg),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _error!,
                      style: PanAfricanTypography.bodyLarge(context),
                    ),
                    SizedBox(height: PanAfricanSpacing.md),
                    FilledButton(onPressed: _load, child: const Text('Retry')),
                  ],
                ),
              ),
            )
          : RefreshIndicator(
              color: PanAfricanColors.primary,
              onRefresh: _load,
              child: ListView.separated(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.all(PanAfricanSpacing.md),
                itemCount: roster.length + 1,
                separatorBuilder: (_, __) =>
                    SizedBox(height: PanAfricanSpacing.sm),
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _HeaderCard(
                          isDark: isDark,
                          classroomCode: classroomCode,
                          count: roster.length,
                        ),
                        if (_importSummary != null) ...[
                          SizedBox(height: PanAfricanSpacing.sm),
                          _ImportBanner(
                            message: _importSummary!,
                            isDark: isDark,
                          ),
                        ],
                        if (_importErrors.isNotEmpty) ...[
                          SizedBox(height: PanAfricanSpacing.sm),
                          _ImportErrorsList(
                            errors: _importErrors,
                            isDark: isDark,
                          ),
                        ],
                      ],
                    );
                  }
                  final m = roster[index - 1];
                  return _RosterCard(
                    isDark: isDark,
                    member: m,
                    showEmail: _shareEmails,
                  );
                },
              ),
            ),
    );
  }
}

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.isDark,
    required this.classroomCode,
    required this.count,
  });

  final bool isDark;
  final String? classroomCode;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(PanAfricanSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
        borderRadius: PanAfricanRadius.lgBR,
        border: Border.all(
          color: isDark
              ? PanAfricanColors.borderDark
              : PanAfricanColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Learners: $count',
            style: PanAfricanTypography.titleMedium(context),
          ),
          if (classroomCode != null && classroomCode!.isNotEmpty) ...[
            SizedBox(height: PanAfricanSpacing.xs),
            Text(
              'Join code: $classroomCode',
              style: PanAfricanTypography.bodySmall(context),
            ),
          ],
        ],
      ),
    );
  }
}

class _ImportBanner extends StatelessWidget {
  const _ImportBanner({required this.message, required this.isDark});

  final String message;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: EdgeInsets.all(PanAfricanSpacing.md),
        decoration: BoxDecoration(
          color: PanAfricanColors.primaryContainer.withValues(alpha: 0.35),
          borderRadius: PanAfricanRadius.lgBR,
        ),
        child: Text(message, style: PanAfricanTypography.bodyMedium(context)),
      ),
    );
  }
}

class _ImportErrorsList extends StatelessWidget {
  const _ImportErrorsList({required this.errors, required this.isDark});

  final List<Map<String, dynamic>> errors;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(PanAfricanSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(
          context,
        ).colorScheme.errorContainer.withValues(alpha: 0.25),
        borderRadius: PanAfricanRadius.lgBR,
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withValues(alpha: 0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fix these rows in your spreadsheet',
            style: PanAfricanTypography.titleSmall(context),
          ),
          SizedBox(height: PanAfricanSpacing.xs),
          ...errors
              .take(8)
              .map(
                (e) => Padding(
                  padding: EdgeInsets.only(bottom: PanAfricanSpacing.xxxs),
                  child: Text(
                    'Line ${e['lineNumber']}: ${e['reason']}',
                    style: PanAfricanTypography.bodySmall(context),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _RosterCard extends StatelessWidget {
  const _RosterCard({
    required this.isDark,
    required this.member,
    required this.showEmail,
  });

  final bool isDark;
  final Map<String, dynamic> member;
  final bool showEmail;

  @override
  Widget build(BuildContext context) {
    final username = member['username']?.toString() ?? 'Learner';
    final globalId = member['globalId']?.toString();
    final role = member['role']?.toString() ?? 'member';
    final email = member['email']?.toString();

    return Container(
      padding: EdgeInsets.all(PanAfricanSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
        borderRadius: PanAfricanRadius.lgBR,
        border: Border.all(
          color: isDark
              ? PanAfricanColors.borderDark
              : PanAfricanColors.borderLight,
        ),
        boxShadow: PanAfricanShadows.sm,
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: PanAfricanColors.primary,
            child: Text(
              username.isNotEmpty ? username[0].toUpperCase() : '?',
              style: PanAfricanTypography.titleMedium(
                context,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
          SizedBox(width: PanAfricanSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(username, style: PanAfricanTypography.titleSmall(context)),
                if (globalId != null && globalId.isNotEmpty)
                  Text(
                    '@$globalId',
                    style: PanAfricanTypography.labelSmall(context),
                  ),
                if (showEmail && email != null && email.isNotEmpty)
                  Text(email, style: PanAfricanTypography.labelSmall(context)),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: PanAfricanSpacing.sm,
              vertical: PanAfricanSpacing.xxxs,
            ),
            decoration: BoxDecoration(
              color: PanAfricanColors.primaryContainer,
              borderRadius: PanAfricanRadius.roundBR,
            ),
            child: Text(
              role,
              style: PanAfricanTypography.labelSmall(
                context,
                color: PanAfricanColors.onPrimaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
