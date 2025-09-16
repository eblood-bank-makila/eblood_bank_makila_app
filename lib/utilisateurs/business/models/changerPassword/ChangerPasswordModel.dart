// To parse this JSON data, do
//
//     final authenticate = authenticateFromJson(jsonString);

import 'dart:convert';

ChangerPasswordModel changerPasswordModelFromJson(String str) =>
    ChangerPasswordModel.fromJson(json.decode(str));

String changerPasswordModelToJson(ChangerPasswordModel data) =>
    json.encode(data.toJson());

class ChangerPasswordModel {
  String oldpassword;
  String password;
  String password2;

  ChangerPasswordModel({
    required this.oldpassword,
    required this.password,
    required this.password2,
  });

  factory ChangerPasswordModel.fromJson(Map<String, dynamic> json) =>
      ChangerPasswordModel(
        oldpassword: json["oldpassword"],
        password: json["password"],
        password2: json["password2"],
      );

  Map<String, String> toJson() => {
        "oldpassword": oldpassword,
        "password": password,
        "password2": password2,
      };
}
