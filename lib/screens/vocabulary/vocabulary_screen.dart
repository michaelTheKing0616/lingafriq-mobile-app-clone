import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../services/vocabulary/vocabulary_service.dart';
import '../../providers/user_provider.dart';
import '../../utils/pan_african_design_system.dart';
import '../../widgets/loading/loading_overlay.dart';
import 'package:just_audio/just_audio.dart';

/// Vocabulary Screen - View and manage learned words
class VocabularyScreen extends ConsumerStatefulWidget {
  final String? language;

  const VocabularyScreen({
    Key? key,
    this.language,
  }) : super(key: key);

  @override
  ConsumerState<VocabularyScreen> createState() => _VocabularyScreenState();
}

class _VocabularyScreenState extends ConsumerState<VocabularyScreen> {
  late final VocabularyService _vocabService;
  final AudioPlayer _audioPlayer = AudioPlayer();
  List<VocabWord> _words = [];
  bool _isLoading = true;
  String _filter = 'all'; // all, mastered, learning, new
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _vocabService = ref.read(vocabularyServiceProvider);
    _loadWords();
  }

  Future<void> _loadWords() async {
    setState(() => _isLoading = true);
    try {
      // VocabularyService maintains a local word bank and syncs opportunistically.
      final words = widget.language == null
          ? _vocabService.allWords
          : _vocabService.getWordsByLanguage(widget.language!);

      if (!mounted) return;
      setState(() {
        _words = words;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading vocabulary: $e');
      setState(() => _isLoading = false);
    }
  }

  List<VocabWord> get _filteredWords {
    var filtered = _words;
    
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((w) =>
        w.word.toLowerCase().contains(_searchQuery.toLowerCase()) ||
        w.translation.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }
    
    switch (_filter) {
      case 'mastered':
        filtered = filtered.where((w) => w.masteryLevel >= 4).toList();
        break;
      case 'learning':
        filtered = filtered.where((w) => w.masteryLevel >= 1 && w.masteryLevel < 4).toList();
        break;
      case 'new':
        filtered = filtered.where((w) => w.masteryLevel == 0).toList();
        break;
    }
    
    return filtered;
  }

  Future<void> _playAudio(String? audioUrl) async {
    if (audioUrl == null || audioUrl.isEmpty) return;
    try {
      await _audioPlayer.setUrl(audioUrl);
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('Error playing audio: $e');
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Vocabulary'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadWords,
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: Column(
          children: [
            // Search and filter
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                children: [
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Search words...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(PanAfricanRadius.md),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                  ),
                  SizedBox(height: 2.h),
                  Row(
                    children: [
                      _buildFilterChip('all', 'All'),
                      SizedBox(width: 2.w),
                      _buildFilterChip('new', 'New'),
                      SizedBox(width: 2.w),
                      _buildFilterChip('learning', 'Learning'),
                      SizedBox(width: 2.w),
                      _buildFilterChip('mastered', 'Mastered'),
                    ],
                  ),
                ],
              ),
            ),
            // Word list
            Expanded(
              child: _filteredWords.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.book, size: 64.sp, color: PanAfricanColors.neutralMedium),
                          SizedBox(height: 2.h),
                          Text(
                            _words.isEmpty
                                ? 'No words learned yet'
                                : 'No words match your filter',
                            style: TextStyle(fontSize: 16.sp),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(4.w),
                      itemCount: _filteredWords.length,
                      itemBuilder: (context, index) {
                        final word = _filteredWords[index];
                        return Card(
                          margin: EdgeInsets.only(bottom: 2.h),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getMasteryColor(word.masteryLevel),
                              child: Text(
                                word.masteryLevel.toString(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              word.word,
                              style: TextStyle(
                                fontSize: 18.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(word.translation),
                                if (word.pronunciation != null)
                                  Text(
                                    word.pronunciation!,
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: word.audioUrl != null
                                ? IconButton(
                                    icon: const Icon(Icons.volume_up),
                                    onPressed: () => _playAudio(word.audioUrl),
                                  )
                                : null,
                            onTap: () {
                              // Show word details
                              _showWordDetails(context, word);
                            },
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label) {
    final isSelected = _filter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _filter = value);
      },
    );
  }

  Color _getMasteryColor(int level) {
    switch (level) {
      case 0:
        return Colors.grey;
      case 1:
      case 2:
        return Colors.orange;
      case 3:
        return Colors.blue;
      case 4:
      case 5:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  void _showWordDetails(BuildContext context, VocabWord word) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              word.word,
              style: TextStyle(fontSize: 24.sp, fontWeight: FontWeight.bold),
            ),
            if (word.pronunciation != null)
              Text(
                word.pronunciation!,
                style: TextStyle(fontSize: 16.sp, fontStyle: FontStyle.italic),
              ),
            SizedBox(height: 2.h),
            Text(
              'Translation: ${word.translation}',
              style: TextStyle(fontSize: 16.sp),
            ),
            if (word.exampleSentences.isNotEmpty) ...[
              SizedBox(height: 2.h),
              Text(
                'Examples:',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
              ),
              ...word.exampleSentences.map((s) => Padding(
                    padding: EdgeInsets.only(top: 1.h),
                    child: Text('• $s', style: TextStyle(fontSize: 14.sp)),
                  )),
            ],
            if (word.culturalNote != null) ...[
              SizedBox(height: 2.h),
              Text(
                'Cultural Note:',
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
              ),
              Text(word.culturalNote!, style: TextStyle(fontSize: 14.sp)),
            ],
            SizedBox(height: 2.h),
            Text(
              'Mastery Level: ${word.masteryLevel}/5',
              style: TextStyle(fontSize: 14.sp),
            ),
          ],
        ),
      ),
    );
  }
}

