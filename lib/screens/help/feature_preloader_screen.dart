import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lingafriq/utils/african_theme.dart';
import 'package:lingafriq/utils/design_system.dart';

/// Informative pre-loader screen that explains new features and terminologies
/// Shown when users first encounter new features
class FeaturePreloaderScreen extends StatefulWidget {
  final String featureName;
  final String featureDescription;
  final List<FeatureTerm> terms;
  final List<FeatureTip> tips;
  final IconData icon;
  final VoidCallback? onComplete;
  final Duration? duration;

  const FeaturePreloaderScreen({
    Key? key,
    required this.featureName,
    required this.featureDescription,
    required this.terms,
    required this.tips,
    required this.icon,
    this.onComplete,
    this.duration,
  }) : super(key: key);

  @override
  State<FeaturePreloaderScreen> createState() => _FeaturePreloaderScreenState();
}

class _FeaturePreloaderScreenState extends State<FeaturePreloaderScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration ?? const Duration(seconds: 5),
      vsync: this,
    );
    _controller.forward().then((_) {
      widget.onComplete?.call();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalPages = 1 + (widget.terms.length > 0 ? 1 : 0) + (widget.tips.length > 0 ? 1 : 0);
    
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: _controller.value,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(AfricanTheme.primaryGreen),
            ),
            Expanded(
              child: PageView(
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                children: [
                  _buildIntroPage(),
                  if (widget.terms.isNotEmpty) _buildTermsPage(),
                  if (widget.tips.isNotEmpty) _buildTipsPage(),
                ],
              ),
            ),
            // Page indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(totalPages, (index) {
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: 4.w),
                  width: _currentPage == index ? 24.w : 8.w,
                  height: 8.h,
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? AfricanTheme.primaryGreen
                        : Colors.grey[300],
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                ).animate().scale(duration: 200.ms);
              }),
            ),
            SizedBox(height: 16.h),
            // Skip/Next button
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: () {
                        // Previous page logic would go here
                      },
                      child: const Text('Previous'),
                    )
                  else
                    const SizedBox.shrink(),
                  FilledButton(
                    onPressed: () {
                      if (_currentPage < totalPages - 1) {
                        // Next page logic
                      } else {
                        widget.onComplete?.call();
                      }
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: AfricanTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 12.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(DesignSystem.radiusRound),
                      ),
                    ),
                    child: Text(_currentPage < totalPages - 1 ? 'Next' : 'Got it!'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIntroPage() {
    return Padding(
      padding: EdgeInsets.all(24.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120.w,
            height: 120.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: AfricanTheme.africanSunset,
              boxShadow: AfricanTheme.africanShadow,
            ),
            child: Icon(
              widget.icon,
              size: 60.sp,
              color: Colors.white,
            ),
          )
              .animate()
              .scale(delay: 200.ms, duration: 600.ms, curve: Curves.elasticOut)
              .fadeIn(duration: 400.ms),
          SizedBox(height: 32.h),
          Text(
            widget.featureName,
            style: TextStyle(
              fontSize: 32.sp,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(delay: 400.ms, duration: 500.ms)
              .slideY(begin: 0.2, end: 0),
          SizedBox(height: 16.h),
          Text(
            widget.featureDescription,
            style: TextStyle(
              fontSize: 18.sp,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          )
              .animate()
              .fadeIn(delay: 600.ms, duration: 500.ms)
              .slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }

  Widget _buildTermsPage() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'New Terms',
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
            ),
          )
              .animate()
              .fadeIn(duration: 300.ms)
              .slideX(begin: -0.1),
          SizedBox(height: 24.h),
          ...widget.terms.map((term) => _buildTermCard(term)),
        ],
      ),
    );
  }

  Widget _buildTermCard(FeatureTerm term) {
    return Card(
      margin: EdgeInsets.only(bottom: 16.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignSystem.radiusL),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: AfricanTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Icons.info_outline_rounded,
                    color: AfricanTheme.primaryGreen,
                    size: 24.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    term.term,
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: AfricanTheme.primaryGreen,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              term.definition,
              style: TextStyle(fontSize: 16.sp),
            ),
            if (term.example != null) ...[
              SizedBox(height: 12.h),
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AfricanTheme.primaryGreen.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(
                    color: AfricanTheme.primaryGreen.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lightbulb_outline_rounded,
                      color: AfricanTheme.accentGold,
                      size: 20.sp,
                    ),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        'Example: ${term.example}',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1);
  }

  Widget _buildTipsPage() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pro Tips',
            style: TextStyle(
              fontSize: 28.sp,
              fontWeight: FontWeight.bold,
            ),
          )
              .animate()
              .fadeIn(duration: 300.ms)
              .slideX(begin: -0.1),
          SizedBox(height: 24.h),
          ...widget.tips.map((tip) => _buildTipCard(tip)),
        ],
      ),
    );
  }

  Widget _buildTipCard(FeatureTip tip) {
    return Card(
      margin: EdgeInsets.only(bottom: 16.h),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignSystem.radiusL),
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: AfricanTheme.accentGold.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                tip.icon ?? Icons.tips_and_updates_rounded,
                color: AfricanTheme.accentGold,
                size: 24.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tip.title,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    tip.description,
                    style: TextStyle(fontSize: 16.sp),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1);
  }
}

class FeatureTerm {
  final String term;
  final String definition;
  final String? example;

  FeatureTerm({
    required this.term,
    required this.definition,
    this.example,
  });
}

class FeatureTip {
  final String title;
  final String description;
  final IconData? icon;

  FeatureTip({
    required this.title,
    required this.description,
    this.icon,
  });
}

