import 'package:flutter/material.dart';

/// Reports whether [child] intersects the nearest scroll viewport.
class ViewportGate extends StatefulWidget {
  const ViewportGate({super.key, required this.onVisible, required this.child});

  final ValueChanged<bool> onVisible;
  final Widget child;

  @override
  State<ViewportGate> createState() => _ViewportGateState();
}

class _ViewportGateState extends State<ViewportGate> {
  bool? _visible;
  ScrollPosition? _position;

  bool _checkScheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = Scrollable.maybeOf(context)?.position;
    if (next != _position) {
      _position?.removeListener(_schedule);
      _position = next;
      _position?.addListener(_schedule);
    }
    _schedule();
  }

  @override
  void dispose() {
    _position?.removeListener(_schedule);
    super.dispose();
  }

  void _schedule() {
    if (_checkScheduled) return;
    _checkScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkScheduled = false;
      _check();
    });
  }

  void _check() {
    if (!mounted) return;
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.attached || !box.hasSize) return;
    final scrollable = Scrollable.maybeOf(context);
    if (scrollable == null) {
      _report(true);
      return;
    }
    final viewportObject = scrollable.context.findRenderObject();
    if (viewportObject is! RenderBox || !viewportObject.hasSize) {
      _report(true);
      return;
    }
    final origin = box.localToGlobal(Offset.zero, ancestor: viewportObject);
    final childRect = origin & box.size;
    final viewRect = Offset.zero & viewportObject.size;
    _report(childRect.overlaps(viewRect));
  }

  void _report(bool visible) {
    if (_visible == visible) return;
    _visible = visible;
    widget.onVisible(visible);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
