import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lingafriq/config/api_contract.dart';
import 'package:lingafriq/services/passport/passport_service.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Published methodology version (keep in sync with `docs/passport/METHODOLOGY.md`).
const String kPassportMethodologyVersionId = '2026.1';
const String kPassportMethodologyReviewBy = '2027-04-27';
const Duration kPassportCredentialTtl = Duration(days: 365);

class PassportCredentialScreen extends StatefulWidget {
  final String verifyToken;
  final String level;
  final int score;
  final String? methodologyVersionId;
  final DateTime? issuedAt;

  const PassportCredentialScreen({
    super.key,
    required this.verifyToken,
    required this.level,
    required this.score,
    this.methodologyVersionId,
    this.issuedAt,
  });

  @override
  State<PassportCredentialScreen> createState() => _PassportCredentialScreenState();
}

class _PassportCredentialScreenState extends State<PassportCredentialScreen> {
  final _svc = PassportService();
  bool _verifying = false;
  String? _verifyError;
  Map<String, dynamic>? _verifyResult;

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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final missingVersion = _methodologyVersionId.isEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Proficiency Passport')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Your credential', style: textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            'CEFR-aligned level ${widget.level} · score ${widget.score}',
            style: textTheme.titleMedium?.copyWith(color: cs.primary),
          ),
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
                onPressed: _verifying ? null : _verifyNow,
                icon: const Icon(Icons.verified_rounded),
                label: Text(_verifying ? 'Verifying…' : 'Verify now'),
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
        ],
      ),
    );
  }
}
