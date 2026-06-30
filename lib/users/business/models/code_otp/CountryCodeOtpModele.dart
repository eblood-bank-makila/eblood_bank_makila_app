//
//
// import 'package:eblood_bank_mak_app/users/business/models/code_otp/CurrencyCodeOtpModele.dart';
//
// import 'PhoneNumberPrefixCodeOtpModele.dart';
//
// class CountryCodeOtpModele {
//   String id;
//   int minPhoneNumberChars;
//   int maxPhoneNumberChars;
//   List<PhoneNumberPrefixCodeOtpModele> phoneNumberPrefixes;
//   List<CountryCodeOtpModele> countryCodes;
//   bool isActivated;
//   String homeCountryId;
//   String countryCode;
//   String countryName;
//   String countryFlag;
//   String nationality;
//   List<CurrencyCodeOtpModele> currencies;
//
//   CountryCodeOtpModele({
//    required this.id,
//     required  this.minPhoneNumberChars,
//     required  this.maxPhoneNumberChars,
//     required  this.phoneNumberPrefixes,
//     required   this.countryCodes,
//     required   this.isActivated,
//     required  this.homeCountryId,
//     required   this.countryCode,
//     required   this.countryName,
//     required   this.countryFlag,
//     required    this.nationality,
//     required    this.currencies,
//   });
//
//   factory CountryCodeOtpModele.fromJson(Map<String, dynamic> json) => CountryCodeOtpModele(
//     id: json["_id"],
//     minPhoneNumberChars: json["min_phone_number_chars"],
//     maxPhoneNumberChars: json["max_phone_number_chars"],
//     phoneNumberPrefixes: List<PhoneNumberPrefixCodeOtpModele>.from(json["phone_number_prefixes"].map((x) => PhoneNumberPrefixCodeOtpModele.fromJson(x))),
//     countryCodes: List<CountryCodeOtpModele>.from(json["country_codes"].map((x) => CountryCodeOtpModele.fromJson(x))),
//     isActivated: json["is_activated"],
//     homeCountryId: json["home_country_id"],
//     countryCode: json["country_code"],
//     countryName: json["country_name"],
//     countryFlag: json["country_flag"],
//     nationality: json["nationality"],
//     currencies: List<CurrencyCodeOtpModele>.from(json["currencies"].map((x) => CurrencyCodeOtpModele.fromJson(x))),
//   );
//
//   Map<String, dynamic> toJson() => {
//     "_id": id,
//     "min_phone_number_chars": minPhoneNumberChars,
//     "max_phone_number_chars": maxPhoneNumberChars,
//     "phone_number_prefixes": List<dynamic>.from(phoneNumberPrefixes.map((x) => x.toJson())),
//     "country_codes": List<dynamic>.from(countryCodes.map((x) => x.toJson())),
//     "is_activated": isActivated,
//     "home_country_id": homeCountryId,
//     "country_code": countryCode,
//     "country_name": countryName,
//     "country_flag": countryFlag,
//     "nationality": nationality,
//     "currencies": List<dynamic>.from(currencies.map((x) => x.toJson())),
//   };
// }

import 'package:eblood_bank_mak_app/users/business/models/code_otp/CurrencyCodeOtpModele.dart';
import 'package:eblood_bank_mak_app/users/business/models/code_otp/PhoneNumberPrefixCodeOtpModele.dart';

class CountryCodeOtpModele {
  String id;
  int minPhoneNumberChars;
  int maxPhoneNumberChars;
  List<PhoneNumberPrefixCodeOtpModele> phoneNumberPrefixes;
  List<CountryCodeOtpModele> countryCodes;
  bool isActivated;
  String homeCountryId;
  String countryCode;
  String countryName;
  String countryFlag;
  String nationality;
  List<CurrencyCodeOtpModele> currencies;

  CountryCodeOtpModele({
    required this.id,
    required this.minPhoneNumberChars,
    required this.maxPhoneNumberChars,
    required this.phoneNumberPrefixes,
    required this.countryCodes,
    required this.isActivated,
    required this.homeCountryId,
    required this.countryCode,
    required this.countryName,
    required this.countryFlag,
    required this.nationality,
    required this.currencies,
  });

  factory CountryCodeOtpModele.fromJson(Map<String, dynamic> json) {
    return CountryCodeOtpModele(
      id: json["_id"] ?? "",
      // Valeur par défaut si null
      minPhoneNumberChars: json["min_phone_number_chars"] ?? 0,
      // Valeur par défaut
      maxPhoneNumberChars: json["max_phone_number_chars"] ?? 0,
      // Valeur par défaut
      phoneNumberPrefixes: json["phone_number_prefixes"] != null
          ? List<PhoneNumberPrefixCodeOtpModele>.from(
              json["phone_number_prefixes"]
                  .map((x) => PhoneNumberPrefixCodeOtpModele.fromJson(x)))
          : [],
      // Liste vide si null
      countryCodes: json["country_codes"] != null
          ? List<CountryCodeOtpModele>.from(json["country_codes"]
              .map((x) => CountryCodeOtpModele.fromJson(x)))
          : [],
      // Liste vide si null
      isActivated: json["is_activated"] ?? false,
      // Valeur par défaut
      homeCountryId: json["home_country_id"] ?? "",
      // Valeur par défaut
      countryCode: json["country_code"] ?? "",
      // Valeur par défaut
      countryName: json["country_name"] ?? "",
      // Valeur par défaut
      countryFlag: json["country_flag"] ?? "",
      // Valeur par défaut
      nationality: json["nationality"] ?? "",
      // Valeur par défaut
      currencies: json["currencies"] != null
          ? List<CurrencyCodeOtpModele>.from(
              json["currencies"].map((x) => CurrencyCodeOtpModele.fromJson(x)))
          : [], // Liste vide si null
    );
  }

  Map<String, dynamic> toJson() => {
        "_id": id,
        "min_phone_number_chars": minPhoneNumberChars,
        "max_phone_number_chars": maxPhoneNumberChars,
        "phone_number_prefixes":
            List<dynamic>.from(phoneNumberPrefixes.map((x) => x.toJson())),
        "country_codes":
            List<dynamic>.from(countryCodes.map((x) => x.toJson())),
        "is_activated": isActivated,
        "home_country_id": homeCountryId,
        "country_code": countryCode,
        "country_name": countryName,
        "country_flag": countryFlag,
        "nationality": nationality,
        "currencies": List<dynamic>.from(currencies.map((x) => x.toJson())),
      };
}
