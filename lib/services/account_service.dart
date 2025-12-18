import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/providers/api_provider.dart';

class AccountService {
  final WidgetRef ref;

  AccountService(this.ref);

  /// Deletes the current user account.
  /// Throws an Exception if deletion fails.
  Future<String> deleteAccount(String currentPassword) async {
    try {
      final success = await ref.read(apiProvider.notifier).deleteUser({
        "current_password": currentPassword,
      });

      if (success) {
        return "Account deleted successfully.";
      } else {
        throw Exception("Failed to delete account.");
      }
    } catch (e) {
      throw Exception("Failed to delete account: $e");
    }
  }
}
