// ignore_for_file: non_constant_identifier_names

import 'dart:convert';

import '../utils/api.dart';

class ProfileModel {
  final int id;
  /// Global, stable identifier shared across services (maps to backend global_id).
  final String? globalId;
  final String email;
  final String username;
  final String first_name;
  final String last_name;
  final bool is_current_user;
  final int? rank;
  final String nationality;
  final bool agree_to_privacy_terms;
  final String? avater;
  /// Back-compat: many UI surfaces treat this as “points earned”.
  /// Backend primarily uses `points`.
  final int completed_point;
  /// Optional backend “level” (string in current backend schema).
  final String? level;
  
  // Alias for avatar (fix typo)
  String? get avatar => avater;

  // Future: streak is not present in backend user schema today; keep as nullable.
  int? get streak => null;
  
  ProfileModel({
    required this.id,
    this.globalId,
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
    this.level,
  });

  ProfileModel copyWith({
    int? id,
    String? globalId,
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
    String? level,
  }) {
    return ProfileModel(
      id: id ?? this.id,
      globalId: globalId ?? this.globalId,
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
      level: level ?? this.level,
    );
  }

  Map<String, dynamic> toMap() {
    final result = <String, dynamic>{};

    result.addAll({'id': id});
    if (globalId != null) {
      result.addAll({'global_id': globalId});
    }
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
    if (level != null) {
      result.addAll({'level': level});
    }

    return result;
  }

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    int parseInt(dynamic v, {int fallback = 0}) {
      if (v == null) return fallback;
      if (v is int) return v;
      if (v is double) return v.toInt();
      if (v is num) return v.toInt();
      if (v is String) {
        final s = v.trim();
        if (s.isEmpty) return fallback;
        return int.tryParse(s) ?? fallback;
      }
      return fallback;
    }

    return ProfileModel(
      id: parseInt(map['id']),
      globalId: (map['global_id'] ?? map['globalId'])?.toString(),
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
      avater: (map['avater'] ?? map['avatar'])?.toString(),
      completed_point: parseInt(map['completed_point'], fallback: parseInt(map['points'])),
      level: map['level']?.toString(),
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
    final a = avater;
    if (a == null || a.isEmpty) return '';
    if (a.contains('http://34.121.156.251:8000/')) {
      return a.replaceAll('http://34.121.156.251:8000/', Api.baseurl);
    }

    return a;
  }
}
