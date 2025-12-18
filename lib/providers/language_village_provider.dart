import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../models/language_village_model.dart';
import 'base_provider.dart';
import 'api_provider.dart';

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
      // TODO: Fetch from backend API
      // For now, create mock villages
      _villages.clear();
      _villages.addAll([
        LanguageVillage(
          id: 'yoruba_village',
          name: 'Yoruba Village',
          language: 'Yoruba',
          description: 'Practice Yoruba with native speakers and learners',
          currentParticipants: 12,
          maxParticipants: 50,
          rules: [
            'Only Yoruba allowed (no English)',
            'Be respectful',
            'Help beginners',
          ],
        ),
        LanguageVillage(
          id: 'swahili_village',
          name: 'Swahili Coast',
          language: 'Swahili',
          description: 'Connect with Swahili speakers from East Africa',
          currentParticipants: 8,
          maxParticipants: 50,
          rules: [
            'Only Swahili allowed',
            'Cultural exchange welcome',
          ],
        ),
        LanguageVillage(
          id: 'hausa_village',
          name: 'Hausa Hub',
          language: 'Hausa',
          description: 'Learn Hausa through conversation',
          currentParticipants: 5,
          maxParticipants: 50,
        ),
        LanguageVillage(
          id: 'igbo_village',
          name: 'Igbo Community',
          language: 'Igbo',
          description: 'Practice Igbo with the community',
          currentParticipants: 15,
          maxParticipants: 50,
        ),
      ]);
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
      // TODO: Connect to voice room (WebRTC/Socket.io)
      // TODO: Add user to participants list
      
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
    // TODO: Disconnect from voice room
    state = state.copyWith();
  }

  /// Create a new village
  Future<bool> createVillage({
    required String name,
    required String language,
    required String description,
  }) async {
    try {
      // TODO: Create via backend API
      final newVillage = LanguageVillage(
        id: 'village_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        language: language,
        description: description,
        currentParticipants: 1,
        hostId: 'current_user', // TODO: Get from auth
      );

      _villages.add(newVillage);
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
}

