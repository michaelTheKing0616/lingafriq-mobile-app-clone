import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/dio_provider.dart';
import 'package:lingafriq/services/games/game_catalog_service.dart';

final gameCatalogServiceProvider = Provider<GameCatalogService>((ref) {
  return GameCatalogService(ref.read(client));
});
