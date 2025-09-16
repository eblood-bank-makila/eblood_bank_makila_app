// // To parse this JSON data, do
// //
// //     final user = userFromJson(jsonString);
//
// import 'dart:convert';
//
// import 'package:eblood_bank_mak_app/utilisateurs/business/models/AuthentificationModele.dart';
//
// User userFromJson(String str) => User.fromJson(json.decode(str));
//
// String userToJson(User data) => json.encode(data.toJson());
//
// class User {
//   bool twoFactor;
//   String sms;
//   AuthentificationModel data;
//   bool success;
//
//   User({
//     required this.twoFactor,
//     required this.sms,
//     required this.data,
//     required this.success,
//   });
//
//   factory User.fromJson(Map<String, dynamic> json) => User(
//         twoFactor: json["two_factor"],
//         sms: json["sms"],
//         data: AuthentificationModel.fromJson(json["data"]),
//         success: json["success"],
//       );
//
//   Map<String, dynamic> toJson() => {
//         "two_factor": twoFactor,
//         "sms": sms,
//         "data": data.toJson(),
//         "success": success,
//       };
// }


import 'dart:convert';
import 'package:eblood_bank_mak_app/utilisateurs/business/models/authentification/AuthentificationModele.dart';

User userFromJson(String str) => User.fromJson(json.decode(str));

String userToJson(User data) => json.encode(data.toJson());

class User {
  final bool twoFactor; // Utiliser final pour l'immutabilité
  final String sms; // Utiliser final pour l'immutabilité
  final AuthentificationModel data; // Utiliser final pour l'immutabilité
  final bool success; // Utiliser final pour l'immutabilité

  User({
    required this.twoFactor,
    required this.sms,
    required this.data,
    required this.success,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Gérer les valeurs nulles
    return User(
      twoFactor: json["two_factor"] ?? false, // Valeur par défaut si null
      sms: json["sms"] ?? '', // Valeur par défaut si null
      data: AuthentificationModel.fromJson(json["data"] ?? {}), // Vérifiez que 'data' n'est pas null
      success: json["success"] ?? false, // Valeur par défaut si null
    );
  }

  Map<String, dynamic> toJson() => {
    "two_factor": twoFactor,
    "sms": sms,
    "data": data.toJson(),
    "success": success,
  };
}
