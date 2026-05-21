import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/services/content/native_review_checklist_service.dart';
import 'package:lingafriq/utils/curriculum_languages.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/pan_african_components.dart';

/// In-app native reviewer sign-off for bundled curriculum content.
class NativeContentReviewScreen extends ConsumerStatefulWidget {
  const NativeContentReviewScreen({super.key});

  @override
  ConsumerState<NativeContentReviewScreen> createState() =>
      _NativeContentReviewScreenState();
}

class _NativeContentReviewScreenState
    extends ConsumerState<NativeContentReviewScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data =
          await ref.read(nativeReviewChecklistServiceProvider).load();
      if (mounted) {
        setState(() {
          _data = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _setStatus(String langKey, String status) async {
    final reviewer = await _promptReviewerName();
    if (reviewer == null) return;
    await ref.read(nativeReviewChecklistServiceProvider).updateLanguage(
          languageKey: langKey,
          status: status,
          reviewer: reviewer,
          signedAt: DateTime.now().toIso8601String(),
        );
    HapticFeedback.mediumImpact();
    await _load();
  }

  Future<String?> _promptReviewerName() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reviewer name'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Your name or team',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null || result.isEmpty) return null;
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Native content review'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? PanAfricanGradients.darkSurface
              : PanAfricanGradients.forest,
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!))
                : _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final checks = List<String>.from(_data!['checks'] as List? ?? []);
    final languages = Map<String, dynamic>.from(
      _data!['languages'] as Map<String, dynamic>,
    );
    final keys = CurriculumLanguages.pickerKeys()
        .where((k) => languages.containsKey(k))
        .toList();

    return ListView(
      padding: EdgeInsets.all(PanAfricanSpacing.md),
      children: [
        PanAfricanCard(
          padding: EdgeInsets.all(PanAfricanSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Sign-off checklist',
                style: PanAfricanTypography.titleMedium(context),
              ),
              SizedBox(height: PanAfricanSpacing.sm),
              ...checks.map(
                (c) => Padding(
                  padding: EdgeInsets.only(bottom: 6.h),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 18.sp,
                        color: PanAfricanColors.primary,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          c,
                          style: PanAfricanTypography.bodySmall(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: PanAfricanSpacing.md),
        ...keys.map((key) {
          final entry = Map<String, dynamic>.from(
            languages[key] as Map<String, dynamic>,
          );
          final status = (entry['status'] as String?) ?? 'pending';
          final reviewer = (entry['reviewer'] as String?) ?? '';
          return Padding(
            padding: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
            child: PanAfricanCard(
              padding: EdgeInsets.all(PanAfricanSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          CurriculumLanguages.displayName(key),
                          style: PanAfricanTypography.titleSmall(context),
                        ),
                      ),
                      _StatusChip(status: status),
                    ],
                  ),
                  if (reviewer.isNotEmpty) ...[
                    SizedBox(height: 4.h),
                    Text(
                      'Reviewer: $reviewer',
                      style: PanAfricanTypography.bodySmall(context),
                    ),
                  ],
                  SizedBox(height: PanAfricanSpacing.sm),
                  Wrap(
                    spacing: 8.w,
                    children: [
                      OutlinedButton(
                        onPressed: () => _setStatus(key, 'in_review'),
                        child: const Text('In review'),
                      ),
                      FilledButton(
                        onPressed: () => _setStatus(key, 'certified'),
                        child: const Text('Certify'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'certified':
        color = PanAfricanColors.success;
        break;
      case 'in_review':
        color = PanAfricanColors.warning;
        break;
      default:
        color = PanAfricanColors.neutralMedium;
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        status,
        style: PanAfricanTypography.labelSmall(context).copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
