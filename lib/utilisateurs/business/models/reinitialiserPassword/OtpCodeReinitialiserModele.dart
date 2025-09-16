// To parse this JSON data, do
//
//     final otpCodeReinitialiserModele = otpCodeReinitialiserModeleFromJson(jsonString);

import 'dart:convert';

OtpCodeReinitialiserModele otpCodeReinitialiserModeleFromJson(String str) =>
    OtpCodeReinitialiserModele.fromJson(json.decode(str));

String otpCodeReinitialiserModeleToJson(OtpCodeReinitialiserModele data) =>
    json.encode(data.toJson());

class OtpCodeReinitialiserModele {
  String data;
  int statusCode;
  bool success;

  OtpCodeReinitialiserModele({
    required this.data,
    required this.statusCode,
    required this.success,
  });

  factory OtpCodeReinitialiserModele.fromJson(Map<String, dynamic> json) =>
      OtpCodeReinitialiserModele(
        data: json["data"],
        statusCode: json["status_code"],
        success: json["success"],
      );

  Map<String, dynamic> toJson() => {
        "data": data,
        "status_code": statusCode,
        "success": success,
      };
}
