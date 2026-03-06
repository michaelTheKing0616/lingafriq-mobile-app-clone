import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/wa_status_provider.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

class WaStatusCreateScreen extends ConsumerStatefulWidget {
  const WaStatusCreateScreen({super.key});

  @override
  ConsumerState<WaStatusCreateScreen> createState() => _WaStatusCreateScreenState();
}

class _WaStatusCreateScreenState extends ConsumerState<WaStatusCreateScreen> {
  final _textController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark ? PanAfricanGradients.darkSurface : PanAfricanGradients.savannaGold,
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: _submitting ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Create status',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? PanAfricanColors.surfaceContainerDark : PanAfricanColors.cardLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'What are you learning right now?',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _textController,
                      maxLines: 6,
                      maxLength: 300,
                      decoration: InputDecoration(
                        hintText: 'Share a phrase, progress win, or quick voice note caption...',
                        filled: true,
                        fillColor: isDark
                            ? PanAfricanColors.surfaceContainerHighDark
                            : PanAfricanColors.surfaceContainerLowLight,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.timer_outlined, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Auto-expires in 24 hours',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: _submitting
                    ? null
                    : () async {
                        if (_textController.text.trim().isEmpty) return;
                        setState(() => _submitting = true);
                        final ok = await ref.read(waStatusProvider.notifier).createStatus(
                              mediaType: 'text',
                              text: _textController.text.trim(),
                            );
                        if (!mounted) return;
                        setState(() => _submitting = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(ok ? 'Status posted' : 'Could not post status')),
                        );
                        if (ok) Navigator.pop(context);
                      },
                icon: _submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(_submitting ? 'Posting...' : 'Post status'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
