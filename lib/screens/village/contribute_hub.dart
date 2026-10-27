import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lingafriq/screens/village/verify_queue_screen.dart';
import 'package:lingafriq/services/lexicon_suggest_client.dart';

/// copy_key: village.verify (P7-929 AC3–AC4).
const String kVillageVerifyCopyKey = 'village.verify';
const String kVillageContributeTitle = 'Contribute';
const String kVillageVerifyTileLabel = 'Verify';
const String kVillageVerifyTileSubtitle =
    'Review community word suggestions (native validators)';
const String kVillageSuggestOnlyNotice =
    'You can suggest words from My Words; native validators approve them here.';

const double kContributeHubMinTouch = 48;

/// Village → Contribute hub with Verify queue entry (P7-929).
class ContributeHubScreen extends StatelessWidget {
  const ContributeHubScreen({
    super.key,
    this.canApproveVerifications = false,
    this.verifyClient,
  });

  /// When false, Verify opens suggest-only messaging (AC4).
  final bool canApproveVerifications;
  final LexiconSuggestClient? verifyClient;

  void _openVerify(BuildContext context) {
    HapticFeedback.selectionClick();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VerifyQueueScreen(
          canApprove: canApproveVerifications,
          client: verifyClient,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(kVillageContributeTitle)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (!canApproveVerifications)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                kVillageSuggestOnlyNotice,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          Semantics(
            button: true,
            label: '$kVillageVerifyCopyKey: $kVillageVerifyTileLabel',
            child: Material(
              color: theme.colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: () => _openVerify(context),
                borderRadius: BorderRadius.circular(12),
                child: ConstrainedBox(
                  constraints:
                      const BoxConstraints(minHeight: kContributeHubMinTouch),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.fact_check_outlined, size: 28),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                kVillageVerifyTileLabel,
                                style: theme.textTheme.titleMedium,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                kVillageVerifyTileSubtitle,
                                style: theme.textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
