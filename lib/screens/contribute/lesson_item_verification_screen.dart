import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../models/lesson_item_model.dart';
import '../../services/lesson_item_verification_service.dart';
import '../../utils/screen_helpers.dart';

class LessonItemVerificationScreen extends ConsumerStatefulWidget {
  final String? languageCode;

  const LessonItemVerificationScreen({
    super.key,
    this.languageCode,
  });

  @override
  ConsumerState<LessonItemVerificationScreen> createState() => _LessonItemVerificationScreenState();
}

class _LessonItemVerificationScreenState extends ConsumerState<LessonItemVerificationScreen> {
  late final LessonItemVerificationService _verificationService;
  final TextEditingController _commentsController = TextEditingController();
  final TextEditingController _textCorrectionController = TextEditingController();
  final TextEditingController _translationCorrectionController = TextEditingController();

  List<LessonItem> _pendingItems = [];
  LessonItem? _currentItem;
  int _currentIndex = 0;
  bool _isLoading = true;
  String? _error;

  bool? _toneCorrect;
  bool? _pronunciationCorrect;
  bool? _translationAccurate;
  bool? _culturalAppropriate;
  String _selectedStatus = 'approved';
  double _confidenceScore = 0.8;
  bool _showCorrections = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadPendingItems();
  }

  Future<void> _loadPendingItems() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final items = await safeAsync(
        () => _verificationService.getPendingVerification(
          languageCode: widget.languageCode,
          limit: 50,
        ),
        onError: (error) {
          setState(() {
            _error = error.toString();
            _isLoading = false;
          });
          return <Map<String, dynamic>>[];
        },
      );

      if (items != null) {
        setState(() {
          _pendingItems = items.map((json) => LessonItem.fromJson(json)).toList();
          if (_pendingItems.isNotEmpty) {
            _currentItem = _pendingItems[0];
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _submitVerification() async {
    if (_currentItem == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final corrections = _showCorrections && (
        _textCorrectionController.text.isNotEmpty ||
        _translationCorrectionController.text.isNotEmpty
      ) ? {
        if (_textCorrectionController.text.isNotEmpty)
          'text': _textCorrectionController.text,
        if (_translationCorrectionController.text.isNotEmpty)
          'translation': _translationCorrectionController.text,
      } : null;

      await safeAsync(
        () => _verificationService.submitVerification(
          itemId: _currentItem!.id,
          status: _selectedStatus,
          toneCorrect: _toneCorrect,
          pronunciationCorrect: _pronunciationCorrect,
          translationAccurate: _translationAccurate,
          culturalAppropriate: _culturalAppropriate,
          comments: _commentsController.text.isEmpty ? null : _commentsController.text,
          corrections: corrections,
          confidenceScore: _confidenceScore,
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Verification submitted successfully')),
        );

        _loadNextItem();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  void _loadNextItem() {
    if (_currentIndex < _pendingItems.length - 1) {
      setState(() {
        _currentIndex++;
        _currentItem = _pendingItems[_currentIndex];
        _resetForm();
      });
    } else {
      _loadPendingItems();
    }
  }

  void _resetForm() {
    _toneCorrect = null;
    _pronunciationCorrect = null;
    _translationAccurate = null;
    _culturalAppropriate = null;
    _selectedStatus = 'approved';
    _confidenceScore = 0.8;
    _showCorrections = false;
    _commentsController.clear();
    _textCorrectionController.clear();
    _translationCorrectionController.clear();
  }

  @override
  void dispose() {
    _commentsController.dispose();
    _textCorrectionController.dispose();
    _translationCorrectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _verificationService = ref.read(lessonItemVerificationServiceProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Lesson Items'),
        actions: [
          if (_pendingItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Center(
                child: Text('${_currentIndex + 1}/${_pendingItems.length}'),
              ),
            ),
        ],
      ),
      body: withErrorBoundary(
        _buildBody(),
        onRetry: _loadPendingItems,
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPendingItems,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_currentItem == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            const Text('No items pending verification'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadPendingItems,
              child: const Text('Refresh'),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildLessonItemCard(),
          const SizedBox(height: 24),
          _buildVerificationForm(),
          const SizedBox(height: 24),
          _buildSubmitButton(),
        ],
      ),
    );
  }

  Widget _buildLessonItemCard() {
    final item = _currentItem!;
    
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Chip(label: Text(item.language)),
                const SizedBox(width: 8),
                Chip(label: Text(item.level)),
                const SizedBox(width: 8),
                Chip(label: Text(item.category)),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              item.text,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            if (item.ipa != null) ...[
              const SizedBox(height: 8),
              Text(
                '/${item.ipa}/',
                style: TextStyle(fontSize: 18, color: Colors.grey[600], fontStyle: FontStyle.italic),
              ),
            ],
            if (item.tonePattern != null && item.tonePattern!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 4,
                children: item.tonePattern!.map((tone) => Chip(
                  label: Text(tone, style: const TextStyle(fontSize: 12)),
                  visualDensity: VisualDensity.compact,
                )).toList(),
              ),
            ],
            const Divider(height: 32),
            Text(
              item.translation,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            if (item.culturalNote != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 20),
                    const SizedBox(width: 8),
                    Expanded(child: Text(item.culturalNote!)),
                  ],
                ),
              ),
            ],
            if (item.exampleSentences != null && item.exampleSentences!.isNotEmpty) ...[
              const SizedBox(height: 16),
              ...item.exampleSentences!.map((example) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(example.text, style: const TextStyle(fontWeight: FontWeight.w500)),
                    Text(example.translation, style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildVerificationForm() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Verification Checklist',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildCheckboxField(
              'Tone correct',
              _toneCorrect,
              (value) => setState(() => _toneCorrect = value),
            ),
            _buildCheckboxField(
              'Pronunciation correct',
              _pronunciationCorrect,
              (value) => setState(() => _pronunciationCorrect = value),
            ),
            _buildCheckboxField(
              'Translation accurate',
              _translationAccurate,
              (value) => setState(() => _translationAccurate = value),
            ),
            _buildCheckboxField(
              'Culturally appropriate',
              _culturalAppropriate,
              (value) => setState(() => _culturalAppropriate = value),
            ),
            const SizedBox(height: 16),
            const Text('Status:'),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'approved', label: Text('Approve')),
                ButtonSegment(value: 'rejected', label: Text('Reject')),
                ButtonSegment(value: 'needs_revision', label: Text('Revise')),
              ],
              selected: {_selectedStatus},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _selectedStatus = newSelection.first;
                });
              },
            ),
            const SizedBox(height: 16),
            const Text('Confidence Score:'),
            Slider(
              value: _confidenceScore,
              min: 0.0,
              max: 1.0,
              divisions: 10,
              label: _confidenceScore.toStringAsFixed(1),
              onChanged: (value) => setState(() => _confidenceScore = value),
            ),
            const SizedBox(height: 16),
            CheckboxListTile(
              title: const Text('Provide corrections'),
              value: _showCorrections,
              onChanged: (value) => setState(() => _showCorrections = value ?? false),
            ),
            if (_showCorrections) ...[
              TextField(
                controller: _textCorrectionController,
                decoration: const InputDecoration(
                  labelText: 'Text correction',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _translationCorrectionController,
                decoration: const InputDecoration(
                  labelText: 'Translation correction',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _commentsController,
              decoration: const InputDecoration(
                labelText: 'Comments (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckboxField(String label, bool? value, ValueChanged<bool?> onChanged) {
    return CheckboxListTile(
      title: Text(label),
      value: value,
      onChanged: onChanged,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton.icon(
      onPressed: _isSubmitting ? null : _submitVerification,
      icon: _isSubmitting
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.check),
      label: Text(_isSubmitting ? 'Submitting...' : 'Submit Verification'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    );
  }
}

