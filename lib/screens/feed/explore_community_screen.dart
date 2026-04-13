import 'package:flutter/material.dart';

import 'x_explore_screen.dart';

/// Stitch mockup `explore_community` — production trending feed + navigation to search.
///
/// Uses [StitchCommunityChatTheme] when registered on [ThemeData.extensions];
/// data is only from `GET /api/feed/explore/trending` (see [XExploreScreen]).
class ExploreCommunityScreen extends StatelessWidget {
  const ExploreCommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return XExploreScreen(
      appBarTitle: 'Explore community',
      stitchCommunityChrome: true,
      onSearchTap: () => Navigator.of(context).pushNamed('/search-community'),
    );
  }
}
