import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lingafriq/services/learning/phrase_dna_service.dart';
import 'package:lingafriq/widgets/animations/smooth_transitions.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'phrase_dna_session_screen.dart';

class PhraseDnaTemplatesScreen extends StatefulWidget {
  final String? language;
  const PhraseDnaTemplatesScreen({super.key, this.language});

  @override
  State<PhraseDnaTemplatesScreen> createState() =>
      _PhraseDnaTemplatesScreenState();
}

class _PhraseDnaTemplatesScreenState extends State<PhraseDnaTemplatesScreen> {
  final _service = PhraseDnaService();
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.listTemplates(language: widget.language);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark
          ? PanAfricanColors.surfaceDark
          : PanAfricanColors.surfaceLight,
      appBar: AppBar(
        title: const Text('Phrase DNA'),
        backgroundColor: isDark
            ? PanAfricanColors.cardDark
            : PanAfricanColors.cardLight,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Failed to load templates.\n${snap.error}'),
              ),
            );
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text(
                  'No Phrase DNA templates yet for this language.\n\n'
                  'If you are staff/admin, create templates via the API and they will appear here.',
                  style: PanAfricanTypography.bodyMedium(context),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final t = items[i];
              final id = (t['_id'] ?? t['id'] ?? '').toString();
              final title = (t['title'] ?? '').toString();
              final desc = (t['description'] ?? '').toString();
              final language = (t['language'] ?? '').toString();
              final pattern = (t['pattern'] ?? '').toString();
              return InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  if (id.isEmpty) return;
                  HapticFeedback.selectionClick();
                  Navigator.of(context).push(
                    SmoothPageRoute.platform(
                      child: PhraseDnaSessionScreen(
                        templateId: id,
                        language: language,
                        title: title.isEmpty ? 'Phrase DNA' : title,
                        pattern: pattern,
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? PanAfricanColors.cardDark
                        : PanAfricanColors.cardLight,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: PanAfricanShadows.sm,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: PanAfricanTypography.titleMedium(context),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        pattern,
                        style: PanAfricanTypography.bodyMedium(context)
                            .copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontFamily: 'monospace',
                            ),
                      ),
                      if (desc.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          desc,
                          style: PanAfricanTypography.bodySmall(context),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
