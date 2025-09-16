// To parse this JSON data, do
//
//     final authenticate = authenticateFromJson(jsonString);

import 'dart:convert';

MotDePasseOublieModele motDePasseOublieModeleFromJson(String str) =>
    MotDePasseOublieModele.fromJson(json.decode(str));

String motDePasseOublieModeleToJson(MotDePasseOublieModele data) =>
    json.encode(data.toJson());

class MotDePasseOublieModele {
  String username;


  MotDePasseOublieModele({
    required this.username,
  });

  factory MotDePasseOublieModele.fromJson(Map<String, dynamic> json) =>
      MotDePasseOublieModele(
        username: json["username"],

      );

  Map<String, String> toJson() => {
    "username": username,
  };
}
