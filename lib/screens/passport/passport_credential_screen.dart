import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lingafriq/config/api_contract.dart';
import 'package:lingafriq/services/passport/passport_service.dart';
import 'package:qr_flutter/qr_flutter.dart';

class PassportCredentialScreen extends StatefulWidget {
  final String verifyToken;
  final String level;
  final int score;

  const PassportCredentialScreen({
    super.key,
    required this.verifyToken,
    required this.level,
    required this.score,
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Proficiency Passport')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Issued credential', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text('Level: ${widget.level}   Score: ${widget.score}', style: Theme.of(context).textTheme.bodyLarge),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outline.withOpacity(0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                QrImageView(
                  data: _verifyUrl,
                  size: 240,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
                  dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Colors.black),
                ),
                const SizedBox(height: 12),
                Text(
                  'This QR encodes a verification link.\nAnyone can verify without logging in.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
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
          const SizedBox(height: 14),
          if (_verifyError != null)
            Text(_verifyError!, style: TextStyle(color: cs.error)),
          if (_verifyResult != null) ...[
            Text('Verified', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(_verifyResult.toString(), style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

