// To parse this JSON data, do
//
//     final authenticate = authenticateFromJson(jsonString);

import 'dart:convert';

OtpModele authenticateFromJson(String str) =>
    OtpModele.fromJson(json.decode(str));

String authenticateToJson(OtpModele data) => json.encode(data.toJson());

class OtpModele {
  //String username;
  String code;

  OtpModele({
    required this.code,
  });

  factory OtpModele.fromJson(Map<String, dynamic> json) => OtpModele(
        code: json["code"],
      );

  Map<String, String> toJson() => {
        "code": code,
      };
}
