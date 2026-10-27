import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lingafriq/config/api_contract.dart';
import 'package:lingafriq/services/passport/passport_service.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Published methodology version (keep in sync with `docs/passport/METHODOLOGY.md`).
const String kPassportMethodologyVersionId = '2026.1';
const String kPassportMethodologyReviewBy = '2027-04-27';
const Duration kPassportCredentialTtl = Duration(days: 365);

class PassportCredentialScreen extends StatefulWidget {
  final String verifyToken;
  final String level;
  final int score;
  final String? credentialId;
  final String? methodologyVersionId;
  final DateTime? issuedAt;

  /// Golden / widget tests — skips network when set.
  final bool? debugPortfolioPrereqBlocked;
  final bool? debugPortfolioLoading;
  final List<PassportPortfolioEntry>? debugPortfolioEntries;
  final Map<String, dynamic>? debugOpenBadgeCredential;
  final String? debugOpenBadgeError;
  final String? debugPublicationStatus;
  final String? debugRevokedReason;
  final bool? debugPublicationStatusLoading;
  final bool? debugPublicationStatusError;

  const PassportCredentialScreen({
    super.key,
    required this.verifyToken,
    required this.level,
    required this.score,
    this.credentialId,
    this.methodologyVersionId,
    this.issuedAt,
    this.debugPortfolioPrereqBlocked,
    this.debugPortfolioLoading,
    this.debugPortfolioEntries,
    this.debugOpenBadgeCredential,
    this.debugOpenBadgeError,
    this.debugPublicationStatus,
    this.debugRevokedReason,
    this.debugPublicationStatusLoading,
    this.debugPublicationStatusError,
  });

  @override
  State<PassportCredentialScreen> createState() => _PassportCredentialScreenState();
}

class _PassportCredentialScreenState extends State<PassportCredentialScreen> {
  final _svc = PassportService();
  bool _verifying = false;
  String? _verifyError;
  Map<String, dynamic>? _verifyResult;

  bool _portfolioLoading = false;
  bool _portfolioPrereqBlocked = false;
  List<PassportPortfolioEntry> _portfolioEntries = const [];
  String? _portfolioError;

  bool _openBadgeLoading = false;
  Map<String, dynamic>? _openBadgeCredential;
  String? _openBadgeError;

  bool _publicationLoading = false;
  String? _publicationStatus;
  String? _revokedReason;
  bool _publicationStatusError = false;

  @override
  void initState() {
    super.initState();
    if (widget.debugOpenBadgeCredential != null || widget.debugOpenBadgeError != null) {
      _openBadgeCredential = widget.debugOpenBadgeCredential;
      _openBadgeError = widget.debugOpenBadgeError;
    }
    if (widget.debugPublicationStatus != null ||
        widget.debugPublicationStatusLoading != null ||
        widget.debugPublicationStatusError != null) {
      _publicationLoading = widget.debugPublicationStatusLoading ?? false;
      _publicationStatus = widget.debugPublicationStatus;
      _revokedReason = widget.debugRevokedReason;
      _publicationStatusError = widget.debugPublicationStatusError ?? false;
      if (widget.debugPortfolioLoading == null &&
          widget.debugPortfolioPrereqBlocked == null &&
          widget.debugPortfolioEntries == null) {
        return;
      }
    }
    if (widget.debugPortfolioLoading != null ||
        widget.debugPortfolioPrereqBlocked != null ||
        widget.debugPortfolioEntries != null) {
      _portfolioLoading = widget.debugPortfolioLoading ?? false;
      _portfolioPrereqBlocked = widget.debugPortfolioPrereqBlocked ?? false;
      _portfolioEntries = widget.debugPortfolioEntries ?? const [];
      if (widget.credentialId != null &&
          widget.debugOpenBadgeCredential == null &&
          _effectivePublicationStatus != 'revoked') {
        _loadOpenBadge();
      }
      return;
    }
    _loadPortfolio();
    _loadPublicationStatus();
    if (widget.credentialId != null && _effectivePublicationStatus != 'revoked') {
      _loadOpenBadge();
    }
  }

