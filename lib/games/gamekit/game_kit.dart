// Elite GameKit - Unified Game Engine
//
// This file exports all public GameKit APIs for easy importing.
// Use this for a clean, organized import:
//
// ```dart
// import 'package:lingafriq/games/gamekit/game_kit.dart';
// ```
//
// This provides access to:
// - Game engine and lifecycle management
// - Game factory and registry
// - Screen integration utilities
// - All game types and configurations

// Core game engine
export 'game_engine.dart';
export 'game.dart';
export 'game_session.dart';
export 'game_result.dart';
export 'game_turn_context.dart';
export 'game_scoring.dart';
export 'game_feedback.dart';
export 'game_difficulty.dart';
export 'game_animation_bridge.dart';

// Factory and registry
export 'all_games_registry.dart';
export 'batch_game_factory.dart';
export 'generic_game_template.dart';
export 'game_migration_helper.dart';

// Services and integration
export 'game_engine_service.dart';
export 'game_screen_integration.dart';

// Meta layer (for advanced features)
export 'game_meta_layer.dart';
