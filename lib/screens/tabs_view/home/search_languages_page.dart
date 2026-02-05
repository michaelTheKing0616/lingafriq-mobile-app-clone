import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

import '../../../models/language_response.dart';
import 'home_tab.dart';

/// Pan-African styled search delegate for languages
class SearchLanguageDelegate extends SearchDelegate<Language?> {
  final List<Language> languages;

  SearchLanguageDelegate(this.languages)
      : super(
          searchFieldLabel: 'Search languages...',
          searchFieldStyle: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w400,
          ),
        );

  @override
  ThemeData appBarTheme(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Theme.of(context).copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: isDark
            ? PanAfricanColors.surfaceContainerDark
            : PanAfricanColors.surfaceLight,
        elevation: 0,
        iconTheme: IconThemeData(
          color: isDark
              ? PanAfricanColors.textPrimaryDark
              : PanAfricanColors.textPrimaryLight,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        hintStyle: PanAfricanTypography.bodyMedium(context).copyWith(
          color: PanAfricanColors.neutralMedium,
        ),
        border: InputBorder.none,
      ),
    );
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      if (query.isNotEmpty)
        IconButton(
          icon: const Icon(Icons.clear_rounded),
          onPressed: () {
            HapticFeedback.lightImpact();
            query = '';
          },
          tooltip: 'Clear search',
        ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back_rounded),
      onPressed: () {
        HapticFeedback.lightImpact();
        close(context, null);
      },
      tooltip: 'Back',
    );
  }

  List<Language> _filterLanguages() {
    if (query.isEmpty) return languages;
    final lowerQuery = query.toLowerCase();
    return languages.where((lang) {
      final name = lang.name?.toLowerCase() ?? '';
      return name.contains(lowerQuery);
    }).toList();
  }

  @override
  Widget buildResults(BuildContext context) {
    return _buildLanguageGrid(context, _filterLanguages());
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return _buildLanguageGrid(context, _filterLanguages());
  }

  Widget _buildLanguageGrid(BuildContext context, List<Language> filteredLanguages) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (filteredLanguages.isEmpty) {
      return Container(
        color: isDark ? PanAfricanColors.surfaceDark : PanAfricanColors.surfaceLight,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 64.sp,
                color: PanAfricanColors.neutralMedium,
              ),
              SizedBox(height: PanAfricanSpacing.md),
              Text(
                'No languages found',
                style: PanAfricanTypography.titleMedium(context),
              ),
              SizedBox(height: PanAfricanSpacing.xs),
              Text(
                'Try a different search term',
                style: PanAfricanTypography.bodyMedium(context).copyWith(
                  color: PanAfricanColors.neutralMedium,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: isDark ? PanAfricanColors.surfaceDark : PanAfricanColors.surfaceLight,
      child: GridView.builder(
        padding: EdgeInsets.all(PanAfricanSpacing.md),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: PanAfricanSpacing.sm,
          mainAxisSpacing: PanAfricanSpacing.sm,
          childAspectRatio: 1.1,
        ),
        itemCount: filteredLanguages.length,
        itemBuilder: (context, index) {
          final language = filteredLanguages[index];
          return _SearchLanguageCard(
            language: language,
            isDark: isDark,
            onTap: () {
              HapticFeedback.lightImpact();
              close(context, language);
            },
          );
        },
      ),
    );
  }
}

class _SearchLanguageCard extends StatelessWidget {
  final Language language;
  final bool isDark;
  final VoidCallback onTap;

  const _SearchLanguageCard({
    required this.language,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
        borderRadius: PanAfricanRadius.lgBR,
        boxShadow: PanAfricanShadows.sm,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: PanAfricanRadius.lgBR,
          child: Padding(
            padding: EdgeInsets.all(PanAfricanSpacing.sm),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Language Image
                ClipRRect(
                  borderRadius: PanAfricanRadius.mdBR,
                  child: CachedNetworkImage(
                    imageUrl: language.background ?? '',
                    width: 56.w,
                    height: 56.w,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 56.w,
                      height: 56.w,
                      decoration: BoxDecoration(
                        color: PanAfricanColors.neutralLight,
                        borderRadius: PanAfricanRadius.mdBR,
                      ),
                      child: Icon(
                        Icons.language_rounded,
                        color: PanAfricanColors.neutralMedium,
                        size: 28.sp,
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 56.w,
                      height: 56.w,
                      decoration: BoxDecoration(
                        color: PanAfricanColors.neutralLight,
                        borderRadius: PanAfricanRadius.mdBR,
                      ),
                      child: Icon(
                        Icons.language_rounded,
                        color: PanAfricanColors.neutralMedium,
                        size: 28.sp,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: PanAfricanSpacing.sm),
                // Language Name
                Text(
                  language.name ?? 'Unknown',
                  style: PanAfricanTypography.titleMedium(context),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: PanAfricanSpacing.xxs),
                // Progress indicator
                if (language.total_score > 0)
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: PanAfricanSpacing.sm,
                      vertical: PanAfricanSpacing.xxs,
                    ),
                    decoration: BoxDecoration(
                      color: PanAfricanColors.primary.withOpacity(0.1),
                      borderRadius: PanAfricanRadius.roundBR,
                    ),
                    child: Text(
                      '${language.total_score} pts',
                      style: PanAfricanTypography.labelMedium(context).copyWith(
                        color: PanAfricanColors.primary,
                      ),
                    ),
                  )
                else
                  Text(
                    'Start learning',
                    style: PanAfricanTypography.labelMedium(context).copyWith(
                      color: PanAfricanColors.neutralMedium,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
