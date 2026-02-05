import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:just_audio/just_audio.dart';
import '../../services/vocabulary/vocabulary_service.dart';
import '../../providers/user_provider.dart';
import '../../utils/pan_african_design_system.dart';
import '../../widgets/loading/loading_overlay.dart';

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading vocabulary. Please try again.')),
        );
      }
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
      backgroundColor: isDark ? PanAfricanColors.surfaceDark : PanAfricanColors.surfaceLight,
      appBar: AppBar(
        title: Text('My Vocabulary', style: PanAfricanTypography.titleLarge(context)),
        backgroundColor: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
        foregroundColor: isDark ? PanAfricanColors.textPrimaryDark : PanAfricanColors.textPrimaryLight,
        leading: IconButton(
          icon: Icon(PanAfricanIcons.back),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.of(context).pop();
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              HapticFeedback.lightImpact();
              _loadWords();
            },
          ),
        ],
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        child: Column(
          children: [
            // Search and filter
            Padding(
              padding: EdgeInsets.all(PanAfricanSpacing.md),
              child: Column(
                children: [
                  TextField(
                    style: PanAfricanTypography.bodyLarge(context),
                    decoration: InputDecoration(
                      hintText: 'Search words...',
                      hintStyle: PanAfricanTypography.bodyMedium(context, color: PanAfricanColors.textSecondaryLight),
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: PanAfricanRadius.mdBR,
                      ),
                      filled: true,
                      fillColor: isDark ? PanAfricanColors.surfaceContainerDark : PanAfricanColors.surfaceContainerLight,
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                  ),
                  SizedBox(height: PanAfricanSpacing.md),
                  Row(
                    children: [
                      _buildFilterChip('all', 'All'),
                      SizedBox(width: PanAfricanSpacing.xs),
                      _buildFilterChip('new', 'New'),
                      SizedBox(width: PanAfricanSpacing.xs),
                      _buildFilterChip('learning', 'Learning'),
                      SizedBox(width: PanAfricanSpacing.xs),
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
                          Icon(PanAfricanIcons.book, size: 64.sp, color: PanAfricanColors.neutralMedium),
                          SizedBox(height: PanAfricanSpacing.md),
                          Text(
                            _words.isEmpty
                                ? 'No words learned yet'
                                : 'No words match your filter',
                            style: PanAfricanTypography.bodyLarge(context),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.all(PanAfricanSpacing.md),
                      itemCount: _filteredWords.length,
                      itemBuilder: (context, index) {
                        final word = _filteredWords[index];
                        return Container(
                          margin: EdgeInsets.only(bottom: PanAfricanSpacing.sm),
                          decoration: BoxDecoration(
                            color: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
                            borderRadius: PanAfricanRadius.lgBR,
                            boxShadow: PanAfricanShadows.sm,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: _getMasteryColor(word.masteryLevel),
                              child: Text(
                                word.masteryLevel.toString(),
                                style: PanAfricanTypography.labelMedium(context, color: Colors.white),
                              ),
                            ),
                            title: Text(
                              word.word,
                              style: PanAfricanTypography.titleMedium(context),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(word.translation, style: PanAfricanTypography.bodyMedium(context)),
                                if (word.pronunciation != null)
                                  Text(
                                    word.pronunciation!,
                                    style: PanAfricanTypography.bodySmall(context).copyWith(fontStyle: FontStyle.italic),
                                  ),
                              ],
                            ),
                            trailing: word.audioUrl != null
                                ? IconButton(
                                    icon: const Icon(Icons.volume_up),
                                    onPressed: () {
                                      HapticFeedback.lightImpact();
                                      _playAudio(word.audioUrl);
                                    },
                                  )
                                : null,
                            onTap: () {
                              HapticFeedback.lightImpact();
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return FilterChip(
      label: Text(label, style: PanAfricanTypography.labelMedium(context, color: isSelected ? Colors.white : (isDark ? PanAfricanColors.textPrimaryDark : PanAfricanColors.textPrimaryLight))),
      selected: isSelected,
      selectedColor: PanAfricanColors.primary,
      checkmarkColor: Colors.white,
      backgroundColor: isDark ? PanAfricanColors.surfaceContainerDark : PanAfricanColors.surfaceContainerLight,
      onSelected: (selected) {
        HapticFeedback.selectionClick();
        setState(() => _filter = value);
      },
    );
  }

  Color _getMasteryColor(int level) {
    switch (level) {
      case 0:
        return PanAfricanColors.neutralMedium;
      case 1:
      case 2:
        return PanAfricanColors.tertiary;
      case 3:
        return PanAfricanColors.kenteBlue;
      case 4:
      case 5:
        return PanAfricanColors.success;
      default:
        return PanAfricanColors.neutralMedium;
    }
  }

  void _showWordDetails(BuildContext context, VocabWord word) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? PanAfricanColors.cardDark : PanAfricanColors.cardLight,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(PanAfricanRadius.xl)),
      ),
      builder: (context) => Container(
        padding: EdgeInsets.all(PanAfricanSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                margin: EdgeInsets.only(bottom: PanAfricanSpacing.md),
                decoration: BoxDecoration(
                  color: PanAfricanColors.neutralLight,
                  borderRadius: PanAfricanRadius.roundBR,
                ),
              ),
            ),
            Text(
              word.word,
              style: PanAfricanTypography.headlineMedium(context),
            ),
            if (word.pronunciation != null)
              Text(
                word.pronunciation!,
                style: PanAfricanTypography.bodyLarge(context).copyWith(fontStyle: FontStyle.italic),
              ),
            SizedBox(height: PanAfricanSpacing.md),
            Text(
              'Translation: ${word.translation}',
              style: PanAfricanTypography.bodyLarge(context),
            ),
            if (word.exampleSentences.isNotEmpty) ...[
              SizedBox(height: PanAfricanSpacing.md),
              Text(
                'Examples:',
                style: PanAfricanTypography.titleSmall(context),
              ),
              ...word.exampleSentences.map((s) => Padding(
                    padding: EdgeInsets.only(top: PanAfricanSpacing.xs),
                    child: Text('• $s', style: PanAfricanTypography.bodyMedium(context)),
                  )),
            ],
            if (word.culturalNote != null) ...[
              SizedBox(height: PanAfricanSpacing.md),
              Text(
                'Cultural Note:',
                style: PanAfricanTypography.titleSmall(context),
              ),
              Text(word.culturalNote!, style: PanAfricanTypography.bodyMedium(context)),
            ],
            SizedBox(height: PanAfricanSpacing.md),
            Text(
              'Mastery Level: ${word.masteryLevel}/5',
              style: PanAfricanTypography.labelMedium(context),
            ),
            SizedBox(height: PanAfricanSpacing.md),
          ],
        ),
      ),
    );
  }
}

