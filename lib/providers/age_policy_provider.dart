import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/onboarding_provider.dart';
import 'package:lingafriq/services/capability_gate.dart';

/// P1-022 — client policy for hiding DMs, calls, snaps, and public feed.
class AgePolicyState {
  const AgePolicyState({
    required this.ageBand,
    required this.socialSurfacesBlocked,
    this.serverMessage,
  });

  final String? ageBand;
  final bool socialSurfacesBlocked;
  final String? serverMessage;

  static bool bandBlocksSocialSurfaces(String? band) {
    final normalized = band?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty || normalized == 'unknown') {
      return true;
    }
    return normalized == 'child' || normalized == 'teen';
  }
}

class AgePolicyNotifier extends AsyncNotifier<AgePolicyState> {
  final CapabilityGate _gate = CapabilityGate();

  @override
  Future<AgePolicyState> build() async {
    final band = ref.read(onboardingProvider.notifier).registrationAgeBand ??
        ref.read(onboardingProvider).ageCategory;
    try {
      final caps = await _gate.load();
      final blocked = _blocked(band, caps);
      return AgePolicyState(ageBand: band, socialSurfacesBlocked: blocked);
    } catch (_) {
      return AgePolicyState(
        ageBand: band,
        socialSurfacesBlocked: AgePolicyState.bandBlocksSocialSurfaces(band),
      );
    }
  }

  void refreshFromServer() {
    _gate.clearCache();
    ref.invalidateSelf();
  }

  bool _blocked(String? band, LearnerCapabilities caps) {
    if (AgePolicyState.bandBlocksSocialSurfaces(band)) return true;
    if (caps.isMinor && !caps.socialEnabled) return true;
    return false;
  }
}

final agePolicyProvider =
    AsyncNotifierProvider<AgePolicyNotifier, AgePolicyState>(
  AgePolicyNotifier.new,
);

/// Parses backend [AGE_RESTRICTION_CODE] payloads (P1-021).
bool isAgeRestrictedResponseBody(Object? data) {
  if (data is! Map) return false;
  final code = data['code']?.toString();
  return code == 'age_restricted';
}
