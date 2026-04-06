import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../utils/modern_griot_design_system.dart';
import '../../widgets/griot/griot_widgets.dart';

// ─── Mock data ──────────────────────────────────────────────────────────────

class _Reply {
  const _Reply({
    required this.name,
    required this.handle,
    required this.text,
    required this.time,
    required this.likes,
  });

  final String name, handle, text, time;
  final int likes;
}

const _postAuthor = 'Fatou Sow';
const _postHandle = '@fatou_sow';
const _postText =
    'Learning #Yoruba proverbs is like discovering hidden wisdom. "Àgbà kì í wà lójà kí orí ọmọ tuntun wó" — An elder does not stand in the market and let a child\'s head go crooked. 🌍 #AfricanWisdom #Proverbs';
const _postTime = 'Apr 3, 2026 · 10:42 AM';
const _postViews = 8340;
const _postReplies = 45;
const _postReposts = 67;
const _postLikes = 256;

const _replies = <_Reply>[
  _Reply(
    name: 'Amina Diallo',
    handle: '@amina_d',
    text:
        'This proverb is so powerful! In #Wolof we have a similar one about community responsibility. Languages carry the same truths in different clothes.',
    time: '12m',
    likes: 28,
  ),
  _Reply(
    name: 'Tunde Adeyemi',
    handle: '@tunde_a',
    text:
        'As a native #Yoruba speaker, I love seeing our proverbs shared here. This one is about collective responsibility for the next generation.',
    time: '45m',
    likes: 63,
  ),
  _Reply(
    name: 'Zainab Mwangi',
    handle: '@zainab_m',
    text:
        'In #Swahili we say "Mtoto akililia wembe, mpe" — Give a child what they cry for. Different angle, same wisdom tradition.',
    time: '1h',
    likes: 41,
  ),
  _Reply(
    name: 'Kofi Adu',
    handle: '@kofi_adu',
    text:
        'Adding this to my proverb journal! The LingAfriq community is a goldmine for this kind of learning.',
    time: '3h',
    likes: 19,
  ),
];

// ─── Screen ─────────────────────────────────────────────────────────────────

class PostDetailCleanScreen extends ConsumerStatefulWidget {
  const PostDetailCleanScreen({super.key, this.postId});
  final String? postId;

  @override
  ConsumerState<PostDetailCleanScreen> createState() =>
      _PostDetailCleanScreenState();
}

class _PostDetailCleanScreenState
    extends ConsumerState<PostDetailCleanScreen> {
  final _replyCtrl = TextEditingController();
  final bool _isAuthenticated = false;

  @override
  void dispose() {
    _replyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GriotScaffold(
      appBar: AppBar(
        backgroundColor: cs.surface,
        surfaceTintColor: Colors.transparent,
        title: Text('Post',
            style: ModernGriotTypography.titleLarge(context: context)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _CleanFocalPost(),
                _divider(cs),
                _CleanEngagementRow(),
                _divider(cs),
                Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  child: Text(
                    'Replies',
                    style:
                        ModernGriotTypography.titleSmall(context: context),
                  ),
                ),
                ...List.generate(_replies.length, (i) {
                  return Column(
                    children: [
                      _CleanReply(reply: _replies[i]),
                      if (i < _replies.length - 1) _divider(cs),
                    ],
                  );
                }),
                SizedBox(height: 32.h),
              ],
            ),
          ),
          _CleanReplyBar(
            controller: _replyCtrl,
            enabled: _isAuthenticated,
          ),
        ],
      ),
    );
  }

  Widget _divider(ColorScheme cs) => Divider(
        height: 1,
        thickness: 1,
        color: cs.outlineVariant.withAlpha(40),
      );
}

// ─── Clean focal post ───────────────────────────────────────────────────────

class _CleanFocalPost extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.all(16.r),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const GriotAvatar(size: 48),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(_postAuthor,
                            style: ModernGriotTypography.titleMedium(
                                context: context)),
                        SizedBox(width: 4.w),
                        Icon(Icons.verified_rounded,
                            size: 16.sp, color: cs.primary),
                      ],
                    ),
                    Text(
                      _postHandle,
                      style: ModernGriotTypography.bodySmall(
                          context: context, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Icon(Icons.more_horiz_rounded,
                  color: cs.onSurfaceVariant, size: 20.sp),
            ],
          ),
          SizedBox(height: 16.h),
          _HashtagText(text: _postText, isLarge: true),
          SizedBox(height: 16.h),
          Row(
            children: [
              Text(
                _postTime,
                style: ModernGriotTypography.labelSmall(
                    context: context, color: cs.onSurfaceVariant),
              ),
              SizedBox(width: 8.w),
              Container(
                width: 3.r,
                height: 3.r,
                decoration: BoxDecoration(
                  color: cs.onSurfaceVariant,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                '${_fmt(_postViews)} views',
                style: ModernGriotTypography.labelSmall(
                    context: context, color: cs.onSurfaceVariant),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Clean engagement row ───────────────────────────────────────────────────

class _CleanEngagementRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _EngageItem(Icons.chat_bubble_outline_rounded, _fmt(_postReplies),
              cs.onSurfaceVariant),
          _EngageItem(
              Icons.repeat_rounded, _fmt(_postReposts), cs.onSurfaceVariant),
          _EngageItem(Icons.favorite_border_rounded, _fmt(_postLikes),
              const Color(0xFFE11D48)),
          _EngageItem(Icons.share_outlined, '', cs.onSurfaceVariant),
          _EngageItem(
              Icons.bookmark_border_rounded, '', cs.onSurfaceVariant),
        ],
      ),
    );
  }
}

