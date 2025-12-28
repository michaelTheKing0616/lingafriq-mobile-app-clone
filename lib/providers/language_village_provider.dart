import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/language_village_model.dart';
import 'base_provider.dart';
import 'api_provider.dart';
import 'dio_provider.dart';
import '../utils/api.dart';
import 'user_provider.dart';

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
      final client = ref.read(dioProvider);
      final response = await client.get('${Api.baseurl}${Api.villages}');
      
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
      debugPrint('Error loading villages from API: $e');
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
          final client = ref.read(dioProvider);
          final response = await client.post(
            '${Api.baseurl}${Api.villageLivekitToken(village.language.toLowerCase())}',
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
              debugPrint('LiveKit token received for village: ${village.id}');
              
              // Add user to participants list
              _participants.add(VillageParticipant(
                userId: user.id.toString(),
                username: user.username ?? 'User',
                avatarUrl: user.avatar ?? '',
                isSpeaking: false,
                joinedAt: DateTime.now(),
              ));
            }
          }
        }
      } catch (e) {
        debugPrint('Error connecting to voice room: $e');
        // Continue even if voice connection fails
      }
      
      state = state.copyWith();
      return true;
    } catch (e) {
      debugPrint('Error joining village: $e');
      return false;
    }
  }

  /// Leave current village
  Future<void> leaveVillage() async {
    try {
      // Disconnect from voice room if connected
      // In production, this would disconnect LiveKit client
      if (_currentVillage != null) {
        debugPrint('Leaving village: ${_currentVillage!.id}');
      }
    } catch (e) {
      debugPrint('Error disconnecting from voice room: $e');
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
        debugPrint('Cannot create village: User not logged in');
        return false;
      }

      // Create via backend API
      final client = ref.read(dioProvider);
      final response = await client.post(
        '${Api.baseurl}${Api.villages}',
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
        final newVillage = LanguageVillage(
          id: villageData['_id']?.toString() ?? villageData['id']?.toString() ?? '',
          name: villageData['name']?.toString() ?? name,
          language: villageData['lang']?.toString() ?? language,
          description: villageData['description']?.toString() ?? description,
          currentParticipants: 1,
          maxParticipants: (villageData['max_participants'] ?? 50) as int,
          hostId: user.id.toString(),
        );

        _villages.add(newVillage);
        state = state.copyWith();
        return true;
      } else {
        debugPrint('Failed to create village: ${response.statusCode}');
        return false;
      }
    } catch (e) {
      debugPrint('Error creating village: $e');
      return false;
    }
  }

  /// Refresh villages
  Future<void> refresh() async {
    await _loadVillages();
  }
}

