/// LingAfriq Learning Engine
///
/// The cognitive core of the language learning system.
/// All features (UI, games, AI, social) read from and write to
/// the learner model through this engine.
///
/// Architecture:
/// ```
/// Skill Graph (DAG)
///      ↓
/// Learner State Vector (per user, per skill)
///      ↓
/// Prediction Engine (BKT + HLR)
///      ↓
/// Lesson/Task Generator
/// ```
///
/// ## Modules
///
/// ### Core Math
/// - [HlrForgettingCurve] — Memory decay (half-life regression)
/// - [BktMastery] — Mastery probability (Bayesian knowledge tracing)
///
/// ### Skill Graph
/// - [SkillNode] — Atomic testable skill definition
/// - [SkillDependencyGraph] — DAG of skill prerequisites
/// - [SkillRegistry] — Registry of all skills per language
///
/// ### Learner Model
/// - [LearnerSkillState] — Per-user per-skill state vector
/// - [LearnerModelService] — CRUD, recommendations, cognitive metrics
/// - [ErrorDistribution] — Error probability vector per skill
///
/// ### Error Taxonomy
/// - [ErrorType] — Classified error types (universal + language-family)
/// - [ErrorTaxonomy] — Error analysis utilities
///
/// ### Pronunciation
/// - [PhonemeAlignment] — DTW-based phoneme alignment
/// - [PronunciationPipeline] — End-to-end pronunciation evaluation
///
/// ### Game Integration
/// - [LearningGame] — Abstract base for learning-aware games
/// - [LearningGameMixin] — Auto learner model integration

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
