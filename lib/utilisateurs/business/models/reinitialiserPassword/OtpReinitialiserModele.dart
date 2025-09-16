// To parse this JSON data, do
//
//     final authenticate = authenticateFromJson(jsonString);

import 'dart:convert';

OtpReinitialiserModele otpReinitialiserModeleFromJson(String str) =>
    OtpReinitialiserModele.fromJson(json.decode(str));

String otpReinitialiserModeleToJson(OtpReinitialiserModele data) =>
    json.encode(data.toJson());

class OtpReinitialiserModele {
  String code;


  OtpReinitialiserModele({
    required this.code,
  });

  factory OtpReinitialiserModele.fromJson(Map<String, dynamic> json) =>
      OtpReinitialiserModele(
        code: json["code"],

      );

  Map<String, String> toJson() => {
    "code": code,
  };
}
