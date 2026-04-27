//
// // To parse this JSON data, do
// //
// //     final otpCodeModele = otpCodeModeleFromJson(jsonString);
//
// import 'dart:convert';
//
// import 'package:eblood_bank_mak_app/users/business/models/code_otp/CordonatesCodeOtpModele.dart';
// import 'package:eblood_bank_mak_app/users/business/models/code_otp/CountryCodeOtpModele.dart';
// import 'package:eblood_bank_mak_app/users/business/models/code_otp/UTelephoneCodeOtpModele.dart';
// import 'package:eblood_bank_mak_app/users/business/models/code_otp/UcourrielCodeOtpModele.dart';
//
// DatumCodeOtpModele datumCodeOtpModeleFromJson(String str) => DatumCodeOtpModele.fromJson(json.decode(str));
//
// String datumCodeOtpModeleToJson(DatumCodeOtpModele data) => json.encode(data.toJson());
//
//
//
// class DatumCodeOtpModele {
//   String authBarear;
//   String uSocket;
//   String uUserName;
//   String uNom;
//   String uPrenom;
//   String uSexe;
//   String uReceveLoginTokenBy;
//   List<UCourrielCodeOtpModele> uCourriels;
//   String uAccountType;
//   String uAccountFrom;
//   List<UTelephoneCodeOtpModele> uTelephones;
//   String countryId;
//   CountryCodeOtpModele country;
//   String city;
//   String uAdresse;
//   DateTime uLastUpdate;
//   CordonatesCodeOtpModele cordonates;
//
//   DatumCodeOtpModele({
//   required  this.authBarear,
//     required this.uSocket,
//     required   this.uUserName,
//     required  this.uNom,
//     required   this.uPrenom,
//     required    this.uSexe,
//     required   this.uReceveLoginTokenBy,
//     required  this.uCourriels,
//     required   this.uAccountType,
//     required    this.uAccountFrom,
//     required   this.uTelephones,
//     required   this.countryId,
//     required   this.country,
//     required   this.city,
//     required   this.uAdresse,
//     required   this.uLastUpdate,
//    required this.cordonates,
//   });
//
//   factory DatumCodeOtpModele.fromJson(Map<String, dynamic> json) => DatumCodeOtpModele(
//     authBarear: json["authBarear"],
//     uSocket: json["uSocket"],
//     uUserName: json["uUserName"],
//     uNom: json["uNom"],
//     uPrenom: json["uPrenom"],
//     uSexe: json["uSexe"],
//     uReceveLoginTokenBy: json["uReceveLoginTokenBy"],
//     uCourriels: List<UCourrielCodeOtpModele>.from(json["uCourriels"].map((x) => UCourrielCodeOtpModele.fromJson(x))),
//     uAccountType: json["uAccountType"],
//     uAccountFrom: json["uAccountFrom"],
//     uTelephones: List<UTelephoneCodeOtpModele>.from(json["uTelephones"].map((x) => UTelephoneCodeOtpModele.fromJson(x))),
//     countryId: json["country_id"],
//     country: CountryCodeOtpModele.fromJson(json["country"]),
//     city: json["city"],
//     uAdresse: json["uAdresse"],
//     uLastUpdate: DateTime.parse(json["uLastUpdate"]),
//     cordonates:  CordonatesCodeOtpModele.fromJson(json["cordonates"]),
//   );
//
//   Map<String, dynamic> toJson() => {
//     "authBarear": authBarear,
//     "uSocket": uSocket,
//     "uUserName": uUserName,
//     "uNom": uNom,
//     "uPrenom": uPrenom,
//     "uSexe": uSexe,
//     "uReceveLoginTokenBy": uReceveLoginTokenBy,
//     "uCourriels": List<dynamic>.from(uCourriels.map((x) => x.toJson())),
//     "uAccountType": uAccountType,
//     "uAccountFrom": uAccountFrom,
//     "uTelephones": List<dynamic>.from(uTelephones.map((x) => x.toJson())),
//     "country_id": countryId,
//     "country": country.toJson(),
//     "city": city,
//     "uAdresse": uAdresse,
//     "uLastUpdate": uLastUpdate.toIso8601String(),
//     "cordonates": cordonates.toJson(),
//   };
// }

import 'dart:convert';

import 'package:eblood_bank_mak_app/users/business/models/code_otp/CordonatesCodeOtpModele.dart';
import 'package:eblood_bank_mak_app/users/business/models/code_otp/CountryCodeOtpModele.dart';
import 'package:eblood_bank_mak_app/users/business/models/code_otp/UTelephoneCodeOtpModele.dart';
import 'package:eblood_bank_mak_app/users/business/models/code_otp/UcourrielCodeOtpModele.dart';
import 'package:eblood_bank_mak_app/apps/config/enums/CommonConfigType.dart';

DatumCodeOtpModele datumCodeOtpModeleFromJson(String str) =>
    DatumCodeOtpModele.fromJson(json.decode(str));

String datumCodeOtpModeleToJson(DatumCodeOtpModele data) =>
    json.encode(data.toJson());

