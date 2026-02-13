/// LingAfriq Avatar Intelligence System
/// 
/// A comprehensive avatar system that brings LingAfriq to life with 
/// African-themed animated characters across onboarding, Polie AI, 
/// 37+ games, gamification, and social/multiplayer experiences.
/// 
/// ## Features
/// 
/// - **Polie AI Avatar**: Afro-futurist AI companion with lip-sync
/// - **Game Avatars**: 4 category-specific characters (Malaika, Baba, Okonkwo, Nneka)
/// - **Onboarding Avatars**: 5 village characters (Elder, Weaver, Griot, Timekeeper, Pathfinder)
/// - **Gamification Integration**: Real-time reactions to XP, levels, streaks
/// - **Social Avatars**: Customizable user avatars, tribe avatars, battle avatars
/// - **Lip-Sync Engine**: Phoneme mapping for African languages
/// - **Avatar Intelligence**: Contextual responses and cross-system synergy
/// 
/// ## Quick Start
/// 
/// ```dart
/// import 'package:lingafriq/avatars/avatars.dart';
/// 
/// // Get the Polie AI avatar
/// final polieController = await AvatarEngine().getController(AvatarType.polie);
/// 
/// // Use in widget
/// PolieAvatar(controller: polieController)
/// 
/// // React to events
/// polieController.celebrate();
/// polieController.setEmotion(AvatarEmotion.proud);
/// 
/// // Use with Riverpod
/// final controller = ref.watch(polieControllerProvider);
/// 
/// // Handle events
/// ref.read(avatarEventHandlerProvider).handleEvent(AvatarEvent.levelUp);
/// ```

library avatars;

// Core systems
export 'avatar_engine.dart';
export 'emotion_system.dart';
export 'personality_system.dart';
export 'lip_sync_engine.dart';

// Providers
export 'avatar_providers.dart';
export 'avatar_intelligence.dart';

// Polie AI Avatar
export 'polie/polie_avatar.dart';
export 'polie/polie_avatar_controller.dart';

// Game Avatars
export 'games/game_avatar_widget.dart';

// Onboarding Avatars
export 'onboarding/onboarding_avatar_widget.dart';

// Gamification
export 'gamification/gamification_avatar_overlay.dart';

// Social/Multiplayer
export 'social/user_avatar_customizer.dart';
export 'social/tribe_avatar_widget.dart';
