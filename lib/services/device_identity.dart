import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class DeviceIdentity {
  static var _googleReady = false;

  static Future<String?> googleIdToken() async {
    final google = GoogleSignIn.instance;
    if (!_googleReady) {
      await google.initialize();
      _googleReady = true;
    }
    if (!google.supportsAuthenticate()) return null;
    final account = await google.authenticate();
    final token = account.authentication.idToken;
    if (token == null || token.isEmpty) return null;
    return token;
  }

  static Future<String?> appleIdToken() async {
    if (!await SignInWithApple.isAvailable()) return null;
    final credential = await SignInWithApple.getAppleIDCredential(
      scopes: const [
        AppleIDAuthorizationScopes.email,
        AppleIDAuthorizationScopes.fullName,
      ],
    );
    final token = credential.identityToken;
    if (token == null || token.isEmpty) return null;
    return token;
  }
}
