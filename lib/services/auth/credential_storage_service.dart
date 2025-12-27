/// CredentialStorageService - Service wrapper for CredentialStorage
import 'credential_storage.dart';

class CredentialStorageService {
  static final CredentialStorageService _instance = CredentialStorageService._internal();
  factory CredentialStorageService() => _instance;
  CredentialStorageService._internal();

  Future<void> initialize() async {
    // CredentialStorage uses FlutterSecureStorage which initializes on first use
    // No explicit initialization needed - storage is ready when accessed
  }
}

