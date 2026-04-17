import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/gamification_services_provider.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

class ClassroomPrivacyScreen extends ConsumerStatefulWidget {
  final String tribeId;
  final String tribeName;
  const ClassroomPrivacyScreen({super.key, required this.tribeId, required this.tribeName});

  @override
  ConsumerState<ClassroomPrivacyScreen> createState() => _ClassroomPrivacyScreenState();
}

class _ClassroomPrivacyScreenState extends ConsumerState<ClassroomPrivacyScreen> {
  bool _loading = true;
  String? _error;
  bool _shareNames = true;
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
      final res = await ref.read(classroomServiceProvider).getPrivacyV2(widget.tribeId);
      final privacy = Map<String, dynamic>.from(res['privacy'] ?? const {});
      setState(() {
        _shareNames = privacy['share_roster_names'] != false;
        _shareEmails = privacy['share_roster_emails'] == true;
        _loading = false;
      });
    } catch (e) {
      if (mounted) ErrorHandler.showError(context, e);
      setState(() {
        _error = 'Unable to load privacy settings right now.';
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    HapticFeedback.mediumImpact();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref.read(classroomServiceProvider).updatePrivacyV2(
            widget.tribeId,
            shareRosterNames: _shareNames,
            shareRosterEmails: _shareEmails,
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Privacy settings saved', style: PanAfricanTypography.bodyMedium(context))),
      );
      setState(() => _loading = false);
    } catch (e) {
      if (mounted) ErrorHandler.showError(context, e);
      setState(() {
        _error = 'Failed to save privacy settings.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text('Privacy: ${widget.tribeName}', style: PanAfricanTypography.titleLarge(context)),
        actions: [
          IconButton(
            tooltip: 'Save',
            icon: const Icon(Icons.save_rounded),
            onPressed: _loading ? null : _save,
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
              : ListView(
                  padding: EdgeInsets.all(PanAfricanSpacing.md),
                  children: [
                    Container(
                      padding: EdgeInsets.all(PanAfricanSpacing.lg),
                      decoration: BoxDecoration(
                        color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
                        borderRadius: PanAfricanRadius.lgBR,
                        border: Border.all(color: isDark ? PanAfricanColors.borderDark : PanAfricanColors.borderLight),
                      ),
                      child: Text(
                        'Control what teacher tools display in roster views. '
                        'These settings help minimize unnecessary exposure of learner data.',
                        style: PanAfricanTypography.bodyMedium(context),
                      ),
                    ),
                    SizedBox(height: PanAfricanSpacing.md),
                    SwitchListTile.adaptive(
                      value: _shareNames,
                      onChanged: (v) {
                        HapticFeedback.selectionClick();
                        setState(() => _shareNames = v);
                      },
                      title: const Text('Show learner names/usernames'),
                      subtitle: const Text('If off, roster will show anonymized entries.'),
                    ),
                    SwitchListTile.adaptive(
                      value: _shareEmails,
                      onChanged: (v) {
                        HapticFeedback.selectionClick();
                        setState(() => _shareEmails = v);
                      },
                      title: const Text('Show learner emails'),
                      subtitle: const Text('Recommended off unless needed for communication.'),
                    ),
                  ],
                ),
    );
  }
}

