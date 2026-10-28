import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/config/api_contract.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

/// P9-951 — verified-native correction feed (ref: Babbel community Q&A + Duolingo sentence discussions).
class CommunityCorrectionsScreen extends HookConsumerWidget {
  const CommunityCorrectionsScreen({super.key});

  static const _feedPath = '/api/v2/native-corrections/feed';
  static const _accessPath = '/api/v2/native-corrections/access';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isLoading = useState<bool>(true);
    final errorMessage = useState<String?>(null);
    final guarded = useState<bool>(false);
    final items = useState<List<NativeCorrectionFeedItem>>([]);
    final markedHelpful = useState<Set<String>>(<String>{});
    final markingIds = useState<Set<String>>(<String>{});

    Future<void> loadCorrections() async {
      isLoading.value = true;
      errorMessage.value = null;
      guarded.value = false;
      try {
        await ApiService.initialize();
        final access = await ApiService.get(ApiContract.url(_accessPath));
        final accessMap = access.data;
        if (accessMap is Map && accessMap['allowed'] == false) {
          guarded.value = true;
          items.value = [];
          return;
        }

        final response = await ApiService.get(
          ApiContract.url(_feedPath),
          queryParameters: {'limit': 20, 'page': 1},
        );
        if (response.statusCode == 403) {
          guarded.value = true;
          items.value = [];
          return;
        }
        if (response.statusCode != 200 || response.data is! Map) {
          throw Exception('feed unavailable');
        }
        final payload = Map<String, dynamic>.from(response.data as Map);
        final raw = payload['corrections'];
        final list = raw is List ? raw : const [];
        items.value = list
            .whereType<Map>()
            .map((row) => NativeCorrectionFeedItem.fromJson(
                  Map<String, dynamic>.from(row),
                ))
            .toList();
      } catch (_) {
        errorMessage.value =
            'We could not load native corrections right now. Pull to try again.';
      } finally {
        isLoading.value = false;
      }
    }

    Future<void> markHelpful(NativeCorrectionFeedItem item) async {
      if (item.id.isEmpty ||
          markedHelpful.value.contains(item.id) ||
          markingIds.value.contains(item.id)) {
        return;
      }
      markingIds.value = {...markingIds.value, item.id};
      try {
        await ApiService.initialize();
        final response = await ApiService.post(
          ApiContract.url('/api/v2/native-corrections/responses/${item.id}/helpful'),
        );
        if (response.statusCode != 200) {
          throw Exception('helpful failed');
        }
        markedHelpful.value = {...markedHelpful.value, item.id};
        items.value = items.value
            .map(
              (current) => current.id == item.id
                  ? current.copyWith(helpfulCount: current.helpfulCount + 1)
                  : current,
            )
            .toList();
      } catch (_) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not save your feedback. Try again in a moment.'),
            ),
          );
        }
      } finally {
        markingIds.value = {...markingIds.value}..remove(item.id);
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
        title: Semantics(
          header: true,
          child: Text(
            'Native corrections',
            style: PanAfricanTypography.titleLarge(context),
          ),
        ),
        backgroundColor: isDark
            ? PanAfricanColors.surfaceContainerDark
            : PanAfricanColors.surfaceContainerLight,
        foregroundColor:
            isDark ? PanAfricanColors.textPrimaryDark : PanAfricanColors.textPrimary,
        elevation: 0,
      ),
      body: isLoading.value
          ? const Center(
              child: CircularProgressIndicator(color: PanAfricanColors.accent),
            )
          : guarded.value
              ? const _GuardianGateState()
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
                              return _CorrectionCard(
                                item: item,
                                markedHelpful: markedHelpful.value.contains(item.id),
                                isMarking: markingIds.value.contains(item.id),
                                onHelpful: () {
                                  HapticFeedback.lightImpact();
                                  markHelpful(item);
                                },
                              );
                            },
                          ),
                        ),
    );
  }
}

class NativeCorrectionFeedItem {
  const NativeCorrectionFeedItem({
    required this.id,
    required this.language,
    required this.originalText,
    required this.correctedText,
    required this.status,
    required this.nativeVerified,
    required this.reputationScore,
    required this.helpfulCount,
    required this.contentQaRouted,
  });

  final String id;
  final String language;
  final String originalText;
  final String correctedText;
  final String status;
  final bool nativeVerified;
  final double? reputationScore;
  final int helpfulCount;
  final bool contentQaRouted;

  NativeCorrectionFeedItem copyWith({int? helpfulCount}) {
    return NativeCorrectionFeedItem(
      id: id,
      language: language,
      originalText: originalText,
      correctedText: correctedText,
      status: status,
      nativeVerified: nativeVerified,
      reputationScore: reputationScore,
      helpfulCount: helpfulCount ?? this.helpfulCount,
      contentQaRouted: contentQaRouted,
    );
  }

