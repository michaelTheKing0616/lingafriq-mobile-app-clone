import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../services/voice/audio_recording_service.dart';
import '../../services/voice/voice_api_service.dart';
import '../../widgets/voice/pronunciation_feedback_widget.dart';
import '../../providers/user_provider.dart';

/// Native Speaker Contribution Screen
/// 
/// Allows native speakers to contribute recordings for:
/// - Vocabulary pronunciation
/// - Sentence examples
/// - Correction phrases
/// - Cultural expressions
/// 
/// All contributions help improve the app's voice features.
class NativeSpeakerContributionScreen extends ConsumerStatefulWidget {
  const NativeSpeakerContributionScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<NativeSpeakerContributionScreen> createState() =>
      _NativeSpeakerContributionScreenState();
}

class _NativeSpeakerContributionScreenState
    extends ConsumerState<NativeSpeakerContributionScreen> {
  final AudioRecordingService _recorder = AudioRecordingService();
  
  String _selectedLanguage = 'Yoruba';
  String _selectedCategory = 'words';
  int _currentPromptIndex = 0;
  bool _isRecording = false;
  String? _lastRecordingPath;
  bool _hasConsented = false;
  int _recordingsCompleted = 0;
  
  // Sample prompts (would come from backend in production)
  final Map<String, Map<String, List<Map<String, String>>>> _prompts = {
    'Yoruba': {
      'words': [
        {'text': 'Ẹ kú àárọ̀', 'translation': 'Good morning', 'instructions': 'Speak clearly, naturally'},
        {'text': 'Ọmọ', 'translation': 'Child', 'instructions': 'Watch the tone on ọ'},
        {'text': 'Omi', 'translation': 'Water', 'instructions': 'Clear mid tone'},
        {'text': 'Ilé', 'translation': 'House', 'instructions': 'High tone on é'},
        {'text': 'Owó', 'translation': 'Money', 'instructions': 'Rising tone pattern'},
      ],
      'sentences': [
        {'text': 'Mo fẹ́ lọ sí ọjà', 'translation': 'I want to go to the market', 'instructions': 'Natural speed'},
        {'text': 'Báwo ni?', 'translation': 'How are you?', 'instructions': 'Question intonation'},
        {'text': 'Ẹ ṣé púpọ̀', 'translation': 'Thank you very much', 'instructions': 'Polite tone'},
      ],
      'corrections': [
        {'text': 'Rárá, kí i ṣe bẹ́ẹ̀', 'translation': 'No, not like that', 'instructions': 'Helpful tone'},
        {'text': 'Gbìyànjú lẹ́ẹ̀kan sí i', 'translation': 'Try again', 'instructions': 'Encouraging'},
        {'text': 'Ó dára!', 'translation': 'It\'s good!', 'instructions': 'Positive, celebratory'},
      ],
    },
    'Swahili': {
      'words': [
        {'text': 'Habari', 'translation': 'Hello/News', 'instructions': 'Natural greeting tone'},
        {'text': 'Asante', 'translation': 'Thank you', 'instructions': 'Polite tone'},
        {'text': 'Chakula', 'translation': 'Food', 'instructions': 'Clear pronunciation'},
      ],
      'sentences': [
        {'text': 'Ninataka kwenda sokoni', 'translation': 'I want to go to the market', 'instructions': 'Natural speed'},
      ],
      'corrections': [
        {'text': 'Hapana, si hivyo', 'translation': 'No, not like that', 'instructions': 'Helpful tone'},
      ],
    },
    'Hausa': {
      'words': [
        {'text': 'Sannu', 'translation': 'Hello', 'instructions': 'Warm greeting'},
        {'text': 'Na gode', 'translation': 'Thank you', 'instructions': 'Grateful tone'},
      ],
      'sentences': [
        {'text': 'Ina so in tafi kasuwa', 'translation': 'I want to go to the market', 'instructions': 'Natural speed'},
      ],
      'corrections': [
        {'text': 'A\'a, ba haka ba', 'translation': 'No, not like that', 'instructions': 'Helpful tone'},
      ],
    },
  };
  
  List<Map<String, String>> get _currentPrompts =>
      _prompts[_selectedLanguage]?[_selectedCategory] ?? [];
  
  Map<String, String>? get _currentPrompt =>
      _currentPromptIndex < _currentPrompts.length 
          ? _currentPrompts[_currentPromptIndex] 
          : null;

  @override
  void initState() {
    super.initState();
    _recorder.requestPermission();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contribute Your Voice'),
        backgroundColor: isDark ? const Color(0xFF1F3527) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
        actions: [
          if (_recordingsCompleted > 0)
            Chip(
              label: Text('$_recordingsCompleted recorded'),
              backgroundColor: Colors.green.shade100,
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: _hasConsented 
          ? _buildContributionInterface(isDark)
          : _buildConsentScreen(isDark),
    );
  }

  Widget _buildConsentScreen(bool isDark) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.sp),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Center(
            child: Column(
              children: [
                Container(
                  padding: EdgeInsets.all(20.sp),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.record_voice_over,
                    size: 48.sp,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(height: 16.h),
                Text(
                  'Help Teach Your Language',
                  style: TextStyle(
                    fontSize: 24.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  'Your voice helps millions learn African languages',
                  style: TextStyle(
                    fontSize: 16.sp,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          SizedBox(height: 32.h),
          
          // Benefits
          _buildInfoSection(
            'What you\'ll do',
            [
              'Read words and phrases in your native language',
              'Help learners hear authentic pronunciation',
              'Contribute to preserving African languages',
            ],
            Icons.checklist,
            Colors.green,
          ),
          SizedBox(height: 16.h),
          
          _buildInfoSection(
            'What you\'ll get',
            [
              '⭐ Free premium features for contributors',
              '🏆 Recognition as a language ambassador',
              '📜 Certificate of contribution',
            ],
            Icons.card_giftcard,
            Colors.orange,
          ),
          SizedBox(height: 16.h),
          
          _buildInfoSection(
            'Your privacy',
            [
              'Recordings used only for language learning',
              'No biometric identification',
              'You can delete your recordings anytime',
              'Licensed under Creative Commons (CC-BY)',
            ],
            Icons.security,
            Colors.blue,
          ),
          SizedBox(height: 32.h),
          
          // Consent checkbox
          CheckboxListTile(
            value: false,
            onChanged: (value) {
              setState(() => _hasConsented = value ?? false);
            },
            title: Text(
              'I agree to contribute my voice recordings for language learning purposes under CC-BY license.',
              style: TextStyle(fontSize: 14.sp),
            ),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          SizedBox(height: 16.h),
          
          // Start button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                setState(() => _hasConsented = true);
              },
              icon: const Icon(Icons.mic),
              label: const Text('Start Contributing'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<String> items, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16.sp),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24.sp),
              SizedBox(width: 8.w),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ...items.map((item) => Padding(
            padding: EdgeInsets.only(bottom: 8.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• ', style: TextStyle(color: color)),
                Expanded(
                  child: Text(
                    item,
                    style: TextStyle(fontSize: 14.sp),
                  ),
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildContributionInterface(bool isDark) {
    return Column(
      children: [
        // Language and category selector
        Container(
          padding: EdgeInsets.all(16.sp),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F3527) : Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            children: [
              // Language dropdown
              DropdownButtonFormField<String>(
                value: _selectedLanguage,
                decoration: InputDecoration(
                  labelText: 'Your Native Language',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                items: _prompts.keys.map((lang) => DropdownMenuItem(
                  value: lang,
                  child: Text(lang),
                )).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedLanguage = value ?? _selectedLanguage;
                    _currentPromptIndex = 0;
                  });
                },
              ),
              SizedBox(height: 12.h),
              
              // Category chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildCategoryChip('words', 'Words'),
                    SizedBox(width: 8.w),
                    _buildCategoryChip('sentences', 'Sentences'),
                    SizedBox(width: 8.w),
                    _buildCategoryChip('corrections', 'Corrections'),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Progress indicator
        LinearProgressIndicator(
          value: _currentPrompts.isNotEmpty 
              ? (_currentPromptIndex + 1) / _currentPrompts.length 
              : 0,
          backgroundColor: Colors.grey.shade200,
          color: Colors.green,
        ),
        
        // Main content
        Expanded(
          child: _currentPrompt != null 
              ? _buildPromptCard() 
              : _buildCompletionCard(),
        ),
      ],
    );
  }

  Widget _buildCategoryChip(String value, String label) {
    final isSelected = _selectedCategory == value;
    return FilterChip(
      selected: isSelected,
      label: Text(label),
      onSelected: (selected) {
        setState(() {
          _selectedCategory = value;
          _currentPromptIndex = 0;
        });
      },
      selectedColor: Colors.green.shade100,
      checkmarkColor: Colors.green,
    );
  }

  Widget _buildPromptCard() {
    final prompt = _currentPrompt!;
    
    return Padding(
      padding: EdgeInsets.all(24.sp),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Progress text
          Text(
            '${_currentPromptIndex + 1} of ${_currentPrompts.length}',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey.shade600,
            ),
          ),
          SizedBox(height: 24.h),
          
          // Prompt card
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: EdgeInsets.all(24.sp),
              child: Column(
                children: [
                  // Native text (what to read)
                  Text(
                    prompt['text'] ?? '',
                    style: TextStyle(
                      fontSize: 32.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16.h),
                  
                  // Translation
                  Text(
                    prompt['translation'] ?? '',
                    style: TextStyle(
                      fontSize: 18.sp,
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16.h),
                  
                  // Instructions
                  Container(
                    padding: EdgeInsets.all(12.sp),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.info_outline, 
                             color: Colors.blue, 
                             size: 20.sp),
                        SizedBox(width: 8.w),
                        Text(
                          prompt['instructions'] ?? 'Speak naturally',
                          style: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.blue.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 32.h),
          
          // Recording button
          RecordingButton(
            isRecording: _isRecording,
            onPressed: _toggleRecording,
            amplitudeStream: _recorder.amplitudeStream,
          ),
          SizedBox(height: 16.h),
          
          Text(
            _isRecording ? 'Tap to stop' : 'Tap to record',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey.shade600,
            ),
          ),
          
          // Last recording playback
          if (_lastRecordingPath != null) ...[
            SizedBox(height: 24.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: _reRecord,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Re-record'),
                ),
                SizedBox(width: 16.w),
                ElevatedButton.icon(
                  onPressed: _submitAndNext,
                  icon: const Icon(Icons.check),
                  label: const Text('Submit & Next'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompletionCard() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.sp),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.celebration,
              size: 80.sp,
              color: Colors.amber,
            ),
            SizedBox(height: 24.h),
            Text(
              'Amazing Work! 🎉',
              style: TextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'You\'ve completed all $_selectedCategory in $_selectedLanguage!',
              style: TextStyle(
                fontSize: 16.sp,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8.h),
            Text(
              'Total recordings: $_recordingsCompleted',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            SizedBox(height: 32.h),
            
            // Options
            ElevatedButton.icon(
              onPressed: () {
                // Switch to next category
                final categories = ['words', 'sentences', 'corrections'];
                final currentIdx = categories.indexOf(_selectedCategory);
                final nextIdx = (currentIdx + 1) % categories.length;
                setState(() {
                  _selectedCategory = categories[nextIdx];
                  _currentPromptIndex = 0;
                });
              },
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Try Another Category'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: 24.w,
                  vertical: 16.h,
                ),
              ),
            ),
            SizedBox(height: 16.h),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Done for now'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      final path = await _recorder.stopRecording();
      setState(() {
        _isRecording = false;
        _lastRecordingPath = path;
      });
    } else {
      final path = await _recorder.startRecording();
      if (path != null) {
        setState(() {
          _isRecording = true;
          _lastRecordingPath = null;
        });
      } else {
        // Permission denied or error
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please grant microphone permission'),
          ),
        );
      }
    }
  }

  void _reRecord() {
    if (_lastRecordingPath != null) {
      _recorder.deleteRecording(_lastRecordingPath!);
    }
    setState(() {
      _lastRecordingPath = null;
    });
  }

  Future<void> _submitAndNext() async {
    if (_lastRecordingPath == null) return;
    
    // TODO: Upload recording to backend
    // For now, just move to next prompt
    
    setState(() {
      _recordingsCompleted++;
      _currentPromptIndex++;
      _lastRecordingPath = null;
    });
    
    // Clean up old recording
    await _recorder.deleteRecording(_lastRecordingPath!);
  }

  @override
  void dispose() {
    _recorder.cancelRecording();
    super.dispose();
  }
}

