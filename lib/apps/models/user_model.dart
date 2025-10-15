import 'dart:convert';

import 'package:eblood_bank_mak_app/apps/models/auth_model.dart';


class UserModel {
  final String id;
  final String email;
  final String? name;
  final String? profilePicture;
  final Map<String, dynamic>? preferences;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isActive;

  UserModel({
    required this.id,
    required this.email,
    this.name,
    this.profilePicture,
    this.preferences,
    this.createdAt,
    this.updatedAt,
    this.isActive = true,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'],
      email: json['email'],
      name: json['name'],
      profilePicture: json['profile_picture'],
      preferences: json['preferences'] != null
          ? (json['preferences'] is String
              ? jsonDecode(json['preferences'])
              : json['preferences'])
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
      isActive: json['is_active'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'profile_picture': profilePicture,
      'preferences': preferences != null
          ? (preferences is String ? preferences : jsonEncode(preferences))
          : null,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_active': isActive,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    String? profilePicture,
    Map<String, dynamic>? preferences,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      profilePicture: profilePicture ?? this.profilePicture,
      preferences: preferences ?? this.preferences,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }
}

TUserModel tUserModelFromJson(dynamic json) => TUserModel.fromJson(json);

String tUserModelToJson(TUserModel data) => json.encode(data.toJson());

class TUserModel {
  String id;
  String username;
  String firstName;
  String userAccountSocketHash;
  String lastName;
  String gender;
  String phoneNumber;
  String emailAddress;
  List<TMfaModel> mfas;

  TUserModel({
    required this.id,
    required this.username,
    required this.firstName,
    required this.userAccountSocketHash,
    required this.lastName,
    required this.gender,
    required this.phoneNumber,
    required this.emailAddress,
    required this.mfas,
  });

  factory TUserModel.fromJson(Map<String, dynamic> json) => TUserModel(
        id: json.containsKey('id') && json["id"] != null ? json["id"] : '-',
        username: json.containsKey('username') && json["username"] != null
            ? json["username"]
            : '-',
        firstName: json.containsKey('first_name') && json["first_name"] != null
            ? json["first_name"]
            : '-',
        userAccountSocketHash: json.containsKey('user_account_socket_hash') &&
                json["user_account_socket_hash"] != null
            ? json["user_account_socket_hash"]
            : '-',
        lastName: json.containsKey('last_name') && json["last_name"] != null
            ? json["last_name"]
            : '-',
        gender: json.containsKey('gender') && json["gender"] != null
            ? json["gender"]
            : '-',
        phoneNumber:
            json.containsKey('phone_number') && json["phone_number"] != null
                ? json["phone_number"]
                : '-',
        emailAddress:
            json.containsKey('email_address') && json["email_address"] != null
                ? json["email_address"]
                : '-',
        mfas: List<TMfaModel>.from(
            json["mfas"].map((x) => TMfaModel.fromJson(x))),
      );
  factory TUserModel.empty() => TUserModel(
      id: '-',
      username: '-',
      firstName: '-',
      lastName: '-',
      gender: '-',
      phoneNumber: '-',
      emailAddress: '-',
      userAccountSocketHash: '-',
      mfas: []);

  Map<String, dynamic> toJson() => {
        "id": id,
        "username": username,
        "first_name": firstName,
        "last_name": lastName,
        "gender": gender,
        "user_account_socket_hash": userAccountSocketHash,
        "phone_number": phoneNumber,
        "email_address": emailAddress,
        "mfas": List<dynamic>.from(mfas.map((x) => x)),
      };

  @override
  String toString() {
    return jsonEncode(toJson());
  }
}
