import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import '../../utils/error_handler.dart';
import '../../utils/integration_helpers.dart';
import '../../utils/performance_utils.dart';
import '../../models/magic_item_model.dart';
import '../../providers/gamification_provider.dart';
import '../../providers/gamification_services_provider.dart';
import '../../providers/user_provider.dart';
import '../../services/gamification/items_service.dart';
import '../../widgets/error_boundary.dart';
import '../../screens/loading/dynamic_loading_screen.dart';

/// Magic Items & Boosters Screen
class MagicItemsScreen extends ConsumerStatefulWidget {
  const MagicItemsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MagicItemsScreen> createState() => _MagicItemsScreenState();
}

class _MagicItemsScreenState extends ConsumerState<MagicItemsScreen> {
  bool _isLoading = false;
  List<dynamic> _userInventory = [];
  List<dynamic> _availableItems = [];

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    setState(() => _isLoading = true);
    try {
      final itemsService = ref.read(itemsServiceProvider);
      final user = ref.read(userProvider);
      
      if (user != null) {
        final allItems = await itemsService.getAllItems();
        final inventory = await itemsService.getUserInventory(user.id.toString());
        
        setState(() {
          _availableItems = allItems;
          _userInventory = inventory;
        });
      } else {
        // Fallback to local items
        setState(() {
          _availableItems = MagicItemDefinitions.allItems.map((item) => {
            'code': item.id,
            'name': item.name,
            'description': item.description,
            'effect': item.effect.toString(),
            'duration_seconds': item.durationHours * 3600,
            'cost_cowries': item.costCowries,
            'cost_beads': item.costBeads,
          }).toList();
        });
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e);
      }
      // Fallback to local items
      setState(() {
        _availableItems = MagicItemDefinitions.allItems.map((item) => {
          'code': item.id,
          'name': item.name,
          'description': item.description,
        }).toList();
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _claimItem(String itemCode) async {
    setState(() => _isLoading = true);
    try {
      final itemsService = ref.read(itemsServiceProvider);
      final user = ref.read(userProvider);
      
      if (user != null) {
        await itemsService.claimItem(user.id.toString(), itemCode);
        await _loadItems(); // Reload inventory
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Item claimed successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _useItem(String itemId) async {
    setState(() => _isLoading = true);
    try {
      final itemsService = ref.read(itemsServiceProvider);
      final user = ref.read(userProvider);
      
      if (user != null) {
        final result = await itemsService.useItem(user.id.toString(), itemId);
        await _loadItems(); // Reload inventory
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Item used! Effect: ${result['effect']}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorHandler.showError(context, e);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final items = _availableItems.isNotEmpty 
        ? _availableItems 
        : MagicItemDefinitions.allItems.map((item) => {
            'code': item.id,
            'name': item.name,
            'description': item.description,
          }).toList();
    final gamification = ref.watch(gamificationProvider.notifier).gamification;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;
    
    if (_isLoading && _availableItems.isEmpty) {
      return const Scaffold(
        body: DynamicLoadingScreen(),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Magic Items & Boosters',
          style: PanAfricanTypography.headlineMedium(context),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(PanAfricanSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Currency display
            Container(
              decoration: BoxDecoration(
                gradient: PanAfricanGradients.celebration,
                borderRadius: PanAfricanRadius.lgBR,
                boxShadow: PanAfricanShadows.md,
              ),
              padding: EdgeInsets.all(PanAfricanSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildCurrencyDisplay(
                    context,
                    emoji: '🐚',
                    value: gamification.cowries,
                    label: 'Cowries',
                  ),
                  Container(
                    width: 1,
                    height: 48.h,
                    color: colorScheme.onPrimary.withOpacity(0.3),
                  ),
                  _buildCurrencyDisplay(
                    context,
                    emoji: '💎',
                    value: gamification.ancestralBeads,
                    label: 'Beads',
                  ),
                ],
              ),
            ),
            SizedBox(height: PanAfricanSpacing.lg),
            Text(
              'Available Items',
              style: PanAfricanTypography.titleMedium(context),
            ),
            SizedBox(height: PanAfricanSpacing.sm),
            // Items list
            ...items.map((itemData) {
              final item = MagicItemDefinitions.allItems.firstWhere(
                (i) => i.id == itemData['code'],
                orElse: () => MagicItemDefinitions.allItems.first,
              );
              return _MagicItemCard(
                item: item,
                isDark: isDark,
                onPurchase: () {
                  HapticFeedback.lightImpact();
                  _purchaseItem(context, ref, item);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrencyDisplay(
    BuildContext context, {
    required String emoji,
    required int value,
    required String label,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Text(emoji, style: TextStyle(fontSize: 28.sp)),
        SizedBox(height: PanAfricanSpacing.xxs),
        Text(
          '$value',
          style: PanAfricanTypography.displaySmall(context, color: colorScheme.onPrimary),
        ),
        Text(
          label,
          style: PanAfricanTypography.labelMedium(context, color: colorScheme.onPrimary.withOpacity(0.9)),
        ),
      ],
    );
  }

  void _purchaseItem(BuildContext context, WidgetRef ref, MagicItem item) {
    final gamification = ref.read(gamificationProvider.notifier);
    final currentGamification = gamification.gamification;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final colorScheme = Theme.of(context).colorScheme;

    // Check if user has enough currency
    if (item.costBeads > 0 && currentGamification.ancestralBeads < item.costBeads) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Not enough Ancestral Beads',
            style: PanAfricanTypography.bodyMedium(context, color: colorScheme.onPrimary),
          ),
          backgroundColor: PanAfricanColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: PanAfricanRadius.mdBR),
        ),
      );
      return;
    }

    if (item.costCowries > 0 && currentGamification.cowries < item.costCowries) {
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Not enough Cowries',
            style: PanAfricanTypography.bodyMedium(context, color: colorScheme.onPrimary),
          ),
          backgroundColor: PanAfricanColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: PanAfricanRadius.mdBR),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: PanAfricanRadius.lgBR),
        title: Text(
          'Purchase ${item.name}?',
          style: PanAfricanTypography.titleLarge(context),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 64.w,
              height: 64.w,
              decoration: BoxDecoration(
                color: PanAfricanColors.secondary.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(item.icon, style: TextStyle(fontSize: 32.sp)),
              ),
            ),
            SizedBox(height: PanAfricanSpacing.md),
            Text(
              item.description,
              style: PanAfricanTypography.bodyMedium(context),
            ),
            SizedBox(height: PanAfricanSpacing.md),
            Container(
              padding: EdgeInsets.all(PanAfricanSpacing.sm),
              decoration: BoxDecoration(
                color: isDark
                    ? PanAfricanColors.surfaceContainerDark
                    : PanAfricanColors.surfaceContainerLight,
                borderRadius: PanAfricanRadius.mdBR,
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.timer_rounded,
                    size: 18.sp,
                    color: PanAfricanColors.neutralMedium,
                  ),
                  SizedBox(width: PanAfricanSpacing.xs),
                  Text(
                    item.durationHours > 0
                        ? 'Duration: ${item.durationHours} hours'
                        : 'One-time use',
                    style: PanAfricanTypography.bodySmall(context),
                  ),
                ],
              ),
            ),
            SizedBox(height: PanAfricanSpacing.sm),
            Row(
              children: [
                if (item.costCowries > 0) ...[
                  Text('🐚', style: TextStyle(fontSize: 18.sp)),
                  SizedBox(width: PanAfricanSpacing.xxs),
                  Text(
                    '${item.costCowries}',
                    style: PanAfricanTypography.titleSmall(context),
                  ),
                ],
                if (item.costCowries > 0 && item.costBeads > 0)
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.xs),
                    child: Text(' + ', style: PanAfricanTypography.bodyMedium(context)),
                  ),
                if (item.costBeads > 0) ...[
                  Text('💎', style: TextStyle(fontSize: 18.sp)),
                  SizedBox(width: PanAfricanSpacing.xxs),
                  Text(
                    '${item.costBeads}',
                    style: PanAfricanTypography.titleSmall(context),
                  ),
                ],
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(context);
            },
            child: Text(
              'Cancel',
              style: PanAfricanTypography.labelLarge(context),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: PanAfricanColors.secondary,
              foregroundColor: PanAfricanColors.neutralDarkest,
            ),
            onPressed: () async {
              HapticFeedback.mediumImpact();
              // Deduct currency
              if (item.costCowries > 0) {
                await gamification.awardCurrency(cowries: -item.costCowries);
              }
              if (item.costBeads > 0) {
                await gamification.awardCurrency(ancestralBeads: -item.costBeads);
              }

              // Activate item
              await gamification.activateBooster(item.id, item.durationHours);

              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      '${item.name} activated!',
                      style: PanAfricanTypography.bodyMedium(context, color: colorScheme.onPrimary),
                    ),
                    backgroundColor: PanAfricanColors.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: PanAfricanRadius.mdBR),
                  ),
                );
              }
            },
            child: Text(
              'Purchase',
              style: PanAfricanTypography.labelLarge(context, color: PanAfricanColors.neutralDarkest),
            ),
          ),
        ],
      ),
    );
  }
}

