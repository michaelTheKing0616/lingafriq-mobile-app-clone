import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lingafriq/services/learning/synthetic_voice_style_service.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

class SyntheticVoiceStylesScreen extends StatefulWidget {
  final String language;
  const SyntheticVoiceStylesScreen({super.key, required this.language});

  @override
  State<SyntheticVoiceStylesScreen> createState() => _SyntheticVoiceStylesScreenState();
}

class _SyntheticVoiceStylesScreenState extends State<SyntheticVoiceStylesScreen> {
  final _svc = SyntheticVoiceStyleService();
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _styles = const [];
  bool _enabled = false;
  String _styleId = 'natural';
  String? _disclaimer;

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
      final styles = await _svc.listStyles();
      final pref = await _svc.getPreference(language: widget.language);
      final preference = pref['preference'];
      final enabled = (preference is Map ? preference['enabled'] : null) == true;
      final styleId = (preference is Map ? preference['styleId'] : null)?.toString() ?? 'natural';
      setState(() {
        _styles = styles;
        _enabled = enabled;
        _styleId = styleId;
        _disclaimer = pref['disclaimer']?.toString();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _save({bool? enabled, String? styleId}) async {
    final nextEnabled = enabled ?? _enabled;
    final nextStyle = styleId ?? _styleId;
    setState(() => _loading = true);
    try {
      await _svc.setPreference(
        language: widget.language,
        enabled: nextEnabled,
        styleId: nextStyle,
      );
      setState(() {
        _enabled = nextEnabled;
        _styleId = nextStyle;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? PanAfricanColors.surfaceDark : PanAfricanColors.surfaceLight,
      appBar: AppBar(
        title: const Text('Tutor voice styles'),
        backgroundColor: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(16), child: Text(_error!)))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (_disclaimer != null && _disclaimer!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Text(_disclaimer!, style: PanAfricanTypography.bodyMedium(context)),
                      ),
                    const SizedBox(height: 14),
                    SwitchListTile.adaptive(
                      value: _enabled,
                      onChanged: (v) {
                        HapticFeedback.selectionClick();
                        _save(enabled: v);
                      },
                      title: const Text('Enable synthetic tutor voice styles'),
                      subtitle: const Text('Non-identifying voices only. No real-person cloning.'),
                    ),
                    const SizedBox(height: 12),
                    Text('Style', style: PanAfricanTypography.titleMedium(context)),
                    const SizedBox(height: 8),
                    for (final s in _styles) ...[
                      _StyleTile(
                        id: (s['id'] ?? '').toString(),
                        label: (s['label'] ?? '').toString(),
                        description: (s['description'] ?? '').toString(),
                        selected: _styleId == (s['id'] ?? '').toString(),
                        disabled: !_enabled,
                        onTap: () {
                          if (!_enabled) return;
                          final id = (s['id'] ?? '').toString();
                          if (id.isEmpty) return;
                          HapticFeedback.lightImpact();
                          _save(styleId: id);
                        },
                      ),
                      const SizedBox(height: 10),
                    ],
                  ],
                ),
    );
  }
}

class _StyleTile extends StatelessWidget {
  final String id;
  final String label;
  final String description;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  const _StyleTile({
    required this.id,
    required this.label,
    required this.description,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Opacity(
      opacity: disabled ? 0.55 : 1,
      child: InkWell(
        onTap: disabled ? null : onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: selected ? cs.primary : cs.outline.withOpacity(0.25), width: selected ? 2 : 1),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(selected ? Icons.check_circle_rounded : Icons.circle_outlined,
                  color: selected ? cs.primary : cs.onSurface.withOpacity(0.5)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: PanAfricanTypography.titleSmall(context)),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(description, style: PanAfricanTypography.bodySmall(context)),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

