import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/models/onboarding_data_model.dart';
import 'package:lingafriq/providers/onboarding_provider.dart';
import 'package:lingafriq/utils/supported_languages.dart';

/// Provider for structured learning paths
class LearningPathNotifier extends Notifier<LearningPath> {
  @override
  LearningPath build() {
    final onboarding = ref.watch(onboardingProvider);
    return _buildPathFromOnboarding(onboarding);
  }

  LearningPath _buildPathFromOnboarding(OnboardingData data) {
    // Determine path based on onboarding
    String pathType = 'explore'; // default
    if (data.selectedPath == 'career') {
      pathType = 'career';
    } else if (data.selectedPath == 'academic') {
      pathType = 'academic';
    }

    // Build structured path
    final path = LearningPath(
      type: pathType,
      currentLevel: data.proficiencyLevel ?? 'beginner',
      modules: _getModulesForPath(pathType, data.proficiencyLevel ?? 'beginner'),
      currentModuleIndex: 0,
      progress: 0.0,
    );

    return path;
  }

  List<LearningModule> _getModulesForPath(String pathType, String proficiency) {
    // All paths support all languages - content is language-agnostic in structure
    // Language-specific content comes from backend
    switch (pathType) {
      case 'career':
        return _getCareerModules(proficiency);
      case 'academic':
        return _getAcademicModules(proficiency);
      default:
        return _getExploreModules(proficiency);
    }
  }
  
  // Ensure all supported languages have learning paths
  bool isLanguageSupported(String language) {
    return SupportedLanguages.isSupported(language);
  }

  List<LearningModule> _getCareerModules(String proficiency) {
    return [
      LearningModule(
        id: 'career_1',
        title: 'Professional Greetings',
        description: 'Learn formal greetings for business settings',
        lessons: ['greeting_formal', 'introductions', 'business_etiquette'],
        estimatedTime: 30,
      ),
      LearningModule(
        id: 'career_2',
        title: 'Workplace Communication',
        description: 'Essential phrases for the workplace',
        lessons: ['meetings', 'emails', 'presentations'],
        estimatedTime: 45,
      ),
      LearningModule(
        id: 'career_3',
        title: 'Networking',
        description: 'Build professional relationships',
        lessons: ['networking', 'small_talk', 'follow_up'],
        estimatedTime: 30,
      ),
    ];
  }

  List<LearningModule> _getAcademicModules(String proficiency) {
    return [
      LearningModule(
        id: 'academic_1',
        title: 'Academic Vocabulary',
        description: 'Essential academic terms',
        lessons: ['academic_terms', 'research', 'analysis'],
        estimatedTime: 45,
      ),
      LearningModule(
        id: 'academic_2',
        title: 'Writing Skills',
        description: 'Academic writing in target language',
        lessons: ['essay_structure', 'citations', 'arguments'],
        estimatedTime: 60,
      ),
      LearningModule(
        id: 'academic_3',
        title: 'Classroom Communication',
        description: 'Participate in academic discussions',
        lessons: ['discussions', 'presentations', 'debates'],
        estimatedTime: 45,
      ),
    ];
  }

  List<LearningModule> _getExploreModules(String proficiency) {
    return [
      LearningModule(
        id: 'explore_1',
        title: 'Cultural Basics',
        description: 'Introduction to culture and customs',
        lessons: ['culture_intro', 'traditions', 'festivals'],
        estimatedTime: 30,
      ),
      LearningModule(
        id: 'explore_2',
        title: 'Everyday Conversations',
        description: 'Common phrases for daily life',
        lessons: ['greetings', 'shopping', 'dining'],
        estimatedTime: 45,
      ),
      LearningModule(
        id: 'explore_3',
        title: 'Travel Essentials',
        description: 'Phrases for traveling',
        lessons: ['directions', 'transportation', 'accommodation'],
        estimatedTime: 30,
      ),
    ];
  }

  void completeModule(String moduleId) {
    final modules = List<LearningModule>.from(state.modules);
    final index = modules.indexWhere((m) => m.id == moduleId);
    if (index != -1) {
      modules[index] = modules[index].copyWith(isCompleted: true);
      state = state.copyWith(
        modules: modules,
        currentModuleIndex: index + 1 < modules.length ? index + 1 : index,
        progress: _calculateProgress(modules),
      );
    }
  }

  double _calculateProgress(List<LearningModule> modules) {
    if (modules.isEmpty) return 0.0;
    final completed = modules.where((m) => m.isCompleted).length;
    return completed / modules.length;
  }
}

final learningPathProvider = NotifierProvider<LearningPathNotifier, LearningPath>(() {
  return LearningPathNotifier();
});

class LearningPath {
  final String type; // 'explore', 'career', 'academic'
  final String currentLevel;
  final List<LearningModule> modules;
  final int currentModuleIndex;
  final double progress;

  LearningPath({
    required this.type,
    required this.currentLevel,
    required this.modules,
    required this.currentModuleIndex,
    required this.progress,
  });

  LearningPath copyWith({
    String? type,
    String? currentLevel,
    List<LearningModule>? modules,
    int? currentModuleIndex,
    double? progress,
  }) {
    return LearningPath(
      type: type ?? this.type,
      currentLevel: currentLevel ?? this.currentLevel,
      modules: modules ?? this.modules,
      currentModuleIndex: currentModuleIndex ?? this.currentModuleIndex,
      progress: progress ?? this.progress,
    );
  }

  LearningModule? get currentModule {
    if (currentModuleIndex >= 0 && currentModuleIndex < modules.length) {
      return modules[currentModuleIndex];
    }
    return null;
  }
}

class LearningModule {
  final String id;
  final String title;
  final String description;
  final List<String> lessons;
  final int estimatedTime; // minutes
  final bool isCompleted;
  final bool isLocked;

  LearningModule({
    required this.id,
    required this.title,
    required this.description,
    required this.lessons,
    required this.estimatedTime,
    this.isCompleted = false,
    this.isLocked = false,
  });

  LearningModule copyWith({
    String? id,
    String? title,
    String? description,
    List<String>? lessons,
    int? estimatedTime,
    bool? isCompleted,
    bool? isLocked,
  }) {
    return LearningModule(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      lessons: lessons ?? this.lessons,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      isCompleted: isCompleted ?? this.isCompleted,
      isLocked: isLocked ?? this.isLocked,
    );
  }
}