  Future<void> _loadPublicationStatus() async {
    final id = widget.credentialId?.trim();
    if (id == null || id.isEmpty) return;
    setState(() {
      _publicationLoading = true;
      _publicationStatusError = false;
    });
    try {
      await ApiService.initialize();
      final res = await ApiService.get('/api/v2/credentials/status/$id');
      final body = res.data;
      if (body is Map) {
        final status = body['status']?.toString();
        setState(() {
          _publicationStatus = status;
          _revokedReason = body['reason']?.toString();
        });
      } else {
        setState(() {
          _publicationStatus = 'unknown';
          _publicationStatusError = true;
        });
      }
    } catch (_) {
      setState(() {
        _publicationStatus = 'unknown';
        _publicationStatusError = true;
      });
    } finally {
      if (mounted) setState(() => _publicationLoading = false);
    }
  }

  Future<void> _loadOpenBadge() async {
    final id = widget.credentialId?.trim();
    if (id == null || id.isEmpty) return;
    setState(() {
      _openBadgeLoading = true;
      _openBadgeError = null;
    });
    try {
      await ApiService.initialize();
      final res = await ApiService.post(
        '/api/v2/credentials/issue',
        data: {'credentialId': id},
      );
      final body = res.data;
      if (body is Map && body['verifiableCredential'] is Map) {
        setState(() => _openBadgeCredential = Map<String, dynamic>.from(body['verifiableCredential'] as Map));
      } else {
        setState(() => _openBadgeError = 'We could not load your Open Badge yet.');
      }
    } catch (e) {
      setState(() => _openBadgeError = 'Your Open Badge is not ready to share yet.');
    } finally {
      if (mounted) setState(() => _openBadgeLoading = false);
    }
  }

  String get _evidenceSummary {
    final count = _effectivePortfolioEntries.length;
    if (count == 0) {
      return 'Proctored speaking at level ${widget.level}';
    }
    return '$count verified can-do${count == 1 ? '' : 's'} plus level ${widget.level}';
  }

  Future<void> _shareOpenBadge() async {
    final vc = _openBadgeCredential;
    if (vc == null) return;
    final json = const JsonEncoder.withIndent('  ').convert(vc);
    await _copy('Open Badge JSON', json);
  }

