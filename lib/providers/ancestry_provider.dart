import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/api_provider.dart';

/// Loads the current user's ancestry graph from backend.
///
/// Backward compatible: uses `/api/ancestry/me` so clients don't need to know
/// their Mongo ObjectId. Falls back in UI if this fails (offline/unauth).
final ancestryMeProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return await ref.read(apiProvider.notifier).getAncestryMe();
});

