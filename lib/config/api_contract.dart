import 'package:lingafriq/services/env_config.dart';

/// Canonical API path contracts shared by mobile features.
/// Keep this file aligned with backend route mounts in `src/routes/index.route.ts`.
class ApiContract {
  ApiContract._();

  static String get baseUrl => EnvConfig.backendBaseUrl.replaceAll(RegExp(r'/$'), '');

  // Auth
  static const String login = '/auth/jwt/create/';
  static const String refresh = '/auth/jwt/refresh/';

  // Accounts
  static const String usersSearch = '/accounts/auth/users/search';

  // Polie
  static const String polieRiveState = '/api/v1/polie/rive-state';
  static const String polieEvaluateGameTurn = '/api/v1/polie/evaluate-game-turn';
  static const String polieGameContent = '/api/games/game-content';

  static String url(String path) => '$baseUrl$path';
}
