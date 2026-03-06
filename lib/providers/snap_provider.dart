import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/config/api_contract.dart';
import 'package:lingafriq/models/snap_models.dart';
import 'package:lingafriq/utils/api_service.dart';
import 'package:lingafriq/utils/structured_logger.dart';

class SnapState {
  final bool loading;
  final List<SnapMessageModel> inbox;
  final List<SnapStoryModel> stories;
  final List<Map<String, dynamic>> streaks;
  final String? errorMessage;

  const SnapState({
    required this.loading,
    required this.inbox,
    required this.stories,
    required this.streaks,
    this.errorMessage,
  });

  factory SnapState.initial() =>
      const SnapState(loading: false, inbox: [], stories: [], streaks: [], errorMessage: null);

  SnapState copyWith({
    bool? loading,
    List<SnapMessageModel>? inbox,
    List<SnapStoryModel>? stories,
    List<Map<String, dynamic>>? streaks,
    String? errorMessage,
  }) {
    return SnapState(
      loading: loading ?? this.loading,
      inbox: inbox ?? this.inbox,
      stories: stories ?? this.stories,
      streaks: streaks ?? this.streaks,
      errorMessage: errorMessage,
    );
  }
}

class SnapNotifier extends Notifier<SnapState> {
  @override
  SnapState build() => SnapState.initial();

  Future<void> loadInbox() async {
    state = state.copyWith(loading: true, errorMessage: null);
    try {
      final res = await ApiService.get(ApiContract.url(ApiContract.snap.messages));
      final list = _extractList(res.data);
      state = state.copyWith(
        loading: false,
        inbox: list.map((e) => SnapMessageModel.fromJson(e)).toList(),
        errorMessage: null,
      );
    } catch (error) {
      logger.error('Failed loading snap inbox', tag: 'snap', error: error);
      state = state.copyWith(loading: false, errorMessage: 'Could not load snap inbox.');
    }
  }

  Future<void> loadStories() async {
    state = state.copyWith(loading: true, errorMessage: null);
    try {
      final res = await ApiService.get(ApiContract.url(ApiContract.snap.stories));
      final list = _extractList(res.data);
      state = state.copyWith(
        loading: false,
        stories: list.map((e) => SnapStoryModel.fromJson(e)).toList(),
        errorMessage: null,
      );
    } catch (error) {
      logger.error('Failed loading snap stories', tag: 'snap', error: error);
      state = state.copyWith(loading: false, errorMessage: 'Could not load stories.');
    }
  }

  Future<bool> sendSnap({
    required String recipientId,
    required String mediaUrl,
    String mediaType = 'image',
    String? caption,
  }) async {
    final temp = SnapMessageModel(
      id: 'tmp_${DateTime.now().millisecondsSinceEpoch}',
      senderId: 'me',
      recipientId: recipientId,
      mediaUrl: mediaUrl,
      mediaType: mediaType,
      caption: caption ?? '',
      opened: false,
    );
    state = state.copyWith(inbox: [temp, ...state.inbox], errorMessage: null);
    try {
      final res = await ApiService.post(
        ApiContract.url(ApiContract.snap.messages),
        data: {
          'recipient_id': recipientId,
          'media_url': mediaUrl,
          'media_type': mediaType,
          'caption': caption,
        },
      );
      final body = _extractMap(res.data);
      final created = _extractMap(body['data']);
      final createdMsg = created.isNotEmpty ? SnapMessageModel.fromJson(created) : temp;
      state = state.copyWith(
        inbox: [createdMsg, ...state.inbox.where((item) => item.id != temp.id)],
      );
      return true;
    } catch (error) {
      logger.error('Failed sending snap', tag: 'snap', error: error);
      state = state.copyWith(
        inbox: state.inbox.where((item) => item.id != temp.id).toList(),
        errorMessage: 'Could not send snap.',
      );
      return false;
    }
  }

  Future<void> loadStreaks() async {
    try {
      final res = await ApiService.get(ApiContract.url(ApiContract.snap.streaks));
      state = state.copyWith(streaks: _extractList(res.data), errorMessage: null);
    } catch (error) {
      logger.error('Failed loading streaks', tag: 'snap', error: error);
      state = state.copyWith(errorMessage: 'Could not load streaks.');
    }
  }

  Future<void> openMessage(String messageId) async {
    try {
      await ApiService.post(ApiContract.url(ApiContract.snap.openMessage(messageId)));
      state = state.copyWith(
        inbox: state.inbox
            .map((msg) => msg.id == messageId
                ? SnapMessageModel(
                    id: msg.id,
                    senderId: msg.senderId,
                    recipientId: msg.recipientId,
                    mediaUrl: msg.mediaUrl,
                    mediaType: msg.mediaType,
                    caption: msg.caption,
                    opened: true,
                  )
                : msg)
            .toList(),
      );
    } catch (error) {
      logger.error('Failed opening snap message', tag: 'snap', error: error);
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

final snapProvider = NotifierProvider<SnapNotifier, SnapState>(SnapNotifier.new);
