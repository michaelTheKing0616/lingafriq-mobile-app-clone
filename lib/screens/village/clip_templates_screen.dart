import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/models/clip_template.dart';
import 'package:lingafriq/screens/village/clip_camera_screen.dart';
import 'package:lingafriq/services/capability_gate.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/responsive_safe_area.dart';

/// Clip starters — reference: Instagram Reels templates row + TikTok create flows.
class ClipTemplatesScreen extends StatefulWidget {
  const ClipTemplatesScreen({
    super.key,
    this.repository,
    this.capabilityGate,
    this.initialLanguage = 'yo',
    this.loadCapabilitiesOnInit = true,
    this.resolveCapabilities,
    this.gateOverride,
  });

  final ClipTemplateRepository? repository;
  final CapabilityGate? capabilityGate;
  final String initialLanguage;
  final bool loadCapabilitiesOnInit;
  final Future<LearnerCapabilities?> Function()? resolveCapabilities;

  /// Widget tests only — skips async capability fetch (avoids infinite progress indicator).
  final ClipTemplatesAccessGate? gateOverride;

  @override
  State<ClipTemplatesScreen> createState() => _ClipTemplatesScreenState();
}

class _ClipTemplatesScreenState extends State<ClipTemplatesScreen> {
  static const _languages = ['yo', 'ig', 'ha', 'pcm', 'sw', 'zu', 'xh', 'tw'];

