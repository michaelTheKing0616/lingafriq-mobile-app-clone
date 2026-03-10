import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/models/private_chat_contact.dart';
import 'package:lingafriq/providers/api_provider.dart';
import 'package:lingafriq/providers/dio_provider.dart';
import 'package:lingafriq/utils/structured_logger.dart';
import 'package:lingafriq/utils/api.dart';

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
      final globalId = contact.globalId?.toLowerCase() ?? '';
      final email = contact.email?.toLowerCase() ?? '';
      final language = contact.language?.toLowerCase() ?? '';
      return username.contains(needle) ||
          globalId.contains(needle) ||
          '@$globalId'.contains(needle) ||
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
      final merged = _mergeContacts(contacts, await _loadRecentChatContacts());
      _lastFetched = DateTime.now();
      state = state.copyWith(
        contacts: merged,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      logger.error('Failed to load contacts', tag: 'private-chat', error: e);
      state = state.copyWith(
        isLoading: false,
        error: 'Unable to load contacts right now.',
      );
    }
  }

  void search(String query) {
    state = state.copyWith(query: query);
  }

  Future<List<PrivateChatContact>> _loadRecentChatContacts() async {
    try {
      final res = await ref.read(client).get(Api.chatPrivate);
      if (res.statusCode != 200) return const [];
      final payload = res.data;
      final dynamicList = _extractMessageList(payload);
      final contacts = <PrivateChatContact>[];
      for (final item in dynamicList) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final userMap = map['otherUser'] ?? map['other_user'] ?? map['sender'] ?? map['recipient'] ?? map['user'];
        if (userMap is Map) {
          final normalized = Map<String, dynamic>.from(userMap);
          final id = int.tryParse('${normalized['id'] ?? normalized['_id'] ?? ''}') ?? -1;
          if (id <= 0) continue;
          contacts.add(
            PrivateChatContact(
              id: id,
              username: (normalized['username'] ?? normalized['name'] ?? 'Learner').toString(),
              globalId: normalized['global_id']?.toString() ?? normalized['globalId']?.toString(),
              email: normalized['email']?.toString(),
              avatarUrl: normalized['avatar']?.toString(),
              language: normalized['language']?.toString(),
            ),
          );
        }
      }
      return contacts;
    } catch (_) {
      return const [];
    }
  }

  List<dynamic> _extractMessageList(dynamic payload) {
    if (payload is List) return payload;
    if (payload is! Map) return const [];
    final map = Map<String, dynamic>.from(payload);
    final candidates = [
      map['data'],
      map['messages'],
      map['results'],
      map['items'],
    ];
    for (final candidate in candidates) {
      if (candidate is List) return candidate;
      if (candidate is Map && candidate['docs'] is List) {
        return candidate['docs'] as List;
      }
    }
    return const [];
  }

  List<PrivateChatContact> _mergeContacts(
    List<PrivateChatContact> profiles,
    List<PrivateChatContact> recents,
  ) {
    final byId = <int, PrivateChatContact>{};
    for (final c in recents) {
      byId[c.id] = c;
    }
    for (final c in profiles) {
      byId[c.id] = c;
    }
    return byId.values.toList();
  }
}

final privateChatProvider =
    NotifierProvider<PrivateChatNotifier, PrivateChatState>(
  () => PrivateChatNotifier(),
);