  factory NativeCorrectionFeedItem.fromJson(Map<String, dynamic> json) {
    final rep = json['reputation_score'];
    return NativeCorrectionFeedItem(
      id: (json['id'] ?? json['_id'] ?? '').toString(),
      language: (json['language'] ?? '').toString(),
      originalText: (json['originalText'] ?? '').toString(),
      correctedText: (json['correctedText'] ?? '').toString(),
      status: (json['status'] ?? 'pending').toString(),
      nativeVerified: json['native_verified'] == true,
      reputationScore: rep is num ? rep.toDouble() : null,
      helpfulCount: (json['helpful_count'] as num?)?.toInt() ??
          (json['upvotes'] as num?)?.toInt() ??
          0,
      contentQaRouted: json['content_qa_routed'] == true,
    );
  }
}

class _CorrectionCard extends StatelessWidget {
  const _CorrectionCard({
    required this.item,
    required this.markedHelpful,
    required this.isMarking,
    required this.onHelpful,
  });

  final NativeCorrectionFeedItem item;
  final bool markedHelpful;
  final bool isMarking;
  final VoidCallback onHelpful;

  @override
  Widget build(BuildContext context) {
    final repLabel = item.reputationScore != null
        ? '${(item.reputationScore! * 100).round()}% helpful'
        : 'Building reputation';

    return Semantics(
      container: true,
      label:
          '${item.language} correction. Original ${item.originalText}. Native suggestion ${item.correctedText}',
      child: Container(
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
                  _LanguageChip(language: item.language),
                  SizedBox(width: PanAfricanSpacing.sm),
                  if (item.nativeVerified)
                    _NativeBadge(reputationLabel: repLabel),
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
                'You wrote',
                style: PanAfricanTypography.labelSmall(context).copyWith(
                  color: PanAfricanColors.textSecondary,
                ),
              ),
              SizedBox(height: PanAfricanSpacing.xs),
              Text(
                item.originalText,
                style: PanAfricanTypography.bodyMedium(context),
              ),
              SizedBox(height: PanAfricanSpacing.md),
              Text(
                'Native correction',
                style: PanAfricanTypography.labelSmall(context).copyWith(
                  color: PanAfricanColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: PanAfricanSpacing.xs),
              Text(
                item.correctedText,
                style: PanAfricanTypography.bodyMedium(context).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (item.contentQaRouted) ...[
                SizedBox(height: PanAfricanSpacing.sm),
                Text(
                  'Sent to our content reviewers — nothing changed in lessons yet.',
                  style: PanAfricanTypography.bodySmall(context).copyWith(
                    color: PanAfricanColors.textSecondary,
                  ),
                ),
              ],
              SizedBox(height: PanAfricanSpacing.md),
              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  onPressed: markedHelpful || isMarking ? null : onHelpful,
                  icon: const Icon(Icons.favorite_outline, size: 20),
                  label: Text(
                    markedHelpful
                        ? 'Marked helpful'
                        : 'Helpful (${item.helpfulCount})',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageChip extends StatelessWidget {
  const _LanguageChip({required this.language});

  final String language;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: PanAfricanSpacing.sm,
        vertical: PanAfricanSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: PanAfricanColors.primary.withValues(alpha: 0.12),
        borderRadius: PanAfricanRadius.roundBR,
      ),
      child: Text(
        language.toUpperCase(),
        style: PanAfricanTypography.labelSmall(context).copyWith(
          color: PanAfricanColors.primary,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _NativeBadge extends StatelessWidget {
  const _NativeBadge({required this.reputationLabel});

  final String reputationLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: PanAfricanSpacing.sm,
        vertical: PanAfricanSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: PanAfricanColors.accent.withValues(alpha: 0.15),
        borderRadius: PanAfricanRadius.roundBR,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified, size: 14, color: PanAfricanColors.accent),
          SizedBox(width: PanAfricanSpacing.xs),
          Text(
            reputationLabel,
            style: PanAfricanTypography.labelSmall(context).copyWith(
              color: PanAfricanColors.accent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
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
            const Icon(
              Icons.translate_outlined,
              size: 72,
              color: PanAfricanColors.textSecondary,
            ),
            SizedBox(height: PanAfricanSpacing.md),
            Text(
              'No corrections yet',
              style: PanAfricanTypography.titleMedium(context),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: PanAfricanSpacing.sm),
            Text(
              'When you ask for help, verified native speakers will answer here.',
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

class _GuardianGateState extends StatelessWidget {
  const _GuardianGateState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(PanAfricanSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_outline,
              size: 72,
              color: PanAfricanColors.textSecondary,
            ),
            SizedBox(height: PanAfricanSpacing.md),
            Text(
              'Ask a guardian first',
              style: PanAfricanTypography.titleMedium(context),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: PanAfricanSpacing.sm),
            Text(
              'Native correction spaces open after age is confirmed with a guardian.',
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
  const _ErrorState({
    required this.message,
    required this.onRetry,
  });

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(PanAfricanSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 72,
              color: PanAfricanColors.error,
            ),
            SizedBox(height: PanAfricanSpacing.md),
            Text(
              message,
              style: PanAfricanTypography.bodyMedium(context),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: PanAfricanSpacing.md),
            FilledButton(
              onPressed: onRetry,
              child: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}
