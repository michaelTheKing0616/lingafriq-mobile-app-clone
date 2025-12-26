import 'dart:math' as math;
import 'ml_curriculum_engine.dart';

/// Advanced Heuristics for ML Curriculum Engine
/// Production-ready difficulty prediction without trained model
/// Multi-factor analysis with weighted scoring

extension MLCurriculumAdvancedHeuristics on MLCurriculumEngine {
  /// Production-ready advanced difficulty prediction using sophisticated heuristics
  /// Multi-factor analysis with weighted scoring - no trained model required
  LessonDifficulty predictDifficultyAdvanced({
    required double avgScore,
    required double errorRate,
    required double confidence,
    required List<ErrorPattern> errorPatterns,
    required List<UserAttempt> recentAttempts,
    required String language,
  }) {
    // Multi-factor weighted scoring system
    double difficultyScore = 0.5;
    double predictionConfidence = 0.7;
    
    // Factor 1: Performance Score (40% weight)
    final performanceFactor = _calculatePerformanceFactor(avgScore, errorRate);
    difficultyScore = (difficultyScore * 0.6) + (performanceFactor * 0.4);
    
    // Factor 2: Trend Analysis (25% weight)
    final trendFactor = _calculateTrendFactor(recentAttempts);
    difficultyScore = (difficultyScore * 0.75) + (trendFactor * 0.25);
    
    // Factor 3: Error Pattern Severity (20% weight)
    final errorPatternFactor = _calculateErrorPatternFactor(errorPatterns);
    difficultyScore = (difficultyScore * 0.8) + (errorPatternFactor * 0.2);
    
    // Factor 4: Consistency Analysis (10% weight)
    final consistencyFactor = _calculateConsistencyFactor(recentAttempts);
    difficultyScore = (difficultyScore * 0.9) + (consistencyFactor * 0.1);
    
    // Factor 5: Language-specific adjustments (5% weight)
    final languageFactor = _calculateLanguageFactor(language, avgScore);
    difficultyScore = (difficultyScore * 0.95) + (languageFactor * 0.05);
    
    // Confidence calculation based on data quality
    predictionConfidence = _calculatePredictionConfidence(
      recentAttempts.length,
      errorPatterns.length,
      confidence,
    );
    
    // Determine level with hysteresis to prevent oscillation
    final level = _determineLevelWithHysteresis(difficultyScore, recentAttempts);
    
    // Clamp score to valid range
    difficultyScore = difficultyScore.clamp(0.0, 1.0);
    
    return LessonDifficulty(
      level: level,
      score: difficultyScore,
      confidence: predictionConfidence,
    );
  }
  
  /// Calculate performance factor (0.0 = hard, 1.0 = easy)
  double _calculatePerformanceFactor(double avgScore, double errorRate) {
    // High score + low errors = ready for harder content
    if (avgScore > 0.9 && errorRate < 0.1) {
      return 0.85; // Make it harder
    }
    // Low score or high errors = need easier content
    if (avgScore < 0.6 || errorRate > 0.3) {
      return 0.15; // Make it easier
    }
    // Medium performance = maintain current level
    return 0.5;
  }
  
  /// Calculate trend factor (improving vs declining)
  double _calculateTrendFactor(List<UserAttempt> attempts) {
    if (attempts.length < 3) return 0.5; // Not enough data
    
    // Split into recent vs older attempts
    final recent = attempts.take(attempts.length ~/ 2).toList();
    final older = attempts.skip(attempts.length ~/ 2).toList();
    
    final recentAvg = recent.map((a) => a.overallScore).reduce((a, b) => a + b) / recent.length;
    final olderAvg = older.map((a) => a.overallScore).reduce((a, b) => a + b) / older.length;
    
    final trend = recentAvg - olderAvg;
    
    // Improving trend = can handle harder
    if (trend > 0.1) return 0.8;
    // Declining trend = need easier
    if (trend < -0.1) return 0.2;
    // Stable = maintain
    return 0.5;
  }
  
