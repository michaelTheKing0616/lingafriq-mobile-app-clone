// Translation Quality Metrics Service
// Tracks, measures, and improves translation quality across the app
// 
// Features:
// - Quality scoring based on user feedback
// - Model performance tracking
// - A/B testing for translation improvements
// - Analytics for continuous improvement

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

/// Quality rating from user
enum TranslationRating {
  excellent,  // 5 stars
  good,       // 4 stars
  okay,       // 3 stars
  poor,       // 2 stars
  wrong,      // 1 star
}

/// Translation quality feedback
class TranslationFeedback {
  final String id;
  final String sourceText;
  final String translatedText;
  final String sourceLang;
  final String targetLang;
  final String model;
  final TranslationRating rating;
  final String? correctedText;
  final String? userComment;
  final DateTime timestamp;
  final String? abTestVariant;

  TranslationFeedback({
    String? id,
    required this.sourceText,
    required this.translatedText,
    required this.sourceLang,
    required this.targetLang,
    required this.model,
    required this.rating,
    this.correctedText,
    this.userComment,
    DateTime? timestamp,
    this.abTestVariant,
  }) : id = id ?? const Uuid().v4(),
       timestamp = timestamp ?? DateTime.now();

  double get ratingScore {
    switch (rating) {
      case TranslationRating.excellent: return 1.0;
      case TranslationRating.good: return 0.8;
      case TranslationRating.okay: return 0.6;
      case TranslationRating.poor: return 0.4;
      case TranslationRating.wrong: return 0.2;
    }
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sourceText': sourceText,
    'translatedText': translatedText,
    'sourceLang': sourceLang,
    'targetLang': targetLang,
    'model': model,
    'rating': rating.name,
    'ratingScore': ratingScore,
    'correctedText': correctedText,
    'userComment': userComment,
    'timestamp': timestamp.toIso8601String(),
    'abTestVariant': abTestVariant,
  };

  factory TranslationFeedback.fromJson(Map<String, dynamic> json) {
    return TranslationFeedback(
      id: json['id'],
      sourceText: json['sourceText'] ?? '',
      translatedText: json['translatedText'] ?? '',
      sourceLang: json['sourceLang'] ?? 'en',
      targetLang: json['targetLang'] ?? 'yo',
      model: json['model'] ?? 'unknown',
      rating: TranslationRating.values.firstWhere(
        (r) => r.name == json['rating'],
        orElse: () => TranslationRating.okay,
      ),
      correctedText: json['correctedText'],
      userComment: json['userComment'],
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
      abTestVariant: json['abTestVariant'],
    );
  }
}

/// Model performance metrics
class ModelMetrics {
  final String model;
  final String languagePair;
  int totalTranslations;
  int feedbackCount;
  double averageRating;
  int excellentCount;
  int goodCount;
  int okayCount;
  int poorCount;
  int wrongCount;
  DateTime lastUpdated;

