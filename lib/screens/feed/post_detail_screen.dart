import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'x_post_detail_screen.dart';

/// Legacy Stitch name for [`XPostDetailScreen`] (`x-post-detail` route).
/// Uses production feed state — no mock thread data.
class PostDetailScreen extends ConsumerWidget {
  const PostDetailScreen({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return XPostDetailScreen(postId: postId);
  }
}
