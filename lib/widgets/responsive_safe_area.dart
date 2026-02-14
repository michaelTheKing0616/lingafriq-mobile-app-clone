import 'package:flutter/material.dart';

/// Short screen height threshold (e.g. 854x480, 4:3). Below this, top/bottom
/// insets are capped so content is not pushed too far up/down.
const double _kShortScreenHeightThreshold = 560;
const double _kShortScreenMaxVerticalInset = 12;

/// Safety zones (notch/island): industry standard 24–44px top, 20–34px bottom.
const double _kMinTopInset = 24;
const double _kMaxTopInset = 44;
const double _kMinBottomInset = 20;
const double _kMaxBottomInset = 34;

/// SafeArea that respects safety zones and works across all screen types.
/// Normal screens: top clamped to 24–44px, bottom to 20–34px.
/// Short screens (height <= 560): top/bottom capped at 12px to preserve vertical space.
class ResponsiveSafeArea extends StatelessWidget {
  final Widget child;
  final bool top;
  final bool bottom;
  final bool left;
  final bool right;

  const ResponsiveSafeArea({
    super.key,
    required this.child,
    this.top = true,
    this.bottom = true,
    this.left = true,
    this.right = true,
  });

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final height = media.size.height;
    final padding = media.padding;
    final viewPadding = media.viewPadding;

    double topInset = top ? (viewPadding.top > 0 ? viewPadding.top : padding.top) : 0;
    double bottomInset = bottom ? (viewPadding.bottom > 0 ? viewPadding.bottom : padding.bottom) : 0;
    double leftInset = left ? (viewPadding.left > 0 ? viewPadding.left : padding.left) : 0;
    double rightInset = right ? (viewPadding.right > 0 ? viewPadding.right : padding.right) : 0;

    if (height <= _kShortScreenHeightThreshold) {
      topInset = topInset > _kShortScreenMaxVerticalInset ? _kShortScreenMaxVerticalInset : topInset;
      bottomInset = bottomInset > _kShortScreenMaxVerticalInset ? _kShortScreenMaxVerticalInset : bottomInset;
    } else {
      if (topInset < _kMinTopInset) topInset = _kMinTopInset;
      if (topInset > _kMaxTopInset) topInset = _kMaxTopInset;
      if (bottomInset < _kMinBottomInset) bottomInset = _kMinBottomInset;
      if (bottomInset > _kMaxBottomInset) bottomInset = _kMaxBottomInset;
    }

    return Padding(
      padding: EdgeInsets.only(
        top: topInset,
        bottom: bottomInset,
        left: leftInset,
        right: rightInset,
      ),
      child: child,
    );
  }
}
