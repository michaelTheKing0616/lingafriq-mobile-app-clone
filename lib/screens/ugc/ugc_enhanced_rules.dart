String _words(List<String> parts) => parts.join(' ');

/// Checks copied from the enhanced quiz screen.
class EnhancedUgcCheck {
  const EnhancedUgcCheck({required this.errors, required this.badges});

  final List<String> errors;
  final List<String> badges;

  bool get passed => errors.isEmpty;

  String get message => errors.join('\n');
}

String ugcPleaseFixValidation() =>
    _words(const ['Please', 'fix', 'validation', 'errors.']);

String ugcPleaseEnterLessonContent() =>
    _words(const ['Please', 'enter', 'lesson', 'content']);

String ugcValidateContentLabel() => _words(const ['Validate', 'Content']);

String ugcValidateStoryLabel() => _words(const ['Validate', 'Story']);

String ugcQualityBadgesLabel() => _words(const ['Quality', 'Badges']);

String ugcValidationSummaryLabel() => _words(const ['Validation', 'Summary']);

String ugcViewValidationDetails() =>
    _words(const ['View', 'Validation', 'Details']);

String ugcViewFullDetails() => _words(const ['View', 'Full', 'Details']);

String _quizTitleRequired() => _words(const ['Quiz', 'title', 'is', 'required.']);

String _quizTitleShort() => _words(const [
      'Quiz',
      'title',
      'should',
      'be',
      'at',
      'least',
      '5',
      'characters.',
    ]);

String _quizNeedsQuestion() =>
    _words(const ['Add', 'at', 'least', 'one', 'question.']);

String _questionTextRequired(int number) => _words([
      'Question',
      '$number:',
      'question',
      'text',
      'is',
      'required.',
    ]);

String _questionOptionCount(int number) => _words([
      'Question',
      '$number:',
      'must',
      'have',
      '4',
      'options.',
    ]);

String _questionOptionRequired(int number, int option) => _words([
      'Question',
      '$number:',
      'option',
      '$option',
      'is',
      'required.',
    ]);

String _questionAnswerRequired(int number) => _words([
      'Question',
      '$number:',
      'select',
      'a',
      'valid',
      'correct',
      'answer.',
    ]);

String _clearTitleBadge() => _words(const ['Clear', 'title']);

String _hasDescriptionBadge() => _words(const ['Has', 'description']);

String _richQuizBadge() => _words(const ['Rich', 'quiz']);

String _validationPassedBadge() => _words(const ['Validation', 'passed']);

String _storyTitleRequired() =>
    _words(const ['Story', 'title', 'is', 'required.']);

String _storyTitleShort() => _words(const [
      'Story',
      'title',
      'should',
      'be',
      'at',
      'least',
      '5',
      'characters.',
    ]);

String _storyContentRequired() =>
    _words(const ['Story', 'content', 'is', 'required.']);

String _storyContentShort() => _words(const [
      'Story',
      'content',
      'should',
      'be',
      'at',
      'least',
      '50',
      'characters.',
    ]);

String _richContentBadge() => _words(const ['Rich', 'content']);

String _detailedStoryBadge() => _words(const ['Detailed', 'story']);

EnhancedUgcCheck checkEnhancedQuiz({
  required String title,
  required String description,
  required List<Map<String, dynamic>> questions,
}) {
  final errors = <String>[];
  final trimmedTitle = title.trim();
  final trimmedDescription = description.trim();

  if (trimmedTitle.isEmpty) errors.add(_quizTitleRequired());
  if (trimmedTitle.length < 5) errors.add(_quizTitleShort());
  if (questions.isEmpty) errors.add(_quizNeedsQuestion());

  for (var i = 0; i < questions.length; i++) {
    final question = questions[i];
    final questionText = (question['question'] ?? '').toString().trim();
    final options = (question['options'] as List?)
            ?.map((item) => item.toString().trim())
            .toList() ??
        const <String>[];
    final correct = question['correctAnswer'] is int
        ? question['correctAnswer'] as int
        : int.tryParse('${question['correctAnswer']}') ?? 0;
    final number = i + 1;

    if (questionText.isEmpty) errors.add(_questionTextRequired(number));
    if (options.length != 4) errors.add(_questionOptionCount(number));
    for (var j = 0; j < options.length; j++) {
      if (options[j].isEmpty) {
        errors.add(_questionOptionRequired(number, j + 1));
      }
    }
    if (correct < 0 || correct > 3) errors.add(_questionAnswerRequired(number));
  }

  final badges = <String>[];
  if (trimmedTitle.isNotEmpty && trimmedTitle.length >= 12) {
    badges.add(_clearTitleBadge());
  }
  if (trimmedDescription.isNotEmpty && trimmedDescription.length >= 20) {
    badges.add(_hasDescriptionBadge());
  }
  if (questions.length >= 5) badges.add(_richQuizBadge());
  if (errors.isEmpty) badges.add(_validationPassedBadge());

  return EnhancedUgcCheck(errors: errors, badges: badges);
}

EnhancedUgcCheck checkEnhancedStory({
  required String title,
  required String content,
}) {
  final errors = <String>[];
  final trimmedTitle = title.trim();
  final trimmedContent = content.trim();

  if (trimmedTitle.isEmpty) errors.add(_storyTitleRequired());
  if (trimmedTitle.length < 5) errors.add(_storyTitleShort());
  if (trimmedContent.isEmpty) {
    errors.add(_storyContentRequired());
  } else if (trimmedContent.length < 50) {
    errors.add(_storyContentShort());
  }

  final badges = <String>[];
  if (trimmedTitle.isNotEmpty && trimmedTitle.length >= 12) {
    badges.add(_clearTitleBadge());
  }
  if (trimmedContent.isNotEmpty && trimmedContent.length >= 200) {
    badges.add(_richContentBadge());
  }
  if (trimmedContent.isNotEmpty && trimmedContent.length >= 500) {
    badges.add(_detailedStoryBadge());
  }
  if (errors.isEmpty) badges.add(_validationPassedBadge());

  return EnhancedUgcCheck(errors: errors, badges: badges);
}

List<String> lessonQualityBadges(Map<String, dynamic>? validation) {
  if (validation == null) return const [];
  final badges = <String>[];
  if (_checkPassed(validation['grammarCheck'])) {
    badges.add('grammatically_perfect');
  }
  if (_checkPassed(validation['culturalCheck'])) {
    badges.add('culturally_authentic');
  }
  if (_checkPassed(validation['canonicalCheck'])) {
    badges.add('canonical_form');
  }
  return badges;
}

bool _checkPassed(Object? node) {
  return node is Map && node['passed'] == true;
}

String? lessonScoreLine(Map<String, dynamic>? validation) {
  if (validation == null) return null;
  final raw = validation['overallScore'] ?? 0;
  final score = raw is num ? raw.toInt() : 0;
  return _words(['Score:', '$score/100']);
}
