import 'package:flutter/material.dart';
import 'package:lingafriq/design/components/ling_state.dart';
import 'package:lingafriq/design/tokens.g.dart';

/// One-line body probe. A loaded list row or card with this label stays
/// within 4 dp of the bone, because the bone uses the same strut.
const String lingSkeletonProbe = 'Save';

/// Placeholder rows. Each bone uses the list row's radius, padding, and
/// minimum height. The fill is the container role. There is no sweep.
class LingSkeletonList extends StatelessWidget {
  const LingSkeletonList({this.itemCount = 3, super.key});

  final int itemCount;

  static const String semanticsLabel = 'Loading';

  @override
  Widget build(BuildContext context) {
    assert(itemCount > 0, 'A skeleton list needs at least one row');
    return Semantics(
      container: true,
      label: semanticsLabel,
      child: ExcludeSemantics(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            for (int index = 0; index < itemCount; index++) ...<Widget>[
              if (index > 0) const SizedBox(height: LingAfriqTokens.spacing12),
              _SkeletonBone(
                key: ValueKey<String>('ling-skeleton-list-box-$index'),
                radius: const BorderRadius.all(
                  Radius.circular(LingAfriqTokens.radiussm),
                ),
                child: const _ListStrut(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Placeholder card. The bone uses the card's radius, padding, and a
/// one-line body strut so the height tracks the loaded card.
class LingSkeletonCard extends StatelessWidget {
  const LingSkeletonCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: LingSkeletonList.semanticsLabel,
      child: const ExcludeSemantics(
        child: _SkeletonBone(
          radius: BorderRadius.all(Radius.circular(LingAfriqTokens.radiusmd)),
          child: _CardStrut(),
        ),
      ),
    );
  }
}

class _ListStrut extends StatelessWidget {
  const _ListStrut();

  @override
  Widget build(BuildContext context) {
    final LingPalette palette = LingPalette.of(Theme.of(context).brightness);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: LingAfriqTokens.spacing16,
        vertical: LingAfriqTokens.spacing12,
      ),
      child: Opacity(
        opacity: 0,
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                lingSkeletonProbe,
                style: lingBody(palette.onSurface),
                softWrap: true,
                overflow: TextOverflow.visible,
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: palette.onSurface,
              size: LingAfriqTokens.spacing24,
            ),
          ],
        ),
      ),
    );
  }
}

class _CardStrut extends StatelessWidget {
  const _CardStrut();

  @override
  Widget build(BuildContext context) {
    final LingPalette palette = LingPalette.of(Theme.of(context).brightness);
    return Padding(
      padding: const EdgeInsets.all(LingAfriqTokens.spacing16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Opacity(
            opacity: 0,
            child: Text(
              lingSkeletonProbe,
              style: lingBody(palette.onSurface),
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }
}

/// Flat container fill. Reduced motion holds the container role. When motion
/// is allowed, opacity eases between the surface role and the container role.
/// The whole bone changes together. Nothing travels across it.
class _SkeletonBone extends StatefulWidget {
  const _SkeletonBone({required this.radius, required this.child, super.key});

  final BorderRadius radius;
  final Widget child;

  @override
  State<_SkeletonBone> createState() => _SkeletonBoneState();
}

class _SkeletonBoneState extends State<_SkeletonBone>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final CurvedAnimation _curve;

  @override
  void initState() {
    super.initState();
    final int ms = LingAfriqTokens.motionProductSlow;
    assert(ms > 0 && ms <= 300, 'product motion must stay within 300 ms');
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: ms),
    );
    _curve = CurvedAnimation(parent: _controller, curve: lingProductCurve);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool reduced = MediaQuery.disableAnimationsOf(context);
    if (reduced) {
      _controller.stop();
      return;
    }
    if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool reduced = MediaQuery.disableAnimationsOf(context);
    final LingPalette palette = LingPalette.of(Theme.of(context).brightness);
    if (reduced) {
      return _fill(palette.surfaceContainer);
    }
    return AnimatedBuilder(
      animation: _curve,
      builder: (BuildContext context, Widget? child) {
        final double mix = 0.55 + (0.45 * _curve.value);
        final Color color = Color.lerp(
          palette.surface,
          palette.surfaceContainer,
          mix,
        )!;
        return _fill(color);
      },
    );
  }

  Widget _fill(Color color) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: LingAfriqTokens.spacing48,
        minHeight: LingAfriqTokens.spacing48,
      ),
      child: Material(
        color: color,
        surfaceTintColor: color,
        elevation: LingAfriqTokens.elevationLightnone,
        borderRadius: widget.radius,
        child: widget.child,
      ),
    );
  }
}
