// To parse this JSON data, do
//
//     final authentificationModel = authentificationModelFromJson(jsonString);

import 'dart:convert';

AuthentificationModel authentificationModelFromJson(String str) =>
    AuthentificationModel.fromJson(json.decode(str));

String authentificationModelToJson(AuthentificationModel data) =>
    json.encode(data.toJson());

class AuthentificationModel {
  String token;
  DateTime datetime;
  String email;

  AuthentificationModel({
    required this.token,
    required this.datetime,
    required this.email,
  });

  factory AuthentificationModel.fromJson(Map<String, dynamic> json) {
    return AuthentificationModel(
      token: json["token"] ?? "", // Default to an empty string if token is null
      datetime: json["datetime"] != null
          ? DateTime.parse(json["datetime"])
          : DateTime.now(), // Default to current time if datetime is null
      email: json["email"] ?? "", // Default to an empty string if email is null
    );
  }

  // factory AuthentificationModel.fromJson(Map<String, dynamic> json) {
  //   return AuthentificationModel(
  //     token: json.containsKey("token") ? json["token"] : '',
  //     datetime: json.containsKey("datetime")
  //         ? DateTime.parse(json["datetime"])
  //         : DateTime.now(),
  //     email: json.containsKey("email") ? json["email"] : '',
  //   );
  // }

  Map<String, dynamic> toJson() => {
        "token": token,
        "datetime": datetime.toIso8601String(),
        "email": email,
      };
}
