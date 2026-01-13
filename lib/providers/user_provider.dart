import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:lingafriq/models/profile_model.dart';

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

  /// Update local user points immediately (UI responsiveness).
  /// Backend remains source-of-truth; we refresh profile after server updates.
  void addPoints(int points) {
    final current = state;
    if (current == null) return;
    state = current.copyWith(completed_point: current.completed_point + points);
  }

  void resetUser() {
    state = null;
  }
}