  late ClipTemplateRepository _repo;
  ClipTemplatesAccessGate _gate = ClipTemplatesAccessGate.loading;
  String _language = 'yo';
  ClipTemplateKind? _selected;
  ClipTemplateContent? _content;
  bool _loadingContent = false;
  String? _contentError;

  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? ClipTemplateRepository();
    _language = widget.initialLanguage.trim().toLowerCase();
    if (!_languages.contains(_language)) _language = 'yo';
    if (widget.gateOverride != null) {
      _gate = widget.gateOverride!;
    } else if (widget.loadCapabilitiesOnInit || widget.resolveCapabilities != null) {
      unawaited(_resolveGate());
    } else {
      _gate = ClipTemplatesAccessGate.allowed;
    }
  }

  Future<void> _resolveGate() async {
    final LearnerCapabilities? caps = widget.resolveCapabilities != null
        ? await widget.resolveCapabilities!()
        : await _fetchCapabilitiesStrict();
    if (!mounted) return;
    if (caps == null) {
      setState(() => _gate = ClipTemplatesAccessGate.offline);
      return;
    }
    if (caps.isMinor || !caps.snaps) {
      setState(() => _gate = ClipTemplatesAccessGate.blockedMinor);
      return;
    }
    if (caps.tier == null || caps.tier!.trim().isEmpty) {
      setState(() => _gate = ClipTemplatesAccessGate.blockedAgeUnknown);
      return;
    }
    setState(() => _gate = ClipTemplatesAccessGate.allowed);
  }

  Future<LearnerCapabilities?> _fetchCapabilitiesStrict() async {
    try {
      await ApiService.initialize();
      final response = await ApiService.get('$capabilitiesBasePath/matrix');
      final data = response.data;
      if (data is Map && data['ok'] == true && data['capabilities'] is Map) {
        return LearnerCapabilities.fromJson(
          Map<String, dynamic>.from(data['capabilities'] as Map),
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _onSelectKind(ClipTemplateKind kind) async {
    setState(() {
      _selected = kind;
      _loadingContent = true;
      _content = null;
      _contentError = null;
    });
    try {
      final loaded = await _repo.load(kind: kind, languageTag: _language);
      if (!mounted) return;
      setState(() {
        _content = loaded;
        _loadingContent = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadingContent = false;
        _contentError = 'We could not load verified content right now.';
      });
    }
  }

  Future<void> _startClip() async {
    final content = _content;
    if (content == null) return;
    HapticFeedback.mediumImpact();
    ClipTemplatePendingStore.set(_repo.presetFrom(content));
    if (!mounted) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const ClipCameraScreen(loadCirclesOnInit: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reducedMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return ResponsiveSafeArea(
      child: Scaffold(
        backgroundColor: theme.colorScheme.surface,
        appBar: AppBar(
          title: const Text('Clip templates'),
          backgroundColor: theme.colorScheme.surface,
          foregroundColor: theme.colorScheme.onSurface,
          elevation: 0,
        ),
        body: switch (_gate) {
          ClipTemplatesAccessGate.loading => const Center(
              child: CircularProgressIndicator.adaptive(),
            ),
          ClipTemplatesAccessGate.blockedMinor ||
          ClipTemplatesAccessGate.blockedAgeUnknown ||
          ClipTemplatesAccessGate.offline =>
            _GateBlockedBody(gate: _gate),
          ClipTemplatesAccessGate.allowed => _buildList(theme, reducedMotion),
        },
      ),
    );
  }

  Widget _buildList(ThemeData theme, bool reducedMotion) {
    return ListView(
      padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 32.h),
      children: [
        Text(
          'Start with verified words',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          'Pick a template, record 15–60 seconds, and share with your circle.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        SizedBox(height: 20.h),
        Text(
          'Language',
          style: theme.textTheme.titleSmall,
        ),
        SizedBox(height: 8.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: [
            for (final code in _languages)
              ChoiceChip(
                label: Text(code.toUpperCase()),
                selected: _language == code,
                onSelected: (selected) {
                  if (!selected) return;
                  setState(() {
                    _language = code;
                    _selected = null;
                    _content = null;
                  });
                },
                labelStyle: TextStyle(fontSize: 14.sp),
              ),
          ],
        ),
        SizedBox(height: 24.h),
        for (final kind in ClipTemplateKind.values)
          _TemplateTile(
            key: Key('clip_template_${kind.name}'),
            kind: kind,
            selected: _selected == kind,
            onTap: () => _onSelectKind(kind),
          ),
        if (_selected != null) ...[
          SizedBox(height: 16.h),
          AnimatedSwitcher(
            duration: reducedMotion
                ? Duration.zero
                : const Duration(milliseconds: 220),
            child: _buildDetail(theme),
          ),
        ],
      ],
    );
  }

  Widget _buildDetail(ThemeData theme) {
    if (_loadingContent) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator.adaptive()),
      );
    }
    if (_contentError != null) {
      return _EmptyLanguageCard(
        title: 'Could not load content',
        body: _contentError!,
      );
    }
    final content = _content;
    if (content == null) {
      return _EmptyLanguageCard(
        title: 'Nothing verified yet',
        body:
            'We do not have reviewed ${_language.toUpperCase()} content for this template yet. Try another language or check back after the next publish.',
      );
    }

    return ClipTemplateDetailPanel(
      content: content,
      onStartClip: _startClip,
    );
  }
}

class _TemplateTile extends StatelessWidget {
  const _TemplateTile({
    super.key,
    required this.kind,
    required this.selected,
    required this.onTap,
  });

  final ClipTemplateKind kind;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Material(
        color: selected
            ? PanAfricanColors.secondaryContainer
            : PanAfricanColors.surfaceContainerHighestLight,
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
            child: Row(
              children: [
                Icon(
                  switch (kind) {
                    ClipTemplateKind.phraseOfDay => Icons.wb_sunny_outlined,
                    ClipTemplateKind.proverbExplainer =>
                      Icons.format_quote_outlined,
                    ClipTemplateKind.tongueTwister => Icons.record_voice_over,
                  },
                  color: PanAfricanColors.primary,
                  size: 28.sp,
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        kind.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        kind.subtitle,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (selected)
                  Icon(Icons.check_circle, color: PanAfricanColors.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyLanguageCard extends StatelessWidget {
  const _EmptyLanguageCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 0,
      color: PanAfricanColors.surfaceContainerHighestLight,
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            SizedBox(height: 8.h),
            Text(body, style: theme.textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}

class _GateBlockedBody extends StatelessWidget {
  const _GateBlockedBody({required this.gate});

  final ClipTemplatesAccessGate gate;

  @override
  Widget build(BuildContext context) {
    final (title, body) = switch (gate) {
      ClipTemplatesAccessGate.blockedMinor => (
          'Clips need a guardian',
          'Clip templates stay off until a parent approves social sharing in Family hub.',
        ),
      ClipTemplatesAccessGate.blockedAgeUnknown => (
          'Confirm your age first',
          'We need an age check before you can post clips. Open Settings → Family to finish setup.',
        ),
      ClipTemplatesAccessGate.offline => (
          'Connect to continue',
          'We could not verify your account online. Clip templates stay closed until we can check age and permissions.',
        ),
      _ => ('Unavailable', 'Clip templates are not available right now.'),
    };

    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.headlineSmall),
          SizedBox(height: 12.h),
          Text(body, style: Theme.of(context).textTheme.bodyLarge),
          SizedBox(height: 24.h),
          FilledButton(
            onPressed: () {
              if (gate == ClipTemplatesAccessGate.blockedMinor ||
                  gate == ClipTemplatesAccessGate.blockedAgeUnknown) {
                CapabilityBlockedSheet.showPurchaseBlocked(context);
              }
            },
            child: const Text('Open Family hub'),
          ),
        ],
      ),
    );
  }
}
