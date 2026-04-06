import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../utils/modern_griot_design_system.dart';
import '../../utils/pan_african_design_system.dart' show PanAfricanSpacing;
import '../../widgets/griot/griot_widgets.dart';

class WaStarredMessagesScreen extends StatelessWidget {
  const WaStarredMessagesScreen({super.key});

  static const _filterOptions = [
    _FilterChip(label: 'All', icon: Icons.star_rounded),
    _FilterChip(label: 'Grammar', icon: Icons.auto_stories_rounded),
    _FilterChip(label: 'Phrase', icon: Icons.format_quote_rounded),
    _FilterChip(label: 'Vocabulary', icon: Icons.menu_book_rounded),
    _FilterChip(label: 'Chat Fragment', icon: Icons.chat_bubble_outline_rounded),
    _FilterChip(label: 'Literature', icon: Icons.library_books_rounded),
  ];

  static const _starredItems = [
    _StarredItem(
      type: 'Grammar',
      text: 'In Wolof, verbs conjugate by adding suffixes to the root. '
          'The present tense marker "-y" attaches directly.',
      timestamp: '2 days ago',
      typeColor: Color(0xFF1565C0),
    ),
    _StarredItem(
      type: 'Phrase',
      text: '"Nanga def?" — How are you? The most common Wolof greeting '
          'used throughout Senegal and The Gambia.',
      timestamp: '3 days ago',
      typeColor: Color(0xFF9E3D00),
    ),
    _StarredItem(
      type: 'Vocabulary',
      text: 'Jërejëf /jeh-reh-jef/ — Thank you. '
          'Used in both formal and informal contexts.',
      timestamp: 'Last week',
      typeColor: Color(0xFF526124),
    ),
    _StarredItem(
      type: 'Chat Fragment',
      text: 'Amina: "Great tip — pronounce the tone with breath control, '
          'not volume. That\'s the key to Wolof intonation."',
      timestamp: 'Last week',
      typeColor: Color(0xFF7B5733),
    ),
    _StarredItem(
      type: 'Literature',
      text: '"The story belongs to the community, but the griot gives it wings." '
          '— Sundiata: An Epic of Old Mali',
      timestamp: '2 weeks ago',
      typeColor: Color(0xFF6A1B9A),
    ),
    _StarredItem(
      type: 'Grammar',
      text: 'Noun classes in Yoruba are indicated by tonal patterns '
          'rather than prefixes or suffixes, unlike Bantu languages.',
      timestamp: '2 weeks ago',
      typeColor: Color(0xFF1565C0),
    ),
    _StarredItem(
      type: 'Phrase',
      text: '"Baal ma" — Forgive me / Excuse me in Wolof. '
          'Essential for polite conversation.',
      timestamp: '3 weeks ago',
      typeColor: Color(0xFF9E3D00),
    ),
    _StarredItem(
      type: 'Vocabulary',
      text: 'Asante /ah-SAHN-teh/ — Thank you in Swahili. '
          'Derived from Arabic, widely used across East Africa.',
      timestamp: '3 weeks ago',
      typeColor: Color(0xFF526124),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: ModernGriotColors.surface,
      body: CustomScrollView(
        slivers: [
          _buildHeroHeader(cs),
          _buildSearchAndFilters(cs),
          _starredItems.isEmpty
              ? _buildEmptyState(cs)
              : _buildMasonryGrid(cs),
          SliverPadding(padding: EdgeInsets.only(bottom: 32.h)),
        ],
      ),
    );
  }

