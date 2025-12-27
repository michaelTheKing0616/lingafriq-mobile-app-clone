/// CredentialStorageService - Service wrapper for CredentialStorage
import 'credential_storage.dart';

class CredentialStorageService {
  static final CredentialStorageService _instance = CredentialStorageService._internal();
  factory CredentialStorageService() => _instance;
  CredentialStorageService._internal();

  Future<void> initialize() async {
    // CredentialStorage uses static methods, no initialization needed
    // But we can verify storage is accessible
    try {
      await CredentialStorage.getUsername();
    } catch (e) {
      // Storage not accessible, but continue
    }
  }
}

