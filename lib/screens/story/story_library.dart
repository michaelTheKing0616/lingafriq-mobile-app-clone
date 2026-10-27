/// P6-027: shared story library — pending never listed publicly.
library;

import 'story_types.dart';

enum SharedStoryApproval { pendingReview, approved }

class SharedStoryListing {
  const SharedStoryListing({
    required this.storyId,
    required this.session,
    required this.approval,
  });

  final String storyId;
  final StorySession session;
  final SharedStoryApproval approval;
}

/// In-memory mirror of server shared-library gate (tests + offline UI).
class StoryLibraryStore {
  StoryLibraryStore._();
  static final StoryLibraryStore instance = StoryLibraryStore._();

  final Map<String, SharedStoryListing> _byId = {};

  void reset() => _byId.clear();

  void submitForSharedLibrary(StorySession session) {
    _byId[session.storyId] = SharedStoryListing(
      storyId: session.storyId,
      session: session,
      approval: SharedStoryApproval.pendingReview,
    );
  }

  void markApproved(String storyId) {
    final row = _byId[storyId];
    if (row == null) return;
    _byId[storyId] = SharedStoryListing(
      storyId: storyId,
      session: StorySession(
        storyId: row.session.storyId,
        title: row.session.title,
        storyText: row.session.storyText,
        glosses: row.session.glosses,
        comprehension: row.session.comprehension,
        language: row.session.language,
        aiGeneratedLabel: row.session.aiGeneratedLabel,
        visibility: StoryVisibility.sharedApproved,
      ),
      approval: SharedStoryApproval.approved,
    );
  }

  List<SharedStoryListing> listPublicShared({String? language}) {
    return _byId.values
        .where((row) => row.approval == SharedStoryApproval.approved)
        .where((row) =>
            language == null ||
            row.session.language.toLowerCase() == language.toLowerCase())
        .toList(growable: false);
  }
}
