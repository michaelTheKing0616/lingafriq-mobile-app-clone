import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/l10n/l10n_of.dart';
import 'package:lingafriq/learning/reminders/reminder_policy.dart';
import 'package:lingafriq/providers/notification_provider.dart';
import 'package:lingafriq/screens/tabs_view/home/home_tab_material3.dart'
    show ageTierStatusProvider;
import 'package:lingafriq/services/connectivity_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/timezone.dart' as tz;

/// Whether the OS lets us post notifications (null = unknown platform).
final reminderPermissionProvider = FutureProvider.autoDispose<bool>(
  (ref) async =>
      !(await Permission.notification.status).isDenied &&
      !(await Permission.notification.status).isPermanentlyDenied,
  retry: (_, _) => null,
);

final reminderOnlineProvider = FutureProvider.autoDispose<bool>(
  (ref) => ConnectivityService.hasInternet(),
);

/// Opens the OS settings page; swappable in tests.
final reminderOpenSettingsProvider = Provider<Future<bool> Function()>(
  (ref) => openAppSettings,
);

const _navy = Color(0xFF2E3A87);
const _gold = Color(0xFFFFC53D);
const _ink = Color(0xFF1F2340);
const _muted = Color(0xFF5B607A);
const _line = Color(0xFFE3E5EF);
const _soft = Color(0xFFF4F5FA);

/// Preset reminder slots (hour, minute); all outside quiet hours.
const _slots = [(7, 30), (12, 30), (18, 30)];

String _hhmm(int h, int m) =>
    '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

/// Moves a time out of quiet hours: late evening -> last allowed slot,
/// early morning -> first allowed slot.
(int, int) clampOutOfQuietHours(int h, int m) {
  if (!ReminderPolicy.inQuietHours(h)) return (h, m);
  return h >= ReminderPolicy.quietHourStart
      ? (ReminderPolicy.quietHourStart - 1, 30)
      : (ReminderPolicy.quietHourEnd, 0);
}

/// Study reminders (onboarding pack pattern 11 + Duolingo settings 14):
/// a live preview of the nudge, one master switch, time chips, a 24-hour
/// strip showing quiet hours, then what we remind about.
class ReminderSettingsScreen extends ConsumerStatefulWidget {
  const ReminderSettingsScreen({super.key});

  @override
  ConsumerState<ReminderSettingsScreen> createState() =>
      _ReminderSettingsScreenState();
}

