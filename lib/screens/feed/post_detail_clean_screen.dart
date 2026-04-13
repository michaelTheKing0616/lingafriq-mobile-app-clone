import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'x_post_detail_screen.dart';

/// Alternate Stitch label; same production implementation as [`PostDetailScreen`].
class PostDetailCleanScreen extends ConsumerWidget {
  const PostDetailCleanScreen({super.key, required this.postId});

  final String postId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return XPostDetailScreen(postId: postId);
  }
}
