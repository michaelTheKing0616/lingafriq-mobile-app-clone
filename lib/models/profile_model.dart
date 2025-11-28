// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import '../utils/api.dart';

class ProfileModel {
  final int id;
  final String email;
  final String username;
  final String first_name;
  final String last_name;
  final bool is_current_user;
  final int? rank;
  final String nationality;
  final bool agree_to_privacy_terms;
  final String? avater;
  final int completed_point;
  ProfileModel({
    required this.id,
    required this.email,
    required this.username,
    required this.first_name,
    required this.last_name,
    required this.is_current_user,
    required this.rank,
    required this.nationality,
    required this.agree_to_privacy_terms,
    required this.avater,
    required this.completed_point,
  });

  ProfileModel copyWith({
    int? id,
    String? email,
    String? username,
    String? first_name,
    String? last_name,
    bool? is_current_user,
    int? rank,
    String? nationality,
    bool? agree_to_privacy_terms,
    String? avater,
    int? completed_point,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      first_name: first_name ?? this.first_name,
      last_name: last_name ?? this.last_name,
      is_current_user: is_current_user ?? this.is_current_user,
      rank: rank ?? this.rank,
      nationality: nationality ?? this.nationality,
      agree_to_privacy_terms: agree_to_privacy_terms ?? this.agree_to_privacy_terms,
      avater: avater ?? this.avater,
      completed_point: completed_point ?? this.completed_point,
    );
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};

    result.addAll({'id': id});
    result.addAll({'email': email});
    result.addAll({'username': username});
    result.addAll({'first_name': first_name});
    result.addAll({'last_name': last_name});
    result.addAll({'is_current_user': is_current_user});
    result.addAll({'rank': rank});
    result.addAll({'nationality': nationality});
    result.addAll({'agree_to_privacy_terms': agree_to_privacy_terms});
    if (avater != null) {
      result.addAll({'avater': avater});
    }
    result.addAll({'completed_point': completed_point});

    return result;
  }

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      id: map['id']?.toInt() ?? 0,
      email: map['email'] ?? '',
      username: map['username'] ?? '',
      first_name: map['first_name'] ?? '',
      last_name: map['last_name'] ?? '',
      is_current_user: map['is_current_user'] ?? false,
      rank: () {
        final rank = map['rank'];
        if (rank is String) {
          return num.parse(rank).toInt();
        }
        return rank??0;
      }.call(),
      nationality: map['nationality'] ?? '',
      agree_to_privacy_terms: map['agree_to_privacy_terms'] ?? false,
      avater: map['avater'],
      completed_point: map['completed_point'] is String
          ? num.parse(map['completed_point']).toInt()
          : map['completed_point']?.toInt() ?? 0,
    );
  }

  String toJson() => json.encode(toMap());

  factory ProfileModel.fromJson(String source) => ProfileModel.fromMap(json.decode(source));

  @override
  String toString() {
    return 'ProfileModel(id: $id, email: $email, username: $username, first_name: $first_name, last_name: $last_name, is_current_user: $is_current_user, rank: $rank, nationality: $nationality, agree_to_privacy_terms: $agree_to_privacy_terms, avater: $avater, completed_point: $completed_point)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ProfileModel &&
        other.id == id &&
        // other.email == email &&
        other.username == username;
    //  &&
    // other.first_name == first_name &&
    // other.last_name == last_name &&
    // other.is_current_user == is_current_user &&
    // other.rank == rank &&
    // other.nationality == nationality &&
    // other.agree_to_privacy_terms == agree_to_privacy_terms &&
    // other.avater == avater &&
    // other.completed_point == completed_point;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        // email.hashCode ^
        username.hashCode;
    //  ^
    // first_name.hashCode ^
    // last_name.hashCode ^
    // is_current_user.hashCode ^
    // rank.hashCode ^
    // nationality.hashCode ^
    // agree_to_privacy_terms.hashCode ^
    // avater.hashCode ^
    // completed_point.hashCode;
  }

  String get fullName => "$first_name $last_name";

  //Support for old server urls
  String get avatarUrl {
    if (avater != null && avater!.contains('http://34.121.156.251:8000/')) {
      return avater!.replaceAll('http://34.121.156.251:8000/', Api.baseurl);
    }

    return avater ?? '';
  }

  String? get avatar => avater;

  int get level => (completed_point ~/ 100) + 1;

  int get streak => 0;
}
