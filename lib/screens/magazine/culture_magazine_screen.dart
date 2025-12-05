import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/models/culture_content_model.dart';
import 'package:lingafriq/utils/app_colors.dart';
import 'package:lingafriq/utils/utils.dart';
import 'package:lingafriq/utils/design_system.dart';
import 'package:lingafriq/widgets/error_boundary.dart';
import 'package:lingafriq/services/culture_magazine_service.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:lingafriq/screens/loading/dynamic_loading_screen.dart';

class CultureMagazineScreen extends ConsumerStatefulWidget {
  const CultureMagazineScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CultureMagazineScreen> createState() => _CultureMagazineScreenState();
}

class _CultureMagazineScreenState extends ConsumerState<CultureMagazineScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedCategory = 'All';
  
  // API state
  List<CultureContent> _allArticles = [];
  List<CultureContent> _featuredArticles = [];
  bool _isLoading = true;
  String? _errorMessage;
  late CultureMagazineService _cultureService;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this); // Updated for 6 categories
    _cultureService = CultureMagazineService(ref);
    _loadArticles();
  }
  
  Future<void> _loadArticles() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    
    try {
      // Load all articles and featured articles in parallel
      final results = await Future.wait([
        _cultureService.getArticles(limit: 100),
        _cultureService.getFeaturedArticles(),
      ]);
      
      setState(() {
        _allArticles = results[0];
        _featuredArticles = results[1];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load articles. Please try again.';
        _isLoading = false;
      });
      debugPrint('Error loading articles: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      errorMessage: 'Cultural Magazine is temporarily unavailable',
      onRetry: () {
        setState(() {});
      },
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final isDark = context.isDarkMode;
    
    // Show loading indicator
    if (_isLoading) {
      return const DynamicLoadingScreen();
    }
    
    // Show error message
    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: isDark ? const Color(0xFF102216) : const Color(0xFFF6F8F6),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _errorMessage!,
                style: TextStyle(
                  color: isDark ? Colors.white : Colors.black87,
                  fontSize: 16.sp,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16.h),
              ElevatedButton(
                onPressed: _loadArticles,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
    
    // Use API data
    final featuredContent = _featuredArticles;
    final allContent = _allArticles;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF102216) : const Color(0xFFF6F8F6),
      body: Stack(
        children: [
          // Gradient Header
          Container(
            height: 25.h,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFF6B35), // Orange
                  Color(0xFF7B2CBF), // Purple
                ],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40),
                bottomRight: Radius.circular(40),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.topLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.white.withOpacity(0.2),
                          shape: const CircleBorder(),
                        ),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    const Icon(
                      Icons.newspaper_rounded,
                      color: Colors.white,
                      size: 64,
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      'Cultural Magazines',
                      style: TextStyle(
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      'Explore African culture & heritage',
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Content
          Positioned(
            top: 22.h,
            left: 0,
            right: 0,
            bottom: 0,
            child: Column(
              children: [
                // Category Cards
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(4.w),
                    child: Column(
                      children: [
                        _CategoryCard(
                          id: 'music',
                          name: 'Music',
                          icon: Icons.music_note_rounded,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFCE1126), Color(0xFFFF6B35)],
                          ),
                          articles: _allArticles.where((a) => a.type == ContentType.music).length,
                          onTap: () {
                            setState(() {
                              _selectedCategory = 'Music';
                              _tabController.animateTo(1);
                            });
                          },
                          isDark: isDark,
                        ),
                        SizedBox(height: 2.h),
                        _CategoryCard(
                          id: 'stories',
                          name: 'Stories',
                          icon: Icons.menu_book_rounded,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF007A3D), Color(0xFF00A8E8)],
                          ),
                          articles: _allArticles.where((a) => a.type == ContentType.story || a.type == ContentType.lore).length,
                          onTap: () {
                            setState(() {
                              _selectedCategory = 'Stories';
                              _tabController.animateTo(2);
                            });
                          },
                          isDark: isDark,
                        ),
                        SizedBox(height: 2.h),
                        _CategoryCard(
                          id: 'articles',
                          name: 'Articles',
                          icon: Icons.newspaper_rounded,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFCD116), Color(0xFFFF6B35)],
                          ),
                          articles: _allArticles.where((a) => a.type == ContentType.article).length,
                          onTap: () {
                            setState(() {
                              _selectedCategory = 'Articles';
                              _tabController.animateTo(3);
                            });
                          },
                          isDark: isDark,
                        ),
                        SizedBox(height: 2.h),
                        _CategoryCard(
                          id: 'history',
                          name: 'History',
                          icon: Icons.public_rounded,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF7B2CBF), Color(0xFFCE1126)],
                          ),
                          articles: _allArticles.where((a) => a.type == ContentType.lore).length,
                          onTap: () {
                            setState(() {
                              _selectedCategory = 'History';
                              _tabController.animateTo(4);
                            });
                          },
                          isDark: isDark,
                        ),
                        SizedBox(height: 2.h),
                        _CategoryCard(
                          id: 'festivals',
                          name: 'Festivals',
                          icon: Icons.celebration_rounded,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFF6B35), Color(0xFF7B2CBF)],
                          ),
                          articles: _allArticles.where((a) => a.type == ContentType.festival).length,
                          onTap: () {
                            setState(() {
                              _selectedCategory = 'Festivals';
                              _tabController.animateTo(5);
                            });
                          },
                          isDark: isDark,
                        ),
                        SizedBox(height: 2.h),
                        _CategoryCard(
                          id: 'recipes',
                          name: 'Recipes',
                          icon: Icons.restaurant_rounded,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF00A8E8), Color(0xFF007A3D)],
                          ),
                          articles: _allArticles.where((a) => a.type == ContentType.recipe).length,
                          onTap: () {
                            setState(() {
                              _selectedCategory = 'Recipes';
                              _tabController.animateTo(6);
                            });
                          },
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllContent(
    BuildContext context,
    List<CultureContent> featured,
    List<CultureContent> all,
    bool isDark,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Featured Section
          if (featured.isNotEmpty) ...[
            Padding(
              padding: EdgeInsets.all(16.sp),
              child: Text(
                'Featured',
                style: TextStyle(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            SizedBox(
              height: 280.sp,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16.sp),
                itemCount: featured.length,
                itemBuilder: (context, index) {
                  return _buildFeaturedCard(context, featured[index], isDark);
                },
              ),
            ),
          ],
          
          // All Content
          Padding(
            padding: EdgeInsets.all(16.sp),
            child: Text(
              'Explore',
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
          ),
          ...all.map((content) => _buildContentCard(context, content, isDark)),
        ],
      ),
    );
  }

  Widget _buildCategoryContent(BuildContext context, ContentType type, bool isDark) {
    final content = _getMockContent().where((c) => c.type == type).toList();
    
    return ListView.builder(
      padding: EdgeInsets.all(16.sp),
      itemCount: content.length,
      itemBuilder: (context, index) {
        return _buildContentCard(context, content[index], isDark);
      },
    );
  }

  Widget _buildFeaturedCard(BuildContext context, CultureContent content, bool isDark) {
    return Container(
      width: 300.sp,
      margin: EdgeInsets.only(right: 12.sp),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // Image
            if (content.imageUrl != null)
              CachedNetworkImage(
                imageUrl: content.imageUrl!,
                width: double.infinity,
                height: double.infinity,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: isDark ? const Color(0xFF1F3527) : Colors.grey[200],
                  child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ),
                errorWidget: (context, url, error) => Container(
                  color: isDark ? const Color(0xFF1F3527) : Colors.grey[200],
                  child: Icon(Icons.image_not_supported),
                ),
              )
            else
              Container(
                color: AppColors.primaryGreen,
                child: Center(
                  child: Text(
                    _getTypeIcon(content.type),
                    style: TextStyle(fontSize: 48.sp),
                  ),
                ),
              ),
            
            // Gradient Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.8),
                    ],
                  ),
                ),
              ),
            ),
            
            // Content
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: EdgeInsets.all(16.sp),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.sp, vertical: 4.sp),
                      decoration: BoxDecoration(
                        color: AppColors.primaryGreen,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        content.type.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(height: 8.sp),
                    Text(
                      content.title,
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.sp),
                    Text(
                      content.description,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentCard(BuildContext context, CultureContent content, bool isDark) {
    return Container(
      margin: EdgeInsets.only(bottom: 16.sp),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F3527) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF2A4A35) : const Color(0xFFE5E5E5),
        ),
      ),
      child: InkWell(
        onTap: () => _showContentDetail(context, content, isDark),
        borderRadius: BorderRadius.circular(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: Container(
                width: 100.sp,
                height: 100.sp,
                color: AppColors.primaryGreen.withOpacity(0.2),
                child: content.imageUrl != null
                    ? CachedNetworkImage(
                        imageUrl: content.imageUrl!,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      )
                    : Center(
                        child: Text(
                          _getTypeIcon(content.type),
                          style: TextStyle(fontSize: 32.sp),
                        ),
                      ),
              ),
            ),
            
            // Content Info
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12.sp),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 6.sp, vertical: 2.sp),
                          decoration: BoxDecoration(
                            color: AppColors.primaryGreen.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            content.type.name.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryGreen,
                            ),
                          ),
                        ),
                        if (content.country != null) ...[
                          SizedBox(width: 8.sp),
                          Text(
                            content.country!,
                            style: TextStyle(
                              fontSize: 12.sp,
                              color: isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 6.sp),
                    Text(
                      content.title,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.sp),
                    Text(
                      content.description,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContentDetail(BuildContext context, CultureContent content, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F3527) : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: EdgeInsets.symmetric(vertical: 12.sp),
              width: 40.sp,
              height: 4.sp,
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16.sp),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (content.imageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: CachedNetworkImage(
                          imageUrl: content.imageUrl!,
                          width: double.infinity,
                          height: 200.sp,
                          fit: BoxFit.cover,
                        ),
                      ),
                    SizedBox(height: 16.sp),
                    Text(
                      content.title,
                      style: TextStyle(
                        fontSize: 24.sp,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    SizedBox(height: 8.sp),
                    Text(
                      content.content,
                      style: TextStyle(
                        fontSize: 16.sp,
                        height: 1.6,
                        color: isDark ? Colors.grey[300] : Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTypeIcon(ContentType type) {
    switch (type) {
      case ContentType.story:
        return '📖';
      case ContentType.music:
        return '🎵';
      case ContentType.festival:
        return '🎉';
      case ContentType.lore:
        return '📜';
      case ContentType.article:
        return '📰';
      case ContentType.recipe:
        return '🍲';
    }
  }

  List<CultureContent> _getMockFeaturedContent() {
    return [
      CultureContent(
        id: '1',
        title: 'The Story of Anansi',
        description: 'A timeless West African folktale',
        type: ContentType.story,
        content: 'Long ago, in the forests of West Africa, there lived a clever spider named Anansi...',
        language: 'English',
        country: '🇬🇭',
        publishDate: DateTime.now(),
        isFeatured: true,
      ),
    ];
  }

  List<CultureContent> _getMockContent() {
    return [
      CultureContent(
        id: '2',
        title: 'Yoruba Festival of Osun',
        description: 'Celebrating the river goddess',
        type: ContentType.festival,
        content: 'The Osun Festival is one of Nigeria\'s most important cultural celebrations...',
        language: 'English',
        country: '🇳🇬',
        publishDate: DateTime.now().subtract(Duration(days: 2)),
      ),
      CultureContent(
        id: '3',
        title: 'Traditional Swahili Music',
        description: 'The rhythms of East Africa',
        type: ContentType.music,
        content: 'Swahili music blends Arabic, Indian, and African influences...',
        language: 'English',
        country: '🇰🇪',
        publishDate: DateTime.now().subtract(Duration(days: 5)),
      ),
    ];
  }
}

class _CategoryCard extends StatelessWidget {
  final String id;
  final String name;
  final IconData icon;
  final Gradient gradient;
  final int articles;
  final VoidCallback onTap;
  final bool isDark;
  
  const _CategoryCard({
    required this.id,
    required this.name,
    required this.icon,
    required this.gradient,
    required this.articles,
    required this.onTap,
    required this.isDark,
  });
  
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(DesignSystem.radiusXL),
        child: Container(
          padding: EdgeInsets.all(5.w),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F3527) : Colors.white,
            borderRadius: BorderRadius.circular(DesignSystem.radiusXL),
            boxShadow: DesignSystem.shadowLarge,
            border: Border.all(
              color: isDark ? const Color(0xFF2A4A35) : Colors.transparent,
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Opacity(
                  opacity: 0.05,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(DesignSystem.radiusXL),
                    ),
                  ),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      gradient: gradient,
                      borderRadius: BorderRadius.circular(DesignSystem.radiusL),
                      boxShadow: DesignSystem.shadowMedium,
                    ),
                    child: Icon(icon, color: Colors.white, size: 32),
                  ),
                  SizedBox(width: 4.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          '$articles articles',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

