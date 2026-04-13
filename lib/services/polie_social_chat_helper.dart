import 'package:hooks_riverpod/hooks_riverpod.dart';

import '../providers/chat_socket_provider.dart';
import '../providers/onboarding_provider.dart';
import 'polie_mention_handler.dart';
import 'polie_rate_limiter.dart';

const _polieSocketUserId = 'polie_bot';
const _polieDisplayName = 'Polie';

/// Result of [deliverPolieAfterSend].
///
/// - [localAppend]: merge into UI when the socket is offline or unavailable.
/// - [rateLimited]: user hit the client rate limit; show a short snackbar.
class PolieSocialDelivery {
  const PolieSocialDelivery({
    this.localAppend,
    this.rateLimited = false,
  });

  final List<Map<String, dynamic>>? localAppend;
  final bool rateLimited;
}

Map<String, dynamic> _localPolieMessage(String text, String idSuffix) {
  final ts = DateTime.now().toIso8601String();
  return {
    'message': text,
    'sender_id': {
      'id': 0,
      'username': _polieDisplayName,
      'global_id': _polieSocketUserId,
    },
    'username': _polieDisplayName,
    'global_id': _polieSocketUserId,
    'createdAt': ts,
    'clientMessageId': 'polie_${idSuffix}_${DateTime.now().millisecondsSinceEpoch}',
  };
}

/// After the user's message is successfully sent, delivers Polie typing + reply.
///
/// When the chat socket is connected, messages are sent on [socketRoom] (same as
/// [ChatSocketNotifier.sendMessage]). When offline, returns maps to merge into local UI state.
///
/// Set [useSocket] to false for REST-only chats that should not emit on the socket
/// (Polie still appears via [localAppend] when disconnected).
///
/// [rateLimitScope] must be unique per surface (e.g. `g_general`, `v_123`, `t_456`).
Future<PolieSocialDelivery?> deliverPolieAfterSend({
  required WidgetRef ref,
  required String userMessage,
  required String socketRoom,
  required String rateLimitScope,
  String? chatContext,
  bool useSocket = true,
}) async {
  final handler = ref.read(polieMentionHandlerProvider);
  if (!handler.hasMention(userMessage)) return null;

  if (!await PolieRateLimiter.allow(rateLimitScope)) {
    return const PolieSocialDelivery(rateLimited: true);
  }

  final onboarding = ref.read(onboardingProvider);
  final lang = onboarding.selectedLanguage ?? 'english';

  final connected = useSocket && ref.read(chatSocketProvider).isConnected;
  final socket = ref.read(chatSocketProvider.notifier);

  if (connected) {
    socket.sendMessage(
      socketRoom,
      '🤖 Polie is thinking...',
      _polieSocketUserId,
      _polieDisplayName,
      null,
      _polieSocketUserId,
    );
  }

  final result = await handler.processMessage(
    message: userMessage,
    userLanguage: lang,
    chatContext: chatContext,
  );
  final formatted = handler.formatResponseForChat(result);
  if (formatted.isEmpty) return const PolieSocialDelivery();

  if (connected) {
    socket.sendMessage(
      socketRoom,
      formatted,
      _polieSocketUserId,
      _polieDisplayName,
      null,
      _polieSocketUserId,
    );
    return const PolieSocialDelivery();
  }

  return PolieSocialDelivery(
    localAppend: [
      _localPolieMessage('🤖 Polie is thinking...', 'think'),
      _localPolieMessage(formatted, 'reply'),
    ],
  );
}
