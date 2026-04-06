import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../../config/api_contract.dart';
import '../../models/feed_post_model.dart';
import '../../providers/x_feed_provider.dart';
import '../../utils/api_service.dart';
import '../../utils/modern_griot_design_system.dart';
import '../../widgets/griot/griot_widgets.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Thread view: root post, replies from `/api/feed/posts/:id/replies`, and reply composer.
class FeedPostThreadScreen extends ConsumerStatefulWidget {
  const FeedPostThreadScreen({
    super.key,
    required this.postId,
    this.preview,
  });

  final String postId;
  final FeedPostModel? preview;

  @override
  ConsumerState<FeedPostThreadScreen> createState() => _FeedPostThreadScreenState();
}

class _FeedPostThreadScreenState extends ConsumerState<FeedPostThreadScreen> {
  FeedPostModel? _root;
  List<FeedPostModel> _replies = [];
  bool _loading = true;
  String? _error;
  final _replyController = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _root = widget.preview;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _registerView();
      _load();
    });
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _registerView() async {
    try {
      await ApiService.post(ApiContract.url(ApiContract.feed.postView(widget.postId)));
    } catch (_) {
      // Non-blocking
    }
  }

  List<Map<String, dynamic>> _extractList(dynamic raw) {
    if (raw is List) {
      return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    if (raw is Map && raw['data'] is List) {
      return (raw['data'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
  }

  Map<String, dynamic> _extractMap(dynamic raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return const {};
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final postRes = await ApiService.get(ApiContract.url(ApiContract.feed.post(widget.postId)));
      final postPayload = _extractMap(postRes.data);
      final postData = _extractMap(postPayload['data']);
      if (postData.isNotEmpty) {
        _root = FeedPostModel.fromJson(postData);
      }

      final repRes = await ApiService.get(ApiContract.url(ApiContract.feed.postReplies(widget.postId)));
      final rows = _extractList(repRes.data);
      _replies = rows.map(FeedPostModel.fromJson).toList();

      setState(() {
        _loading = false;
        _error = null;
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = 'Could not load this thread.';
      });
    }
  }

  Future<void> _sendReply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    HapticFeedback.mediumImpact();
    try {
      await ApiService.post(
        ApiContract.url(ApiContract.feed.posts),
        data: {
          'content': text,
          'type': 'text',
          'visibility': 'public',
          'reply_to_id': widget.postId,
        },
      );
      _replyController.clear();
      await _load();
      await ref.read(xFeedProvider.notifier).loadTimeline();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not send reply')),
        );
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final root = _root;

    return GriotScaffold(
      appBar: AppBar(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        title: Text('Thread', style: ModernGriotTypography.titleLarge(context: context)),
      ),
      body: Column(
        children: [
          if (_error != null)
            Material(
              color: cs.errorContainer,
              child: Padding(
                padding: EdgeInsets.all(12.r),
                child: Row(
                  children: [
                    Expanded(child: Text(_error!, style: TextStyle(color: cs.onErrorContainer))),
                    TextButton(onPressed: _load, child: const Text('Retry')),
                  ],
                ),
              ),
            ),
          Expanded(
            child: _loading && root == null
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    children: [
                      if (root != null) _RootPostCard(post: root),
                      SizedBox(height: 16.h),
                      Text(
                        'Replies (${_replies.length})',
                        style: ModernGriotTypography.titleSmall(context: context),
                      ),
                      SizedBox(height: 8.h),
                      if (_replies.isEmpty && !_loading)
                        Text(
                          'No replies yet. Be the first to respond.',
                          style: ModernGriotTypography.bodySmall(
                            context: context,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ..._replies.map((r) => _ReplyTile(post: r)),
                    ],
                  ),
          ),
          Material(
            elevation: 8,
            color: cs.surface,
            child: SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.fromLTRB(12.w, 8.h, 12.w, 8.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _replyController,
                        minLines: 1,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          hintText: 'Write a reply…',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    FilledButton(
                      onPressed: _sending ? null : _sendReply,
                      child: _sending
                          ? SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: cs.onPrimary,
                              ),
                            )
                          : const Icon(Icons.send_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RootPostCard extends StatelessWidget {
  const _RootPostCard({required this.post});
  final FeedPostModel post;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GriotCard(
      surfaceLevel: 1,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const GriotAvatar(size: 40),
              SizedBox(width: 10.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(post.displayName,
                        style: ModernGriotTypography.titleSmall(context: context)),
                    Text(post.handle,
                        style: ModernGriotTypography.bodySmall(
                            context: context, color: cs.onSurfaceVariant)),
                  ],
                ),
              ),
              GriotBadgePill(label: post.languageChipLabel),
            ],
          ),
          SizedBox(height: 12.h),
          Text(post.content, style: ModernGriotTypography.bodyMedium(context: context)),
          if (post.hasImage && post.mediaUrls.isNotEmpty) ...[
            SizedBox(height: 12.h),
            ClipRRect(
              borderRadius: BorderRadius.circular(ModernGriotRadius.lg),
              child: CachedNetworkImage(
                imageUrl: post.mediaUrls.first,
                height: 180.h,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  height: 180.h,
                  color: cs.surfaceContainerHighest,
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (_, __, ___) => Container(
                  height: 120.h,
                  color: cs.surfaceContainerHighest,
                  child: Icon(Icons.broken_image_outlined, color: cs.onSurfaceVariant),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReplyTile extends StatelessWidget {
  const _ReplyTile({required this.post});
  final FeedPostModel post;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: GriotCard(
        surfaceLevel: 0,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const GriotAvatar(size: 36),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(post.displayName,
                      style: ModernGriotTypography.titleSmall(context: context)),
                  Text(post.content,
                      style: ModernGriotTypography.bodyMedium(context: context)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
