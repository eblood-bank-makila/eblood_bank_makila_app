// To parse this JSON data, do
//
//     final otpCodeModele = otpCodeModeleFromJson(jsonString);

import 'dart:convert';

import 'package:eblood_bank_mak_app/utilisateurs/business/models/code_otp/DatumCodeOtpModele.dart';

OtpCodeModele otpCodeModeleFromJson(String str) =>
    OtpCodeModele.fromJson(json.decode(str));

String otpCodeModeleToJson(OtpCodeModele data) => json.encode(data.toJson());

class OtpCodeModele {
  DatumCodeOtpModele data;
  int statusCode;
  bool success;

  OtpCodeModele({
    required this.data,
    required this.statusCode,
    required this.success,
  });

  factory OtpCodeModele.fromJson(Map<String, dynamic> json) => OtpCodeModele(
        data: DatumCodeOtpModele.fromJson(json["data"]),
        statusCode: json["status_code"],
        success: json["success"],
      );

  Map<String, dynamic> toJson() => {
        "data": data.toJson(),
        "status_code": statusCode,
        "success": success,
      };
}
