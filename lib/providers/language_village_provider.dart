import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/config/api_contract.dart';
import '../models/language_village_model.dart';
import 'base_provider.dart';
import 'dio_provider.dart' show client;
import 'user_provider.dart';
import '../utils/structured_logger.dart';

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

  List<LanguageVillage> get villages => List.unmodifiable(_villages);
  LanguageVillage? get currentVillage => _currentVillage;
  List<VillageParticipant> get participants => List.unmodifiable(_participants);

  @override
  BaseProviderState build() {
    _loadVillages();
    return BaseProviderState();
  }

  /// Load available villages
  Future<void> _loadVillages() async {
    state = state.copyWith(isLoading: true);

    try {
      // Fetch from backend API
      final dioClient = ref.read(client);
      final response =
          await dioClient.get(ApiContract.url(ApiContract.villages.list));
      
      if (response.statusCode == 200) {
        final responseData = response.data;
        final data = responseData is Map<String, dynamic> && responseData.containsKey('data')
            ? responseData['data']
            : (responseData is List ? responseData : responseData);
        final villagesData = List<Map<String, dynamic>>.from(data is List ? data : [data]);
        _villages.clear();
        _villages.addAll(villagesData.map((v) => LanguageVillage(
          id: v['_id']?.toString() ?? v['id']?.toString() ?? '',
          name: v['name']?.toString() ?? 'Unknown Village',
          language: v['lang']?.toString() ?? v['language']?.toString() ?? '',
          description: v['description']?.toString() ?? '',
          currentParticipants: (v['current_participants'] ?? v['currentParticipants'] ?? 0) as int,
          maxParticipants: (v['max_participants'] ?? v['maxParticipants'] ?? 50) as int,
          rules: v['community_rules'] != null 
            ? (v['community_rules'] is String 
                ? [v['community_rules'] as String]
                : List<String>.from(v['community_rules'] ?? []))
            : [],
        )).toList());
      } else {
        // Fallback to empty list if API fails
        _villages.clear();
      }
    } catch (e) {
      logger.error('Error loading villages from API', tag: 'language-village', error: e);
      // Fallback to empty list on error
      _villages.clear();
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
      
      // Get LiveKit token for voice room connection
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
            
            if (token != null && roomName != null) {
              // Store token for WebRTC connection
              // In production, this would initialize LiveKit client
              logger.info('LiveKit token received for village', tag: 'language-village', context: {'villageId': village.id});
              
              // Add user to participants list
              _participants.add(VillageParticipant(
                userId: user.id.toString(),
                username: user.username,
                avatar: user.avatar,
                isSpeaking: false,
                joinedAt: DateTime.now(),
              ));
            }
          }
        }
      } catch (e) {
        logger.error('Error connecting to voice room', tag: 'language-village', error: e);
        // Continue even if voice connection fails
      }
      
      state = state.copyWith();
      return true;
    } catch (e) {
      logger.error('Error joining village', tag: 'language-village', error: e);
      return false;
    }
  }

  /// Leave current village
  Future<void> leaveVillage() async {
    try {
      // Disconnect from voice room if connected
      // In production, this would disconnect LiveKit client
      if (_currentVillage != null) {
        logger.info('Leaving village', tag: 'language-village', context: {'villageId': _currentVillage!.id});
      }
    } catch (e) {
      logger.error('Error disconnecting from voice room', tag: 'language-village', error: e);
    }
    
    _currentVillage = null;
    _participants.clear();
    state = state.copyWith();
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
        logger.warn('Cannot create village: User not logged in', tag: 'language-village');
        return false;
      }

      // Create via backend API
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
        final raw = villageData is Map<String, dynamic> ? villageData : <String, dynamic>{};
        final newVillage = LanguageVillage(
          id: raw['_id']?.toString() ?? raw['id']?.toString() ?? '',
          name: raw['name']?.toString() ?? name,
          language: raw['lang']?.toString() ?? language,
          description: raw['description']?.toString() ?? description,
          currentParticipants: (raw['current_participants'] ?? raw['currentParticipants'] ?? 0) as int,
          maxParticipants: (raw['max_participants'] ?? raw['maxParticipants'] ?? 50) as int,
          hostId: user.id.toString(),
        );

        if (newVillage.id.isEmpty) {
          logger.warn('Create village response missing id', tag: 'language-village', context: {'raw': raw});
        }
        _villages.add(newVillage);
        state = state.copyWith();
        // Refetch list from backend so UI stays in sync with server
        await _loadVillages();
        return true;
      } else {
        logger.warn('Failed to create village', tag: 'language-village', context: {'statusCode': response.statusCode});
        return false;
      }
    } catch (e) {
      logger.error('Error creating village', tag: 'language-village', error: e);
      return false;
    }
  }

  /// Refresh villages
  Future<void> refresh() async {
    await _loadVillages();
  }
}

