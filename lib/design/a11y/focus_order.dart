import 'package:flutter/widgets.dart';

/// Shell and onboarding order helper.
///
/// Wraps a column of focusable children and assigns [FocusTraversalOrder]
/// from top to bottom, so keyboard and switch navigation follow reading
/// order. The last child does not wrap into a loop that cannot escape.
/// Focus can leave the column.
class LingFocusOrder extends StatelessWidget {
  const LingFocusOrder({
    required this.children,
    super.key,
  });

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return FocusTraversalGroup(
      policy: _ColumnOrderPolicy(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (var index = 0; index < children.length; index++)
            FocusTraversalOrder(
              order: NumericFocusOrder(index.toDouble()),
              child: children[index],
            ),
        ],
      ),
    );
  }
}

/// Reading order inside the column, and no closed loop at either end.
class _ColumnOrderPolicy extends OrderedTraversalPolicy {
  @override
  bool next(FocusNode currentNode) => _step(currentNode, forward: true);

  @override
  bool previous(FocusNode currentNode) => _step(currentNode, forward: false);

  bool _step(FocusNode currentNode, {required bool forward}) {
    final List<FocusNode> members = _members(currentNode);
    final int index = members.indexOf(currentNode);
    if (index == -1) {
      return forward ? super.next(currentNode) : super.previous(currentNode);
    }
    final int nextIndex = forward ? index + 1 : index - 1;
    if (nextIndex >= 0 && nextIndex < members.length) {
      members[nextIndex].requestFocus();
      return true;
    }
    return _leave(currentNode, members: members, forward: forward);
  }

  List<FocusNode> _members(FocusNode currentNode) {
    final FocusScopeNode? scope = currentNode.nearestScope;
    if (scope == null) {
      return <FocusNode>[currentNode];
    }
    final List<FocusNode> inColumn = <FocusNode>[];
    for (final FocusNode node in scope.traversalDescendants) {
      if (!identical(FocusTraversalGroup.maybeOfNode(node), this)) {
        continue;
      }
      final BuildContext? nodeContext = node.context;
      if (nodeContext == null || FocusTraversalOrder.maybeOf(nodeContext) == null) {
        continue;
      }
      inColumn.add(node);
    }
    if (inColumn.isEmpty) {
      return <FocusNode>[currentNode];
    }
    return sortDescendants(inColumn, currentNode).toList();
  }

  bool _leave(
    FocusNode currentNode, {
    required List<FocusNode> members,
    required bool forward,
  }) {
    final FocusScopeNode? scope = currentNode.nearestScope;
    if (scope == null) {
      return false;
    }
    final List<FocusNode> sorted = ReadingOrderTraversalPolicy.sort(
      scope.traversalDescendants,
    ).toList();
    final int index = sorted.indexOf(currentNode);
    if (index == -1) {
      return false;
    }
    final int step = forward ? 1 : -1;
    for (int cursor = index + step; cursor >= 0 && cursor < sorted.length; cursor += step) {
      final FocusNode candidate = sorted[cursor];
      if (members.contains(candidate)) {
        continue;
      }
      candidate.requestFocus();
      return true;
    }
    return false;
  }
}
