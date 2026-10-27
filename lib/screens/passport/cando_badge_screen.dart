import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/config/api_contract.dart';
import 'package:lingafriq/providers/dio_provider.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/responsive_safe_area.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

/// Shareable can-do badge — reference: Duolingo achievement share sheet.
class CanDoBadgeScreen extends ConsumerStatefulWidget {
  final String unitId;
  final String canDoId;
  final String canDoText;
  final String cefrLevel;
  final bool earned;

  const CanDoBadgeScreen({
    super.key,
    required this.unitId,
    required this.canDoId,
    required this.canDoText,
    required this.cefrLevel,
    this.earned = false,
  });

  @override
  ConsumerState<CanDoBadgeScreen> createState() => _CanDoBadgeScreenState();
}

class _CanDoBadgeScreenState extends ConsumerState<CanDoBadgeScreen> {
  bool _loading = true;
  String? _error;
  String? _verifyToken;
  String? _verifyPath;
  bool _shared = false;

  @override
  void initState() {
    super.initState();
    Future.microtask(_load);
  }

  Future<void> _load() async {
    if (!widget.earned) {
      setState(() {
        _loading = false;
        _error = 'BADGE_NOT_EARNED';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dio = ref.read(client);
      final res = await dio.get(
        '/api/gamification/cando-badges/mine',
        queryParameters: {'unitId': widget.unitId, 'canDoId': widget.canDoId},
      );
      final data = res.data as Map<String, dynamic>;
      setState(() {
        _verifyToken = data['verifyToken'] as String?;
        _verifyPath = data['verifyPath'] as String?;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  String get _verifyUrl {
    final path = _verifyPath ?? '';
    if (path.startsWith('http')) return path;
    return ApiContract.url(path.isNotEmpty ? path : '/api/gamification/cando-badges/verify/');
  }

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: _verifyUrl));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Verification link copied')),
    );
  }

  Future<void> _share() async {
    HapticFeedback.mediumImpact();
    final text =
        'I earned a can-do badge on LingAfriq: ${widget.canDoText} (${widget.cefrLevel}). Verify: $_verifyUrl';
    await Share.share(text, subject: 'My LingAfriq can-do badge');
    setState(() => _shared = true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? PanAfricanColors.backgroundDark : PanAfricanColors.backgroundLight;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        title: Text('Can-do badge', style: PanAfricanTypography.titleLarge(context)),
      ),
      body: ResponsiveSafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: EdgeInsets.all(PanAfricanSpacing.md),
                children: [
                  if (_error == 'BADGE_NOT_EARNED' || (!widget.earned && _error != null))
                    _LockedState(canDoText: widget.canDoText)
                  else if (_error != null)
                    _ErrorState(message: _error!, onRetry: _load)
                  else if (_verifyToken == null)
                    _LockedState(canDoText: widget.canDoText)
                  else
                    _EarnedShareBody(
                      canDoText: widget.canDoText,
                      cefrLevel: widget.cefrLevel,
                      verifyUrl: _verifyUrl,
                      shared: _shared,
                      onCopy: _copyLink,
                      onShare: _share,
                    ),
                ],
              ),
      ),
    );
  }
}

class _LockedState extends StatelessWidget {
  final String canDoText;

  const _LockedState({required this.canDoText});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.lock_rounded, size: 48.sp, color: PanAfricanColors.primary.withValues(alpha: 0.6)),
        SizedBox(height: PanAfricanSpacing.md),
        Text(
          'Finish the checkpoint first',
          style: PanAfricanTypography.headlineSmall(context),
        ),
        SizedBox(height: PanAfricanSpacing.sm),
        Text(
          'This badge unlocks when you demonstrate: $canDoText',
          style: PanAfricanTypography.bodyLarge(context),
        ),
        SizedBox(height: PanAfricanSpacing.lg),
        Text(
          'Generic tap badges do not count — only verified can-dos earn a shareable badge.',
          style: PanAfricanTypography.bodyMedium(context),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('We could not load your badge right now.', style: PanAfricanTypography.bodyLarge(context)),
        SizedBox(height: PanAfricanSpacing.sm),
        Text(message, style: PanAfricanTypography.bodySmall(context)),
        SizedBox(height: PanAfricanSpacing.lg),
        FilledButton(
          onPressed: onRetry,
          style: FilledButton.styleFrom(minimumSize: Size.fromHeight(48.h)),
          child: const Text('Try again'),
        ),
      ],
    );
  }
}

class _EarnedShareBody extends StatelessWidget {
  final String canDoText;
  final String cefrLevel;
  final String verifyUrl;
  final bool shared;
  final VoidCallback onCopy;
  final VoidCallback onShare;

  const _EarnedShareBody({
    required this.canDoText,
    required this.cefrLevel,
    required this.verifyUrl,
    required this.shared,
    required this.onCopy,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('You demonstrated', style: PanAfricanTypography.labelLarge(context)),
        SizedBox(height: PanAfricanSpacing.xs),
        Text(canDoText, style: PanAfricanTypography.headlineSmall(context)),
        SizedBox(height: PanAfricanSpacing.xs),
        Text('Level $cefrLevel', style: PanAfricanTypography.titleMedium(context)),
        SizedBox(height: PanAfricanSpacing.lg),
        Semantics(
          label: 'Can-do badge verification QR code',
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(PanAfricanSpacing.md),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outline.withValues(alpha: 0.25)),
            ),
            child: Column(
              children: [
                QrImageView(
                  data: verifyUrl,
                  size: 220,
                  backgroundColor: Colors.white,
                ),
                SizedBox(height: PanAfricanSpacing.sm),
                Text(
                  shared
                      ? 'Shared — friends can verify this link without an account.'
                      : 'Share your proof. Anyone can verify the link.',
                  textAlign: TextAlign.center,
                  style: PanAfricanTypography.bodyMedium(context),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: PanAfricanSpacing.lg),
        Semantics(
          label: 'Share can-do badge',
          button: true,
          child: FilledButton.icon(
            onPressed: onShare,
            icon: const Icon(Icons.ios_share_rounded),
            label: const Text('Share badge'),
            style: FilledButton.styleFrom(
              minimumSize: Size.fromHeight(48.h),
              backgroundColor: PanAfricanColors.primary,
            ),
          ),
        ),
        SizedBox(height: PanAfricanSpacing.sm),
        OutlinedButton(
          onPressed: onCopy,
          style: OutlinedButton.styleFrom(minimumSize: Size.fromHeight(48.h)),
          child: const Text('Copy verify link'),
        ),
      ],
    );
  }
}
