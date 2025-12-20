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

  void resetUser() {
    state = null;
  }
}
