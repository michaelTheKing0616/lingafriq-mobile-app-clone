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

const _focalPostAuthor = 'Amina Diallo';
const _focalPostHandle = '@amina_d';
const _focalPostText =
    'Just finished my first #Wolof conversation with a native speaker! The tonal patterns are beautiful — I never realized how much music lives inside a language 🎶 #LingAfriq #LanguageLearning';
const _focalPostTime = 'Apr 3, 2026 · 2:14 PM';
const _focalViews = 12480;
const _focalReplies = 42;
const _focalReposts = 18;
const _focalLikes = 256;

const _replies = <_Reply>[
  _Reply(
    name: 'Kwame Asante',
    handle: '@kwame_learns',
    text:
        'This is so true! I had the same revelation with #Twi. The tonal system completely changes meaning — it\'s like learning to sing and speak at the same time.',
    time: '15m',
    likes: 34,
  ),
  _Reply(
    name: 'Fatou Sow',
    handle: '@fatou_sow',
    text:
        'Welcome to the club! Wait until you discover Wolof wordplay — the griots make it an art form 🎭',
    time: '28m',
    likes: 21,
  ),
  _Reply(
    name: 'Yusuf Okafor',
    handle: '@yusuf_o',
    text:
        'Congrats! I remember my first full conversation in #Swahili. It was about ordering tea but I felt like I conquered a mountain 🏔️',
    time: '1h',
    likes: 48,
  ),
  _Reply(
    name: 'Nia Mensah',
    handle: '@nia_m',
    text:
        'The voice exercises on LingAfriq really help with tones! Have you tried the shadowing feature?',
    time: '2h',
    likes: 15,
  ),
];

// ─── Screen ─────────────────────────────────────────────────────────────────

class PostDetailScreen extends ConsumerStatefulWidget {
  const PostDetailScreen({super.key, this.postId});
  final String? postId;

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _replyCtrl = TextEditingController();

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
        title: Text('Thread',
            style: ModernGriotTypography.titleLarge(context: context)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
              children: [
                _FocalPost(),
                SizedBox(height: 8.h),
                _EngagementStats(),
                SizedBox(height: 16.h),
                ...List.generate(_replies.length, (i) {
                  final isLast = i == _replies.length - 1;
                  return _ThreadReply(reply: _replies[i], isLast: isLast);
                }),
                SizedBox(height: 16.h),
                _TribeCta(),
                SizedBox(height: 24.h),
              ],
            ),
          ),
          _ReplyInputBar(controller: _replyCtrl),
        ],
      ),
    );
  }
}

// ─── Focal post ─────────────────────────────────────────────────────────────

class _FocalPost extends StatelessWidget {
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
              GriotAvatar(
                size: 48,
                badge: Container(
                  width: 20.r,
                  height: 20.r,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    shape: BoxShape.circle,
                    border: Border.all(color: cs.surface, width: 2),
                  ),
                  child: Icon(Icons.verified_rounded,
                      size: 12.sp, color: cs.onPrimary),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_focalPostAuthor,
                        style: ModernGriotTypography.titleMedium(
                            context: context)),
                    Text(
                      _focalPostHandle,
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
          _HashtagText(text: _focalPostText, isLarge: true),
          SizedBox(height: 12.h),
          Text(
            _focalPostTime,
            style: ModernGriotTypography.labelSmall(
                context: context, color: cs.onSurfaceVariant),
          ),
          SizedBox(height: 8.h),
          Text(
            '${_fmt(_focalViews)} views',
            style: ModernGriotTypography.bodySmall(
                context: context, color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

// ─── Engagement stats row ───────────────────────────────────────────────────

class _EngagementStats extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GriotCard(
      surfaceLevel: 0,
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(Icons.chat_bubble_outline_rounded, '$_focalReplies',
              'Replies'),
          _StatItem(Icons.repeat_rounded, '$_focalReposts', 'Reposts'),
          _StatItem(Icons.favorite_border_rounded, '$_focalLikes', 'Likes',
              tint: const Color(0xFFE11D48)),
          _StatItem(
              Icons.visibility_outlined, _fmt(_focalViews), 'Views'),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem(this.icon, this.value, this.label, {this.tint});
  final IconData icon;
  final String value, label;
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final color = tint ?? cs.onSurfaceVariant;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18.sp, color: color),
        SizedBox(height: 4.h),
        Text(value,
            style: ModernGriotTypography.titleSmall(context: context)),
        Text(label,
            style: ModernGriotTypography.labelSmall(
                context: context, color: cs.onSurfaceVariant)),
      ],
    );
  }
}

// ─── Thread reply with vertical connector ───────────────────────────────────

class _ThreadReply extends StatelessWidget {
  const _ThreadReply({required this.reply, this.isLast = false});
  final _Reply reply;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 40.w,
            child: Column(
              children: [
                const GriotAvatar(size: 36),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2.w,
                      margin: EdgeInsets.symmetric(vertical: 4.h),
                      color: cs.outlineVariant.withAlpha(80),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: 16.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(reply.name,
                          style: ModernGriotTypography.titleSmall(
                              context: context)),
                      SizedBox(width: 6.w),
                      Text(reply.handle,
                          style: ModernGriotTypography.labelSmall(
                              context: context,
                              color: cs.onSurfaceVariant)),
                      const Spacer(),
                      Text(reply.time,
                          style: ModernGriotTypography.labelSmall(
                              context: context,
                              color: cs.onSurfaceVariant)),
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
                      Text('${reply.likes}',
                          style: ModernGriotTypography.labelSmall(
                              context: context,
                              color: cs.onSurfaceVariant)),
                      SizedBox(width: 16.w),
                      Icon(Icons.chat_bubble_outline_rounded,
                          size: 16.sp, color: cs.onSurfaceVariant),
                      SizedBox(width: 16.w),
                      Icon(Icons.repeat_rounded,
                          size: 16.sp, color: cs.onSurfaceVariant),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Reply input bar ────────────────────────────────────────────────────────

class _ReplyInputBar extends StatelessWidget {
  const _ReplyInputBar({required this.controller});
  final TextEditingController controller;

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
                  color: cs.surfaceContainerHighest,
                  borderRadius: ModernGriotRadius.borderPill,
                ),
                child: TextField(
                  controller: controller,
                  style:
                      ModernGriotTypography.bodyMedium(context: context),
                  decoration: InputDecoration(
                    hintText: 'Post your reply…',
                    hintStyle: ModernGriotTypography.bodyMedium(
                        context: context,
                        color: cs.onSurfaceVariant.withAlpha(120)),
                    border: InputBorder.none,
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 10.h),
                  ),
                ),
              ),
            ),
            SizedBox(width: 10.w),
            GriotFab(
              icon: Icons.send_rounded,
              size: 40,
              onPressed: () {
                controller.clear();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reply sent!')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Join the Twi Tribe CTA ────────────────────────────────────────────────

class _TribeCta extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GriotCard(
      surfaceLevel: 2,
      child: Row(
        children: [
          Container(
            width: 48.r,
            height: 48.r,
            decoration: BoxDecoration(
              color: cs.primary.withAlpha(25),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.groups_rounded,
                color: cs.primary, size: 24.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Join the Twi Tribe',
                    style: ModernGriotTypography.titleSmall(
                        context: context)),
                Text(
                  '1.2K members learning Twi together',
                  style: ModernGriotTypography.bodySmall(
                      context: context, color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          GriotSecondaryButton(
            label: 'Join',
            onPressed: () {},
            width: 70,
          ),
        ],
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
