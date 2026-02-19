// LingAfriq Learning Engine
//
// The cognitive core of the language learning system.
// All features (UI, games, AI, social) read from and write to
// the learner model through this engine.
//
// Architecture:
//   Skill Graph (DAG)
//        ↓
//   Learner State Vector (per user, per skill)
//        ↓
//   Prediction Engine (BKT + HLR)
//        ↓
//   Lesson/Task Generator

// Core math
export 'core/hlr_forgetting_curve.dart';
export 'core/bkt_mastery.dart';

// Skill graph
export 'skill_graph/skill_node.dart';
export 'skill_graph/dependency_graph.dart';
export 'skill_graph/skill_registry.dart';

// Learner model
export 'learner_model/learner_skill_state.dart';
export 'learner_model/learner_model_service.dart';
export 'learner_model/error_taxonomy.dart';

// Pronunciation
export 'pronunciation/phoneme_alignment.dart';
export 'pronunciation/pronunciation_pipeline.dart';

// Game integration
export 'game_integration/learning_game.dart';