  ModelMetrics({
    required this.model,
    required this.languagePair,
    this.totalTranslations = 0,
    this.feedbackCount = 0,
    this.averageRating = 0.0,
    this.excellentCount = 0,
    this.goodCount = 0,
    this.okayCount = 0,
    this.poorCount = 0,
    this.wrongCount = 0,
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  double get qualityScore {
    if (feedbackCount == 0) return 0.5; // Default neutral score
    return averageRating;
  }

  void addFeedback(TranslationFeedback feedback) {
    feedbackCount++;
    
    switch (feedback.rating) {
      case TranslationRating.excellent: excellentCount++; break;
      case TranslationRating.good: goodCount++; break;
      case TranslationRating.okay: okayCount++; break;
      case TranslationRating.poor: poorCount++; break;
      case TranslationRating.wrong: wrongCount++; break;
    }
    
    // Recalculate average
    averageRating = (excellentCount * 1.0 + 
                     goodCount * 0.8 + 
                     okayCount * 0.6 + 
                     poorCount * 0.4 + 
                     wrongCount * 0.2) / feedbackCount;
    
    lastUpdated = DateTime.now();
  }

  Map<String, dynamic> toJson() => {
    'model': model,
    'languagePair': languagePair,
    'totalTranslations': totalTranslations,
    'feedbackCount': feedbackCount,
    'averageRating': averageRating,
    'excellentCount': excellentCount,
    'goodCount': goodCount,
    'okayCount': okayCount,
    'poorCount': poorCount,
    'wrongCount': wrongCount,
    'lastUpdated': lastUpdated.toIso8601String(),
  };

  factory ModelMetrics.fromJson(Map<String, dynamic> json) {
    return ModelMetrics(
      model: json['model'] ?? 'unknown',
      languagePair: json['languagePair'] ?? 'en-yo',
      totalTranslations: json['totalTranslations'] ?? 0,
      feedbackCount: json['feedbackCount'] ?? 0,
      averageRating: (json['averageRating'] ?? 0.0).toDouble(),
      excellentCount: json['excellentCount'] ?? 0,
      goodCount: json['goodCount'] ?? 0,
      okayCount: json['okayCount'] ?? 0,
      poorCount: json['poorCount'] ?? 0,
      wrongCount: json['wrongCount'] ?? 0,
      lastUpdated: json['lastUpdated'] != null 
          ? DateTime.parse(json['lastUpdated']) 
          : DateTime.now(),
    );
  }
}

/// A/B Test configuration
class ABTestConfig {
  final String testId;
  final String name;
  final String description;
  final Map<String, double> variants; // variant name -> weight
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;

  ABTestConfig({
    String? testId,
    required this.name,
    required this.description,
    required this.variants,
    DateTime? startDate,
    this.endDate,
    this.isActive = true,
  }) : testId = testId ?? const Uuid().v4(),
       startDate = startDate ?? DateTime.now();

  /// Select variant based on weights
  String selectVariant() {
    final random = DateTime.now().microsecondsSinceEpoch % 100 / 100;
    double cumulative = 0.0;
    
    for (final entry in variants.entries) {
      cumulative += entry.value;
      if (random < cumulative) {
        return entry.key;
      }
    }
    
    return variants.keys.first;
  }

  Map<String, dynamic> toJson() => {
    'testId': testId,
    'name': name,
    'description': description,
    'variants': variants,
    'startDate': startDate.toIso8601String(),
    'endDate': endDate?.toIso8601String(),
    'isActive': isActive,
  };

  factory ABTestConfig.fromJson(Map<String, dynamic> json) {
    return ABTestConfig(
      testId: json['testId'],
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      variants: Map<String, double>.from(json['variants'] ?? {'control': 1.0}),
      startDate: json['startDate'] != null 
          ? DateTime.parse(json['startDate']) 
          : DateTime.now(),
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      isActive: json['isActive'] ?? true,
    );
  }
}

/// Translation Quality Service
class TranslationQualityService {
  static final TranslationQualityService _instance = TranslationQualityService._internal();
  factory TranslationQualityService() => _instance;
  TranslationQualityService._internal();

  static const String _feedbackKey = 'translation_feedback';
  static const String _metricsKey = 'translation_metrics';
  static const String _abTestsKey = 'translation_ab_tests';
  static const String _userVariantsKey = 'user_ab_variants';
  static const int _maxStoredFeedback = 500;

  SharedPreferences? _prefs;
  bool _initialized = false;
  
  final List<TranslationFeedback> _feedbackQueue = [];
  final Map<String, ModelMetrics> _metrics = {};
  final Map<String, ABTestConfig> _abTests = {};
  final Map<String, String> _userVariants = {}; // testId -> assigned variant

  /// Initialize the service
  Future<void> initialize() async {
    if (_initialized) return;
    
    _prefs = await SharedPreferences.getInstance();
    await _loadData();
    _initialized = true;
    
    // Set up default A/B tests
    _setupDefaultABTests();
    
    debugPrint('TranslationQualityService initialized');
  }

  /// Load persisted data
  Future<void> _loadData() async {
    try {
      // Load feedback
      final feedbackJson = _prefs?.getString(_feedbackKey);
      if (feedbackJson != null) {
        final List<dynamic> feedbackList = json.decode(feedbackJson);
        _feedbackQueue.clear();
        _feedbackQueue.addAll(
          feedbackList.map((f) => TranslationFeedback.fromJson(f)).toList()
        );
      }

      // Load metrics
      final metricsJson = _prefs?.getString(_metricsKey);
      if (metricsJson != null) {
        final Map<String, dynamic> metricsMap = json.decode(metricsJson);
        _metrics.clear();
        metricsMap.forEach((key, value) {
          _metrics[key] = ModelMetrics.fromJson(value);
        });
      }

      // Load A/B tests
      final abTestsJson = _prefs?.getString(_abTestsKey);
      if (abTestsJson != null) {
        final Map<String, dynamic> testsMap = json.decode(abTestsJson);
        _abTests.clear();
        testsMap.forEach((key, value) {
          _abTests[key] = ABTestConfig.fromJson(value);
        });
      }

      // Load user variants
      final variantsJson = _prefs?.getString(_userVariantsKey);
      if (variantsJson != null) {
        final Map<String, dynamic> variantsMap = json.decode(variantsJson);
        _userVariants.clear();
        _userVariants.addAll(Map<String, String>.from(variantsMap));
      }
    } catch (e) {
      debugPrint('Failed to load translation quality data: $e');
    }
  }

  /// Save data to persistence
  Future<void> _saveData() async {
    try {
      await _prefs?.setString(
        _feedbackKey, 
        json.encode(_feedbackQueue.map((f) => f.toJson()).toList())
      );
      await _prefs?.setString(
        _metricsKey, 
        json.encode(_metrics.map((k, v) => MapEntry(k, v.toJson())))
      );
      await _prefs?.setString(
        _abTestsKey, 
        json.encode(_abTests.map((k, v) => MapEntry(k, v.toJson())))
      );
      await _prefs?.setString(
        _userVariantsKey, 
        json.encode(_userVariants)
      );
    } catch (e) {
      debugPrint('Failed to save translation quality data: $e');
    }
  }

  /// Set up default A/B tests
  void _setupDefaultABTests() {
    // Test: Google Translate vs NLLB as primary
    if (!_abTests.containsKey('primary_model_test')) {
      _abTests['primary_model_test'] = ABTestConfig(
        testId: 'primary_model_test',
        name: 'Primary Translation Model',
        description: 'Test Google Translate vs NLLB-200 as primary model',
        variants: {
          'google_primary': 0.7,    // 70% use Google first
          'nllb_primary': 0.3,      // 30% use NLLB first
        },
      );
    }

    // Test: Diacritics enforcement strength
    if (!_abTests.containsKey('diacritics_test')) {
      _abTests['diacritics_test'] = ABTestConfig(
        testId: 'diacritics_test',
        name: 'Diacritics Enforcement',
        description: 'Test strict vs lenient diacritics correction',
        variants: {
          'strict': 0.5,
          'lenient': 0.5,
        },
      );
    }
  }

  /// Record translation feedback
  Future<void> recordFeedback(TranslationFeedback feedback) async {
    if (!_initialized) await initialize();

    _feedbackQueue.add(feedback);
    
    // Enforce max size
    if (_feedbackQueue.length > _maxStoredFeedback) {
      _feedbackQueue.removeAt(0);
    }

    // Update metrics
    final metricsKey = '${feedback.model}_${feedback.sourceLang}_${feedback.targetLang}';
    final metrics = _metrics.putIfAbsent(
      metricsKey,
      () => ModelMetrics(
        model: feedback.model,
        languagePair: '${feedback.sourceLang}-${feedback.targetLang}',
      ),
    );
    metrics.addFeedback(feedback);

    await _saveData();
    
    debugPrint('Recorded feedback: ${feedback.rating.name} for ${feedback.model}');
  }

  /// Record translation (for counting without feedback)
  Future<void> recordTranslation({
    required String model,
    required String sourceLang,
    required String targetLang,
  }) async {
    if (!_initialized) await initialize();

    final metricsKey = '${model}_${sourceLang}_$targetLang';
    final metrics = _metrics.putIfAbsent(
      metricsKey,
      () => ModelMetrics(
        model: model,
        languagePair: '$sourceLang-$targetLang',
      ),
    );
    metrics.totalTranslations++;
    metrics.lastUpdated = DateTime.now();

    // Periodic save (every 10 translations)
    if (metrics.totalTranslations % 10 == 0) {
      await _saveData();
    }
  }

  /// Get A/B test variant for user
  String getABTestVariant(String testId) {
    if (!_initialized) {
      debugPrint('Warning: TranslationQualityService not initialized');
      return 'control';
    }

    // Check if user already assigned
    if (_userVariants.containsKey(testId)) {
      return _userVariants[testId]!;
    }

    // Check if test exists
    final test = _abTests[testId];
    if (test == null || !test.isActive) {
      return 'control';
    }

    // Assign variant
    final variant = test.selectVariant();
    _userVariants[testId] = variant;
    _saveData(); // Persist assignment

    debugPrint('Assigned A/B variant: $testId -> $variant');
    return variant;
  }

  /// Get model metrics
  ModelMetrics? getModelMetrics(String model, String sourceLang, String targetLang) {
    final key = '${model}_${sourceLang}_$targetLang';
    return _metrics[key];
  }

  /// Get all metrics
  Map<String, ModelMetrics> getAllMetrics() => Map.unmodifiable(_metrics);

  /// Get best model for language pair based on metrics
  String getBestModel(String sourceLang, String targetLang) {
    final candidates = _metrics.entries.where((e) => 
      e.value.languagePair == '$sourceLang-$targetLang' &&
      e.value.feedbackCount >= 5 // Require minimum feedback
    ).toList();

    if (candidates.isEmpty) {
      return 'google-translate'; // Default
    }

    candidates.sort((a, b) => b.value.qualityScore.compareTo(a.value.qualityScore));
    return candidates.first.value.model;
  }

  /// Get quality report
  Map<String, dynamic> getQualityReport() {
    final report = <String, dynamic>{
      'totalFeedback': _feedbackQueue.length,
      'metricsCount': _metrics.length,
      'activeABTests': _abTests.values.where((t) => t.isActive).length,
    };

    // Add top/bottom models by quality
    final sortedMetrics = _metrics.values.toList()
      ..sort((a, b) => b.qualityScore.compareTo(a.qualityScore));

    if (sortedMetrics.isNotEmpty) {
      report['topModel'] = sortedMetrics.first.toJson();
      if (sortedMetrics.length > 1) {
        report['bottomModel'] = sortedMetrics.last.toJson();
      }
    }

    // Add overall quality distribution
    int total = 0;
    int excellent = 0, good = 0, okay = 0, poor = 0, wrong = 0;
    
    for (final m in _metrics.values) {
      total += m.feedbackCount;
      excellent += m.excellentCount;
      good += m.goodCount;
      okay += m.okayCount;
      poor += m.poorCount;
      wrong += m.wrongCount;
    }

    if (total > 0) {
      report['qualityDistribution'] = {
        'excellent': (excellent / total * 100).toStringAsFixed(1),
        'good': (good / total * 100).toStringAsFixed(1),
        'okay': (okay / total * 100).toStringAsFixed(1),
        'poor': (poor / total * 100).toStringAsFixed(1),
        'wrong': (wrong / total * 100).toStringAsFixed(1),
      };
    }

    return report;
  }

  /// Clear all data
  Future<void> clearAllData() async {
    _feedbackQueue.clear();
    _metrics.clear();
    _userVariants.clear();
    await _prefs?.remove(_feedbackKey);
    await _prefs?.remove(_metricsKey);
    await _prefs?.remove(_userVariantsKey);
  }

  /// Export feedback for analysis
  List<Map<String, dynamic>> exportFeedback() {
    return _feedbackQueue.map((f) => f.toJson()).toList();
  }
}