  Future<void> _loadPortfolio() async {
    setState(() {
      _portfolioLoading = true;
      _portfolioError = null;
    });
    try {
      final result = await _svc.fetchPortfolio();
      if (!mounted) return;
      setState(() {
        _portfolioPrereqBlocked = result.prereqBlocked;
        _portfolioEntries = result.entries;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _portfolioError = e.toString());
    } finally {
      if (mounted) setState(() => _portfolioLoading = false);
    }
  }

  String get _verifyUrl => ApiContract.url(ApiContract.learningV2.passportVerify(widget.verifyToken));

  String get _methodologyVersionId => widget.methodologyVersionId ?? kPassportMethodologyVersionId;

  DateTime? get _issuedAt {
    if (widget.issuedAt != null) return widget.issuedAt;
    final payload = _decodeTokenPayload(widget.verifyToken);
    final exp = payload?['exp'];
    if (exp is int) {
      return DateTime.fromMillisecondsSinceEpoch(exp).subtract(kPassportCredentialTtl);
    }
    final cred = _verifyResult?['credential'];
    if (cred is Map) {
      final expires = cred['expiresAt']?.toString();
      if (expires != null) {
        final dt = DateTime.tryParse(expires);
        if (dt != null) return dt.subtract(kPassportCredentialTtl);
      }
    }
    return null;
  }

  static Map<String, dynamic>? _decodeTokenPayload(String token) {
    final parts = token.split('.');
    if (parts.length != 2) return null;
    try {
      var normalized = parts[0];
      while (normalized.length % 4 != 0) {
        normalized += '=';
      }
      final json = utf8.decode(base64Url.decode(normalized));
      final decoded = jsonDecode(json);
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } catch (_) {
      return null;
    }
    return null;
  }

  Future<void> _copy(String label, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$label copied')));
  }

  Future<void> _verifyNow() async {
    setState(() {
      _verifying = true;
      _verifyError = null;
      _verifyResult = null;
    });
    try {
      final res = await _svc.verifyPublic(widget.verifyToken);
      setState(() => _verifyResult = res);
    } catch (e) {
      setState(() => _verifyError = e.toString());
    } finally {
      setState(() => _verifying = false);
    }
  }

  void _openMethodologySheet() {
    final issued = _issuedAt;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('How we map to CEFR', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  'Methodology version $_methodologyVersionId'
                  '${issued != null ? ' · issued ${issued.toLocal().toString().split(' ').first}' : ''}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Unit can-dos in our curriculum map to CEFR Companion Volume (2020) global-scale descriptor ids by skill and level. '
                  'Your Passport level reflects a proctored speaking rubric — it is not an official exam certificate.',
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 12),
                Text(
                  'Next review: $kPassportMethodologyReviewBy',
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 16),
                Semantics(
                  button: true,
                  label: 'Open full methodology document',
                  child: FilledButton.tonalIcon(
                    onPressed: () {
                      Navigator.pop(ctx);
                      _copy(
                        'Methodology path',
                        '/passport/methodology/$_methodologyVersionId',
                      );
                    },
                    icon: const Icon(Icons.menu_book_outlined),
                    label: const Text('Copy methodology link path'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPortfolioSection(ColorScheme cs, TextTheme textTheme) {
    if (_effectivePortfolioLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 24),
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (_portfolioError != null && widget.debugPortfolioEntries == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'We could not load your evidence portfolio. Pull to refresh later.',
            style: textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
          ),
        ),
      );
    }
    if (_effectivePortfolioEntries.isEmpty) {
      return Card(
        color: cs.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Evidence portfolio', style: textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                'Passed can-do tasks will appear here once verified on our servers — nothing you self-report.',
                style: textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Evidence portfolio', style: textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Can-dos you demonstrated with verified speaking evidence',
          style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        ..._effectivePortfolioEntries.map((entry) {
          final date = entry.passedAt.toLocal().toString().split(' ').first;
          return Semantics(
            label: 'Can-do ${entry.canDoId}, level ${entry.cefrLevel}, verified $date',
            child: Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                minVerticalPadding: 12,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: CircleAvatar(
                  backgroundColor: cs.primaryContainer,
                  child: Icon(Icons.check_rounded, color: cs.onPrimaryContainer),
                ),
                title: Text(entry.canDoId, style: textTheme.titleSmall),
                subtitle: Text(
                  '${entry.cefrLevel} · task ${entry.taskId} · $date',
                  style: textTheme.bodySmall,
                ),
                trailing: entry.scorerConfidence != null
                    ? Text(
                        '${(entry.scorerConfidence! * 100).round()}%',
                        style: textTheme.labelLarge?.copyWith(color: cs.primary),
                      )
                    : null,
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildPrereqBlocked(ColorScheme cs, TextTheme textTheme) {
    return Scaffold(
      appBar: AppBar(title: const Text('Proficiency Passport')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.hourglass_top_rounded, size: 48, color: cs.primary),
            const SizedBox(height: 16),
            Text('Passport is not available yet', style: textTheme.headlineSmall),
            const SizedBox(height: 12),
            Text(
              'We are still calibrating real lesson content and speaking scores. '
              'Your credential will unlock when both are ready — we will not show a Passport before then.',
              style: textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }

  bool get _effectivePortfolioLoading =>
      widget.debugPortfolioLoading ?? _portfolioLoading;

  bool get _effectivePortfolioPrereqBlocked =>
      widget.debugPortfolioPrereqBlocked ?? _portfolioPrereqBlocked;

  List<PassportPortfolioEntry> get _effectivePortfolioEntries =>
      widget.debugPortfolioEntries ?? _portfolioEntries;

  bool get _effectivePublicationLoading =>
      widget.debugPublicationStatusLoading ?? _publicationLoading;

  String? get _effectivePublicationStatus =>
      widget.debugPublicationStatus ?? _publicationStatus;

  String? get _effectiveRevokedReason => widget.debugRevokedReason ?? _revokedReason;

  bool get _effectivePublicationStatusError =>
      widget.debugPublicationStatusError ?? _publicationStatusError;

  bool get _treatAsRevoked => _effectivePublicationStatus == 'revoked';

  bool get _treatAsUnknown =>
      _effectivePublicationStatusError || _effectivePublicationStatus == 'unknown';

  Widget _buildRevokedState(ColorScheme cs, TextTheme textTheme) {
    final reason = (_effectiveRevokedReason ?? '').trim();
    return Scaffold(
      appBar: AppBar(title: const Text('Proficiency Passport')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Semantics(
            label: 'Credential revoked',
            child: Icon(Icons.block_rounded, size: 56, color: cs.error),
          ),
          const SizedBox(height: 16),
          Text('This credential was revoked', style: textTheme.headlineSmall),
          const SizedBox(height: 12),
          Text(
            reason.isNotEmpty
                ? reason
                : 'LingAfriq withdrew publication of this Passport after a review.',
            style: textTheme.bodyLarge,
          ),
          const SizedBox(height: 20),
          Text(
            'What you can do next',
            style: textTheme.titleMedium?.copyWith(color: cs.primary),
          ),
          const SizedBox(height: 8),
          Text(
            'Retake a proctored Passport session when you are ready, or contact support if you believe this was a mistake.',
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          Semantics(
            button: true,
            label: 'Contact LingAfriq support about revoked credential',
            child: FilledButton.tonalIcon(
              onPressed: () => _copy('Support', 'support@lingafriq.com'),
              icon: const Icon(Icons.mail_outline_rounded),
              label: const Text('Email support'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnknownPublicationBanner(ColorScheme cs, TextTheme textTheme) {
    return Card(
      color: cs.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.cloud_off_rounded, color: cs.onSurfaceVariant),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'We could not confirm whether this credential is still valid. '
                'We will not show it as verified until status loads.',
                style: textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final missingVersion = _methodologyVersionId.isEmpty;

    if (!_effectivePortfolioLoading && _effectivePortfolioPrereqBlocked) {
      return _buildPrereqBlocked(cs, textTheme);
    }

    if (!_effectivePublicationLoading && _treatAsRevoked) {
      return _buildRevokedState(cs, textTheme);
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Proficiency Passport')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_effectivePublicationLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: LinearProgressIndicator(minHeight: 3),
            ),
          if (_treatAsUnknown && !_effectivePublicationLoading) ...[
            _buildUnknownPublicationBanner(cs, textTheme),
            const SizedBox(height: 12),
          ],
          Text('Your credential', style: textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            'CEFR-aligned level ${widget.level} · score ${widget.score}',
            style: textTheme.titleMedium?.copyWith(color: cs.primary),
          ),
          if (_issuedAt != null) ...[
            const SizedBox(height: 6),
            Text(
              'Issued ${_issuedAt!.toLocal().toString().split(' ').first} · $_evidenceSummary',
              style: textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                QrImageView(
                  data: _verifyUrl,
                  size: 220,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
                  dataModuleStyle: const QrDataModuleStyle(
                    dataModuleShape: QrDataModuleShape.square,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Scan or share this link — verification works without signing in.',
                  textAlign: TextAlign.center,
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (missingVersion)
            Card(
              color: cs.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: cs.onErrorContainer),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Methodology version is missing for this credential.',
                        style: textTheme.bodyMedium?.copyWith(color: cs.onErrorContainer),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            Semantics(
              button: true,
              label: 'View CEFR mapping methodology version $_methodologyVersionId',
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                minVerticalPadding: 12,
                leading: Icon(Icons.verified_user_outlined, color: cs.primary),
                title: const Text('CEFR mapping methodology'),
                subtitle: Text('Version $_methodologyVersionId · review by $kPassportMethodologyReviewBy'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _openMethodologySheet,
              ),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                onPressed: () => _copy('Verification link', _verifyUrl),
                icon: const Icon(Icons.link_rounded),
                label: const Text('Copy link'),
              ),
              OutlinedButton.icon(
                onPressed: () => _copy('Verification token', widget.verifyToken),
                icon: const Icon(Icons.key_rounded),
                label: const Text('Copy token'),
              ),
              FilledButton.icon(
                onPressed: (_verifying || _treatAsUnknown) ? null : _verifyNow,
                icon: const Icon(Icons.verified_rounded),
                label: Text(_verifying ? 'Verifying…' : 'Verify now'),
              ),
              if (_openBadgeLoading)
                OutlinedButton.icon(
                  onPressed: null,
                  icon: const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  label: const Text('Preparing badge…'),
                )
              else if (_openBadgeCredential != null)
                Semantics(
                  button: true,
                  label: 'Share Open Badge credential',
                  child: FilledButton.tonalIcon(
                    onPressed: _shareOpenBadge,
                    icon: const Icon(Icons.ios_share_rounded),
                    label: const Text('Share Open Badge'),
                  ),
                )
              else if (_openBadgeError != null)
                Text(
                  _openBadgeError!,
                  style: textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_verifyError != null)
            Text(_verifyError!, style: TextStyle(color: cs.error)),
          if (_verifyResult != null) ...[
            Text('Verified on server', style: textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(_verifyResult.toString(), style: textTheme.bodySmall),
          ],
          const SizedBox(height: 24),
          _buildPortfolioSection(cs, textTheme),
        ],
      ),
    );
  }
}
