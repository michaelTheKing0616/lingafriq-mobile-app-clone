import 'package:flutter/material.dart';
import 'package:lingafriq/screens/lens/see_it_in_the_wild.dart';

/// Learn object vocabulary lesson with a scoped Lens CTA (P7-915 AC2).
class LearnObjectLessonScreen extends StatelessWidget {
  const LearnObjectLessonScreen({
    super.key,
    required this.title,
    required this.language,
    required this.objectSetIds,
    this.preflight,
  });

  final String title;
  final String language;
  final List<String> objectSetIds;
  final LensAvailability? preflight;

  static const String findAtHomeLabel = 'Find these at home';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Objects in this lesson',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            ...objectSetIds.map(
              (id) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('• $id'),
              ),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => openLensEntry(
                context,
                intent: LensEntryIntent(
                  language: language,
                  scopedObjectSetIds: objectSetIds,
                ),
                preflight: preflight,
              ),
              icon: const Icon(Icons.home_outlined),
              label: const Text(findAtHomeLabel),
            ),
          ],
        ),
      ),
    );
  }
}
