import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/widgets/responsive_safe_area.dart';

const String dataSubjectExportApiPath = '/api/v2/data-subject/export';
const String dataSubjectDeletionApiPath = '/api/v2/data-subject/deletion';

/// P10-925 — export archive + account deletion (Apple Settings / Google Takeout pattern).
class DataExportScreen extends HookConsumerWidget {
  const DataExportScreen({super.key, this.loadStatusOnMount = true});

  final bool loadStatusOnMount;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    final exportStatus = useState<String>('idle');
    final exportError = useState<String?>(null);
    final exportLoading = useState(false);
    final deletionStatus = useState<String>('idle');
    final deletionError = useState<String?>(null);
    final deletionLoading = useState(false);
    final passwordController = useTextEditingController();

    Future<void> refreshExportStatus() async {
      try {
        final res = await ApiService.get('$dataSubjectExportApiPath/status');
        final data = res.data;
        if (data is Map) {
          exportStatus.value = (data['status'] as String?) ?? 'idle';
          exportError.value = data['error_code'] as String?;
        }
      } catch (_) {
        exportStatus.value = 'failed';
        exportError.value = 'offline';
      }
    }

    Future<void> refreshDeletionStatus() async {
      try {
        final res = await ApiService.get('$dataSubjectDeletionApiPath/status');
        final data = res.data;
        if (data is Map) {
          deletionStatus.value = (data['status'] as String?) ?? 'idle';
          deletionError.value = data['last_error'] as String?;
        }
      } catch (_) {
        // keep last known
      }
    }

    useEffect(() {
      if (!loadStatusOnMount) return null;
      refreshExportStatus();
      refreshDeletionStatus();
      return null;
    }, [loadStatusOnMount]);

    Future<void> requestExport() async {
      HapticFeedback.mediumImpact();
      exportLoading.value = true;
      exportError.value = null;
      try {
        await ApiService.post('$dataSubjectExportApiPath/request');
        exportStatus.value = 'requested';
        await refreshExportStatus();
      } catch (_) {
        exportStatus.value = 'failed';
        exportError.value = 'request_failed';
      } finally {
        exportLoading.value = false;
      }
    }

    String exportStatusLabel() {
      switch (exportStatus.value) {
        case 'ready':
          return 'Your download is ready';
        case 'processing':
        case 'requested':
          return 'We are preparing your file (up to 7 days)';
        case 'failed':
          return 'Something went wrong — try again';
        default:
          return 'Request a copy of your learning data';
      }
    }

    Future<void> confirmDeletion() async {
      final password = passwordController.text;
      if (password.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enter your password to confirm deletion.')),
        );
        return;
      }
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete your account?'),
          content: const Text(
            'This permanently removes your profile, progress, and personal data from LingAfriq. '
            'You cannot undo this.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Keep account'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete forever'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;

      deletionLoading.value = true;
      deletionError.value = null;
      try {
        await ApiService.post(
          '$dataSubjectDeletionApiPath/request',
          data: {'current_password': password},
        );
        deletionStatus.value = 'pending';
        await refreshDeletionStatus();
        if (deletionStatus.value == 'completed' && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Your account has been deleted.')),
          );
        }
      } catch (_) {
        deletionStatus.value = 'failed';
        deletionError.value = 'deletion_failed';
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'We could not start deletion. Check your password and connection.',
              ),
            ),
          );
        }
      } finally {
        deletionLoading.value = false;
      }
    }

    return Scaffold(
      appBar: AppBar(
        leading: Semantics(
          label: 'Back',
          button: true,
          child: IconButton(
            icon: Icon(Icons.arrow_back_rounded, color: colorScheme.onPrimary),
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
          ),
        ),
        title: Text(
          'Your data',
          style: PanAfricanTypography.titleLarge(context)
              .copyWith(color: colorScheme.onPrimary),
        ),
        backgroundColor: PanAfricanColors.primary,
      ),
      body: ResponsiveSafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(PanAfricanSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Export my data',
                style: PanAfricanTypography.titleMedium(context),
              ),
              SizedBox(height: PanAfricanSpacing.sm),
              Text(
                exportStatusLabel(),
                style: PanAfricanTypography.bodyMedium(context),
              ),
              if (exportError.value != null) ...[
                SizedBox(height: PanAfricanSpacing.xs),
                Text(
                  'We will retry automatically. Status: ${exportError.value}',
                  style: PanAfricanTypography.bodySmall(context),
                ),
              ],
              SizedBox(height: PanAfricanSpacing.md),
              Semantics(
                label: 'Export my data',
                button: true,
                child: FilledButton(
                  onPressed: exportLoading.value ? null : requestExport,
                  style: FilledButton.styleFrom(
                    minimumSize: Size.fromHeight(48.h),
                  ),
                  child: exportLoading.value
                      ? SizedBox(
                          height: 22.h,
                          width: 22.h,
                          child: const CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Export my data'),
                ),
              ),
              if (exportStatus.value == 'ready') ...[
                SizedBox(height: PanAfricanSpacing.sm),
                Semantics(
                  label: 'Download data archive',
                  button: true,
                  child: OutlinedButton(
                    onPressed: () async {
                      try {
                        await ApiService.get('$dataSubjectExportApiPath/download');
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Download started. Check your browser or files app.',
                              ),
                            ),
                          );
                        }
                      } catch (_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Download is not ready yet.'),
                            ),
                          );
                        }
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: Size.fromHeight(48.h),
                    ),
                    child: const Text('Download archive'),
                  ),
                ),
              ],
              SizedBox(height: PanAfricanSpacing.xl),
              Divider(color: isDark ? PanAfricanColors.borderDark : PanAfricanColors.borderLight),
              SizedBox(height: PanAfricanSpacing.lg),
              Text(
                'Delete account',
                style: PanAfricanTypography.titleMedium(context),
              ),
              SizedBox(height: PanAfricanSpacing.sm),
              Text(
                deletionStatus.value == 'pending' || deletionStatus.value == 'processing'
                    ? 'Deletion is in progress. We will email you when it finishes.'
                    : 'Remove your LingAfriq account and personal data. Re-enter your password to confirm.',
                style: PanAfricanTypography.bodyMedium(context),
              ),
              SizedBox(height: PanAfricanSpacing.md),
              Semantics(
                label: 'Current password for account deletion',
                textField: true,
                child: TextField(
                  controller: passwordController,
                  obscureText: true,
                  autofillHints: const [AutofillHints.password],
                  decoration: InputDecoration(
                    labelText: 'Current password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                    ),
                  ),
                ),
              ),
              SizedBox(height: PanAfricanSpacing.md),
              Semantics(
                label: 'Delete account',
                button: true,
                child: TextButton(
                  onPressed: deletionLoading.value ? null : confirmDeletion,
                  style: TextButton.styleFrom(
                    foregroundColor: colorScheme.error,
                    minimumSize: Size.fromHeight(48.h),
                  ),
                  child: deletionLoading.value
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Delete account'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
