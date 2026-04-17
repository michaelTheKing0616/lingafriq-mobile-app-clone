import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lingafriq/services/learning/dialect_preference_service.dart';
import 'package:lingafriq/utils/modern_griot_design_system.dart';

class DialectVariantPicker extends StatefulWidget {
  final String umbrellaLanguage;

  const DialectVariantPicker({super.key, required this.umbrellaLanguage});

  @override
  State<DialectVariantPicker> createState() => _DialectVariantPickerState();
}

class _DialectVariantPickerState extends State<DialectVariantPicker> {
  final _svc = DialectPreferenceService();
  late final TextEditingController _tagController;
  bool _loading = true;
  String? _error;
  String _mode = 'common'; // common | local
  String _localTag = '';

  @override
  void initState() {
    super.initState();
    _tagController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final pref = await _svc.get(umbrellaLanguage: widget.umbrellaLanguage);
      if (!mounted) return;
      if (pref != null &&
          pref['umbrellaLanguage']?.toString().toLowerCase() ==
              widget.umbrellaLanguage.toLowerCase()) {
        final tag = pref['preferredDialectTag']?.toString() ?? '';
        setState(() {
          _localTag = tag;
          _tagController.text = tag;
          _mode = tag.trim().isEmpty ? 'common' : 'local';
          _loading = false;
        });
        return;
      }
      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    HapticFeedback.lightImpact();
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tag = _mode == 'local' ? _tagController.text.trim() : 'standard';
      if (_mode == 'local' && tag.isEmpty) {
        throw Exception('Enter a local dialect tag (e.g., “yo-lagos”).');
      }
      await _svc.put(
        umbrellaLanguage: widget.umbrellaLanguage.toLowerCase(),
        preferredDialectTag: tag,
        confidence: _mode == 'local' ? 0.6 : 0.5,
        exposureScore: 0,
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dialect mode', style: ModernGriotTypography.titleLarge()),
          const SizedBox(height: 6),
          Text(
            'Choose “Common” for widely-taught standard forms, or “Local” for a specific region/city variant.',
            style: ModernGriotTypography.bodySmall(),
          ),
          const SizedBox(height: 12),
          if (_error != null) ...[
            Text(_error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
            const SizedBox(height: 8),
          ],
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(child: CircularProgressIndicator()),
            )
          else ...[
            RadioListTile<String>(
              value: 'common',
              groupValue: _mode,
              title: const Text('Common (standard)'),
              onChanged: (v) => setState(() => _mode = v ?? 'common'),
            ),
            RadioListTile<String>(
              value: 'local',
              groupValue: _mode,
              title: const Text('Local (dialect tag)'),
              onChanged: (v) => setState(() => _mode = v ?? 'local'),
            ),
            if (_mode == 'local') ...[
              TextField(
                controller: _tagController,
                decoration: const InputDecoration(
                  labelText: 'Local dialect tag',
                  hintText: 'e.g. yo-lagos, sw-ke, ig-enugu',
                ),
                onChanged: (v) => _localTag = v,
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _save,
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

