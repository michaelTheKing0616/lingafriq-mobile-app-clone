import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/gamification_services_provider.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

class ClassroomRosterScreen extends ConsumerStatefulWidget {
  final String tribeId;
  final String tribeName;

  const ClassroomRosterScreen({
    super.key,
    required this.tribeId,
    required this.tribeName,
  });

  @override
  ConsumerState<ClassroomRosterScreen> createState() => _ClassroomRosterScreenState();
}

class _ClassroomRosterScreenState extends ConsumerState<ClassroomRosterScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _data;
  bool _shareEmails = true;

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
      final res = await ref.read(classroomServiceProvider).getRosterV2(widget.tribeId);
      if (!mounted) return;
      final classroom = Map<String, dynamic>.from(res['classroom'] ?? const {});
      final privacy = Map<String, dynamic>.from(classroom['privacy'] ?? const {});
      setState(() {
        _data = res;
        _shareEmails = privacy['share_roster_emails'] == true;
        _loading = false;
      });
    } catch (e) {
      if (mounted) ErrorHandler.showError(context, e);
      setState(() {
        _error = 'Unable to load roster right now.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final roster = List<Map<String, dynamic>>.from(_data?['roster'] ?? const []);
    final classroom = Map<String, dynamic>.from(_data?['classroom'] ?? const {});
    final classroomCode = classroom['classroom_code']?.toString();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Roster: ${widget.tribeName}',
          style: PanAfricanTypography.titleLarge(context),
        ),
        actions: [
          if (classroomCode != null && classroomCode.isNotEmpty)
            IconButton(
              tooltip: 'Copy class code',
              icon: const Icon(Icons.copy_rounded),
              onPressed: () {
                HapticFeedback.lightImpact();
                Clipboard.setData(ClipboardData(text: classroomCode));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Class code copied', style: PanAfricanTypography.bodyMedium(context)),
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
                        Text(_error!, style: PanAfricanTypography.bodyLarge(context)),
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
                    separatorBuilder: (_, __) => SizedBox(height: PanAfricanSpacing.sm),
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return _HeaderCard(
                          isDark: isDark,
                          classroomCode: classroomCode,
                          count: roster.length,
                        );
                      }
                      final m = roster[index - 1];
      return _RosterCard(isDark: isDark, member: m, showEmail: _shareEmails);
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
        border: Border.all(color: isDark ? PanAfricanColors.borderDark : PanAfricanColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Learners: $count', style: PanAfricanTypography.titleMedium(context)),
          if (classroomCode != null && classroomCode!.isNotEmpty) ...[
            SizedBox(height: PanAfricanSpacing.xs),
            Text('Join code: $classroomCode', style: PanAfricanTypography.bodySmall(context)),
          ],
        ],
      ),
    );
  }
}

class _RosterCard extends StatelessWidget {
  const _RosterCard({required this.isDark, required this.member, required this.showEmail});

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
        border: Border.all(color: isDark ? PanAfricanColors.borderDark : PanAfricanColors.borderLight),
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
                  Text('@$globalId', style: PanAfricanTypography.labelSmall(context)),
                if (showEmail && email != null && email.isNotEmpty)
                  Text(email, style: PanAfricanTypography.labelSmall(context)),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.sm, vertical: PanAfricanSpacing.xxxs),
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