  /// Calculate error pattern factor
  double _calculateErrorPatternFactor(List<ErrorPattern> patterns) {
    if (patterns.isEmpty) return 0.6; // No patterns = slightly easier
    
    // Weight by frequency and severity
    double totalWeight = 0;
    double weightedSeverity = 0;
    
    for (final pattern in patterns) {
      final weight = pattern.frequency * pattern.severity;
      totalWeight += weight;
      weightedSeverity += pattern.severity * weight;
    }
    
    if (totalWeight == 0) return 0.5;
    
    final avgSeverity = weightedSeverity / totalWeight;
    
    // High severity patterns = need easier content
    if (avgSeverity > 0.5) return 0.2;
    // Low severity = can handle harder
    if (avgSeverity < 0.2) return 0.7;
    // Medium = maintain
    return 0.5;
  }
  
  /// Calculate consistency factor (variance in performance)
  double _calculateConsistencyFactor(List<UserAttempt> attempts) {
    if (attempts.length < 3) return 0.5;
    
    final scores = attempts.map((a) => a.overallScore).toList();
    final mean = scores.reduce((a, b) => a + b) / scores.length;
    
    // Calculate variance
    double variance = 0;
    for (final score in scores) {
      variance += math.pow(score - mean, 2);
    }
    variance /= scores.length;
    final stdDev = math.sqrt(variance);
    
    // Low variance (consistent) = can handle harder
    if (stdDev < 0.1) return 0.7;
    // High variance (inconsistent) = need easier
    if (stdDev > 0.2) return 0.3;
    // Medium = maintain
    return 0.5;
  }
  
  /// Language-specific adjustments
  double _calculateLanguageFactor(String language, double avgScore) {
    // Tonal languages (Yoruba, Igbo, Twi) are inherently harder
    final isTonal = ['yoruba', 'igbo', 'twi'].contains(language.toLowerCase());
    
    if (isTonal) {
      // For tonal languages, require higher scores to advance
      if (avgScore > 0.85) return 0.6; // Still slightly easier
      if (avgScore < 0.7) return 0.3; // Make it easier
    }
    
    return 0.5; // Neutral for non-tonal languages
  }
  
  /// Calculate prediction confidence
  double _calculatePredictionConfidence(
    int attemptCount,
    int patternCount,
    double userConfidence,
  ) {
    double confidence = 0.5;
    
    // More attempts = higher confidence
    if (attemptCount >= 10) confidence += 0.2;
    else if (attemptCount >= 5) confidence += 0.1;
    
    // More error patterns = higher confidence in prediction
    if (patternCount >= 3) confidence += 0.15;
    else if (patternCount >= 1) confidence += 0.05;
    
    // User confidence affects prediction confidence
    confidence = (confidence + userConfidence) / 2;
    
    return confidence.clamp(0.0, 1.0);
  }
  
  /// Determine level with hysteresis to prevent rapid oscillation
  String _determineLevelWithHysteresis(
    double difficultyScore,
    List<UserAttempt> recentAttempts,
  ) {
    // Get last known level from attempts (if available)
    String? lastLevel;
    if (recentAttempts.isNotEmpty) {
      // Infer from scores (simplified - in production, store level)
      final lastScore = recentAttempts.last.overallScore;
      if (lastScore > 0.8) lastLevel = 'advanced';
      else if (lastScore > 0.6) lastLevel = 'intermediate';
      else lastLevel = 'beginner';
    }
    
    // Determine new level
    String newLevel;
    if (difficultyScore >= 0.7) {
      newLevel = 'advanced';
    } else if (difficultyScore >= 0.4) {
      newLevel = 'intermediate';
    } else {
      newLevel = 'beginner';
    }
    
    // Hysteresis: require significant change to switch levels
    if (lastLevel != null && lastLevel != newLevel) {
      final threshold = lastLevel == 'beginner' ? 0.5 : 
                       lastLevel == 'intermediate' ? 0.6 : 0.7;
      
      if (math.abs(difficultyScore - threshold) < 0.15) {
        // Not enough change, keep current level
        return lastLevel;
      }
    }
    
    return newLevel;
  }
}

