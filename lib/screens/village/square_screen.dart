import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/user_provider.dart';
import 'package:lingafriq/services/capability_gate.dart';
import 'package:lingafriq/services/chat/chat_room_learning_service.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/chat/tone_lens_sheet.dart';
import 'package:lingafriq/widgets/responsive_safe_area.dart';
import 'package:lingafriq/widgets/safety/safety_actions_sheet.dart';

/// copy_keys: square.title, square.minor.blocked (P9-956).
const String kSquareTitle = 'Language Square';
const String kSquareMinorBlocked =
    'The public Square is for adult learners. Ask a guardian about circle chat instead.';
const String kSquareEmpty =
    'No posts yet. Share a phrase you are practising and help others learn.';
const String kSquareOffline =
    'You are offline. Pull to refresh when you reconnect.';
const String kSquareHeldNotice =
    'Your post is with our stewards for a quick review before it appears.';

const List<String> kSquareLanguageTags = [
  'yo',
  'ig',
  'ha',
  'pcm',
  'sw',
  'zu',
  'xh',
  'tw',
  'am',
  'ti',
];

/// Village public feed — reference: Twitter/X learning community + Duolingo forum cards.
class SquareScreen extends HookConsumerWidget {
  const SquareScreen({
    super.key,
    this.capabilityGate,
    this.feedLoader,
    this.poster,
  });

  final CapabilityGate? capabilityGate;
  final Future<Map<String, dynamic>> Function()? feedLoader;
  final Future<Map<String, dynamic>> Function({
    required String languageTag,
    required String body,
  })? poster;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(userProvider);
    final posts = useState<List<Map<String, dynamic>>>([]);
    final loading = useState(true);
    final error = useState<String?>(null);
    final minorBlocked = useState(false);
    final readOnly = useState(false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Future<void> load() async {
      loading.value = true;
      error.value = null;
      try {
        final caps = capabilityGate ?? CapabilityGate();
        final matrix = await caps.load(forceRefresh: true);
        if (matrix.isMinor && !matrix.publicSnapFeed) {
          minorBlocked.value = true;
          readOnly.value = true;
          posts.value = [];
          return;
        }
        minorBlocked.value = false;
        final res = feedLoader != null
            ? await feedLoader!()
            : (await ApiService.get('/api/v2/square/feed')).data;
        if (res is! Map || res['ok'] != true) {
          error.value = 'We could not load the Square right now.';
          return;
        }
        readOnly.value = res['read_only'] == true || matrix.isMinor;
        final rows = res['posts'];
        posts.value = rows is List
            ? rows.map((e) => Map<String, dynamic>.from(e as Map)).toList()
            : [];
      } catch (_) {
        error.value = kSquareOffline;
      } finally {
        loading.value = false;
      }
    }

    useEffect(() {
      load();
      return null;
    }, const []);

    return Scaffold(
      backgroundColor:
          isDark ? PanAfricanColors.backgroundDark : PanAfricanColors.backgroundLight,
      appBar: AppBar(
        title: Text(kSquareTitle, style: PanAfricanTypography.titleLarge(context)),
      ),
      floatingActionButton: minorBlocked.value || readOnly.value || me == null
          ? null
          : Semantics(
              button: true,
              label: 'Write a Square post',
              child: FloatingActionButton.extended(
                onPressed: () => _openComposer(context, me.id.toString(), load, poster),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Share'),
              ),
            ),
      body: ResponsiveSafeArea(
        child: minorBlocked.value
            ? _minorBlockedBody(context)
            : RefreshIndicator(
                onRefresh: load,
                child: _feedBody(
                  context,
                  loading.value,
                  error.value,
                  posts.value,
                  me?.id.toString() ?? '0',
                  load,
                ),
              ),
      ),
    );
  }

