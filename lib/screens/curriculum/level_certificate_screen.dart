import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

/// Light MVP level completion certificate (share text).
class LevelCertificateScreen extends StatelessWidget {
  const LevelCertificateScreen({
    super.key,
    required this.language,
    required this.level,
    required this.lessonsCompleted,
  });

  final String language;
  final String level;
  final int lessonsCompleted;

  @override
  Widget build(BuildContext context) {
    final body = '''
LingAfriq Certificate of Progress

Language: $language
Level: $level
Lessons completed: $lessonsCompleted

This certifies meaningful progress on the authentic LingAfriq curriculum path.
Speak boldly before speaking perfectly.
''';

    return Scaffold(
      appBar: AppBar(title: const Text('Level certificate')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(Icons.workspace_premium, size: 72, color: PanAfricanColors.primary),
            const SizedBox(height: 16),
            Text(
              '$language — $level',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(body, style: Theme.of(context).textTheme.bodyMedium),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => Share.share(body, subject: 'LingAfriq $level certificate'),
              icon: const Icon(Icons.share_outlined),
              label: const Text('Share certificate'),
            ),
          ],
        ),
      ),
    );
  }
}
