import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/learning_engine_providers.dart';
import 'package:lingafriq/services/social/peer_learning_service.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

class CommunityCorrectionsScreen extends HookConsumerWidget {
  const CommunityCorrectionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.read(peerLearningServiceProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLoading = useState<bool>(true);
    final errorMessage = useState<String?>(null);
    final items = useState<List<CommunityCorrectionFeedItem>>([]);
    final votedIds = useState<Set<String>>(<String>{});
    final votingIds = useState<Set<String>>(<String>{});

    Future<void> loadCorrections() async {
      isLoading.value = true;
      errorMessage.value = null;
      try {
        final page = await service.fetchCommunityCorrections(
          limit: 20,
          page: 1,
        );
        items.value = page.corrections;
      } catch (e) {
        errorMessage.value = 'Unable to load community corrections. Please try again.';
      } finally {
        isLoading.value = false;
      }
    }

    Future<void> vote(CommunityCorrectionFeedItem item, bool isUpvote) async {
      if (item.id.isEmpty) return;
      if (votedIds.value.contains(item.id) || votingIds.value.contains(item.id)) {
        return;
      }

      final previousItem = item;
      final optimisticItem = isUpvote
          ? item.copyWith(upvotes: item.upvotes + 1)
          : item.copyWith(downvotes: item.downvotes + 1);

      votingIds.value = {...votingIds.value, item.id};
      items.value = items.value
          .map((current) => current.id == item.id ? optimisticItem : current)
          .toList();

      try {
        final updated = await service.voteOnCorrection(
          correctionId: item.id,
          isUpvote: isUpvote,
        );
        items.value = items.value
            .map((current) => current.id == item.id ? updated : current)
            .toList();
        votedIds.value = {...votedIds.value, item.id};
      } catch (_) {
        items.value = items.value
            .map((current) => current.id == item.id ? previousItem : current)
            .toList();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vote failed. Please try again.')),
          );
        }
      } finally {
        votingIds.value = {...votingIds.value}..remove(item.id);
      }
    }

    useEffect(() {
      loadCorrections();
      return null;
    }, const []);

    return Scaffold(
      backgroundColor:
          isDark ? PanAfricanColors.backgroundDark : PanAfricanColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Community Corrections'),
        backgroundColor: isDark
            ? PanAfricanColors.surfaceContainerDark
            : PanAfricanColors.surfaceContainerLight,
        foregroundColor:
            isDark ? PanAfricanColors.textPrimaryDark : PanAfricanColors.textPrimary,
        elevation: 0,
      ),
      body: isLoading.value
          ? Center(
              child: CircularProgressIndicator(color: PanAfricanColors.accent),
            )
          : errorMessage.value != null
              ? _ErrorState(
                  message: errorMessage.value!,
                  onRetry: loadCorrections,
                )
              : items.value.isEmpty
                  ? const _EmptyState()
                  : RefreshIndicator(
                      onRefresh: loadCorrections,
                      color: PanAfricanColors.accent,
                      child: ListView.builder(
                        padding: EdgeInsets.all(PanAfricanSpacing.md),
                        itemCount: items.value.length,
                        itemBuilder: (context, index) {
                          final item = items.value[index];
                          final hasVoted = votedIds.value.contains(item.id);
                          final isVoting = votingIds.value.contains(item.id);
                          return _CorrectionCard(
                            item: item,
                            hasVoted: hasVoted,
                            isVoting: isVoting,
                            onUpvote: () {
                              HapticFeedback.lightImpact();
                              vote(item, true);
                            },
                            onDownvote: () {
                              HapticFeedback.lightImpact();
                              vote(item, false);
                            },
                          );
                        },
                      ),
                    ),
    );
  }
}

class _CorrectionCard extends StatelessWidget {
  final CommunityCorrectionFeedItem item;
  final bool hasVoted;
  final bool isVoting;
  final VoidCallback onUpvote;
  final VoidCallback onDownvote;

  const _CorrectionCard({
    required this.item,
    required this.hasVoted,
    required this.isVoting,
    required this.onUpvote,
    required this.onDownvote,
  });

  @override
  Widget build(BuildContext context) {
    final actionDisabled = hasVoted || isVoting;
    return Container(
      margin: EdgeInsets.only(bottom: PanAfricanSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? PanAfricanColors.cardDark
            : PanAfricanColors.cardLight,
        borderRadius: PanAfricanRadius.lgBR,
        boxShadow: PanAfricanShadows.sm,
      ),
      child: Padding(
        padding: EdgeInsets.all(PanAfricanSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: PanAfricanSpacing.sm,
                    vertical: PanAfricanSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: PanAfricanColors.primary.withOpacity(0.12),
                    borderRadius: PanAfricanRadius.roundBR,
                  ),
                  child: Text(
                    item.language.toUpperCase(),
                    style: PanAfricanTypography.labelSmall(context).copyWith(
                      color: PanAfricanColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  item.status,
                  style: PanAfricanTypography.bodySmall(context).copyWith(
                    color: PanAfricanColors.textSecondary,
                  ),
                ),
              ],
            ),
            SizedBox(height: PanAfricanSpacing.md),
            Text(
              'Original',
              style: PanAfricanTypography.labelSmall(context).copyWith(
                color: PanAfricanColors.textSecondary,
              ),
            ),
            SizedBox(height: PanAfricanSpacing.xs),
            Text(
              item.originalText,
              style: PanAfricanTypography.bodyMedium(context).copyWith(
                color: PanAfricanColors.textPrimary,
              ),
            ),
            SizedBox(height: PanAfricanSpacing.md),
            Text(
              'Suggested correction',
              style: PanAfricanTypography.labelSmall(context).copyWith(
                color: PanAfricanColors.textSecondary,
              ),
            ),
            SizedBox(height: PanAfricanSpacing.xs),
            Text(
              item.correctedText,
              style: PanAfricanTypography.bodyMedium(context).copyWith(
                color: PanAfricanColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: PanAfricanSpacing.md),
            Row(
              children: [
                FilledButton.icon(
                  onPressed: actionDisabled ? null : onUpvote,
                  icon: const Icon(Icons.thumb_up_alt_outlined, size: 16),
                  label: Text('${item.upvotes}'),
                ),
                SizedBox(width: PanAfricanSpacing.sm),
                FilledButton.icon(
                  onPressed: actionDisabled ? null : onDownvote,
                  icon: const Icon(Icons.thumb_down_alt_outlined, size: 16),
                  label: Text('${item.downvotes}'),
                ),
                if (isVoting) ...[
                  SizedBox(width: PanAfricanSpacing.sm),
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(PanAfricanSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.groups_outlined,
              size: 72,
              color: PanAfricanColors.textSecondary,
            ),
            SizedBox(height: PanAfricanSpacing.md),
            Text(
              'No pending community corrections',
              style: PanAfricanTypography.titleMedium(context).copyWith(
                color: PanAfricanColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: PanAfricanSpacing.sm),
            Text(
              'Check back later for new items to review.',
              style: PanAfricanTypography.bodyMedium(context).copyWith(
                color: PanAfricanColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(PanAfricanSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 72,
              color: PanAfricanColors.error,
            ),
            SizedBox(height: PanAfricanSpacing.md),
            Text(
              message,
              style: PanAfricanTypography.bodyMedium(context).copyWith(
                color: PanAfricanColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: PanAfricanSpacing.md),
            FilledButton(
              onPressed: () {
                onRetry();
              },
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
