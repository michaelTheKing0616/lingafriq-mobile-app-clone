import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/models/culture_content_model.dart';
import 'package:lingafriq/navigation/village_navigation.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

/// Route arguments for [FlbHeritageDetailScreen].
class FlbHeritageDetailArgs {
  FlbHeritageDetailArgs(this.content);
  final CultureContent content;
}

/// Full-text view for a single heritage entry.
class FlbHeritageDetailScreen extends ConsumerWidget {
  const FlbHeritageDetailScreen({super.key, required this.content});

  final CultureContent content;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;
    final img = content.imageUrl;

    return Scaffold(
      backgroundColor:
          isDark ? PanAfricanColors.surfaceDark : PanAfricanColors.surfaceLight,
      appBar: AppBar(
        title: Text(
          l10n.flbHeritageDetailTitle,
          style: PanAfricanTypography.titleLarge(context),
        ),
        backgroundColor:
            isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
        foregroundColor: isDark
            ? PanAfricanColors.textPrimaryDark
            : PanAfricanColors.textPrimaryLight,
        elevation: 0,
        leading: IconButton(
          icon: Icon(PanAfricanIcons.back),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            tooltip: l10n.tooltipTribes,
            icon: const Icon(Icons.groups_rounded),
            onPressed: () {
              HapticFeedback.selectionClick();
              VillageNavigation.pushTribeHub(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (img != null && img.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16.r),
                child: CachedNetworkImage(
                  imageUrl: img,
                  width: double.infinity,
                  height: 200.h,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    height: 200.h,
                    color: Colors.black12,
                    alignment: Alignment.center,
                    child: const CircularProgressIndicator(),
                  ),
                  errorWidget: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            if (img != null && img.isNotEmpty) SizedBox(height: 16.h),
            Text(
              content.title,
              style: PanAfricanTypography.headlineSmall(context),
            ),
            SizedBox(height: 8.h),
            Text(
              content.description,
              style: PanAfricanTypography.bodyLarge(context),
            ),
            SizedBox(height: 12.h),
            Wrap(
              spacing: 8.w,
              runSpacing: 8.h,
              children: [
                if (content.country != null)
                  Chip(label: Text(content.country!)),
                Chip(label: Text(content.language)),
                ...content.tags.map((t) => Chip(label: Text(t))),
              ],
            ),
            SizedBox(height: 20.h),
            SelectableText(
              content.content,
              style: PanAfricanTypography.bodyMedium(context).copyWith(
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Parses [ModalRoute] arguments for [FlbHeritageDetailScreen].
CultureContent? heritageDetailFromArguments(Object? arguments) {
  if (arguments is FlbHeritageDetailArgs) {
    return arguments.content;
  }
  if (arguments is CultureContent) {
    return arguments;
  }
  if (arguments is Map) {
    final c = arguments['content'];
    if (c is CultureContent) return c;
    if (c is Map) {
      return CultureContent.fromMap(Map<String, dynamic>.from(c));
    }
  }
  return null;
}
