/// Lens photo privacy and minor consent gates (P7-914).
library;

/// Product age bands from onboarding (`age_category` pref).
enum LensAgeBand {
  child,
  teen,
  adult,
  unknown,
}

/// Whether a captured photo may be sent to a server vision model.
enum LensPhotoServerPolicy {
  allowed,
  onDeviceOnly,
}

/// Visible block reasons — copy keys for UI layers.
enum LensServerPhotoBlockReason {
  minorNoGuardianConsent,
  serverOnlyFeatureWithoutConsent,
}

class LensLearnerPrivacyContext {
  const LensLearnerPrivacyContext({
    required this.ageBand,
    required this.guardianPhotoConsentRecorded,
  });

  final LensAgeBand ageBand;
  final bool guardianPhotoConsentRecorded;

  bool get isMinor =>
      ageBand == LensAgeBand.child || ageBand == LensAgeBand.teen;
}

LensAgeBand lensAgeBandFromCategory(String? raw) {
  switch (raw?.trim().toLowerCase()) {
    case 'child':
      return LensAgeBand.child;
    case 'teen':
      return LensAgeBand.teen;
    case 'adult':
    case 'senior':
      return LensAgeBand.adult;
    default:
      return LensAgeBand.unknown;
  }
}

/// Builds privacy context from onboarding prefs (age source of truth until profile birth year ships).
LensLearnerPrivacyContext lensPrivacyContextFromPrefs({
  String? ageCategory,
  bool guardianPhotoConsentRecorded = false,
}) {
  return LensLearnerPrivacyContext(
    ageBand: lensAgeBandFromCategory(ageCategory),
    guardianPhotoConsentRecorded: guardianPhotoConsentRecorded,
  );
}

LensPhotoServerPolicy lensServerPhotoPolicy(LensLearnerPrivacyContext ctx) {
  if (!ctx.isMinor) return LensPhotoServerPolicy.allowed;
  if (ctx.guardianPhotoConsentRecorded) return LensPhotoServerPolicy.allowed;
  return LensPhotoServerPolicy.onDeviceOnly;
}

LensServerPhotoBlockReason? lensServerPhotoBlockReason(
  LensLearnerPrivacyContext ctx,
) {
  if (lensServerPhotoPolicy(ctx) == LensPhotoServerPolicy.allowed) {
    return null;
  }
  return LensServerPhotoBlockReason.minorNoGuardianConsent;
}

/// Analytics / logs must never carry image bytes or reversible encodings.
bool lensLogPayloadContainsImageBytes(Map<String, Object?> payload) {
  for (final entry in payload.entries) {
    final key = entry.key.toLowerCase();
    if (key.contains('image') &&
        (key.contains('base64') || key.contains('bytes') || key == 'image')) {
      final v = entry.value;
      if (v is List<int> && v.isNotEmpty) return true;
      if (v is String && v.length > 64) return true;
    }
    if (entry.value is Map<String, Object?>) {
      if (lensLogPayloadContainsImageBytes(
        Map<String, Object?>.from(entry.value as Map),
      )) {
        return true;
      }
    }
  }
  return false;
}

/// Safe telemetry fields for a Lens processing event (opaque ids only).
Map<String, String> lensPrivacySafeTelemetry({
  required String sessionId,
  required String route,
}) {
  return {
    'lens_session_id': sessionId,
    'lens_route': route,
  };
}