class _EngageItem extends StatelessWidget {
  const _EngageItem(this.icon, this.label, this.color);
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 20.sp, color: color),
        if (label.isNotEmpty) ...[
          SizedBox(width: 4.w),
          Text(
            label,
            style: ModernGriotTypography.labelSmall(
                context: context, color: color),
          ),
        ],
      ],
    );
  }
}

// ─── Clean reply card ───────────────────────────────────────────────────────

class _CleanReply extends StatelessWidget {
  const _CleanReply({required this.reply});
  final _Reply reply;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const GriotAvatar(size: 36),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        reply.name,
                        style: ModernGriotTypography.titleSmall(
                            context: context),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      reply.handle,
                      style: ModernGriotTypography.labelSmall(
                          context: context, color: cs.onSurfaceVariant),
                    ),
                    const Spacer(),
                    Text(
                      reply.time,
                      style: ModernGriotTypography.labelSmall(
                          context: context, color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
                SizedBox(height: 6.h),
                _HashtagText(text: reply.text),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Icon(Icons.favorite_border_rounded,
                        size: 16.sp, color: cs.onSurfaceVariant),
                    SizedBox(width: 4.w),
                    Text(
                      '${reply.likes}',
                      style: ModernGriotTypography.labelSmall(
                          context: context, color: cs.onSurfaceVariant),
                    ),
                    SizedBox(width: 20.w),
                    Icon(Icons.chat_bubble_outline_rounded,
                        size: 16.sp, color: cs.onSurfaceVariant),
                    SizedBox(width: 20.w),
                    Icon(Icons.repeat_rounded,
                        size: 16.sp, color: cs.onSurfaceVariant),
                    SizedBox(width: 20.w),
                    Icon(Icons.share_outlined,
                        size: 16.sp, color: cs.onSurfaceVariant),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Clean reply bar (disabled when not authenticated) ──────────────────────

class _CleanReplyBar extends StatelessWidget {
  const _CleanReplyBar({required this.controller, required this.enabled});
  final TextEditingController controller;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 10.h),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            const GriotAvatar(size: 32),
            SizedBox(width: 10.w),
            Expanded(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                decoration: BoxDecoration(
                  color: enabled
                      ? cs.surfaceContainerHighest
                      : cs.surfaceContainerHighest.withAlpha(120),
                  borderRadius: ModernGriotRadius.borderPill,
                ),
                child: TextField(
                  controller: controller,
                  enabled: enabled,
                  style:
                      ModernGriotTypography.bodyMedium(context: context),
                  decoration: InputDecoration(
                    hintText: enabled
                        ? 'Post your reply…'
                        : 'Sign in to reply',
                    hintStyle: ModernGriotTypography.bodyMedium(
                      context: context,
                      color: cs.onSurfaceVariant.withAlpha(enabled ? 120 : 80),
                    ),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 10.h),
                  ),
                ),
              ),
            ),
            SizedBox(width: 10.w),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 200),
              opacity: enabled ? 1.0 : 0.4,
              child: GriotFab(
                icon: Icons.send_rounded,
                size: 40,
                onPressed: enabled
                    ? () {
                        controller.clear();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Reply sent!')),
                        );
                      }
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Hashtag rich text ──────────────────────────────────────────────────────

class _HashtagText extends StatelessWidget {
  const _HashtagText({required this.text, this.isLarge = false});
  final String text;
  final bool isLarge;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final base = isLarge
        ? ModernGriotTypography.bodyLarge(context: context)
        : ModernGriotTypography.bodyMedium(context: context);
    final tagStyle =
        base.copyWith(color: cs.primary, fontWeight: FontWeight.w600);
    final spans = <TextSpan>[];
    final re = RegExp(r'(#\w+)');
    var last = 0;
    for (final m in re.allMatches(text)) {
      if (m.start > last) {
        spans.add(TextSpan(text: text.substring(last, m.start)));
      }
      spans.add(TextSpan(text: m.group(0), style: tagStyle));
      last = m.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));

    return RichText(text: TextSpan(style: base, children: spans));
  }
}

// ─── Helpers ────────────────────────────────────────────────────────────────

String _fmt(int n) {
  if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
  if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
  return '$n';
}
