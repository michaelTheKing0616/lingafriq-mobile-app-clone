import 'package:flutter/material.dart';
import 'package:lingafriq/services/quiz/can_do_grader.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

/// Short conversation task. Finish runs [gradeConversation] and shows each
/// can-do as met, not met, or unsure. An unavailable scorer stores nothing.
class ConversationTaskItem extends StatefulWidget {
  const ConversationTaskItem({
    super.key,
    required this.prompt,
    required this.canDoIds,
    required this.turns,
    required this.scorerAvailable,
  });

  final String prompt;
  final List<String> canDoIds;
  final List<EvidenceTurn> turns;
  final bool scorerAvailable;

  @override
  State<ConversationTaskItem> createState() => _ConversationTaskItemState();
}

class _ConversationTaskItemState extends State<ConversationTaskItem> {
  String _phase = 'task';
  ConversationGrade? _grade;

  void _markInProgress() {
    if (_grade != null || _phase != 'task') return;
    setState(() => _phase = 'in-progress');
  }

  void _finish() {
    if (_grade != null) return;
    final grade = gradeConversation(
      canDoIds: widget.canDoIds,
      turns: widget.turns,
      scorerAvailable: widget.scorerAvailable,
    );
    setState(() {
      _grade = grade;
      _phase = grade.phase;
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'met':
        return PanAfricanColors.success;
      case 'not-met':
        return PanAfricanColors.error;
      default:
        return PanAfricanColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final grade = _grade;
    final verdicts = grade != null && grade.stored
        ? grade.results
        : const <CanDoResult>[];
    return Semantics(
      container: true,
      explicitChildNodes: true,
      label: 'item.conv',
      child: Column(
        key: ValueKey<String>('phase-$_phase'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            ConversationCopy.conv,
            style: TextStyle(
              color: PanAfricanColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextButton(
            onPressed: grade == null && _phase == 'task'
                ? _markInProgress
                : null,
            child: Text(widget.prompt),
          ),
          for (final turn in widget.turns)
            Padding(
              padding: EdgeInsets.only(top: PanAfricanSpacing.xxs),
              child: Text(
                turn.text,
                style: TextStyle(
                  color: _phase == 'in-progress'
                      ? PanAfricanColors.primary
                      : PanAfricanColors.textSecondary,
                ),
              ),
            ),
          Semantics(
            container: true,
            explicitChildNodes: true,
            label: 'item.candos',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: PanAfricanSpacing.sm),
                  child: const Text(
                    ConversationCopy.candos,
                    style: TextStyle(
                      color: PanAfricanColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (verdicts.isEmpty)
                  for (final id in widget.canDoIds)
                    Padding(
                      padding: EdgeInsets.only(top: PanAfricanSpacing.xxs),
                      child: Text(id),
                    ),
                for (final result in verdicts) ...[
                  Padding(
                    padding: EdgeInsets.only(top: PanAfricanSpacing.xs),
                    child: Text(result.canDoId),
                  ),
                  Text(
                    result.status,
                    style: TextStyle(
                      color: _statusColor(result.status),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (result.status == 'unsure')
                    Text(
                      ConversationCopy.unsure,
                      style: const TextStyle(color: PanAfricanColors.warning),
                    ),
                  for (final id in result.evidenceTurnIds)
                    Text(
                      id,
                      style: const TextStyle(
                        color: PanAfricanColors.textSecondary,
                      ),
                    ),
                ],
              ],
            ),
          ),
          if (grade != null && !grade.stored)
            Padding(
              padding: EdgeInsets.only(top: PanAfricanSpacing.sm),
              child: const Text(
                ConversationCopy.unavailable,
                style: TextStyle(color: PanAfricanColors.warning),
              ),
            ),
          Padding(
            padding: EdgeInsets.only(top: PanAfricanSpacing.md),
            child: TextButton(
              onPressed: grade == null ? _finish : null,
              child: const Text('Finish'),
            ),
          ),
        ],
      ),
    );
  }
}