class DatumCodeOtpModele {
  String authBarear;
  String uSocket;
  String uUserName;
  String uNom;
  String uPrenom;
  String uSexe;
  String uReceveLoginTokenBy;
  List<UCourrielCodeOtpModele> uCourriels;
  String uAccountType;
  String uAccountFrom;
  List<UTelephoneCodeOtpModele> uTelephones;
  String countryId;
  CountryCodeOtpModele country;
  String city;
  String uAdresse;
  DateTime uLastUpdate;
  CordonatesCodeOtpModele cordonates;

  // New profile type fields
  String? profilTypeFlag; // The enum value from backend
  String? profilTypeName; // The display name from backend

  DatumCodeOtpModele({
    required this.authBarear,
    required this.uSocket,
    required this.uUserName,
    required this.uNom,
    required this.uPrenom,
    required this.uSexe,
    required this.uReceveLoginTokenBy,
    required this.uCourriels,
    required this.uAccountType,
    required this.uAccountFrom,
    required this.uTelephones,
    required this.countryId,
    required this.country,
    required this.city,
    required this.uAdresse,
    required this.uLastUpdate,
    required this.cordonates,
    this.profilTypeFlag,
    this.profilTypeName,
  });

  factory DatumCodeOtpModele.fromJson(Map<String, dynamic> json) =>
      DatumCodeOtpModele(
        authBarear: json["authBarear"] ?? "",
        // Valeur par défaut
        uSocket: json["uSocket"] ?? "",
        // Valeur par défaut
        uUserName: json["uUserName"] ?? "",
        // Valeur par défaut
        uNom: json["uNom"] ?? "",
        // Valeur par défaut
        uPrenom: json["uPrenom"] ?? "",
        // Valeur par défaut
        uSexe: json["uSexe"] ?? "",
        // Valeur par défaut
        uReceveLoginTokenBy: json["uReceveLoginTokenBy"] ?? "",
        // Valeur par défaut
        uCourriels: json["uCourriels"] != null
            ? List<UCourrielCodeOtpModele>.from(json["uCourriels"]
                .map((x) => UCourrielCodeOtpModele.fromJson(x)))
            : [],
        // Liste vide si null
        uAccountType: json["uAccountType"] ?? "",
        // Valeur par défaut
        uAccountFrom: json["uAccountFrom"] ?? "",
        // Valeur par défaut
        uTelephones: json["uTelephones"] != null
            ? List<UTelephoneCodeOtpModele>.from(json["uTelephones"]
                .map((x) => UTelephoneCodeOtpModele.fromJson(x)))
            : [],
        // Liste vide si null
        countryId: json["country_id"] ?? "",
        // Valeur par défaut
        country: json["country"] != null
            ? CountryCodeOtpModele.fromJson(json["country"])
            : CountryCodeOtpModele(
                id: "",
                minPhoneNumberChars: 0,
                maxPhoneNumberChars: 0,
                phoneNumberPrefixes: [],
                countryCodes: [],
                isActivated: false,
                homeCountryId: "",
                countryCode: "",
                countryName: "",
                countryFlag: "",
                nationality: "",
                currencies: []),
        // Valeur par défaut
        city: json["city"] ?? "",
        // Valeur par défaut
        uAdresse: json["uAdresse"] ?? "",
        // Valeur par défaut
        uLastUpdate: json["uLastUpdate"] != null
            ? DateTime.parse(json["uLastUpdate"])
            : DateTime.now(),
        // Valeur par défaut
        cordonates: json["cordonates"] != null
            ? CordonatesCodeOtpModele.fromJson(json["cordonates"])
            : CordonatesCodeOtpModele(
                longitude: 0.0, latitude: 0.0), // Valeur par défaut
        profilTypeFlag: json["profil_type_flag"]?.toString(),
        profilTypeName: json["profil_type_name"]?.toString(),
      );

  Map<String, dynamic> toJson() => {
        "authBarear": authBarear,
        "uSocket": uSocket,
        "uUserName": uUserName,
        "uNom": uNom,
        "uPrenom": uPrenom,
        "uSexe": uSexe,
        "uReceveLoginTokenBy": uReceveLoginTokenBy,
        "uCourriels": List<dynamic>.from(uCourriels.map((x) => x.toJson())),
        "uAccountType": uAccountType,
        "uAccountFrom": uAccountFrom,
        "uTelephones": List<dynamic>.from(uTelephones.map((x) => x.toJson())),
        "country_id": countryId,
        "country": country.toJson(),
        "city": city,
        "uAdresse": uAdresse,
        "uLastUpdate": uLastUpdate.toIso8601String(),
        "cordonates": cordonates.toJson(),
        "profil_type_flag": profilTypeFlag,
        "profil_type_name": profilTypeName,
      };

  /// Get the account type enum from the profile type flag
  ECommonConfigType get accountType {
    if (profilTypeFlag == null) return ECommonConfigType.none;
    return ECommonConfigType.fromString(profilTypeFlag!);
  }

  /// Get the display name for the account type
  String get accountTypeDisplayName {
    return profilTypeName ?? accountType.displayName;
  }

  /// Check if user has a specific account type
  bool hasAccountType(ECommonConfigType type) {
    return accountType == type;
  }
}
