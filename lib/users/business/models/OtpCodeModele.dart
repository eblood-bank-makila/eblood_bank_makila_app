// To parse this JSON data, do
//
//     final otpCodeModele = otpCodeModeleFromJson(jsonString);

import 'dart:convert';

OtpCodeModele otpCodeModeleFromJson(String str) =>
    OtpCodeModele.fromJson(json.decode(str));

String otpCodeModeleToJson(OtpCodeModele data) => json.encode(data.toJson());

class OtpCodeModele {
  final String authBarear;
  final String uSocket;
  final String uUserName;
  final String uNom;
  final String uPrenom;
  final String uSexe;
  final String uReceveLoginTokenBy;
  final DateTime uLastUpdate;

  OtpCodeModele({
    required this.authBarear,
    required this.uSocket,
    required this.uUserName,
    required this.uNom,
    required this.uPrenom,
    required this.uSexe,
    required this.uReceveLoginTokenBy,
    required this.uLastUpdate,
  });

  factory OtpCodeModele.fromJson(Map<String, dynamic> json) => OtpCodeModele(
        authBarear: json["authBarear"],
        uSocket: json["uSocket"],
        uUserName: json["uUserName"],
        uNom: json["uNom"],
        uPrenom: json["uPrenom"],
        uSexe: json["uSexe"],
        uReceveLoginTokenBy: json["uReceveLoginTokenBy"],
        uLastUpdate: DateTime.parse(json["uLastUpdate"]),
      );

  Map<String, dynamic> toJson() => {
        "authBarear": authBarear,
        "uSocket": uSocket,
        "uUserName": uUserName,
        "uNom": uNom,
        "uPrenom": uPrenom,
        "uSexe": uSexe,
        "uReceveLoginTokenBy": uReceveLoginTokenBy,
        "uLastUpdate": uLastUpdate.toIso8601String(),
      };
}
