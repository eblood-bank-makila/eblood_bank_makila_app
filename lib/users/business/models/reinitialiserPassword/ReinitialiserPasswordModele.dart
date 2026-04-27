// To parse this JSON data, do
//
//     final authenticate = authenticateFromJson(jsonString);

import 'dart:convert';

ReinitialiserPasswordModele reinitialiserPasswordModeleFromJson(String str) =>
    ReinitialiserPasswordModele.fromJson(json.decode(str));

String reinitialiserPasswordModeleToJson(ReinitialiserPasswordModele data) =>
    json.encode(data.toJson());

class ReinitialiserPasswordModele{
  String password;
  String password2;


  ReinitialiserPasswordModele({
    required this.password,
    required this.password2,
  });

  factory ReinitialiserPasswordModele.fromJson(Map<String, dynamic> json) =>
      ReinitialiserPasswordModele(
        password: json["password"],
        password2: json["password2"],

      );

  Map<String, String> toJson() => {
    "password": password,
    "password2": password2,
  };
}
