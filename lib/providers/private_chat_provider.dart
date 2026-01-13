import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/models/private_chat_contact.dart';
import 'package:lingafriq/providers/api_provider.dart';

class PrivateChatState {
  final List<PrivateChatContact> contacts;
  final bool isLoading;
  final String query;
  final String? error;

  const PrivateChatState({
    this.contacts = const [],
    this.isLoading = false,
    this.query = '',
    this.error,
  });

  List<PrivateChatContact> get filteredContacts {
    if (query.trim().isEmpty) return contacts;
    final needle = query.trim().toLowerCase();
    return contacts.where((contact) {
      final username = contact.username.toLowerCase();
      final email = contact.email?.toLowerCase() ?? '';
      final language = contact.language?.toLowerCase() ?? '';
      return username.contains(needle) ||
          email.contains(needle) ||
          language.contains(needle);
    }).toList();
  }

  PrivateChatState copyWith({
    List<PrivateChatContact>? contacts,
    bool? isLoading,
    String? query,
    String? error,
  }) {
    return PrivateChatState(
      contacts: contacts ?? this.contacts,
      isLoading: isLoading ?? this.isLoading,
      query: query ?? this.query,
      error: error,
    );
  }
}

class PrivateChatNotifier extends Notifier<PrivateChatState> {
  DateTime? _lastFetched;

  @override
  PrivateChatState build() => const PrivateChatState();

  Future<void> loadContacts({bool forceRefresh = false}) async {
    if (!forceRefresh &&
        _lastFetched != null &&
        DateTime.now().difference(_lastFetched!) < const Duration(minutes: 5) &&
        state.contacts.isNotEmpty) {
      return;
    }

    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await ref.read(apiProvider.notifier).getProfilesResponse();
      final contacts = response.result.results
          .map(PrivateChatContact.fromProfile)
          .toList();
      _lastFetched = DateTime.now();
      state = state.copyWith(
        contacts: contacts,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      debugPrint('Failed to load contacts: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Unable to load contacts right now.',
      );
    }
  }

  void search(String query) {
    state = state.copyWith(query: query);

    // If the user is searching by handle (starting with "@"), try a backend
    // lookup by global_id to find users that may not be in the local list yet.
    final trimmed = query.trim();
    if (trimmed.startsWith('@') && trimmed.length > 1) {
      final handle = trimmed.substring(1);
      _searchByHandle(handle);
      return;
    }

    // Otherwise rely on local filtering of the loaded contacts list.
  }

  Future<void> _searchByHandle(String handle) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final api = ref.read(apiProvider.notifier);
      final results = await api.searchUsersByHandle(handle);
      final contacts = results
          .map<PrivateChatContact>((m) => PrivateChatContact(
                id: (m['id'] as num?)?.toInt() ?? -1,
                username: (m['username'] ?? '') as String,
                email: m['email']?.toString(),
                avatarUrl: m['avater']?.toString(),
                language: m['nationality']?.toString(),
              ))
          .toList();

      state = state.copyWith(
        contacts: contacts,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      debugPrint('Failed to search by handle: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Unable to search by handle right now.',
      );
    }
  }
}

final privateChatProvider =
    NotifierProvider<PrivateChatNotifier, PrivateChatState>(
  () => PrivateChatNotifier(),
);