class _ReminderSettingsScreenState
    extends ConsumerState<ReminderSettingsScreen> {
  String? _clash;

  /// Connectivity is only checked once the learner changes something:
  /// the offline note is about where that change is saved.
  bool _changed = false;
  void _touch() {
    if (!_changed) setState(() => _changed = true);
  }

  Future<void> _setTime(int h, int m) async {
    final (ch, cm) = clampOutOfQuietHours(h, m);
    _touch();
    setState(() => _clash = (ch, cm) == (h, m) ? null : _hhmm(ch, cm));
    HapticFeedback.selectionClick();
    await ref
        .read(notificationProvider.notifier)
        .updateReminderTime(Time(ch, cm));
  }

  Future<void> _custom() async {
    final t = ref.read(notificationProvider).reminderTime;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: t.hour, minute: t.minute),
    );
    if (picked != null) await _setTime(picked.hour, picked.minute);
  }

  @override
  Widget build(BuildContext context) {
    final l = l10nOf(context);
    final s = ref.watch(notificationProvider);
    final n = ref.read(notificationProvider.notifier);
    final perm = ref.watch(reminderPermissionProvider);
    final online =
        !_changed || (ref.watch(reminderOnlineProvider).value ?? true);
    final child =
        ref.watch(ageTierStatusProvider).value?.tier?.toLowerCase() == 'child';
    final on = s.studyRemindersEnabled;
    final h = s.reminderTime.hour, m = s.reminderTime.minute;
    final custom = !_slots.contains((h, m));
    final slotNames = [l.rmMorning, l.rmLunch, l.rmEvening];

    final children = <Widget>[
      _Preview(
        on: on,
        time: _hhmm(h, m),
        app: l.rmPreviewApp,
        body: l.rmPreviewBody,
        off: l.rmPreviewOff,
      ),
      const SizedBox(height: 12),
      if (perm.isLoading && !perm.hasError && !perm.hasValue)
        _Loading(label: l.rmLoading)
      else if (perm.hasError)
        _Banner(
          key: const Key('rm-check-error'),
          icon: Icons.error_outline_rounded,
          title: l.rmCheckError,
          action: l.rmRetry,
          actionKey: const Key('rm-retry'),
          onAction: () => ref.invalidate(reminderPermissionProvider),
        )
      else if (perm.value == false)
        _Banner(
          key: const Key('rm-blocked'),
          icon: Icons.notifications_off_rounded,
          title: l.rmBlockedTitle,
          body: l.rmBlockedBody,
          action: l.rmOpenSettings,
          actionKey: const Key('rm-open-settings'),
          onAction: () => ref.read(reminderOpenSettingsProvider)(),
        ),
      if (!online)
        _Note(
          key: const Key('rm-offline'),
          icon: Icons.cloud_off_rounded,
          text: l.rmOffline,
        ),
      if (child)
        _Note(
          key: const Key('rm-child'),
          icon: Icons.shield_moon_rounded,
          text: l.rmChild,
        ),
      _Card(
        child: SwitchListTile(
          key: const Key('rm-master'),
          value: on,
          activeThumbColor: Colors.white,
          activeTrackColor: _navy,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          title: Text(
            l.rmMaster,
            semanticsLabel: l.rmMasterA11y,
            style: const TextStyle(fontWeight: FontWeight.w800, color: _ink),
          ),
          subtitle: ExcludeSemantics(child: Text(l.rmMasterSub)),
          onChanged: (v) {
            HapticFeedback.selectionClick();
            _touch();
            n.setStudyRemindersEnabled(v);
          },
        ),
      ),
      _Section(l.rmWhen),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final (i, (sh, sm)) in _slots.indexed)
            _TimeChip(
              key: Key('rm-slot-$i'),
              label: slotNames[i],
              time: _hhmm(sh, sm),
              selected: (h, m) == (sh, sm),
              enabled: on,
              onTap: () => _setTime(sh, sm),
            ),
          _TimeChip(
            key: const Key('rm-custom'),
            label: l.rmCustom,
            time: custom ? _hhmm(h, m) : null,
            selected: custom,
            enabled: on,
            onTap: _custom,
          ),
        ],
      ),
      const SizedBox(height: 12),
      _DayStrip(hour: h + m / 60, on: on),
      const SizedBox(height: 6),
      Text(
        l.rmQuiet(
          _hhmm(ReminderPolicy.quietHourStart, 0),
          _hhmm(ReminderPolicy.quietHourEnd, 0),
        ),
        style: const TextStyle(fontSize: 13, color: _muted),
      ),
      if (_clash != null)
        _Note(
          key: const Key('rm-clash'),
          icon: Icons.nightlight_round,
          text: l.rmQuietClash(_clash!),
        ),
      const SizedBox(height: 8),
      _Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
          leading: const Icon(Icons.public_rounded, color: _navy),
          title: Text(l.rmTimezone),
          subtitle: Text(
            s.timezone,
            textDirection: TextDirection.ltr,
            textAlign: Directionality.of(context) == TextDirection.rtl
                ? TextAlign.right
                : TextAlign.left,
          ),
          trailing: TextButton(
            key: const Key('rm-tz'),
            style: TextButton.styleFrom(
              minimumSize: const Size(48, 48),
              foregroundColor: _navy,
            ),
            onPressed: () {
              HapticFeedback.selectionClick();
              _touch();
              n.updateTimezone(tz.local.name);
            },
            child: Text(l.rmUseDevice),
          ),
        ),
      ),
      _Section(l.rmAbout),
      _Card(
        child: Column(
          children: [
            SwitchListTile(
              key: const Key('rm-goal'),
              value: s.dailyGoalRemindersEnabled,
              activeTrackColor: _navy,
              activeThumbColor: Colors.white,
              secondary: const Icon(Icons.flag_rounded, color: _navy),
              title: Text(l.rmGoal),
              subtitle: Text(l.rmGoalSub),
              onChanged: on
                  ? (v) {
                      _touch();
                      n.toggleDailyGoalReminders(v);
                    }
                  : null,
            ),
            const Divider(height: 1, color: _line),
            SwitchListTile(
              key: const Key('rm-rhythm'),
              value: s.streakRemindersEnabled,
              activeTrackColor: _navy,
              activeThumbColor: Colors.white,
              secondary: const Icon(Icons.celebration_rounded, color: _navy),
              title: Text(l.rmRhythm),
              subtitle: Text(l.rmRhythmSub),
              onChanged: on
                  ? (v) {
                      _touch();
                      n.toggleStreakReminders(v);
                    }
                  : null,
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      Row(
        children: [
          const Icon(Icons.cloud_done_rounded, size: 18, color: _muted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l.rmSync,
              style: const TextStyle(fontSize: 13, color: _muted),
            ),
          ),
        ],
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          key: const Key('rm-back'),
          tooltip: l.rmBack,
          icon: const BackButtonIcon(),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(
          l.rmTitle,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListView(
              key: const Key('rm-list'),
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({
    required this.on,
    required this.time,
    required this.app,
    required this.body,
    required this.off,
  });
  final bool on;
  final String time, app, body, off;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const Key('rm-preview'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _navy,
        borderRadius: BorderRadius.circular(24),
      ),
      child: AnimatedOpacity(
        opacity: on ? 1 : 0.85,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 200),
        child: on
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 10),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _gold,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.record_voice_over_rounded,
                            color: _navy,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                app,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: _muted,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                body,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: _ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    key: const Key('rm-preview-time'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _gold,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.alarm_rounded, size: 18, color: _ink),
                        const SizedBox(width: 6),
                        Text(
                          time,
                          textDirection: TextDirection.ltr,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            color: _ink,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Row(
                children: [
                  const Icon(
                    Icons.notifications_paused_rounded,
                    color: _gold,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      off,
                      style: const TextStyle(color: Colors.white, fontSize: 15),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({
    super.key,
    required this.label,
    required this.time,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });
  final String label;
  final String? time;
  final bool selected, enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      child: Material(
        color: selected ? _navy : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: selected ? _navy : _line, width: 2),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: enabled ? onTap : null,
          child: Container(
            constraints: const BoxConstraints(minHeight: 56, minWidth: 96),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Opacity(
              opacity: enabled ? 1 : 0.45,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: selected ? Colors.white : _ink,
                    ),
                  ),
                  if (time != null)
                    Text(
                      time!,
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        fontSize: 13,
                        color: selected ? _gold : _muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 24-hour strip: quiet hours shaded navy, the reminder a gold pin.
/// Always laid out midnight -> midnight left to right (a clock, not text).
class _DayStrip extends StatelessWidget {
  const _DayStrip({required this.hour, required this.on});
  final double hour;
  final bool on;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          children: [
            SizedBox(
              key: const Key('rm-strip'),
              height: 28,
              child: CustomPaint(
                size: Size.infinite,
                painter: _StripPainter(hour: hour, on: on),
              ),
            ),
            const SizedBox(height: 2),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('00', style: TextStyle(fontSize: 11, color: _muted)),
                Text('06', style: TextStyle(fontSize: 11, color: _muted)),
                Text('12', style: TextStyle(fontSize: 11, color: _muted)),
                Text('18', style: TextStyle(fontSize: 11, color: _muted)),
                Text('24', style: TextStyle(fontSize: 11, color: _muted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StripPainter extends CustomPainter {
  _StripPainter({required this.hour, required this.on});
  final double hour;
  final bool on;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, y = size.height / 2;
    final r = RRect.fromLTRBR(0, y - 6, w, y + 6, const Radius.circular(6));
    canvas.drawRRect(r, Paint()..color = _soft);
    final quiet = Paint()..color = _navy.withValues(alpha: 0.75);
    canvas.save();
    canvas.clipRRect(r);
    canvas.drawRect(
      Rect.fromLTRB(0, y - 6, w * ReminderPolicy.quietHourEnd / 24, y + 6),
      quiet,
    );
    canvas.drawRect(
      Rect.fromLTRB(w * ReminderPolicy.quietHourStart / 24, y - 6, w, y + 6),
      quiet,
    );
    canvas.restore();
    if (on) {
      final x = w * hour / 24;
      canvas.drawCircle(Offset(x, y), 11, Paint()..color = Colors.white);
      canvas.drawCircle(Offset(x, y), 8, Paint()..color = _gold);
    }
  }

  @override
  bool shouldRepaint(_StripPainter o) => o.hour != hour || o.on != on;
}

class _Section extends StatelessWidget {
  const _Section(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 20, 4, 10),
    child: Semantics(
      header: true,
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w800,
          color: _ink,
        ),
      ),
    ),
  );
}

class _Card extends StatelessWidget {
  const _Card({required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 8),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: _line, width: 2),
    ),
    clipBehavior: Clip.antiAlias,
    child: Material(color: Colors.white, child: child),
  );
}

class _Note extends StatelessWidget {
  const _Note({super.key, required this.icon, required this.text});
  final IconData icon;
  final String text;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(top: 8),
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: _soft,
      borderRadius: BorderRadius.circular(14),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: _navy),
        const SizedBox(width: 10),
        Expanded(
          child: Text(text, style: const TextStyle(fontSize: 14, color: _ink)),
        ),
      ],
    ),
  );
}

class _Banner extends StatelessWidget {
  const _Banner({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    required this.action,
    required this.actionKey,
    required this.onAction,
  });
  final IconData icon;
  final String title, action;
  final String? body;
  final Key actionKey;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF4D6),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFFE8C46A)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF8C5A00)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  color: _ink,
                  fontSize: 15,
                ),
              ),
            ),
          ],
        ),
        if (body != null) ...[
          const SizedBox(height: 4),
          Text(body!, style: const TextStyle(color: _ink, fontSize: 14)),
        ],
        const SizedBox(height: 8),
        FilledButton(
          key: actionKey,
          style: FilledButton.styleFrom(
            backgroundColor: _navy,
            minimumSize: const Size(48, 48),
          ),
          onPressed: onAction,
          child: Text(action),
        ),
      ],
    ),
  );
}

class _Loading extends StatelessWidget {
  const _Loading({required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Semantics(
    key: const Key('rm-loading'),
    label: label,
    liveRegion: true,
    child: ExcludeSemantics(
      child: Container(
        height: 72,
        decoration: BoxDecoration(
          color: _soft,
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: _line,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FractionallySizedBox(
                    widthFactor: 0.7,
                    child: Container(height: 12, color: _line),
                  ),
                  const SizedBox(height: 8),
                  FractionallySizedBox(
                    widthFactor: 0.4,
                    child: Container(height: 10, color: _line),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