  SliverToBoxAdapter _buildHeroHeader(ColorScheme cs) {
    return SliverToBoxAdapter(
      child: Builder(
        builder: (context) {
          final topPadding = MediaQuery.of(context).padding.top;
          return Container(
            padding: EdgeInsets.only(
              top: topPadding + PanAfricanSpacing.md,
              left: PanAfricanSpacing.lg,
              right: PanAfricanSpacing.lg,
              bottom: PanAfricanSpacing.lg,
            ),
            decoration: const BoxDecoration(
              gradient: ModernGriotGradients.sunsetWarm,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_rounded,
                        color: ModernGriotColors.onSurface,
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop();
                      },
                    ),
                    const Spacer(),
                  ],
                ),
                SizedBox(height: PanAfricanSpacing.sm),
                Text(
                  'CULTURAL ARCHIVE',
                  style: ModernGriotTypography.labelMedium(
                    color: ModernGriotColors.primary,
                  ).copyWith(letterSpacing: 2.0),
                ),
                SizedBox(height: PanAfricanSpacing.xs),
                Text(
                  'Your Starred Snippets',
                  style: ModernGriotTypography.headlineMedium(
                    color: ModernGriotColors.onSurface,
                  ),
                ),
                SizedBox(height: PanAfricanSpacing.xxs),
                Text(
                  '${_starredItems.length} saved items across your learning journey',
                  style: ModernGriotTypography.bodySmall(
                    color: ModernGriotColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  SliverToBoxAdapter _buildSearchAndFilters(ColorScheme cs) {
    return SliverToBoxAdapter(
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: PanAfricanSpacing.md,
              vertical: PanAfricanSpacing.sm,
            ),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: PanAfricanSpacing.md,
                vertical: PanAfricanSpacing.sm,
              ),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: ModernGriotRadius.borderXl,
                border: Border.all(
                  color: cs.outlineVariant.withAlpha(38),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search_rounded,
                    size: 20.sp,
                    color: cs.onSurfaceVariant,
                  ),
                  SizedBox(width: PanAfricanSpacing.xs),
                  Expanded(
                    child: Text(
                      'Search starred snippets...',
                      style: ModernGriotTypography.bodyMedium(
                        color: cs.onSurfaceVariant.withAlpha(153),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: 44.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.md),
              itemCount: _filterOptions.length,
              separatorBuilder: (_, __) => SizedBox(width: PanAfricanSpacing.xs),
              itemBuilder: (context, index) {
                final filter = _filterOptions[index];
                final isSelected = index == 0;
                return GriotChip(
                  label: filter.label,
                  selected: isSelected,
                  icon: filter.icon,
                );
              },
            ),
          ),
          SizedBox(height: PanAfricanSpacing.sm),
        ],
      ),
    );
  }

  SliverPadding _buildMasonryGrid(ColorScheme cs) {
    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: PanAfricanSpacing.md),
      sliver: SliverToBoxAdapter(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final halfWidth =
                (constraints.maxWidth - PanAfricanSpacing.sm) / 2;

            return Wrap(
              spacing: PanAfricanSpacing.sm,
              runSpacing: PanAfricanSpacing.sm,
              children: _starredItems.asMap().entries.map((entry) {
                final index = entry.key;
                final item = entry.value;
                final isWide = index % 3 == 0;

                return SizedBox(
                  width: isWide ? constraints.maxWidth : halfWidth,
                  child: _buildStarredCard(item, cs),
                );
              }).toList(),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStarredCard(_StarredItem item, ColorScheme cs) {
    return GriotCard(
      surfaceLevel: 1,
      padding: EdgeInsets.all(PanAfricanSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: item.typeColor.withAlpha(25),
              borderRadius: ModernGriotRadius.borderPill,
            ),
            child: Text(
              item.type.toUpperCase(),
              style: TextStyle(
                fontSize: 10.sp,
                fontWeight: FontWeight.w700,
                color: item.typeColor,
                letterSpacing: 0.8,
              ),
            ),
          ),
          SizedBox(height: PanAfricanSpacing.sm),
          Text(
            item.text,
            style: ModernGriotTypography.bodyMedium(color: cs.onSurface),
            maxLines: 5,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: PanAfricanSpacing.sm),
          Row(
            children: [
              Text(
                item.timestamp,
                style: ModernGriotTypography.labelSmall(
                  color: cs.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => HapticFeedback.selectionClick(),
                child: Icon(
                  Icons.copy_rounded,
                  size: 18.sp,
                  color: cs.onSurfaceVariant,
                ),
              ),
              SizedBox(width: PanAfricanSpacing.sm),
              GestureDetector(
                onTap: () => HapticFeedback.selectionClick(),
                child: Icon(
                  Icons.share_outlined,
                  size: 18.sp,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  SliverFillRemaining _buildEmptyState(ColorScheme cs) {
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(PanAfricanSpacing.xxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 96.r,
                height: 96.r,
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHigh,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.star_outline_rounded,
                  size: 48.sp,
                  color: cs.onSurfaceVariant,
                ),
              ),
              SizedBox(height: PanAfricanSpacing.lg),
              Text(
                'No starred messages yet',
                style: ModernGriotTypography.titleMedium(color: cs.onSurface),
              ),
              SizedBox(height: PanAfricanSpacing.xs),
              Text(
                'Long-press any message in a chat to star it.\n'
                'Your cultural archive will grow here.',
                textAlign: TextAlign.center,
                style: ModernGriotTypography.bodySmall(
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip {
  final String label;
  final IconData icon;

  const _FilterChip({required this.label, required this.icon});
}

class _StarredItem {
  final String type;
  final String text;
  final String timestamp;
  final Color typeColor;

  const _StarredItem({
    required this.type,
    required this.text,
    required this.timestamp,
    required this.typeColor,
  });
}
