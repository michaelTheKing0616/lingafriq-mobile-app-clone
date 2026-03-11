import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/config/api_contract.dart';
import 'package:lingafriq/config/app_config.dart';
import 'package:livekit_client/livekit_client.dart' hide logger;
import '../models/language_village_model.dart';
import 'base_provider.dart';
import 'dio_provider.dart' show client;
import 'user_provider.dart';
import '../utils/structured_logger.dart';

final languageVillageProvider =
    NotifierProvider<LanguageVillageProvider, BaseProviderState>(() {
  return LanguageVillageProvider();
});

/// Language Village Provider for voice rooms with LiveKit integration
class LanguageVillageProvider extends Notifier<BaseProviderState>
    with BaseProviderMixin {
  final List<LanguageVillage> _villages = [];
  LanguageVillage? _currentVillage;
  final List<VillageParticipant> _participants = [];

  Room? _livekitRoom;
  bool _isRoomConnected = false;
  bool _isMicEnabled = true;
  bool _isCameraEnabled = false;
  String? _connectionError;

  List<LanguageVillage> get villages => List.unmodifiable(_villages);
  LanguageVillage? get currentVillage => _currentVillage;
  List<VillageParticipant> get participants => List.unmodifiable(_participants);

  Room? get livekitRoom => _livekitRoom;
  bool get isRoomConnected => _isRoomConnected;
  bool get isMicEnabled => _isMicEnabled;
  bool get isCameraEnabled => _isCameraEnabled;
  String? get connectionError => _connectionError;
  int get remoteParticipantCount =>
      _livekitRoom?.remoteParticipants.length ?? 0;

  @override
  BaseProviderState build() {
    _loadVillages();
    return BaseProviderState();
  }

  /// Load available villages
  Future<void> _loadVillages() async {
    state = state.copyWith(isLoading: true);

    try {
      final dioClient = ref.read(client);
      final response =
          await dioClient.get(ApiContract.url(ApiContract.villages.list));

      if (response.statusCode == 200) {
        final responseData = response.data;
        final data =
            responseData is Map<String, dynamic> && responseData.containsKey('data')
                ? responseData['data']
                : (responseData is List ? responseData : responseData);
        final villagesData =
            List<Map<String, dynamic>>.from(data is List ? data : [data]);
        _villages.clear();
        _villages.addAll(villagesData.map((v) => LanguageVillage(
              id: v['_id']?.toString() ?? v['id']?.toString() ?? '',
              name: v['name']?.toString() ?? 'Unknown Village',
              language: v['lang']?.toString() ?? v['language']?.toString() ?? '',
              description: v['description']?.toString() ?? '',
              currentParticipants:
                  (v['current_participants'] ?? v['currentParticipants'] ?? 0)
                      as int,
              maxParticipants:
                  (v['max_participants'] ?? v['maxParticipants'] ?? 50) as int,
              rules: v['community_rules'] != null
                  ? (v['community_rules'] is String
                      ? [v['community_rules'] as String]
                      : List<String>.from(v['community_rules'] ?? []))
                  : [],
            )));
      } else {
        _villages.clear();
      }
    } catch (e) {
      logger.error('Error loading villages from API',
          tag: 'language-village', error: e);
      _villages.clear();
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  /// Join a village and connect to its LiveKit voice room
  Future<bool> joinVillage(String villageId) async {
    try {
      final village = _villages.firstWhere((v) => v.id == villageId);
      if (village.currentParticipants >= village.maxParticipants) {
        return false;
      }

      _currentVillage = village;
      _connectionError = null;

      try {
        final user = ref.read(userProvider);
        if (user != null) {
          final dioClient = ref.read(client);
          final response = await dioClient.post(
            ApiContract.url(ApiContract.villages
                .livekitToken(village.language.toLowerCase())),
            data: {
              'userId': user.id.toString(),
              'villageId': village.id,
            },
          );

          if (response.statusCode == 200 && response.data is Map) {
            final data = response.data as Map<String, dynamic>;
            final token = data['token'] as String?;
            final roomName = data['roomName'] as String?;
            final serverUrl =
                data['url'] as String? ?? AppConfig.liveKitUrl;

            if (token != null && roomName != null) {
              _participants.add(VillageParticipant(
                userId: user.id.toString(),
                username: user.username,
                avatar: user.avatar,
                isSpeaking: false,
                joinedAt: DateTime.now(),
              ));

              await _connectToLiveKit(serverUrl, token);
            }
          }
        }
      } catch (e) {
        logger.error('Error connecting to voice room',
            tag: 'language-village', error: e);
        _connectionError =
            'Voice room connection failed. You can still view the village.';
      }

      state = state.copyWith();
      return true;
    } catch (e) {
      logger.error('Error joining village',
          tag: 'language-village', error: e);
      return false;
    }
  }

  Future<void> _connectToLiveKit(String serverUrl, String token) async {
    try {
      _livekitRoom = Room();

      await _livekitRoom!.connect(
        serverUrl,
        token,
        roomOptions: RoomOptions(),
      );

      _isRoomConnected = true;
      _isMicEnabled = true;
      _isCameraEnabled = false;

      logger.info('LiveKit room connected', tag: 'language-village');

      _livekitRoom!.addListener(_onRoomChanged);
      _syncRemoteParticipants();

      state = state.copyWith();
    } catch (e) {
      logger.error('LiveKit connection failed',
          tag: 'language-village', error: e);
      _isRoomConnected = false;
      _connectionError = 'Unable to connect to voice room. Please try again.';
      _livekitRoom?.dispose();
      _livekitRoom = null;
      state = state.copyWith();
      rethrow;
    }
  }

  void _onRoomChanged() {
    _syncRemoteParticipants();
    state = state.copyWith();
  }

  /// Merge LiveKit remote participants into the local participants list,
  /// preserving the current user entry added at join time.
  void _syncRemoteParticipants() {
    if (_livekitRoom == null) return;

    final user = ref.read(userProvider);
    final localUserId = user?.id.toString();

    final localEntries =
        _participants.where((p) => p.userId == localUserId).toList();

    final remoteEntries =
        _livekitRoom!.remoteParticipants.values.map((rp) {
      return VillageParticipant(
        userId: rp.identity,
        username: rp.name.isNotEmpty ? rp.name : 'Participant',
        isSpeaking: rp.isSpeaking,
        joinedAt: DateTime.now(),
      );
    }).toList();

    _participants
      ..clear()
      ..addAll(localEntries)
      ..addAll(remoteEntries);
  }

  /// Toggle the local microphone track on/off
  Future<void> toggleMicrophone() async {
    if (_livekitRoom == null || !_isRoomConnected) return;
    try {
      await _livekitRoom!.localParticipant
          ?.setMicrophoneEnabled(!_isMicEnabled);
      _isMicEnabled = !_isMicEnabled;
      state = state.copyWith();
    } catch (e) {
      logger.error('Error toggling microphone',
          tag: 'language-village', error: e);
    }
  }

  /// Toggle the local camera track on/off
  Future<void> toggleCamera() async {
    if (_livekitRoom == null || !_isRoomConnected) return;
    try {
      await _livekitRoom!.localParticipant
          ?.setCameraEnabled(!_isCameraEnabled);
      _isCameraEnabled = !_isCameraEnabled;
      state = state.copyWith();
    } catch (e) {
      logger.error('Error toggling camera',
          tag: 'language-village', error: e);
    }
  }

  /// Leave current village and disconnect LiveKit
  Future<void> leaveVillage() async {
    try {
      await _disconnectLiveKit();
      if (_currentVillage != null) {
        logger.info('Leaving village',
            tag: 'language-village',
            context: {'villageId': _currentVillage!.id});
      }
    } catch (e) {
      logger.error('Error disconnecting from voice room',
          tag: 'language-village', error: e);
    }

    _currentVillage = null;
    _participants.clear();
    _connectionError = null;
    state = state.copyWith();
  }

  Future<void> _disconnectLiveKit() async {
    if (_livekitRoom != null) {
      _livekitRoom!.removeListener(_onRoomChanged);
      await _livekitRoom!.disconnect();
      _livekitRoom!.dispose();
      _livekitRoom = null;
    }
    _isRoomConnected = false;
    _isMicEnabled = true;
    _isCameraEnabled = false;
  }

  /// Create a new village
  Future<bool> createVillage({
    required String name,
    required String language,
    required String description,
  }) async {
    try {
      final user = ref.read(userProvider);
      if (user == null) {
        logger.warn('Cannot create village: User not logged in',
            tag: 'language-village');
        return false;
      }

      final dioClient = ref.read(client);
      final response = await dioClient.post(
        ApiContract.url(ApiContract.villages.list),
        data: {
          'lang': language.toLowerCase(),
          'name': name,
          'description': description,
          'maxParticipants': 50,
        },
      );

      if (response.statusCode == 201 && response.data is Map) {
        final responseData = response.data as Map<String, dynamic>;
        final villageData = responseData['village'] ?? responseData;
        final raw =
            villageData is Map<String, dynamic> ? villageData : <String, dynamic>{};
        final newVillage = LanguageVillage(
          id: raw['_id']?.toString() ?? raw['id']?.toString() ?? '',
          name: raw['name']?.toString() ?? name,
          language: raw['lang']?.toString() ?? language,
          description: raw['description']?.toString() ?? description,
          currentParticipants:
              (raw['current_participants'] ?? raw['currentParticipants'] ?? 0)
                  as int,
          maxParticipants:
              (raw['max_participants'] ?? raw['maxParticipants'] ?? 50) as int,
          hostId: user.id.toString(),
        );

        if (newVillage.id.isEmpty) {
          logger.warn('Create village response missing id',
              tag: 'language-village', context: {'raw': raw});
        }
        _villages.add(newVillage);
        state = state.copyWith();
        await _loadVillages();
        return true;
      } else {
        logger.warn('Failed to create village',
            tag: 'language-village',
            context: {'statusCode': response.statusCode});
        return false;
      }
    } catch (e) {
      logger.error('Error creating village',
          tag: 'language-village', error: e);
      return false;
    }
  }

  /// Refresh villages
  Future<void> refresh() async {
    await _loadVillages();
  }
}
