// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

class User {
  final int id;
  final String email;
  final String username;
  final String first_name;
  final String last_name;
  final String nationality;
  final bool agree_to_privacy_terms;
  final String? image_url;
  final String? avater;
  final String ranks;
  final String points;
  final String level;
  User({
    required this.id,
    required this.email,
    required this.username,
    required this.first_name,
    required this.last_name,
    required this.nationality,
    required this.agree_to_privacy_terms,
    required this.image_url,
    this.avater,
    required this.ranks,
    required this.points,
    required this.level,
  });

  User copyWith({
    int? id,
    String? email,
    String? username,
    String? first_name,
    String? last_name,
    String? nationality,
    bool? agree_to_privacy_terms,
    String? image_url,
    String? avater,
    String? ranks,
    String? points,
    String? level,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      first_name: first_name ?? this.first_name,
      last_name: last_name ?? this.last_name,
      nationality: nationality ?? this.nationality,
      agree_to_privacy_terms: agree_to_privacy_terms ?? this.agree_to_privacy_terms,
      image_url: image_url ?? this.image_url,
      avater: avater ?? this.avater,
      ranks: ranks ?? this.ranks,
      points: points ?? this.points,
      level: level ?? this.level,
    );
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};

    result.addAll({'id': id});
    result.addAll({'email': email});
    result.addAll({'username': username});
    result.addAll({'first_name': first_name});
    result.addAll({'last_name': last_name});
    result.addAll({'nationality': nationality});
    result.addAll({'agree_to_privacy_terms': agree_to_privacy_terms});
    if (image_url != null) {
      result.addAll({'image_url': image_url});
    }
    if (avater != null) {
      result.addAll({'avater': avater});
    }
    result.addAll({'ranks': ranks});
    result.addAll({'points': points});
    result.addAll({'level': level});

    return result;
  }

  // Map<String, dynamic> toMapUpdate() {
  //   final result = <String, dynamic>{};

  //   result.addAll({'first_name': first_name});
  //   result.addAll({'last_name': last_name});
  //   result.addAll({'nationality': nationality});
  //   if (image_url != null) {
  //     result.addAll({'image_url': image_url});
  //   }
  //   if (avater != null) {
  //     result.addAll({'avater': avater});
  //   }

  //   return result;
  // }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id']?.toInt() ?? 0,
      email: map['email'] ?? '',
      username: map['username'] ?? '',
      first_name: map['first_name'] ?? '',
      last_name: map['last_name'] ?? '',
      nationality: map['nationality'] ?? '',
      agree_to_privacy_terms: map['agree_to_privacy_terms'] ?? false,
      image_url: map['image_url'],
      avater: map['avater'],
      ranks: map['ranks'] ?? '',
      points: map['points'] ?? '',
      level: map['level'] ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory User.fromJson(String source) => User.fromMap(json.decode(source));

  @override
  String toString() {
    return 'User(id: $id, email: $email, username: $username, first_name: $first_name, last_name: $last_name, nationality: $nationality, agree_to_privacy_terms: $agree_to_privacy_terms, image_url: $image_url, avater: $avater, ranks: $ranks, points: $points, level: $level)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is User &&
        other.id == id &&
        other.email == email &&
        other.username == username &&
        other.first_name == first_name &&
        other.last_name == last_name &&
        other.nationality == nationality &&
        other.agree_to_privacy_terms == agree_to_privacy_terms &&
        other.image_url == image_url &&
        other.avater == avater &&
        other.ranks == ranks &&
        other.points == points &&
        other.level == level;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        email.hashCode ^
        username.hashCode ^
        first_name.hashCode ^
        last_name.hashCode ^
        nationality.hashCode ^
        agree_to_privacy_terms.hashCode ^
        image_url.hashCode ^
        avater.hashCode ^
        ranks.hashCode ^
        points.hashCode ^
        level.hashCode;
  }

  String get fullName => "$first_name $last_name";
}
