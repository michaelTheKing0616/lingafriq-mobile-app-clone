import 'package:flutter/material.dart';

/// Tracks consecutive correct answers and calculates XP multipliers
class ComboTracker extends ChangeNotifier {
  int _consecutiveCorrect = 0;
  int _maxCombo = 0;
  
  int get consecutiveCorrect => _consecutiveCorrect;
  int get maxCombo => _maxCombo;
  
  /// Get current XP multiplier based on combo count
  double get currentMultiplier {
    if (_consecutiveCorrect >= 10) return 4.0;
    if (_consecutiveCorrect >= 7) return 3.0;
    if (_consecutiveCorrect >= 4) return 2.0;
    if (_consecutiveCorrect >= 2) return 1.5;
    return 1.0;
  }
  
  /// Check if combo is active (>= 2)
  bool get hasCombo => _consecutiveCorrect >= 2;
  
  /// Record a correct answer and increment combo
  void recordCorrect() {
    _consecutiveCorrect++;
    if (_consecutiveCorrect > _maxCombo) {
      _maxCombo = _consecutiveCorrect;
    }
    notifyListeners();
  }
  
  /// Record an incorrect answer and reset combo
  void recordIncorrect() {
    _consecutiveCorrect = 0;
    notifyListeners();
  }
  
  /// Reset combo tracker (e.g., when starting new quiz/game)
  void reset() {
    _consecutiveCorrect = 0;
    _maxCombo = 0;
    notifyListeners();
  }
}
