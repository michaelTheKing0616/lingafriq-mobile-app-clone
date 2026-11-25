import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/responsive_safe_area.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String kPrivacyPolicyAsset = 'docs/privacy/PRIVACY_POLICY.md';
const String kPrivacyPolicyAckPref = 'privacy_policy_ack_version';

/// P10-927 — plain-language privacy policy (Apple Settings legal-doc pattern).
class PrivacyPolicyScreen extends HookConsumerWidget {
  const PrivacyPolicyScreen({super.key});

  static const String privacyPolicyTitleKey = 'privacy_policy_title';

  static Future<void> open(BuildContext context) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const PrivacyPolicyScreen()),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final loadState = useState<_LoadState>(_LoadState.loading);
    final version = useState<String?>(null);
    final effectiveDate = useState<String?>(null);
    final bodyMarkdown = useState<String>('');
    final needsAck = useState(false);
    final ackSaving = useState(false);

    Future<void> loadPolicy() async {
      loadState.value = _LoadState.loading;
      try {
        final raw = await rootBundle.loadString(kPrivacyPolicyAsset);
        final parsed = _parsePolicyAsset(raw);
        version.value = parsed.version;
        effectiveDate.value = parsed.effectiveDate;
        bodyMarkdown.value = parsed.body;
        final prefs = await SharedPreferences.getInstance();
        final acked = prefs.getString(kPrivacyPolicyAckPref);
        needsAck.value = acked != parsed.version;
        loadState.value = _LoadState.loaded;
      } catch (_) {
        loadState.value = _LoadState.error;
      }
    }

    Future<void> acknowledge() async {
      final v = version.value;
      if (v == null) return;
      ackSaving.value = true;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(kPrivacyPolicyAckPref, v);
      needsAck.value = false;
      ackSaving.value = false;
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thanks — we saved your confirmation.')),
        );
      }
    }

    useEffect(() {
      loadPolicy();
      return null;
    }, const []);

    final reduceMotion = MediaQuery.disableAnimationsOf(context);

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
        title: Semantics(
          label: 'Privacy policy',
          header: true,
          child: Text(
            'Privacy policy',
            key: const Key(privacyPolicyTitleKey),
            style: PanAfricanTypography.titleLarge(context)
                .copyWith(color: colorScheme.onPrimary),
          ),
        ),
        backgroundColor: PanAfricanColors.primary,
      ),
      body: ResponsiveSafeArea(
        child: switch (loadState.value) {
          _LoadState.loading => const Center(child: CircularProgressIndicator()),
          _LoadState.error => Center(
              child: Padding(
                padding: EdgeInsets.all(PanAfricanSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'We could not load the policy offline.',
                      style: PanAfricanTypography.bodyLarge(context),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: PanAfricanSpacing.md),
                    FilledButton(
                      onPressed: loadPolicy,
                      style: FilledButton.styleFrom(
                        minimumSize: Size.fromHeight(48.h),
                      ),
                      child: const Text('Try again'),
                    ),
                  ],
                ),
              ),
            ),
          _LoadState.loaded => LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: reduceMotion
                      ? const ClampingScrollPhysics()
                      : const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(bottom: PanAfricanSpacing.lg),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (needsAck.value)
                          Material(
                            color: colorScheme.errorContainer,
                            child: Padding(
                              padding: EdgeInsets.all(PanAfricanSpacing.md),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'We updated our privacy policy (${version.value}). '
                                    'Please read it and confirm.',
                                    style: PanAfricanTypography.bodyMedium(context)
                                        .copyWith(color: colorScheme.onErrorContainer),
                                  ),
                                  SizedBox(height: PanAfricanSpacing.sm),
                                  Semantics(
                                    label: 'I understand the updated privacy policy',
                                    button: true,
                                    child: FilledButton(
                                      onPressed: ackSaving.value ? null : acknowledge,
                                      style: FilledButton.styleFrom(
                                        minimumSize: Size.fromHeight(48.h),
                                      ),
                                      child: ackSaving.value
                                          ? SizedBox(
                                              height: 20.h,
                                              width: 20.h,
                                              child: const CircularProgressIndicator(
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Text('I understand'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            PanAfricanSpacing.md,
                            PanAfricanSpacing.sm,
                            PanAfricanSpacing.md,
                            PanAfricanSpacing.xs,
                          ),
                          child: Text(
                            'Version ${version.value ?? '—'} · ${effectiveDate.value ?? '—'}',
                            style: PanAfricanTypography.labelLarge(context),
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.md),
                          child: MarkdownBody(
                            data: bodyMarkdown.value,
                            styleSheet: MarkdownStyleSheet(
                              h1: PanAfricanTypography.headlineSmall(context),
                              h2: PanAfricanTypography.titleMedium(context),
                              p: PanAfricanTypography.bodyMedium(context),
                              tableBody: PanAfricanTypography.bodySmall(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        },
      ),
    );
  }
}

enum _LoadState { loading, loaded, error }

class _ParsedPolicy {
  _ParsedPolicy({
    required this.version,
    required this.effectiveDate,
    required this.body,
  });

  final String version;
  final String effectiveDate;
  final String body;
}

_ParsedPolicy _parsePolicyAsset(String raw) {
  const fmStart = '---\n';
  if (!raw.startsWith(fmStart)) {
    throw const FormatException('missing front matter');
  }
  final end = raw.indexOf('\n---\n', fmStart.length);
  if (end < 0) {
    throw const FormatException('unclosed front matter');
  }
  final yamlText = raw.substring(fmStart.length, end);
  final versionMatch =
      RegExp(r'^version:\s*"?([^"\n]+)"?\s*$', multiLine: true).firstMatch(yamlText);
  final dateMatch = RegExp(r'^effective_date:\s*"?([^"\n]+)"?\s*$', multiLine: true)
      .firstMatch(yamlText);
  final version = versionMatch?.group(1)?.trim();
  final effectiveDate = dateMatch?.group(1)?.trim();
  if (version == null || version.isEmpty || effectiveDate == null || effectiveDate.isEmpty) {
    throw const FormatException('version or effective_date missing');
  }
  final body = raw.substring(end + 5);
  return _ParsedPolicy(
    version: version,
    effectiveDate: effectiveDate,
    body: body,
  );
}
