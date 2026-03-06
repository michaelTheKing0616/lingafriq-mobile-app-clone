import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/config/api_contract.dart';
import 'package:lingafriq/models/wa_status_model.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/utils/structured_logger.dart';

class WaStatusState {
  final bool loading;
  final List<WaStatusModel> feed;
  final List<WaStatusModel> mine;
  final String? errorMessage;

  const WaStatusState({
    required this.loading,
    required this.feed,
    required this.mine,
    this.errorMessage,
  });

  factory WaStatusState.initial() =>
      const WaStatusState(loading: false, feed: [], mine: [], errorMessage: null);

  WaStatusState copyWith({
    bool? loading,
    List<WaStatusModel>? feed,
    List<WaStatusModel>? mine,
    String? errorMessage,
  }) {
    return WaStatusState(
      loading: loading ?? this.loading,
      feed: feed ?? this.feed,
      mine: mine ?? this.mine,
      errorMessage: errorMessage,
    );
  }
}

class WaStatusNotifier extends Notifier<WaStatusState> {
  @override
  WaStatusState build() => WaStatusState.initial();

  Future<void> loadFeed() async {
    state = state.copyWith(loading: true, errorMessage: null);
    try {
      final response = await ApiService.get(ApiContract.url(ApiContract.wa.statusFeed));
      final list = _extractList(response.data);
      state = state.copyWith(
        loading: false,
        feed: list.map((item) => WaStatusModel.fromJson(item)).toList(),
        errorMessage: null,
      );
    } catch (error) {
      logger.error('Failed loading WA status feed', tag: 'wa-status', error: error);
      state = state.copyWith(loading: false, errorMessage: 'Could not load status feed.');
    }
  }

  Future<void> loadMine() async {
    state = state.copyWith(loading: true, errorMessage: null);
    try {
      final response = await ApiService.get(ApiContract.url(ApiContract.wa.statusMine));
      final list = _extractList(response.data);
      state = state.copyWith(
        loading: false,
        mine: list.map((item) => WaStatusModel.fromJson(item)).toList(),
        errorMessage: null,
      );
    } catch (error) {
      logger.error('Failed loading my WA statuses', tag: 'wa-status', error: error);
      state = state.copyWith(loading: false, errorMessage: 'Could not load your statuses.');
    }
  }

  Future<bool> createStatus({
    required String mediaType,
    String? mediaUrl,
    String? text,
    String? caption,
  }) async {
    final temp = WaStatusModel(
      id: 'tmp_${DateTime.now().millisecondsSinceEpoch}',
      userId: 'me',
      mediaUrl: mediaUrl ?? '',
      mediaType: mediaType,
      text: text ?? '',
      caption: caption ?? '',
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(hours: 24)),
    );
    state = state.copyWith(mine: [temp, ...state.mine], errorMessage: null);
    try {
      final response = await ApiService.post(
        ApiContract.url('/api/wa/status'),
        data: {
          'media_type': mediaType,
          'media_url': mediaUrl,
          'text': text,
          'caption': caption,
        },
      );
      final map = _extractMap(response.data);
      final data = _extractMap(map['data']);
      final created = data.isNotEmpty ? WaStatusModel.fromJson(data) : temp;
      state = state.copyWith(
        mine: [created, ...state.mine.where((status) => status.id != temp.id)],
      );
      return true;
    } catch (error) {
      logger.error('Failed creating status', tag: 'wa-status', error: error);
      state = state.copyWith(
        mine: state.mine.where((status) => status.id != temp.id).toList(),
        errorMessage: 'Could not create status.',
      );
      return false;
    }
  }

  Future<void> markViewed(String statusId) async {
    try {
      await ApiService.post(ApiContract.url(ApiContract.wa.statusView(statusId)));
    } catch (error) {
      logger.error('Failed marking status viewed', tag: 'wa-status', error: error);
    }
  }

  Future<List<Map<String, dynamic>>> loadViewers(String statusId) async {
    try {
      final response = await ApiService.get(ApiContract.url(ApiContract.wa.statusViewers(statusId)));
      return _extractList(response.data);
    } catch (error) {
      logger.error('Failed loading status viewers', tag: 'wa-status', error: error);
      return const [];
    }
  }

  Future<bool> deleteStatus(String statusId) async {
    final before = state.mine;
    state = state.copyWith(mine: before.where((item) => item.id != statusId).toList());
    try {
      await ApiService.delete(ApiContract.url(ApiContract.wa.statusDelete(statusId)));
      return true;
    } catch (error) {
      logger.error('Failed deleting status', tag: 'wa-status', error: error);
      state = state.copyWith(mine: before, errorMessage: 'Could not delete status.');
      return false;
    }
  }

  List<Map<String, dynamic>> _extractList(dynamic raw) {
    if (raw is List) {
      return raw.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    if (raw is Map && raw['data'] is List) {
      return (raw['data'] as List)
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
    }
    return const [];
  }

  Map<String, dynamic> _extractMap(dynamic raw) {
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return const {};
  }
}

final waStatusProvider = NotifierProvider<WaStatusNotifier, WaStatusState>(
  WaStatusNotifier.new,
);
