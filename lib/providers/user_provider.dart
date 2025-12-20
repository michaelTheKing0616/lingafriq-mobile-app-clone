import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/models/profile_model.dart';
import 'package:lingafriq/providers/api_provider.dart';

final userProvider = NotifierProvider<UserProvider, ProfileModel?>(
  () => UserProvider(),
);

class UserProvider extends Notifier<ProfileModel?> {
  @override
  ProfileModel? build() {
    return null;
  }

  void overrideUser(ProfileModel? user) {
    state = user;
  }

  void resetUser() {
    state = null;
  }

  void addPoints(int points) {
    if (state == null) return;
    final newTotal =
        (state!.completed_point + points).clamp(0, 1 << 31).toInt();
    state = state!.copyWith(completed_point: newTotal);
    
    // Sync points to backend
    _syncPointsToBackend(points);
  }

  Future<void> _syncPointsToBackend(int points) async {
    try {
      final api = ref.read(apiProvider.notifier);
      await api.updateUserPoints(points);
    } catch (e) {
      // Silently fail - points are updated locally
    }
  }
}
