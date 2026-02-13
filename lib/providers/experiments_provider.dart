import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/utils/structured_logger.dart';

class ExperimentsState {
  final Map<String, bool> flags;
  final Map<String, String> variants;
  final bool loaded;
  final bool isLoading;
  final String? error;

  const ExperimentsState({
    this.flags = const {},
    this.variants = const {},
    this.loaded = false,
    this.isLoading = false,
    this.error,
  });

  ExperimentsState copyWith({
    Map<String, bool>? flags,
    Map<String, String>? variants,
    bool? loaded,
    bool? isLoading,
    String? error,
  }) {
    return ExperimentsState(
      flags: flags ?? this.flags,
      variants: variants ?? this.variants,
      loaded: loaded ?? this.loaded,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  String? variant(String key) => variants[key];
}

final experimentsProvider =
    NotifierProvider<ExperimentsNotifier, ExperimentsState>(() {
  return ExperimentsNotifier();
});

class ExperimentsNotifier extends Notifier<ExperimentsState> {
  @override
  ExperimentsState build() {
    // Load experiments lazily after first build
    Future.microtask(_load);
    return const ExperimentsState();
  }

  Future<void> _load() async {
    try {
      state = state.copyWith(isLoading: true);
      final api = ref.read(apiProvider.notifier);
      final config = await api.getExperimentsConfig();

      final flagsRaw =
          Map<String, dynamic>.from(config['flags'] as Map? ?? const {});
      final variantsRaw =
          Map<String, dynamic>.from(config['variants'] as Map? ?? const {});

      final flags = <String, bool>{};
      flagsRaw.forEach((key, value) {
        flags[key] = value == true;
      });

      final variants = <String, String>{};
      variantsRaw.forEach((key, value) {
        if (value != null) {
          variants[key] = value.toString();
        }
      });

      state = ExperimentsState(
        flags: flags,
        variants: variants,
        loaded: true,
      );
      state = state.copyWith(isLoading: false);
    } catch (e) {
      logger.error('Error loading experiments config', tag: 'experiments', error: e);
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load experiments config',
      );
    }
  }

  bool isEnabled(String flagKey) {
    return state.flags[flagKey] ?? false;
  }

  String? variant(String experimentKey) {
    return state.variants[experimentKey];
  }

  bool isVariant(String experimentKey, String value) {
    return state.variants[experimentKey] == value;
  }
}


