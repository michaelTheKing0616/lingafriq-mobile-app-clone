import 'package:flutter/material.dart';

/// Tracks consecutive correct answers and calculates XP multipliers
class ComboTracker extends ChangeNotifier {
  int _consecutiveCorrect = 0;
  int _maxCombo = 0;
  
  /// Optional callback for combo milestone celebrations
  /// Called when combo reaches milestones (5, 10, 15, 20, 25, 50, etc.)
  /// Parameter: current combo count
  void Function(int combo)? onMilestoneReached;
  
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
    
    // Check for combo milestones (5, 10, 15, 20, 25, 50, etc.)
    if (_consecutiveCorrect % 5 == 0 && _consecutiveCorrect > 0) {
      try {
        onMilestoneReached?.call(_consecutiveCorrect);
      } catch (e) {
        // Silently handle callback errors to prevent breaking combo tracking
      }
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