class _MagicItemCard extends StatelessWidget {
  final MagicItem item;
  final bool isDark;
  final VoidCallback onPurchase;

  const _MagicItemCard({
    required this.item,
    required this.isDark,
    required this.onPurchase,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
        borderRadius: PanAfricanRadius.lgBR,
        border: Border.all(
          color: isDark ? PanAfricanColors.borderDark : PanAfricanColors.borderLight,
        ),
        boxShadow: PanAfricanShadows.sm,
      ),
      child: Padding(
        padding: EdgeInsets.all(PanAfricanSpacing.md),
        child: Row(
          children: [
            Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                color: PanAfricanColors.secondary.withOpacity(0.15),
                borderRadius: PanAfricanRadius.mdBR,
              ),
              child: Center(
                child: Text(item.icon, style: TextStyle(fontSize: 28.sp)),
              ),
            ),
            SizedBox(width: PanAfricanSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: PanAfricanTypography.titleSmall(context),
                  ),
                  SizedBox(height: PanAfricanSpacing.xxxs),
                  Text(
                    item.description,
                    style: PanAfricanTypography.bodySmall(context),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: PanAfricanSpacing.xs),
                  Row(
                    children: [
                      Icon(
                        item.durationHours > 0 ? Icons.timer_rounded : Icons.bolt_rounded,
                        size: 14.sp,
                        color: PanAfricanColors.neutralMedium,
                      ),
                      SizedBox(width: PanAfricanSpacing.xxxs),
                      Text(
                        item.durationHours > 0 ? '${item.durationHours}h' : 'Instant',
                        style: PanAfricanTypography.labelSmall(context),
                      ),
                      SizedBox(width: PanAfricanSpacing.md),
                      if (item.costCowries > 0) ...[
                        Text('🐚', style: TextStyle(fontSize: 12.sp)),
                        SizedBox(width: PanAfricanSpacing.xxxs),
                        Text(
                          '${item.costCowries}',
                          style: PanAfricanTypography.labelSmall(context),
                        ),
                      ],
                      if (item.costCowries > 0 && item.costBeads > 0)
                        Text(' + ', style: PanAfricanTypography.labelSmall(context)),
                      if (item.costBeads > 0) ...[
                        Text('💎', style: TextStyle(fontSize: 12.sp)),
                        SizedBox(width: PanAfricanSpacing.xxxs),
                        Text(
                          '${item.costBeads}',
                          style: PanAfricanTypography.labelSmall(context),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: PanAfricanSpacing.sm),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: PanAfricanColors.secondary,
                foregroundColor: PanAfricanColors.neutralDarkest,
                padding: EdgeInsets.symmetric(
                  horizontal: PanAfricanSpacing.md,
                  vertical: PanAfricanSpacing.sm,
                ),
              ),
              onPressed: onPurchase,
              child: Text(
                'Buy',
                style: PanAfricanTypography.labelLarge(context, color: PanAfricanColors.neutralDarkest),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

