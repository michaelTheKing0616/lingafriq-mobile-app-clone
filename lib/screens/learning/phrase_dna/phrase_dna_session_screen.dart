import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lingafriq/services/learning/phrase_dna_service.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

class PhraseDnaSessionScreen extends StatefulWidget {
  final String templateId;
  final String language;
  final String title;
  final String pattern;
  final String? dialectTag;

  const PhraseDnaSessionScreen({
    super.key,
    required this.templateId,
    required this.language,
    required this.title,
    required this.pattern,
    this.dialectTag,
  });

  @override
  State<PhraseDnaSessionScreen> createState() => _PhraseDnaSessionScreenState();
}

class _PhraseDnaSessionScreenState extends State<PhraseDnaSessionScreen> {
  final _service = PhraseDnaService();
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _session;
  final Map<String, TextEditingController> _controllers = {};
  String? _resultText;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _resultText = null;
    });
    try {
      final session = await _service.start(
        templateId: widget.templateId,
        language: widget.language,
        dialectTag: widget.dialectTag,
      );
      final template = session['template'];
      final slots = (template is Map ? template['slots'] : null);
      if (slots is List) {
        for (final s in slots) {
          if (s is! Map) continue;
          final key = (s['key'] ?? '').toString();
          if (key.isEmpty) continue;
          _controllers[key] = TextEditingController();
        }
      }
      setState(() {
        _session = session;
        _loading = false;
      });
    } catch (e) {
      // Offline-first fallback: build a minimal session from cached template.
      try {
        final cached = await _service.getCachedTemplate(
          language: widget.language,
          templateId: widget.templateId,
        );
        final slots = (cached?['slots'] is List) ? (cached!['slots'] as List) : const [];
        for (final s in slots) {
          if (s is! Map) continue;
          final key = (s['key'] ?? '').toString();
          if (key.isEmpty) continue;
          _controllers[key] = TextEditingController();
        }
        setState(() {
          _session = {
            'template': cached ?? {'slots': const []},
            'prompt': 'Offline mode: fill the slots and submit when online.',
            'suggestions': const {},
          };
          _loading = false;
          _error = null;
        });
      } catch (_) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  String _buildPhrase() {
    var built = widget.pattern;
    for (final entry in _controllers.entries) {
      final v = entry.value.text.trim();
      built = built.replaceAll('{${entry.key}}', v.isEmpty ? '{${entry.key}}' : v);
    }
    return built.trim();
  }

  Future<void> _submit() async {
    final built = _buildPhrase();
    final slots = <String, String>{};
    for (final e in _controllers.entries) {
      if (e.value.text.trim().isNotEmpty) {
        slots[e.key] = e.value.text.trim();
      }
    }
    setState(() => _resultText = null);
    final res = await _service.submit(
      language: widget.language,
      templateId: widget.templateId,
      dialectTag: widget.dialectTag,
      built: built,
      slots: slots,
    );

    final queued = res['queued'] == true;
    final wellFormed = res['wellFormed'] == true;
    final score = res['score'];
    final feedback = (res['feedback'] ?? '').toString();
    final corrections = res['corrections'];
    final corrList = corrections is List ? corrections.map((e) => e.toString()).where((e) => e.isNotEmpty).toList() : <String>[];

    final buffer = StringBuffer();
    buffer.writeln(queued ? 'Saved offline (queued)' : 'Graded');
    buffer.writeln('Well-formed: ${wellFormed ? 'Yes' : 'No'}');
    if (score != null) buffer.writeln('Score: $score');
    if (feedback.isNotEmpty) {
      buffer.writeln('\nFeedback:\n$feedback');
    }
    if (corrList.isNotEmpty) {
      buffer.writeln('\nCorrections:');
      for (final c in corrList) {
        buffer.writeln('- $c');
      }
    }
    setState(() => _resultText = buffer.toString().trim());
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark ? PanAfricanColors.surfaceDark : PanAfricanColors.surfaceLight,
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              HapticFeedback.lightImpact();
              _controllers.clear();
              _load();
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(_error!),
                  ),
                )
              : _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final template = (_session?['template'] is Map) ? (_session!['template'] as Map) : const {};
    final slots = template['slots'];
    final slotList = slots is List ? slots : const [];
    final prompt = (_session?['prompt'] ?? '').toString();
    final suggestions = (_session?['suggestions'] is Map) ? (_session!['suggestions'] as Map) : const {};

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Pattern', style: PanAfricanTypography.titleMedium(context)),
              const SizedBox(height: 6),
              Text(
                widget.pattern,
                style: PanAfricanTypography.bodyMedium(context).copyWith(fontFamily: 'monospace'),
              ),
              if (prompt.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(prompt, style: PanAfricanTypography.bodySmall(context)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 14),
        for (final s in slotList) ...[
          if (s is Map) _slotField(context, s, suggestions),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: PanAfricanShadows.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Built phrase', style: PanAfricanTypography.titleMedium(context)),
              const SizedBox(height: 6),
              Text(_buildPhrase(), style: PanAfricanTypography.bodyMedium(context)),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    _submit();
                  },
                  icon: const Icon(Icons.check_circle_rounded),
                  label: const Text('Submit for grading'),
                ),
              ),
            ],
          ),
        ),
        if (_resultText != null) ...[
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: PanAfricanShadows.sm,
            ),
            child: Text(_resultText!, style: PanAfricanTypography.bodyMedium(context)),
          ),
        ],
      ],
    );
  }

  Widget _slotField(BuildContext context, Map s, Map suggestions) {
    final key = (s['key'] ?? '').toString();
    final label = (s['label'] ?? key).toString();
    final desc = (s['description'] ?? '').toString();
    final controller = _controllers[key] ??= TextEditingController();
    final sug = suggestions[key];
    final sugList = sug is List ? sug.map((e) => e.toString()).where((e) => e.isNotEmpty).toList() : <String>[];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: PanAfricanShadows.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: PanAfricanTypography.titleSmall(context)),
          if (desc.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(desc, style: PanAfricanTypography.bodySmall(context)),
          ],
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: 'Enter $label',
              border: const OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
          if (sugList.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: sugList.take(6).map((v) {
                return ActionChip(
                  label: Text(v),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    controller.text = v;
                    setState(() {});
                  },
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

