// To parse this JSON data, do
//
//     final authenticate = authenticateFromJson(jsonString);

import 'dart:convert';

AuthenticateRequestBody authenticateFromJson(String str) =>
    AuthenticateRequestBody.fromJson(json.decode(str));

String authenticateToJson(AuthenticateRequestBody data) =>
    json.encode(data.toJson());

class AuthenticateRequestBody {

  String username;
  String password;

  AuthenticateRequestBody({
    required this.username,
    required this.password,
  });

  factory AuthenticateRequestBody.fromJson(Map<String, dynamic> json) =>
      AuthenticateRequestBody(
        username: json["username"],
        password: json["password"],
      );

  Map<String, String> toJson() => {
        "username": username,
        "password": password,
      };
}
