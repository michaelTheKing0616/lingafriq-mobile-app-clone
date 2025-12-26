import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:dio/dio.dart';
import 'package:lingafriq/utils/pan_african_design_system.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/utils/integration_helpers.dart';
import 'package:lingafriq/utils/performance_utils.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lingafriq/screens/ugc/ugc_validation_feedback_screen.dart';
import 'package:lingafriq/screens/ugc/ugc_quality_badges_widget.dart';

/// Enhanced Create Story Screen with Validation Feedback
class CreateStoryScreenEnhanced extends HookConsumerWidget {
  const CreateStoryScreenEnhanced({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final titleController = useTextEditingController();
    final contentController = useTextEditingController();
    final selectedLanguage = useState('yoruba');
    final isSubmitting = useState(false);
    final validationResult = useState<Map<String, dynamic>?>(null);
    final qualityBadges = useState<List<String>>([]);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    Future<void> validateContent() async {
      // Similar validation logic
    }

    Future<void> submitStory() async {
      // Similar submission logic
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Create Story'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? PanAfricanGradients.darkSurface
              : LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    PanAfricanColors.surfaceLight,
                    PanAfricanColors.surfaceContainerLight,
                  ],
                ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(PanAfricanSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Quality Badges Preview
                if (qualityBadges.value.isNotEmpty)
                  Card(
                    color: PanAfricanColors.primaryContainer.withOpacity(0.3),
                    child: Padding(
                      padding: EdgeInsets.all(PanAfricanSpacing.md),
                      child: UGCQualityBadgesWidget(
                        badges: qualityBadges.value,
                        isDark: isDark,
                      ),
                    ),
                  ),
                SizedBox(height: PanAfricanSpacing.lg),

                // Title
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Story Title *',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? PanAfricanColors.surfaceContainerDark
                        : PanAfricanColors.surfaceContainerLight,
                  ),
                ),
                SizedBox(height: PanAfricanSpacing.md),

                // Content
                TextField(
                  controller: contentController,
                  decoration: InputDecoration(
                    labelText: 'Story Content *',
                    hintText: 'Write your story here...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                    ),
                    filled: true,
                    fillColor: isDark
                        ? PanAfricanColors.surfaceContainerDark
                        : PanAfricanColors.surfaceContainerLight,
                  ),
                  maxLines: 15,
                ),
                SizedBox(height: PanAfricanSpacing.lg),

                // Validate Button
                ElevatedButton.icon(
                  onPressed: validateContent,
                  icon: Icon(Icons.check_circle),
                  label: Text('Validate Story'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PanAfricanColors.secondary,
                    foregroundColor: Colors.black,
                  ),
                ),
                SizedBox(height: PanAfricanSpacing.xl),

                // Submit Button
                ElevatedButton(
                  onPressed: isSubmitting.value ? null : submitStory,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PanAfricanColors.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: PanAfricanSpacing.md),
                  ),
                  child: isSubmitting.value
                      ? CircularProgressIndicator()
                      : Text('Create Story'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