  Widget _minorBlockedBody(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.all(PanAfricanSpacing.lg),
      children: [
        Icon(
          Icons.lock_outline,
          size: 48,
          color: Theme.of(context).colorScheme.primary,
        ),
        SizedBox(height: PanAfricanSpacing.md),
        Text(
          kSquareMinorBlocked,
          style: PanAfricanTypography.bodyLarge(context),
        ),
      ],
    );
  }

  Widget _feedBody(
    BuildContext context,
    bool loading,
    String? error,
    List<Map<String, dynamic>> posts,
    String learnerUserId,
    Future<void> Function() reload,
  ) {
    if (loading && posts.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.sizeOf(context).height * 0.3),
          const Center(child: CircularProgressIndicator()),
        ],
      );
    }
    if (error != null && posts.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(PanAfricanSpacing.lg),
        children: [
          Text(error, style: PanAfricanTypography.bodyLarge(context)),
          SizedBox(height: PanAfricanSpacing.md),
          Semantics(
            button: true,
            label: 'Try again',
            child: FilledButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                reload();
              },
              child: const Text('Try again'),
            ),
          ),
        ],
      );
    }
    if (posts.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(PanAfricanSpacing.lg),
        children: [
          Text(kSquareEmpty, style: PanAfricanTypography.bodyLarge(context)),
        ],
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: PanAfricanSpacing.md,
        vertical: PanAfricanSpacing.sm,
      ),
      itemCount: posts.length,
      separatorBuilder: (_, __) => SizedBox(height: PanAfricanSpacing.sm),
      itemBuilder: (context, index) {
        final post = posts[index];
        return _SquarePostCard(
          post: post,
          learnerUserId: learnerUserId,
          onChanged: reload,
        );
      },
    );
  }

  static Future<void> _openComposer(
    BuildContext context,
    String learnerUserId,
    Future<void> Function() reload,
    Future<Map<String, dynamic>> Function({
      required String languageTag,
      required String body,
    })? poster,
  ) async {
    final bodyCtrl = TextEditingController();
    var language = kSquareLanguageTags.first;
    final posted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            left: PanAfricanSpacing.md,
            right: PanAfricanSpacing.md,
            bottom: MediaQuery.viewInsetsOf(ctx).bottom + PanAfricanSpacing.lg,
            top: PanAfricanSpacing.sm,
          ),
          child: StatefulBuilder(
            builder: (ctx, setLocal) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Share a phrase', style: PanAfricanTypography.titleMedium(ctx)),
                  SizedBox(height: PanAfricanSpacing.sm),
                  DropdownButtonFormField<String>(
                    value: language,
                    decoration: const InputDecoration(labelText: 'Language'),
                    items: kSquareLanguageTags
                        .map(
                          (t) => DropdownMenuItem(
                            value: t,
                            child: Text(t.toUpperCase()),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setLocal(() => language = v);
                    },
                  ),
                  SizedBox(height: PanAfricanSpacing.sm),
                  TextField(
                    controller: bodyCtrl,
                    maxLines: 4,
                    maxLength: 500,
                    decoration: const InputDecoration(
                      hintText: 'What are you practising today?',
                    ),
                  ),
                  SizedBox(height: PanAfricanSpacing.sm),
                  FilledButton(
                    onPressed: () async {
                      final body = bodyCtrl.text.trim();
                      if (body.isEmpty) return;
                      try {
                        final res = poster != null
                            ? await poster(languageTag: language, body: body)
                            : (await ApiService.post(
                                '/api/v2/square/posts',
                                data: {'languageTag': language, 'body': body},
                              ))
                                .data;
                        if (res is Map && res['ok'] == true) {
                          if (res['held'] == true && ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(content: Text(kSquareHeldNotice)),
                            );
                          }
                          if (ctx.mounted) Navigator.of(ctx).pop(true);
                        }
                      } catch (_) {
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text('We could not post that. Try again.'),
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Post'),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
    bodyCtrl.dispose();
    if (posted == true) await reload();
  }
}

class _SquarePostCard extends StatelessWidget {
  const _SquarePostCard({
    required this.post,
    required this.learnerUserId,
    required this.onChanged,
  });

  final Map<String, dynamic> post;
  final String learnerUserId;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context) {
    final lang = post['language_tag']?.toString() ?? '';
    final body = post['body']?.toString() ?? '';
    final author = post['author_display']?.toString() ?? 'Learner';
    final postId = post['id']?.toString() ?? '';
    final authorOid = post['author_object_id']?.toString();
    final service = ChatRoomLearningService(
      languageCode: lang.isNotEmpty ? lang : 'yo',
      learnerUserId: learnerUserId,
    );

    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(PanAfricanRadius.md),
      child: Padding(
        padding: EdgeInsets.all(PanAfricanSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    author,
                    style: PanAfricanTypography.titleSmall(context),
                  ),
                ),
                if (lang.isNotEmpty)
                  Chip(
                    label: Text(lang.toUpperCase()),
                    visualDensity: VisualDensity.compact,
                  ),
                Semantics(
                  button: true,
                  label: 'Safety actions for this post',
                  child: IconButton(
                    icon: const Icon(Icons.more_horiz),
                    onPressed: () {
                      final ledger = SafetyTapLedger();
                      showSafetyActionsSheet(
                        context,
                        target: SafetyActionTarget(
                          kind: SafetyTargetKind.comment,
                          targetId: postId,
                          peerUserId: authorOid,
                          peerDisplayName: author,
                          previewText: body,
                        ),
                        tapLedger: ledger,
                      ).then((_) => onChanged());
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: PanAfricanSpacing.xs),
            Wrap(
              spacing: PanAfricanSpacing.xxs,
              runSpacing: PanAfricanSpacing.xxs,
              children: _wordChips(context, body, postId, service),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _wordChips(
    BuildContext context,
    String body,
    String postId,
    ChatRoomLearningService service,
  ) {
    final parts = body.split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    return parts.map((word) {
      final clean = word.replaceAll(RegExp(r'^[^\w]+|[^\w]+$'), '');
      final surface = clean.isNotEmpty ? clean : word;
      return Semantics(
        button: true,
        label: 'Open Tone Lens for $surface',
        child: ActionChip(
          label: Text(word),
          onPressed: () async {
            HapticFeedback.selectionClick();
            await showToneLensSheet(
              context: context,
              service: service,
              messageId: 'square:$postId',
              word: surface,
              e2ee: false,
            );
          },
        ),
      );
    }).toList();
  }
}
