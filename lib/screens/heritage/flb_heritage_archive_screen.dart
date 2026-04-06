import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/models/culture_content_model.dart';
import 'package:lingafriq/screens/heritage/flb_heritage_detail_screen.dart';
import 'package:lingafriq/l10n/generated/app_localizations.dart';
import 'package:lingafriq/services/flb_heritage_service.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';

/// FLB Heritage — browse/search archive (API `tags=flb-heritage` + bundled fallback).
class FlbHeritageArchiveScreen extends ConsumerStatefulWidget {
  const FlbHeritageArchiveScreen({super.key});

  @override
  ConsumerState<FlbHeritageArchiveScreen> createState() =>
      _FlbHeritageArchiveScreenState();
}

class _FlbHeritageArchiveScreenState
    extends ConsumerState<FlbHeritageArchiveScreen> {
  final _searchCtrl = TextEditingController();
  List<CultureContent> _items = [];
  bool _loading = true;
  bool _loadFailed = false;
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
    _load();
  }

  void _onSearchChanged() {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), _load);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _loadFailed = false;
    });
    try {
      final svc = FlbHeritageService(ref);
      final list =
          await svc.loadItems(searchQuery: _searchCtrl.text.trim());
      if (!mounted) return;
      setState(() {
        _items = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadFailed = true;
        _items = [];
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor:
          isDark ? PanAfricanColors.surfaceDark : PanAfricanColors.surfaceLight,
      appBar: AppBar(
        title: Text(
          l10n.flbHeritageTitle,
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
            tooltip: l10n.flbHeritageRefresh,
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              HapticFeedback.selectionClick();
              _load();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: l10n.flbHeritageSearchHint,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchCtrl.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchCtrl.clear();
                          _load();
                        },
                      ),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14.r),
                ),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _load(),
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _buildBody(context, isDark, l10n),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    bool isDark,
    AppLocalizations l10n,
  ) {
    if (_loading) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 120.h),
          const Center(child: CircularProgressIndicator()),
        ],
      );
    }
    if (_loadFailed) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(24.w),
        children: [
          SizedBox(height: 80.h),
          Icon(Icons.wifi_off_rounded, size: 48.sp, color: Colors.orange),
          SizedBox(height: 12.h),
          Text(
            l10n.flbHeritageLoadError,
            textAlign: TextAlign.center,
            style: PanAfricanTypography.bodyLarge(context),
          ),
          SizedBox(height: 16.h),
          FilledButton(
            onPressed: _load,
            child: Text(l10n.tryAgain),
          ),
        ],
      );
    }
    if (_items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(24.w),
        children: [
          SizedBox(height: 80.h),
          Icon(Icons.inventory_2_outlined, size: 48.sp),
          SizedBox(height: 12.h),
          Text(
            l10n.flbHeritageEmptyMessage,
            textAlign: TextAlign.center,
            style: PanAfricanTypography.bodyLarge(context),
          ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 24.h),
      itemCount: _items.length,
      separatorBuilder: (_, __) => SizedBox(height: 12.h),
      itemBuilder: (context, i) {
        final item = _items[i];
        return _HeritageCard(
          item: item,
          isDark: isDark,
          onTap: () {
            HapticFeedback.mediumImpact();
            Navigator.of(context).pushNamed(
              '/flb-heritage-detail',
              arguments: FlbHeritageDetailArgs(item),
            );
          },
        );
      },
    );
  }
}

class _HeritageCard extends StatelessWidget {
  const _HeritageCard({
    required this.item,
    required this.isDark,
    required this.onTap,
  });

  final CultureContent item;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final img = item.imageUrl;
    return Material(
      color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
      borderRadius: BorderRadius.circular(16.r),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.all(12.r),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (img != null && img.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12.r),
                  child: CachedNetworkImage(
                    imageUrl: img,
                    width: 72.w,
                    height: 72.w,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      width: 72.w,
                      height: 72.w,
                      color: Colors.black12,
                      child: const Icon(Icons.image_outlined),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      width: 72.w,
                      height: 72.w,
                      color: Colors.black12,
                      child: const Icon(Icons.broken_image_outlined),
                    ),
                  ),
                )
              else
                Container(
                  width: 72.w,
                  height: 72.w,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.r),
                    gradient: PanAfricanGradients.sunset,
                  ),
                  child: Icon(Icons.menu_book_rounded,
                      color: Colors.white, size: 28.sp),
                ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: PanAfricanTypography.titleSmall(context),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: PanAfricanTypography.bodySmall(context),
                    ),
                    SizedBox(height: 6.h),
                    Wrap(
                      spacing: 6.w,
                      runSpacing: 4.h,
                      children: [
                        if (item.country != null)
                          Chip(
                            label: Text(item.country!,
                                style: TextStyle(fontSize: 10.sp)),
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        Chip(
                          label: Text(item.language,
                              style: TextStyle(fontSize: 10.sp)),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 22.sp),
            ],
          ),
        ),
      ),
    );
  }
}
