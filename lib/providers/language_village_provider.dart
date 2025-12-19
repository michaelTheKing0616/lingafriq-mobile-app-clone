import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/language_village_model.dart';
import 'base_provider.dart';
import 'api_provider.dart';
import 'onboarding_provider.dart';
import '../services/voice/audio_recording_service.dart';
import '../services/polie_content_generator.dart';
import 'package:livekit_client/livekit_client.dart' as lk;

final languageVillageProvider =
    NotifierProvider<LanguageVillageProvider, BaseProviderState>(() {
  return LanguageVillageProvider();
});

/// Language Village Provider for voice rooms
class LanguageVillageProvider extends Notifier<BaseProviderState>
    with BaseProviderMixin {
  final List<LanguageVillage> _villages = [];
  LanguageVillage? _currentVillage;
  final List<VillageParticipant> _participants = [];
  final List<Map<String, dynamic>> _voiceMessages = [];
  String? _polieRecap;
  bool _isAskingPolie = false;

  // LiveKit SFU state (optional, when configured on backend)
  lk.Room? _liveRoom;
  bool _isLiveConnecting = false;

  List<LanguageVillage> get villages => List.unmodifiable(_villages);
  LanguageVillage? get currentVillage => _currentVillage;
  List<VillageParticipant> get participants => List.unmodifiable(_participants);
  List<Map<String, dynamic>> get voiceMessages =>
      List.unmodifiable(_voiceMessages);
  String? get polieRecap => _polieRecap;
  bool get isAskingPolieRecap => _isAskingPolie;
  bool get isLiveConnected => _liveRoom != null && _liveRoom!.connectionState == lk.ConnectionState.connected;
  bool get isLiveConnecting => _isLiveConnecting;

  @override
  BaseProviderState build() {
    _loadVillages();
    return BaseProviderState();
  }

  /// Load available villages
  Future<void> _loadVillages() async {
    state = state.copyWith(isLoading: true);

    try {
      final onboarding = ref.read(onboardingProvider);
      final api = ref.read(apiProvider.notifier);
      final preferredLang = (onboarding.selectedLanguage ?? '').toLowerCase();

      // 1) Load all available villages from backend so users can pick any village,
      //    not only the one bound to their onboarding language.
      final villagesResponse = await api.getVillages();
      _villages
        ..clear()
        ..addAll(villagesResponse
            .map<LanguageVillage>((v) => LanguageVillage.fromJson(v)));

      // 2) Select default village for the learner's language if available.
      _currentVillage = _villages.firstWhere(
        (v) => v.language.toLowerCase() == preferredLang,
        orElse: () => _villages.isNotEmpty ? _villages.first : null,
      );

      // 3) Do not preload voice messages until a village is actually viewed,
      //    to save bandwidth on low-end networks. They will be loaded on demand.
      _voiceMessages.clear();
      _polieRecap = null;
      _isAskingPolie = false;
    } catch (e) {
      debugPrint('Error loading villages: $e');
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Join a village
  Future<bool> joinVillage(String villageId) async {
    try {
      final village = _villages.firstWhere((v) => v.id == villageId);
      if (village.currentParticipants >= village.maxParticipants) {
        return false; // Village is full
      }

      _currentVillage = village;
      // Reset voice-room specific state and load messages for this village.
      _voiceMessages.clear();
      _polieRecap = null;
      _isAskingPolie = false;

      await refreshVoiceMessages();

      state = state.copyWith();
      return true;
    } catch (e) {
      debugPrint('Error joining village: $e');
      return false;
    }
  }

  /// Leave current village
  Future<void> leaveVillage() async {
    _currentVillage = null;
    _participants.clear();
    _voiceMessages.clear();
    _polieRecap = null;
    _isAskingPolie = false;

    // Disconnect from live SFU room if connected.
    if (_liveRoom != null) {
      await _liveRoom!.disconnect();
      _liveRoom = null;
    }
    // Voice room disconnect is handled client-side.
    state = state.copyWith();
  }

  /// Refresh recent voice messages for the current village.
  Future<void> refreshVoiceMessages() async {
    if (_currentVillage == null) return;
    try {
      final api = ref.read(apiProvider.notifier);
      final messages = await api.getVillageVoiceMessages(
        language: _currentVillage!.language.toLowerCase(),
        limit: 50,
      );
      _voiceMessages
        ..clear()
        ..addAll(messages);
      _polieRecap = null; // new messages imply recap is stale
      state = state.copyWith();
    } catch (e) {
      debugPrint('Error refreshing village voice messages: $e');
    }
  }

  /// Record, upload, and publish a new village voice message.
  /// (caller is responsible for handling the recording UX)
  Future<bool> sendRecordedVoiceMessage(String filePath) async {
    try {
      if (_currentVillage == null) return false;

      final api = ref.read(apiProvider.notifier);
      final language = _currentVillage!.language.toLowerCase();
      final fileName = filePath.split('/').last;

      // 1) Upload media
      final media = await api.uploadMedia(
        filePath: filePath,
        fileName: fileName,
        title: 'Village voice message',
        description: 'Live practice in $language village',
        language: language,
      );
      final mediaId = (media['_id'] ?? media['id'])?.toString();
      if (mediaId == null) return false;

      // 2) Link as village voice message
      final ok = await api.createVillageVoiceMessage(
        language: language,
        mediaId: mediaId,
      );

      if (ok) {
        await refreshVoiceMessages();
      }

      return ok;
    } catch (e) {
      debugPrint('Error sending village voice message: $e');
      return false;
    }
  }

  /// Create a new village
  Future<bool> createVillage({
    required String name,
    required String language,
    required String description,
  }) async {
    try {
      final api = ref.read(apiProvider.notifier);
      final response = await api.client.post(
        '/api/villages',
        data: {
          'lang': language.toLowerCase(),
          'name': name,
          'description': description,
        },
      );
      if (response.statusCode != 201 && response.statusCode != 200) {
        throw response.data;
      }
      final body = response.data;
      final villageJson = body is Map && body['village'] != null
          ? body['village'] as Map<String, dynamic>
          : body as Map<String, dynamic>;

      final created = LanguageVillage.fromJson(villageJson);
      _villages.add(created);
      state = state.copyWith();
      return true;
    } catch (e) {
      debugPrint('Error creating village: $e');
      return false;
    }
  }

  /// Refresh villages
  Future<void> refresh() async {
    await _loadVillages();
  }

  /// Ask Polie for a recap of the recent village voice messages.
  Future<void> askPolieForRecap() async {
    if (_currentVillage == null) return;
    if (_isAskingPolie) return;

    _isAskingPolie = true;
    _polieRecap = null;
    state = state.copyWith();

    try {
      final language = _currentVillage!.language.toLowerCase();
      final api = ref.read(apiProvider.notifier);
      final polieGenerator = ref.read(polieContentGeneratorProvider);

      final summaryResult = await api.summarizeVillageAudio(
        language: language,
        limit: 10,
      );
      final rawSummary = summaryResult['summary']?.toString() ?? '';
      final transcriptsDynamic = summaryResult['transcripts'];
      final List<String> snippets = [];
      if (transcriptsDynamic is List) {
        for (final t in transcriptsDynamic) {
          if (t is String) {
            snippets.add(t);
          } else if (t is Map && t['text'] != null) {
            snippets.add(t['text'].toString());
          }
        }
      }

      final recap = await polieGenerator.generateVillageRecap(
        language: language,
        summary: rawSummary,
        transcriptSnippets: snippets,
      );

      _polieRecap = recap;
    } catch (e) {
      debugPrint('Error asking Polie for village recap: $e');
      _polieRecap =
          'Polie had trouble summarizing this session. Keep sharing voice messages and try again in a little while.';
    } finally {
      _isAskingPolie = false;
      state = state.copyWith();
    }
  }

  /// Connect to the optional LiveKit SFU room for this village.
  /// If the backend is not configured for LiveKit, this will fail gracefully
  /// and the traditional voice‑note flow will continue to work.
  Future<void> connectLiveRoom() async {
    if (_currentVillage == null) return;
    if (_liveRoom != null &&
        _liveRoom!.connectionState == lk.ConnectionState.connected) {
      return;
    }

    _isLiveConnecting = true;
    state = state.copyWith();

    try {
      final api = ref.read(apiProvider.notifier);
      final lang = _currentVillage!.language.toLowerCase();

      final res = await api.client.post(
        '/api/villages/$lang/livekit-token',
      );
      if (res.statusCode != 200) {
        throw res.data;
      }

      final data = res.data as Map<String, dynamic>;
      final url = data['url'] as String?;
      final token = data['token'] as String?;

      if (url == null || token == null) {
        throw Exception('Invalid LiveKit credentials from server');
      }

      final room = lk.Room();
      await lk.connect(
        url,
        token,
        room: room,
        connectOptions: const lk.ConnectOptions(
          autoSubscribe: true,
        ),
      );

      _liveRoom = room;
    } catch (e) {
      debugPrint('Error connecting to LiveKit village room: $e');
      // Fall back silently; voice‑note UX remains available.
    } finally {
      _isLiveConnecting = false;
      state = state.copyWith();
    }
  }

  /// Disconnect from the LiveKit SFU room if currently connected.
  Future<void> disconnectLiveRoom() async {
    if (_liveRoom != null) {
      try {
        await _liveRoom!.disconnect();
      } catch (_) {
        // Ignore errors during disconnect
      }
      _liveRoom = null;
      state = state.copyWith();
    }
  }
}

