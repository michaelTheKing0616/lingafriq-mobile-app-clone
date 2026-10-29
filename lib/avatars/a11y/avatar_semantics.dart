import 'package:flutter/scheduler.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../l10n/generated/app_localizations.dart';
import '../cast/cast_contract.dart';
import '../cast/cast_session.dart';

/// System reduced-motion preference (idle loops off in Rive; blink keeps running).
bool avatarReducedMotionOf(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context);

/// English fallback when [BuildContext] has no localizations (unit tests).
String avatarSemanticsLabel({
  required String name,
  required String expression,
  required String activity,
}) {
  final readable = _readableExpression(expression);
  if (activity == 'idle') {
    return '$name looks $readable';
  }
  return '$name looks $readable and is $activity';
}

String avatarSemanticsLabelFromContext(
  BuildContext context, {
  required String name,
  required String expression,
  required String activity,
}) {
  final l10n = AppLocalizations.of(context);
  final readable = _readableExpression(expression);
  if (l10n == null) {
    return avatarSemanticsLabel(
      name: name,
      expression: expression,
      activity: activity,
    );
  }
  if (activity == 'idle') {
    return l10n.avatarSemanticsExpression(name, readable);
  }
  return l10n.avatarSemanticsExpressionActivity(name, readable, activity);
}

String avatarSemanticsLabelForSession(
  BuildContext context,
  CastSession session,
) {
  return avatarSemanticsLabelFromContext(
    context,
    name: castSpokenName(session.pose.preset),
    expression: session.pose.expression,
    activity: session.pose.activity,
  );
}

/// Applies [avatarReducedMotionOf] to a [CastSession] when dependencies change.
void syncAvatarReducedMotion(BuildContext context, CastSession session) {
  session.reducedMotion(avatarReducedMotionOf(context));
}

/// Screen-reader wrapper: live region label; announces once per expression/activity change.
class AvatarCastSemantics extends StatefulWidget {
  const AvatarCastSemantics({
    super.key,
    required this.session,
    required this.child,
  });

  final CastSession session;
  final Widget child;

  @override
  State<AvatarCastSemantics> createState() => _AvatarCastSemanticsState();
}

class _AvatarCastSemanticsState extends State<AvatarCastSemantics> {
  String? _lastAnnouncedLabel;
  bool _active = true;

  @override
  void deactivate() {
    _active = false;
    super.deactivate();
  }

  @override
  void activate() {
    super.activate();
    _active = true;
  }

  @override
  void initState() {
    super.initState();
    widget.session.addListener(_onSession);
  }

  @override
  void didUpdateWidget(AvatarCastSemantics oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session != widget.session) {
      oldWidget.session.removeListener(_onSession);
      widget.session.addListener(_onSession);
      _lastAnnouncedLabel = null;
    }
  }

  @override
  void dispose() {
    widget.session.removeListener(_onSession);
    super.dispose();
  }

  void _onSession() {
    // A shared session can notify while this element sits deactivated
    // (e.g. mid page swap); ancestor lookups are unsafe then.
    if (!mounted || !_active) return;
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((_) => _onSession());
      return;
    }
    final label = avatarSemanticsLabelForSession(context, widget.session);
    if (label == _lastAnnouncedLabel) return;
    _lastAnnouncedLabel = label;
    SemanticsService.sendAnnouncement(
      View.of(context),
      label,
      Directionality.of(context),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    syncAvatarReducedMotion(context, widget.session);
    final label = avatarSemanticsLabelForSession(context, widget.session);
    return Semantics(label: label, liveRegion: true, child: widget.child);
  }
}

String _readableExpression(String expression) {
  switch (expression) {
    case 'happy':
      return 'happy';
    case 'proud':
      return 'proud';
    case 'encouraging':
      return 'encouraging';
    case 'thinking':
      return 'thinking';
    case 'concerned':
      return 'concerned';
    case 'neutral':
      return 'neutral';
    default:
      return expression.replaceAll('_', ' ');
  }
}
