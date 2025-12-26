import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/models/curriculum_model.dart';
import 'package:lingafriq/services/curriculum_service.dart';
import 'package:lingafriq/utils/app_colors.dart';
import 'package:lingafriq/utils/error_handler.dart';
import 'package:lingafriq/utils/integration_helpers.dart';
import 'package:lingafriq/utils/performance_utils.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Detailed lesson screen with AI-generated content
class LessonDetailScreen extends ConsumerStatefulWidget {
  final CurriculumLesson lesson;
  final String language;
  final String level;

  const LessonDetailScreen({
    Key? key,
    required this.lesson,
    required this.language,
    required this.level,
  }) : super(key: key);

  @override
  ConsumerState<LessonDetailScreen> createState() => _LessonDetailScreenState();
}

class _LessonDetailScreenState extends ConsumerState<LessonDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Map<String, dynamic>? _generatedContent;
  bool _isGenerating = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _generateContent();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _generateContent() async {
    setState(() => _isGenerating = true);
    
    await safeAsync(
      context: context,
      operation: () async {
        final curriculumService = ref.read(curriculumServiceProvider);
        final vocabObjects = widget.lesson.vocabObjects;
        
        final content = await curriculumService.generateLessonContent(
          language: widget.language,
          level: widget.level,
          lessonTitle: widget.lesson.title,
          vocab: vocabObjects.map((v) => v.toMap()).toList(),
          grammar: widget.lesson.grammar,
          topic: widget.lesson.title,
        );
        
        if (mounted) {
          setState(() {
            _generatedContent = content;
            _isGenerating = false;
          });
        }
      },
      errorContext: 'generateLessonContent',
      showError: true,
    );
    
    if (mounted && _isGenerating) {
      setState(() => _isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF102216) : const Color(0xFFF6F8F6),
      appBar: AppBar(
        title: Text(widget.lesson.title),
        backgroundColor: isDark ? const Color(0xFF1F3527) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Vocabulary', icon: Icon(Icons.book)),
            Tab(text: 'Grammar', icon: Icon(Icons.description)),
            Tab(text: 'Dialogue', icon: Icon(Icons.chat)),
            Tab(text: 'Exercises', icon: Icon(Icons.quiz)),
          ],
        ),
      ),
      body: _isGenerating
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  SizedBox(height: 16.sp),
                  Text(
                    'Generating lesson content with Polie...',
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildVocabularyTab(isDark),
                _buildGrammarTab(isDark),
                _buildDialogueTab(isDark),
                _buildExercisesTab(isDark),
              ],
            ),
    );
  }

  Widget _buildVocabularyTab(bool isDark) {
    final vocab = widget.lesson.vocabObjects;
    
    return OptimizedListView.builder(
      padding: EdgeInsets.all(16.sp),
      itemCount: vocab.length,
      itemBuilder: (context, index) {
        final word = vocab[index];
        return Card(
          margin: EdgeInsets.only(bottom: 12.sp),
          color: isDark ? const Color(0xFF1F3527) : Colors.white,
          child: ListTile(
            title: Text(
              word.word,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 4.sp),
                Text(
                  word.meaning,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
                if (word.pos != null) ...[
                  SizedBox(height: 4.sp),
                  Chip(
                    label: Text(word.pos!),
                    backgroundColor: AppColors.primaryGreen.withOpacity(0.2),
                  ),
                ],
                if (word.example != null) ...[
                  SizedBox(height: 8.sp),
                  Text(
                    'Example: ${word.example}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontStyle: FontStyle.italic,
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildGrammarTab(bool isDark) {
    final grammar = widget.lesson.grammar ?? [];
    final explanations = _generatedContent?['grammar_explanations'] as List? ?? [];
    
    return OptimizedListView.builder(
      padding: EdgeInsets.all(16.sp),
      itemCount: grammar.length,
      itemBuilder: (context, index) {
        final grammarPoint = grammar[index];
        final explanation = index < explanations.length
            ? ((explanations[index] as Map<String, dynamic>?)?['explanation'] as String?) ?? ''
            : '';
        
        return Card(
          margin: EdgeInsets.only(bottom: 12.sp),
          color: isDark ? const Color(0xFF1F3527) : Colors.white,
          child: ExpansionTile(
            title: Text(
              grammarPoint,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            children: [
              Padding(
                padding: EdgeInsets.all(16.sp),
                child: Text(
                  explanation.isNotEmpty
                      ? explanation
                      : 'Grammar explanation will be generated by Polie.',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDialogueTab(bool isDark) {
    final dialogue = widget.lesson.dialogue;
    final generatedDialogue = _generatedContent?['dialogue'] as Map?;
    
    final script = dialogue?.script ?? generatedDialogue?['script'] as List? ?? [];
    
    return OptimizedListView.builder(
      padding: EdgeInsets.all(16.sp),
      itemCount: script.length,
      itemBuilder: (context, index) {
        final line = script[index] as Map;
        final speaker = line['speaker'] ?? 'A';
        final text = line['text'] ?? '';
        
        return Container(
          margin: EdgeInsets.only(bottom: 12.sp),
          padding: EdgeInsets.all(16.sp),
          decoration: BoxDecoration(
            color: speaker == 'A'
                ? AppColors.primaryGreen.withOpacity(0.2)
                : (isDark ? const Color(0xFF2A4A35) : Colors.grey[100]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primaryGreen,
                child: Text(speaker),
              ),
              SizedBox(width: 12.sp),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildExercisesTab(bool isDark) {
    final exercises = widget.lesson.exercises;
    final generatedExercises = _generatedContent?['exercises'] as List? ?? [];
    
    final allExercises = [
      ...exercises.map((e) => {'type': e.type, 'items': e.items}),
      ...generatedExercises,
    ];
    
    return OptimizedListView.builder(
      padding: EdgeInsets.all(16.sp),
      itemCount: allExercises.length,
      itemBuilder: (context, index) {
        final exercise = allExercises[index] as Map;
        final type = exercise['type'] ?? '';
        final items = exercise['items'] as List? ?? [];
        
        return Card(
          margin: EdgeInsets.only(bottom: 12.sp),
          color: isDark ? const Color(0xFF1F3527) : Colors.white,
          child: Padding(
            padding: EdgeInsets.all(16.sp),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.toUpperCase(),
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryGreen,
                  ),
                ),
                SizedBox(height: 8.sp),
                ...items.map((item) => Padding(
                      padding: EdgeInsets.only(bottom: 4.sp),
                      child: Text(
                        item.toString(),
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: isDark ? Colors.grey[300] : Colors.grey[700],
                        ),
                      ),
                    )),
              ],
            ),
          ),
        );
      },
    );
  }
}

