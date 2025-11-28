import 'package:lingafriq/models/profile_model.dart';

class PrivateChatContact {
  final int id;
  final String username;
  final String? email;
  final String? avatarUrl;
  final String? language;

  const PrivateChatContact({
    required this.id,
    required this.username,
    this.email,
    this.avatarUrl,
    this.language,
  });

  factory PrivateChatContact.fromProfile(ProfileModel profile) {
    return PrivateChatContact(
      id: profile.id,
      username: profile.username,
      email: profile.email,
      avatarUrl: profile.avater,
      language: profile.nationality,
    );
  }

  factory PrivateChatContact.fromOnlineMap(Map<String, dynamic> data) {
    final rawId = data['userId']?.toString() ?? '';
    return PrivateChatContact(
      id: int.tryParse(rawId) ?? -1,
      username: (data['username'] ?? 'Learner').toString(),
      email: data['email']?.toString(),
    );
  }
}

