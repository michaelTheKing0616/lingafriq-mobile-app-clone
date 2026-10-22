/// Leaf certificate pin check shared by iOS and Android.
///
/// Pins are SHA-256 of the leaf DER, formatted `sha256/<base64>`.
/// An empty list leaves the connection open. Any one configured pin is enough,
/// so the current pin and the next pin can both be present during rotation.
class CertificatePinException implements Exception {
  static const String code = 'certificate_pin_mismatch';

  final String host;

  const CertificatePinException({required this.host});

  @override
  String toString() => code;
}

class LeafPinCheck {
  static List<String> parsePins(String raw) {
    return raw.split(',').map((pin) => pin.trim()).where((pin) => pin.isNotEmpty).toList();
  }

  /// Returns true when the leaf may be used.
  /// Throws [CertificatePinException] when pins are set and none match.
  static bool allows({
    required List<String> pins,
    required String leafPin,
    required String host,
  }) {
    if (pins.isEmpty) return true;
    if (leafPin != 'sha256/ERROR' && pins.contains(leafPin)) return true;
    throw CertificatePinException(host: host);
  }
}
