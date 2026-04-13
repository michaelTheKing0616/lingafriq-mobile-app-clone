import 'package:flutter/material.dart';

import 'x_profile_screen.dart';

/// Stitch mockup `community_profile` — production feed profile (`GET /api/feed/profile`).
///
/// Uses [StitchCommunityChatTheme] when registered on [ThemeData.extensions].
class CommunityProfileScreen extends StatelessWidget {
  const CommunityProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const XProfileScreen(
      appBarTitle: 'Community profile',
      stitchCommunityChrome: true,
    );
  }
}
