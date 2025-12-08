import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Material 3 Navigation Rail - For larger screens
class NavigationRailM3 extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int>? onDestinationSelected;
  final List<NavigationRailDestination> destinations;
  final Widget? trailing;
  final Widget? leading;

  const NavigationRailM3({
    Key? key,
    required this.selectedIndex,
    this.onDestinationSelected,
    required this.destinations,
    this.trailing,
    this.leading,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      destinations: destinations,
      trailing: trailing,
      leading: leading,
      labelType: NavigationRailLabelType.all,
      extended: false,
    );
  }
}

