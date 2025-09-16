// To parse this JSON data, do
//
//     final authentificationModel = authentificationModelFromJson(jsonString);

import 'dart:convert';

MotDePasseModele motDePasseModeleModelFromJson(String str) =>
    MotDePasseModele.fromJson(json.decode(str));

String motDePasseModeleModelToJson(MotDePasseModele data) =>
    json.encode(data.toJson());

class MotDePasseModele {
  final String token;
  final String datetime;
  final String email;

  MotDePasseModele({
    required this.token,
    required this.datetime,
    required this.email,
  });

  factory MotDePasseModele.fromJson(Map json) => MotDePasseModele(
    token: json['token'],
    datetime: json['datetime'],
    email: json['email'],
  );

  Map<String, dynamic> toJson() => {
    'token': token,
    'datetime': datetime,
    'email': email,
  };
}
