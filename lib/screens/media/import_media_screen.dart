import 'package:flutter/widgets.dart';

import 'import_media_screen_enhanced.dart';

/// Canonical media import entrypoint.
///
/// This screen intentionally delegates to the enhanced implementation so there
/// is a single production code path for upload/transcribe/generate flows.
class ImportMediaScreen extends StatelessWidget {
  const ImportMediaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ImportMediaScreenEnhanced();
  }
}
