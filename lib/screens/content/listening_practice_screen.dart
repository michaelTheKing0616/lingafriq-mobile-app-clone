import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/utils/polie_design_tokens.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:velocity_x/velocity_x.dart';

/// Listening Comprehension Practice Screen
/// Audio clips with comprehension questions, difficulty levels, fill-in-the-blank
class ListeningPracticeScreen extends ConsumerStatefulWidget {
  final String? language;

  const ListeningPracticeScreen({
    super.key,
    this.language,
  });

  @override
  ConsumerState<ListeningPracticeScreen> createState() => _ListeningPracticeScreenState();
}

class _ListeningPracticeScreenState extends ConsumerState<ListeningPracticeScreen> {
  List<ListeningExercise> _exercises = [];
  ListeningExercise? _currentExercise;
  String _selectedDifficulty = 'normal'; // slow, normal, fast
  bool _isLoading = true;
  bool _isPlaying = false;
  final AudioPlayer _audioPlayer = AudioPlayer();
  Map<String, String> _answers = {};
  final Map<String, bool> _completedExercises = {};

  @override
  void initState() {
    super.initState();
    _loadExercises();
    _audioPlayer.playerStateStream.listen((state) {
      setState(() {
        _isPlaying = state.playing;
      });
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadExercises() async {
    setState(() => _isLoading = true);
    
    try {
      // TODO: Replace with actual API call
      _exercises = _getDefaultExercises();
    } catch (e) {
      debugPrint('Error loading exercises: $e');
      _exercises = _getDefaultExercises();
    }
    
    setState(() => _isLoading = false);
  }

  List<ListeningExercise> _getDefaultExercises() {
    return [
      ListeningExercise(
        id: 'listen_1',
        title: 'Greeting Conversation',
        audioUrl: null, // TODO: Add actual audio URL
        difficulty: 'beginner',
        transcript: 'Jambo! Habari gani? Nzuri sana, asante.',
        questions: [
          ComprehensionQuestion(
            id: 'q1',
            type: QuestionType.multipleChoice,
            question: 'What does "Habari gani" mean?',
            options: ['How are you?', 'Good morning', 'Thank you', 'Goodbye'],
            correctAnswer: 'How are you?',
          ),
          ComprehensionQuestion(
            id: 'q2',
            type: QuestionType.fillInBlank,
            question: 'Complete: "Nzuri ___, asante"',
            correctAnswer: 'sana',
          ),
        ],
        language: widget.language ?? 'sw',
      ),
      ListeningExercise(
        id: 'listen_2',
        title: 'Market Shopping',
        audioUrl: null,
        difficulty: 'intermediate',
        transcript: 'Ninaomba bei. Bei gani? Hii ni shilingi mia tano.',
        questions: [
          ComprehensionQuestion(
            id: 'q1',
            type: QuestionType.multipleChoice,
            question: 'What is the person asking for?',
            options: ['Directions', 'Price', 'Help', 'Food'],
            correctAnswer: 'Price',
          ),
        ],
        language: widget.language ?? 'sw',
      ),
    ];
  }

  Future<void> _playAudio(String? audioUrl) async {
    if (audioUrl == null || audioUrl.isEmpty) {
      // Show message that audio is not available
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Audio not available')),
      );
      return;
    }

    try {
      if (_isPlaying) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.setUrl(audioUrl);
        await _audioPlayer.play();
      }
    } catch (e) {
      debugPrint('Error playing audio: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error playing audio')),
      );
    }
  }

  void _startExercise(ListeningExercise exercise) {
    setState(() {
      _currentExercise = exercise;
      _answers = {};
    });
  }

  void _submitAnswer(String questionId, String answer) {
    setState(() {
      _answers[questionId] = answer;
    });
  }

  Future<void> _completeExercise() async {
    if (_currentExercise == null) return;

    int correct = 0;
    for (final question in _currentExercise!.questions) {
      final answer = _answers[question.id];
      if (answer == question.correctAnswer) {
        correct++;
      }
    }

    final score = (correct / _currentExercise!.questions.length * 100).round();
    
    setState(() {
      _completedExercises[_currentExercise!.id] = true;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('listening_${_currentExercise!.id}', true);

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Exercise Complete!'),
          content: Text('Score: $score%\nCorrect: $correct/${_currentExercise!.questions.length}'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _currentExercise = null;
                  _answers = {};
                });
              },
              child: Text('Done'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;

    return Scaffold(
      backgroundColor: isDark ? PolieColors.obsidian : PolieColors.surfaceLight,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              PolieColors.primary,
              PolieColors.primaryDark,
              PolieColors.obsidian,
            ],
          ),
        ),
        child: SafeArea(
          child: _currentExercise == null
              ? _buildExerciseList(context)
              : _buildExerciseView(context),
        ),
      ),
    );
  }

  Widget _buildExerciseList(BuildContext context) {
    return Column(
      children: [
        _buildHeader(context),
        _buildDifficultySelector(context),
        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: PolieColors.electricTeal))
              : _buildExercisesList(context),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(PolieSpacing.md),
      child: Row(
        children: [
          Semantics(
            label: 'Go back',
            button: true,
            child: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: PolieColors.textPrimary, semanticLabel: 'Back'),
              onPressed: () {
                HapticFeedback.lightImpact();
                Navigator.of(context).pop();
              },
            ),
          ),
          SizedBox(width: PolieSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Listening Practice',
                  style: PolieTypography.h2(context).copyWith(
                    color: PolieColors.textPrimary,
                  ),
                ),
                Text(
                  'Improve your comprehension',
                  style: PolieTypography.bodySmall(context).copyWith(
                    color: PolieColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.1);
  }

  Widget _buildDifficultySelector(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: PolieSpacing.md),
      padding: EdgeInsets.all(PolieSpacing.sm),
      decoration: BoxDecoration(
        color: PolieColors.surfaceContainerLight.withOpacity(0.1),
        borderRadius: BorderRadius.circular(PolieRadius.md),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _DifficultyChip(
            label: 'Slow',
            value: 'slow',
            selected: _selectedDifficulty == 'slow',
            onTap: () => setState(() => _selectedDifficulty = 'slow'),
          ),
          _DifficultyChip(
            label: 'Normal',
            value: 'normal',
            selected: _selectedDifficulty == 'normal',
            onTap: () => setState(() => _selectedDifficulty = 'normal'),
          ),
          _DifficultyChip(
            label: 'Fast',
            value: 'fast',
            selected: _selectedDifficulty == 'fast',
            onTap: () => setState(() => _selectedDifficulty = 'fast'),
          ),
        ],
      ),
    );
  }

  Widget _buildExercisesList(BuildContext context) {
    final filteredExercises = _exercises.where((e) {
      if (_selectedDifficulty == 'slow') return e.difficulty == 'beginner';
      if (_selectedDifficulty == 'fast') return e.difficulty == 'advanced';
      return e.difficulty == 'intermediate' || e.difficulty == 'beginner';
    }).toList();

    if (filteredExercises.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.headphones_outlined, size: 64.sp, color: PolieColors.textSecondary),
            SizedBox(height: PolieSpacing.md),
            Text(
              'No exercises available',
              style: PolieTypography.h3(context).copyWith(
                color: PolieColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(PolieSpacing.md),
      itemCount: filteredExercises.length,
      itemBuilder: (context, index) {
        final exercise = filteredExercises[index];
        final isCompleted = _completedExercises[exercise.id] ?? false;
        return _ExerciseCard(
          exercise: exercise,
          isCompleted: isCompleted,
          onTap: () => _startExercise(exercise),
        )
            .animate(delay: (index * 50).ms)
            .fadeIn(duration: 200.ms)
            .slideX(begin: 0.1);
      },
    );
  }

  Widget _buildExerciseView(BuildContext context) {
    if (_currentExercise == null) return SizedBox.shrink();

    return Column(
      children: [
        _buildExerciseHeader(context),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(PolieSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAudioPlayer(context),
                SizedBox(height: PolieSpacing.lg),
                Text(
                  'Questions',
                  style: PolieTypography.h3(context).copyWith(
                    color: PolieColors.textPrimary,
                  ),
                ),
                SizedBox(height: PolieSpacing.md),
                ..._currentExercise!.questions.map((question) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: PolieSpacing.lg),
                    child: _buildQuestion(question),
                  );
                }),
                SizedBox(height: PolieSpacing.lg),
                Semantics(
                  label: 'Submit your answers',
                  button: true,
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.mediumImpact();
                        _completeExercise();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: PolieColors.success,
                        padding: EdgeInsets.symmetric(vertical: PolieSpacing.md),
                      ),
                      child: Text(
                        'Submit Answers',
                        style: PolieTypography.labelLarge(context).copyWith(
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExerciseHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(PolieSpacing.md),
      child: Row(
        children: [
          Semantics(
            label: 'Go back to exercise list',
            button: true,
            child: IconButton(
              icon: Icon(Icons.arrow_back_rounded, color: PolieColors.textPrimary, semanticLabel: 'Back'),
              onPressed: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _currentExercise = null;
                  _answers = {};
                });
              },
            ),
          ),
          SizedBox(width: PolieSpacing.md),
          Expanded(
            child: Text(
              _currentExercise?.title ?? '',
              style: PolieTypography.h2(context).copyWith(
                color: PolieColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAudioPlayer(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(PolieSpacing.lg),
      decoration: BoxDecoration(
        color: PolieColors.surfaceContainerLight.withOpacity(0.1),
        borderRadius: BorderRadius.circular(PolieRadius.lg),
      ),
      child: Column(
        children: [
          Semantics(
            label: _isPlaying ? 'Pause audio' : 'Play audio',
            button: true,
            child: IconButton(
              icon: Icon(
                _isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                size: 64.sp,
                color: PolieColors.electricTeal,
                semanticLabel: _isPlaying ? 'Pause' : 'Play',
              ),
              onPressed: () => _playAudio(_currentExercise?.audioUrl),
            ),
          ),
          SizedBox(height: PolieSpacing.sm),
          Text(
            'Tap to play audio',
            style: PolieTypography.body(context).copyWith(
              color: PolieColors.textSecondary,
            ),
          ),
          if (_currentExercise?.transcript != null) ...[
            SizedBox(height: PolieSpacing.md),
            Semantics(
              label: 'Transcript: ${_currentExercise!.transcript}',
              child: Container(
                padding: EdgeInsets.all(PolieSpacing.md),
                decoration: BoxDecoration(
                  color: PolieColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(PolieRadius.md),
                ),
                child: Text(
                  'Transcript: ${_currentExercise!.transcript}',
                  style: PolieTypography.body(context),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildQuestion(ComprehensionQuestion question) {
    switch (question.type) {
      case QuestionType.multipleChoice:
        return _buildMultipleChoiceQuestion(question);
      case QuestionType.fillInBlank:
        return _buildFillInBlankQuestion(question);
    }
  }

  Widget _buildMultipleChoiceQuestion(ComprehensionQuestion question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question.question,
          style: PolieTypography.titleMedium(context).copyWith(
            color: PolieColors.textPrimary,
          ),
        ),
        SizedBox(height: PolieSpacing.md),
        ...question.options!.map((option) {
          final isSelected = _answers[question.id] == option;
          return Container(
            margin: EdgeInsets.only(bottom: PolieSpacing.sm),
            child: Material(
              color: Colors.transparent,
                child: Semantics(
                  label: 'Answer option: $option',
                  button: true,
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _submitAnswer(question.id, option);
                    },
                    borderRadius: BorderRadius.circular(PolieRadius.md),
                    child: Container(
                  padding: EdgeInsets.all(PolieSpacing.md),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? PolieColors.electricTeal.withOpacity(0.2)
                        : PolieColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(PolieRadius.md),
                    border: Border.all(
                      color: isSelected
                          ? PolieColors.electricTeal
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                        color: isSelected ? PolieColors.electricTeal : PolieColors.textSecondary,
                      ),
                      SizedBox(width: PolieSpacing.sm),
                      Expanded(
                        child: Text(
                          option,
                          style: PolieTypography.body(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          );
        }),
      ],
    );
  }

  Widget _buildFillInBlankQuestion(ComprehensionQuestion question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question.question,
          style: PolieTypography.titleMedium(context).copyWith(
            color: PolieColors.textPrimary,
          ),
        ),
        SizedBox(height: PolieSpacing.md),
        Semantics(
          label: 'Type your answer for: ${question.question}',
          textField: true,
          child: TextField(
            onChanged: (value) => _submitAnswer(question.id, value),
            decoration: InputDecoration(
              hintText: 'Type your answer',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(PolieRadius.md),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class ListeningExercise {
  final String id;
  final String title;
  final String? audioUrl;
  final String difficulty;
  final String transcript;
  final List<ComprehensionQuestion> questions;
  final String language;

  ListeningExercise({
    required this.id,
    required this.title,
    this.audioUrl,
    required this.difficulty,
    required this.transcript,
    required this.questions,
    required this.language,
  });
}

class ComprehensionQuestion {
  final String id;
  final QuestionType type;
  final String question;
  final List<String>? options;
  final String correctAnswer;

  ComprehensionQuestion({
    required this.id,
    required this.type,
    required this.question,
    this.options,
    required this.correctAnswer,
  });
}

enum QuestionType {
  multipleChoice,
  fillInBlank,
}

class _DifficultyChip extends StatelessWidget {
  final String label;
  final String value;
  final bool selected;
  final VoidCallback onTap;

  const _DifficultyChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Difficulty: $label${selected ? ", selected" : ""}',
      button: true,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Container(
          padding: EdgeInsets.symmetric(
            horizontal: PolieSpacing.md,
            vertical: PolieSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: selected
                ? PolieColors.electricTeal.withOpacity(0.3)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(PolieRadius.pill),
            border: Border.all(
              color: selected ? PolieColors.electricTeal : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            style: PolieTypography.label(context).copyWith(
              color: selected ? PolieColors.electricTeal : PolieColors.textSecondary,
            ),
          ),
        ),
      ),
    ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  final ListeningExercise exercise;
  final bool isCompleted;
  final VoidCallback onTap;

  const _ExerciseCard({
    required this.exercise,
    required this.isCompleted,
    required this.onTap,
  });

  Color _getDifficultyColor() {
    switch (exercise.difficulty) {
      case 'beginner':
        return PolieColors.success;
      case 'intermediate':
        return PolieColors.goldEmber;
      case 'advanced':
        return PolieColors.error;
      default:
        return PolieColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.isDarkMode;
    final difficultyColor = _getDifficultyColor();

    return Container(
      margin: EdgeInsets.only(bottom: PolieSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? PolieColors.surfaceContainer : PolieColors.surfaceContainerLight,
        borderRadius: BorderRadius.circular(PolieRadius.lg),
        border: Border.all(
          color: isCompleted ? PolieColors.success.withOpacity(0.5) : difficultyColor.withOpacity(0.3),
          width: isCompleted ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: Semantics(
          label: '${exercise.title}. ${exercise.difficulty} difficulty. ${exercise.questions.length} questions',
          button: true,
          child: InkWell(
            onTap: () {
              HapticFeedback.mediumImpact();
              onTap();
            },
            borderRadius: BorderRadius.circular(PolieRadius.lg),
            child: Padding(
            padding: EdgeInsets.all(PolieSpacing.lg),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(PolieSpacing.md),
                  decoration: BoxDecoration(
                    color: difficultyColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(PolieRadius.md),
                  ),
                  child: Icon(
                    Icons.headphones_rounded,
                    color: difficultyColor,
                    size: 32.sp,
                  ),
                ),
                SizedBox(width: PolieSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              exercise.title,
                              style: PolieTypography.h3(context).copyWith(
                                color: PolieColors.textPrimary,
                              ),
                            ),
                          ),
                          if (isCompleted)
                            Semantics(
                              label: 'Completed',
                              child: Icon(
                                Icons.check_circle,
                                color: PolieColors.success,
                                size: 20.sp,
                                semanticLabel: 'Completed',
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: PolieSpacing.xs),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: PolieSpacing.sm,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: difficultyColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(PolieRadius.sm),
                            ),
                            child: Text(
                              exercise.difficulty.toUpperCase(),
                              style: PolieTypography.bodySmall(context).copyWith(
                                color: difficultyColor,
                                fontSize: 10.sp,
                              ),
                            ),
                          ),
                          SizedBox(width: PolieSpacing.sm),
                          Text(
                            '${exercise.questions.length} questions',
                            style: PolieTypography.bodySmall(context).copyWith(
                              color: PolieColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Semantics(
                  excludeSemantics: true,
                  child: Icon(
                    Icons.arrow_forward_ios,
                    size: 16.sp,
                    color: PolieColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}
