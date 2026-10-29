import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/age_policy_provider.dart';

/// Age bands as stored by registration (`registration_age_band`).
enum ChatAgeBand { child, teen, adult, unknown }

ChatAgeBand chatAgeBandFrom(String? raw) {
  switch (raw?.trim().toLowerCase()) {
    case 'child':
      return ChatAgeBand.child;
    case 'teen':
      return ChatAgeBand.teen;
    case 'adult':
      return ChatAgeBand.adult;
    default:
      return ChatAgeBand.unknown;
  }
}

/// THE single switch for who may open public Global chat.
///
/// Safest default: adults only. Children never see the entry and the route is
/// guarded. Teens (13-17) are also kept out of open chat with strangers; this
/// matches the age-gate policy (private profile, no DMs from adults) and is
/// safer than moderated rooms we cannot staff yet. An unknown band is treated
/// as a minor. To change policy, edit this set only; see HANDOFF.md.
const Set<ChatAgeBand> kGlobalChatAllowedBands = {ChatAgeBand.adult};

enum GlobalChatAccess {
  allowed,
  deniedChild,
  deniedTeen,
  deniedUnknown,
  checking,
}

GlobalChatAccess globalChatAccessFor(
  String? band, {
  bool serverBlocksSocial = false,
  Set<ChatAgeBand> allowed = kGlobalChatAllowedBands,
}) {
  final b = chatAgeBandFrom(band);
  if (allowed.contains(b) && !serverBlocksSocial) {
    return GlobalChatAccess.allowed;
  }
  return switch (b) {
    ChatAgeBand.child => GlobalChatAccess.deniedChild,
    ChatAgeBand.teen => GlobalChatAccess.deniedTeen,
    // An adult whose server capabilities block social is treated like unknown.
    ChatAgeBand.adult || ChatAgeBand.unknown => GlobalChatAccess.deniedUnknown,
  };
}

/// Access for the signed-in learner. Fails closed while loading or on error.
final globalChatAccessProvider = Provider<GlobalChatAccess>((ref) {
  final policy = ref.watch(agePolicyProvider);
  return policy.when(
    data: (s) => globalChatAccessFor(
      s.ageBand,
      // Adults are only blocked when the server says so for a non-band reason.
      serverBlocksSocial:
          chatAgeBandFrom(s.ageBand) == ChatAgeBand.adult &&
          s.socialSurfacesBlocked,
    ),
    loading: () => GlobalChatAccess.checking,
    error: (_, _) => GlobalChatAccess.deniedUnknown,
  );
});

/// Whether entry points (drawer, hubs) may show Global chat at all.
final globalChatEntryVisibleProvider = Provider<bool>(
  (ref) => ref.watch(globalChatAccessProvider) == GlobalChatAccess.allowed,
);
