import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../utils/modern_griot_design_system.dart';
import '../../widgets/griot/griot_widgets.dart';

class VillageMarketScreen extends ConsumerWidget {
  const VillageMarketScreen({super.key});

  static const _categories = [
    _Category('Family', Icons.family_restroom_rounded, 12, 86),
    _Category('Tradition', Icons.temple_buddhist_rounded, 8, 64),
    _Category('Trade', Icons.handshake_rounded, 6, 42),
    _Category('Nature', Icons.eco_rounded, 10, 73),
  ];

  static const _items = [
    _MarketItem('Greetings Pack', 'Essential daily greetings in Swahili',
        4.8, 150, Icons.waving_hand_rounded),
    _MarketItem('Proverbs Collection', 'Wisdom of the elders — 50 proverbs',
        4.6, 200, Icons.auto_stories_rounded),
    _MarketItem('Market Vocab', 'Bargain like a local trader',
        4.5, 120, Icons.storefront_rounded),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return GriotScaffold(
      body: GriotSvgPatternBackground(
        pattern: GriotPattern.kente,
        opacity: 0.03,
        child: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 12.h),
                _buildAppBar(context),
                SizedBox(height: 16.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: _buildSearchBar(context),
                ),
                SizedBox(height: 20.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: _buildHeroCard(context),
                ),
                SizedBox(height: 20.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: _buildSecondaryItems(context),
                ),
                SizedBox(height: 28.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: _buildCategoryGrid(context),
                ),
                SizedBox(height: 28.h),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: _buildPromoBanner(context),
                ),
                SizedBox(height: 32.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.maybePop(context),
            child: Container(
              width: 40.r,
              height: 40.r,
              decoration: BoxDecoration(
                color: ModernGriotColors.surfaceContainerLow,
                shape: BoxShape.circle,
                boxShadow: ModernGriotShadows.sm,
              ),
              child: Icon(Icons.arrow_back_rounded, size: 20.sp),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Village Market',
                    style: ModernGriotTypography.titleLarge()),
                Text('SOKO LA KIJIJI',
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w800,
                      color: ModernGriotColors.primary,
                      letterSpacing: 1.5,
                    )),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: ModernGriotColors.primaryContainer.withAlpha(30),
              borderRadius: ModernGriotRadius.borderPill,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.toll_rounded,
                    size: 16.sp, color: ModernGriotColors.primaryContainer),
                SizedBox(width: 4.w),
                Text('1,250',
                    style: ModernGriotTypography.labelMedium(
                        color: ModernGriotColors.primaryContainer)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return Container(
      height: 44.h,
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: ModernGriotColors.surfaceContainerHighest,
        borderRadius: ModernGriotRadius.borderPill,
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded,
              size: 20.sp, color: ModernGriotColors.onSurfaceVariant),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              'Search packs, words, phrases...',
              style: ModernGriotTypography.bodySmall(
                  color: ModernGriotColors.onSurfaceVariant.withAlpha(150)),
            ),
          ),
          Icon(Icons.tune_rounded,
              size: 18.sp, color: ModernGriotColors.onSurfaceVariant),
        ],
      ),
    );
  }

  Widget _buildHeroCard(BuildContext context) {
    return GestureDetector(
      onTap: () => HapticFeedback.mediumImpact(),
      child: Container(
        padding: EdgeInsets.all(20.r),
        decoration: BoxDecoration(
          gradient: ModernGriotGradients.signatureGradient,
          borderRadius: ModernGriotRadius.borderXl,
          boxShadow: ModernGriotShadows.lg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48.r,
                  height: 48.r,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(30),
                    borderRadius: ModernGriotRadius.borderLg,
                  ),
                  child: Icon(Icons.auto_awesome_rounded,
                      size: 24.sp, color: Colors.white),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Proverbs of the Sahel',
                          style: ModernGriotTypography.titleMedium(
                              color: Colors.white)),
                      SizedBox(height: 2.h),
                      Text('50 proverbs · Cultural wisdom pack',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.white.withAlpha(180),
                          )),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            Row(
              children: [
                _buildStarRating(4.9),
                SizedBox(width: 12.w),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(30),
                    borderRadius: ModernGriotRadius.borderPill,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.toll_rounded,
                          size: 14.sp, color: Colors.white),
                      SizedBox(width: 4.w),
                      Text('300',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          )),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 18.w, vertical: 10.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: ModernGriotRadius.borderPill,
                  ),
                  child: Text('Trade Now',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: ModernGriotColors.primary,
                      )),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStarRating(double rating) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final isFull = i < rating.floor();
        final isHalf = !isFull && i < rating;
        return Icon(
          isFull
              ? Icons.star_rounded
              : isHalf
                  ? Icons.star_half_rounded
                  : Icons.star_outline_rounded,
          size: 16.sp,
          color: const Color(0xFFFFC107),
        );
      }),
    );
  }

  Widget _buildSecondaryItems(BuildContext context) {
    return Column(
      children: _items.map((item) {
        return Padding(
          padding: EdgeInsets.only(bottom: 12.h),
          child: GriotCard(
            surfaceLevel: 1,
            onTap: () {},
            child: Row(
              children: [
                Container(
                  width: 44.r,
                  height: 44.r,
                  decoration: BoxDecoration(
                    color: ModernGriotColors.primary.withAlpha(15),
                    borderRadius: ModernGriotRadius.borderLg,
                  ),
                  child: Icon(item.icon,
                      size: 22.sp, color: ModernGriotColors.primary),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.name,
                          style: ModernGriotTypography.titleSmall()),
                      SizedBox(height: 2.h),
                      Text(item.description,
                          style: ModernGriotTypography.bodySmall(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.star_rounded,
                            size: 14.sp, color: const Color(0xFFFFC107)),
                        SizedBox(width: 2.w),
                        Text('${item.rating}',
                            style: ModernGriotTypography.labelSmall()),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.toll_rounded,
                            size: 12.sp,
                            color: ModernGriotColors.primaryContainer),
                        SizedBox(width: 2.w),
                        Text('${item.tokens}',
                            style: ModernGriotTypography.labelSmall(
                                color: ModernGriotColors.primaryContainer)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategoryGrid(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Browse by Category',
            style: ModernGriotTypography.titleMedium()),
        SizedBox(height: 14.h),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12.h,
          crossAxisSpacing: 12.w,
          childAspectRatio: 0.75,
          children: _categories.map((cat) {
            return GestureDetector(
              onTap: () => HapticFeedback.selectionClick(),
              child: Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  color: ModernGriotColors.surfaceContainerLow,
                  borderRadius: ModernGriotRadius.borderXl,
                  boxShadow: ModernGriotShadows.sm,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 36.r,
                      height: 36.r,
                      decoration: BoxDecoration(
                        color: ModernGriotColors.primary.withAlpha(15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(cat.icon,
                          size: 18.sp, color: ModernGriotColors.primary),
                    ),
                    SizedBox(height: 6.h),
                    Text(cat.name,
                        style: ModernGriotTypography.labelSmall(),
                        textAlign: TextAlign.center),
                    SizedBox(height: 2.h),
                    Text('${cat.packs}p · ${cat.words}w',
                        style: TextStyle(
                          fontSize: 9.sp,
                          color: ModernGriotColors.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildPromoBanner(BuildContext context) {
    return GestureDetector(
      onTap: () => HapticFeedback.mediumImpact(),
      child: ClipRRect(
        borderRadius: ModernGriotRadius.borderXl,
        child: CustomPaint(
          painter: _BlobPainter(),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF526124),
                  Color(0xFF7A8C3A),
                ],
              ),
              borderRadius: ModernGriotRadius.borderXl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GriotBadgePill(
                  label: 'LIMITED',
                  icon: Icons.local_fire_department_rounded,
                  color: const Color(0xFFFFC107),
                  textColor: const Color(0xFF3A1500),
                ),
                SizedBox(height: 12.h),
                Text('Weekend Culture Bundle',
                    style: ModernGriotTypography.titleMedium(
                        color: Colors.white)),
                SizedBox(height: 4.h),
                Text(
                  'Get 3 packs for the price of 2. Explore family, greetings & proverbs.',
                  style: ModernGriotTypography.bodySmall(
                      color: Colors.white.withAlpha(200)),
                ),
                SizedBox(height: 12.h),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: ModernGriotRadius.borderPill,
                  ),
                  child: Text('Claim Bundle',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF526124),
                      )),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BlobPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(15)
      ..style = PaintingStyle.fill;

    final path = Path()
      ..moveTo(size.width * 0.6, 0)
      ..quadraticBezierTo(
          size.width * 1.1, size.height * 0.3, size.width * 0.8, size.height)
      ..lineTo(size.width, size.height)
      ..lineTo(size.width, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Category {
  const _Category(this.name, this.icon, this.packs, this.words);
  final String name;
  final IconData icon;
  final int packs;
  final int words;
}

class _MarketItem {
  const _MarketItem(
      this.name, this.description, this.rating, this.tokens, this.icon);
  final String name;
  final String description;
  final double rating;
  final int tokens;
  final IconData icon;
}
