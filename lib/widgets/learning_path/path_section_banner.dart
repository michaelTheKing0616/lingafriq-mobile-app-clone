import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

/// L10n keys (resolved in ARB): [kPathUnitBannerKey], [kPathPreviewSheetKey].
const String kPathUnitBannerKey = 'learn.f_007.unit';

/// Unit boundary banner on the learning path (P7-952 AC1).
class PathSectionBanner extends StatelessWidget {
  const PathSectionBanner({
    super.key,
    required this.unitName,
    required this.cefrLevel,
    required this.canDoStatement,
  });

  final String unitName;
  final String cefrLevel;
  final String canDoStatement;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      label: '$unitName. $cefrLevel. $canDoStatement',
      header: true,
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.35)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    unitName,
                    style: PanAfricanTypography.titleSmall(context).copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: PanAfricanColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    cefrLevel,
                    style: PanAfricanTypography.labelMedium(context).copyWith(
                      color: PanAfricanColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (canDoStatement.isNotEmpty) ...[
              SizedBox(height: 8.h),
              Text(
                canDoStatement,
                style: PanAfricanTypography.bodyMedium(context).copyWith(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
