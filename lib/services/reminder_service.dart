// One reminder per inactivity episode. It opens a 2-minute session.
// This file does not call a platform notification plugin. With no sender,
// or when the sender declines, the reminder stays pending.
const int kInactivitySessionMinutes = 2;

const String kInactivityReminderTitle = 'A 2-minute session is ready';

const String kInactivityReminderBody = 'Open it for one short practice.';

/// The payload a sender would hand off. [sessionMinutes] is the session
/// the reminder opens.
class InactivityReminderRequest {
  const InactivityReminderRequest({
    required this.episodeId,
    required this.sessionMinutes,
    required this.title,
    required this.body,
  });

  final String episodeId;
  final int sessionMinutes;
  final String title;
  final String body;

  bool opensSessionOf(int minutes) => sessionMinutes == minutes;
}

/// Returns true only when the notification was handed off.
/// False, or a thrown error, means it was not delivered.
typedef InactivityReminderSender =
    Future<bool> Function(InactivityReminderRequest request);

/// A reminder recorded for one inactivity episode.
class InactivityReminder {
  const InactivityReminder({
    required this.episodeId,
    required this.sessionMinutes,
    required this.title,
    required this.body,
    required this.delivered,
  });

  final String episodeId;
  final int sessionMinutes;
  final String title;
  final String body;

  /// True only after a sender accepts the reminder.
  final bool delivered;

  /// Recorded, and not delivered.
  bool get pending => !delivered;

  bool opensSessionOf(int minutes) => sessionMinutes == minutes;
}

/// Records at most one reminder for each inactivity episode the caller names.
///
/// The caller supplies [considerInactivity]'s [inactive] flag and episode id.
/// This type does not invent an episode, and it does not read a device clock.
class ReminderService {
  ReminderService({this.sender});

  final InactivityReminderSender? sender;
  final List<InactivityReminder> _reminders = <InactivityReminder>[];
  final Set<String> _episodes = <String>{};

  /// Reminders recorded so far, including ones that were not delivered.
  List<InactivityReminder> get reminders =>
      List<InactivityReminder>.unmodifiable(_reminders);

  /// Records one reminder when [inactive] is true and [episodeId] is new.
  ///
  /// Returns that reminder. Returns null when the learner is not inactive,
  /// when [episodeId] is blank, or when this episode already has a reminder.
  /// A second call for the same episode does not send again.
  /// A different episode may record one more.
  ///
  /// [delivered] is false when no sender is set, when the sender returns
  /// false, or when the sender throws. That record is pending.
  Future<InactivityReminder?> considerInactivity({
    required bool inactive,
    required String episodeId,
  }) async {
    final String id = episodeId.trim();
    if (!inactive || id.isEmpty) return null;
    if (!_episodes.add(id)) return null;

    final InactivityReminderRequest request = InactivityReminderRequest(
      episodeId: id,
      sessionMinutes: kInactivitySessionMinutes,
      title: kInactivityReminderTitle,
      body: kInactivityReminderBody,
    );

    var delivered = false;
    final InactivityReminderSender? notify = sender;
    if (notify != null) {
      try {
        delivered = await notify(request);
      } on Object {
        delivered = false;
      }
    }

    final InactivityReminder reminder = InactivityReminder(
      episodeId: id,
      sessionMinutes: request.sessionMinutes,
      title: request.title,
      body: request.body,
      delivered: delivered,
    );
    _reminders.add(reminder);
    return reminder;
  }
}
