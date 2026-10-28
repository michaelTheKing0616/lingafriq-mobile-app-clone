import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/gamification_provider.dart';
import 'package:lingafriq/services/capability_gate.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/widgets/gamification/gamification_widgets.dart';
import 'package:lingafriq/widgets/responsive_safe_area.dart';

/// Cowries shop — reference: Duolingo gems shop (clear list, confirm sheet, honest labels).
class CowriesShopScreen extends ConsumerStatefulWidget {
  const CowriesShopScreen({super.key});

  @override
  ConsumerState<CowriesShopScreen> createState() => _CowriesShopScreenState();
}

class _CowriesShopScreenState extends ConsumerState<CowriesShopScreen> {
  String? _statusMessage;
  String? _pendingItemId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(gamificationProvider.notifier).loadCowriesShopCatalog();
    });
  }

  Future<void> _confirmPurchase(CowriesShopItem item) async {
    final gate = CapabilityGate();
    if (!await gate.mayPurchase()) {
      if (!mounted) return;
      await CapabilityBlockedSheet.showPurchaseBlocked(context);
      return;
    }
    final balance = ref.read(gamificationProvider.notifier).gamification.cowries;
    if (balance < item.cost) {
      setState(() => _statusMessage = 'You need ${item.cost - balance} more Cowries for this.');
      return;
    }

    final owned = ref.read(gamificationProvider.notifier).ownsShopItem(item);
    if (owned) {
      setState(() => _statusMessage = 'You already have this.');
      return;
    }

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            PanAfricanSpacing.lg,
            PanAfricanSpacing.sm,
            PanAfricanSpacing.lg,
            PanAfricanSpacing.xl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(item.title, style: PanAfricanTypography.titleLarge(ctx)),
              SizedBox(height: PanAfricanSpacing.sm),
              Text(item.does, style: PanAfricanTypography.bodyMedium(ctx)),
              SizedBox(height: PanAfricanSpacing.md),
              Text(
                'Cost: ${item.cost} Cowries',
                style: PanAfricanTypography.bodyLarge(ctx),
              ),
              SizedBox(height: PanAfricanSpacing.lg),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: FilledButton.styleFrom(minimumSize: Size.fromHeight(48.h)),
                child: const Text('Confirm purchase'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Not now'),
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _pendingItemId = item.id;
      _statusMessage = null;
    });

    final result = await ref.read(gamificationProvider.notifier).purchaseCowriesShopItem(item.id);
    setState(() => _pendingItemId = null);

    if (!result.ok) {
      setState(() => _statusMessage = result.message);
      return;
    }
    setState(() => _statusMessage = 'Done — ${item.title} is yours.');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    ref.watch(gamificationProvider);
    final notifier = ref.read(gamificationProvider.notifier);
    final catalog = notifier.shopCatalog;
    final balance = notifier.gamification.cowries;
    final loading = notifier.shopCatalogLoading;

    return Scaffold(
      backgroundColor:
          isDark ? PanAfricanColors.backgroundDark : PanAfricanColors.backgroundLight,
      appBar: AppBar(
        title: Text('Cowries shop', style: PanAfricanTypography.titleLarge(context)),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: PanAfricanSpacing.sm),
            child: CowriesBalanceChip(amount: balance, compact: true),
          ),
        ],
      ),
      body: ResponsiveSafeArea(
        child: loading && catalog.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: EdgeInsets.all(PanAfricanSpacing.md),
                children: [
                  Text(
                    'Spend Cowries on cosmetics, streak repair, and reviewed persona chapters. Every item explains exactly what you get.',
                    style: PanAfricanTypography.bodyMedium(context),
                  ),
                  if (_statusMessage != null) ...[
                    SizedBox(height: PanAfricanSpacing.sm),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        _statusMessage!,
                        style: PanAfricanTypography.bodySmall(context).copyWith(
                          color: PanAfricanColors.primary,
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: PanAfricanSpacing.md),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: catalog.length,
                    itemBuilder: (context, index) {
                    final item = catalog[index];
                    final owned = notifier.ownsShopItem(item);
                    final insufficient = balance < item.cost;
                    final disabled = owned || insufficient || _pendingItemId == item.id;
                    return Padding(
                      padding: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
                      child: Semantics(
                        label: '${item.title}. ${item.does}. Cost ${item.cost} Cowries.',
                        button: !owned,
                        child: Card(
                          elevation: 0,
                          color: Theme.of(context).colorScheme.surfaceContainerLow,
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: PanAfricanSpacing.md,
                              vertical: PanAfricanSpacing.xs,
                            ),
                            title: Text(
                              item.title,
                              style: PanAfricanTypography.bodyLarge(context),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SizedBox(height: PanAfricanSpacing.xs),
                                Text(item.does, style: PanAfricanTypography.bodySmall(context)),
                                SizedBox(height: PanAfricanSpacing.xs),
                                Text(
                                  '${item.cost} Cowries',
                                  style: PanAfricanTypography.labelLarge(context),
                                ),
                                if (owned)
                                  Text(
                                    'Owned',
                                    style: PanAfricanTypography.labelMedium(context),
                                  ),
                                if (!owned && insufficient)
                                  Text(
                                    'Not enough Cowries',
                                    style: PanAfricanTypography.labelMedium(context),
                                  ),
                              ],
                            ),
                            trailing: owned
                                ? const Icon(Icons.check_circle, color: PanAfricanColors.primary)
                                : FilledButton(
                                    onPressed: disabled
                                        ? null
                                        : () {
                                            HapticFeedback.mediumImpact();
                                            _confirmPurchase(item);
                                          },
                                    style: FilledButton.styleFrom(
                                      minimumSize: Size(96.w, 48.h),
                                    ),
                                    child: _pendingItemId == item.id
                                        ? SizedBox(
                                            width: 20.w,
                                            height: 20.w,
                                            child: const CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : const Text('Buy'),
                                  ),
                          ),
                        ),
                      ),
                    );
                  },
                  ),
                ],
              ),
      ),
    );
  }
}
