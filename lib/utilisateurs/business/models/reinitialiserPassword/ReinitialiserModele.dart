// To parse this JSON data, do
//
//     final reinitialiserModele = reinitialiserModeleFromJson(jsonString);

import 'dart:convert';

ReinitialiserModele reinitialiserModeleFromJson(String str) =>
    ReinitialiserModele.fromJson(json.decode(str));

String reinitialiserModeleToJson(ReinitialiserModele data) =>
    json.encode(data.toJson());

class ReinitialiserModele {
  String sms;
  int statusCode;
  bool success;

  ReinitialiserModele({
    required this.sms,
    required this.statusCode,
    required this.success,
  });

  factory ReinitialiserModele.fromJson(Map<String, dynamic> json) =>
      ReinitialiserModele(
        sms: json["sms"],
        statusCode: json["status_code"],
        success: json["success"],
      );

  Map<String, dynamic> toJson() => {
        "sms": sms,
        "status_code": statusCode,
        "success": success,
      };
}
