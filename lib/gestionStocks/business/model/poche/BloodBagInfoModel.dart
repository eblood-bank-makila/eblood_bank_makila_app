import 'dart:convert';
import 'package:eblood_bank_mak_app/gestionStocks/business/model/poche/BloodTypeInfoModel.dart';
import 'package:eblood_bank_mak_app/gestionStocks/business/model/poche/BloodVolumeInfoModel.dart';
import '../recherche/BloodBagInfoRecherchePocheModel.dart';
import 'BloodRhesusInfoModel.dart';

BloodBagInfo bloodBagInfoFromJson(String str) =>
    BloodBagInfo.fromJson(json.decode(str));

String bloodBagInfoToJson(BloodBagInfo data) => json.encode(data.toJson());

class BloodBagInfo {
  String id;
  bool isActivated;
  String identifier;
  DateTime createdAt;
  String bloodTypeId;
  String bloodRhesusId;
  String bloodVolumeId;
  BloodTypeInfoModel bloodTypeInfo;
  BloodRhesusInfoModel bloodRhesusInfo;
  BloodVolumeInfoModel bloodVolumeInfo;

  BloodBagInfo({
    required this.id,
    this.isActivated = false,
    required this.identifier,
    required this.createdAt,
    required this.bloodTypeId,
    required this.bloodRhesusId,
    required this.bloodVolumeId,
    required this.bloodTypeInfo,
    required this.bloodRhesusInfo,
    required this.bloodVolumeInfo,
  });

  // Constructeur à partir de BloodBagRecherchePocheModel
  factory BloodBagInfo.fromRecherche(BloodBagInfoRecherchePocheModel rechercheModel) {
    return BloodBagInfo(
      id: rechercheModel.id,
      // Assurez-vous que ces propriétés existent
      isActivated: rechercheModel.isActivated,
      identifier: rechercheModel.identifier,
      createdAt: rechercheModel.createdAt,
      // Assurez-vous que c'est au bon format
      bloodTypeId: rechercheModel.bloodTypeId,
      bloodRhesusId: rechercheModel.bloodRhesusId,
      bloodVolumeId: rechercheModel.bloodVolumeId,
      bloodTypeInfo:
          BloodTypeInfoModel.fromRecherche(rechercheModel.bloodTypeInfo),
      bloodRhesusInfo:
          BloodRhesusInfoModel.fromRecherche(rechercheModel.bloodRhesusInfo),
      bloodVolumeInfo:
          BloodVolumeInfoModel.fromRecherche(rechercheModel.bloodVolumeInfo),
    );
  }

  factory BloodBagInfo.fromJson(Map<String, dynamic> json) => BloodBagInfo(
        id: json["_id"] ?? '',
        isActivated: json["is_activated"] ?? true, // Default to true if null
        identifier: json["identifier"] ?? '',
        createdAt: json["createdAt"] != null ? DateTime.parse(json["createdAt"]) : DateTime.now(),
        bloodTypeId: json["blood_type_id"] ?? '',
        bloodRhesusId: json["blood_rhesus_id"] ?? '',
        bloodVolumeId: json["blood_volume_id"] ?? '',
        bloodTypeInfo: BloodTypeInfoModel.fromJson(json["blood_type_info"] ?? {}),
        bloodRhesusInfo:
            BloodRhesusInfoModel.fromJson(json["blood_rhesus_info"] ?? {}),
        bloodVolumeInfo:
            BloodVolumeInfoModel.fromJson(json["blood_volume_info"] ?? {}),
      );

  Map<String, dynamic> toJson() => {
        "_id": id,
        "is_activated": isActivated,
        "identifier": identifier,
        "createdAt": createdAt.toIso8601String(),
        "blood_type_id": bloodTypeId,
        "blood_rhesus_id": bloodRhesusId,
        "blood_volume_id": bloodVolumeId,
        "blood_type_info": bloodTypeInfo.toJson(),
        "blood_rhesus_info": bloodRhesusInfo.toJson(),
        "blood_volume_info": bloodVolumeInfo.toJson(),
      };
}

// import 'dart:convert';
// import 'package:eblood_bank_mak_app/gestionStocks/business/model/poche/BloodTypeInfoModel.dart';
// import 'package:eblood_bank_mak_app/gestionStocks/business/model/poche/BloodVolumeInfoModel.dart';
// import 'package:eblood_bank_mak_app/gestionStocks/business/model/poche/PocheModel.dart';
// import 'BloodRhesusInfoModel.dart';
//
// BloodBagInfo bloodBagInfoFromJson(String str) =>
//     BloodBagInfo.fromJson(json.decode(str));
//
// String bloodBagInfoToJson(BloodBagInfo data) => json.encode(data.toJson());
//
// class BloodBagInfo {
//   final String id; // Utilisation de 'final' pour l'immuabilité
//   final bool isActivated; // Utilisation de 'final' pour l'immuabilité
//   final String identifier; // Utilisation de 'final' pour l'immuabilité
//   final DateTime createdAt; // Utilisation de 'final' pour l'immuabilité
//   final String bloodTypeId; // Utilisation de 'final' pour l'immuabilité
//   final String bloodRhesusId; // Utilisation de 'final' pour l'immuabilité
//   final String bloodVolumeId; // Utilisation de 'final' pour l'immuabilité
//   final BloodTypeInfoModel
//       bloodTypeInfo; // Utilisation de 'final' pour l'immuabilité
//   final BloodRhesusInfoModel
//       bloodRhesusInfo; // Utilisation de 'final' pour l'immuabilité
//   final BloodVolumeInfoModel
//       bloodVolumeInfo; // Utilisation de 'final' pour l'immuabilité
//
//   BloodBagInfo({
//     required this.id,
//     this.isActivated = false,
//     required this.identifier,
//     required this.createdAt,
//     required this.bloodTypeId,
//     required this.bloodRhesusId,
//     required this.bloodVolumeId,
//     required this.bloodTypeInfo,
//     required this.bloodRhesusInfo,
//     required this.bloodVolumeInfo,
//   });
//
//   // Constructeur à partir de BloodBagRecherchePocheModel
//   factory BloodBagInfo.fromRecherche(
//       BloodBagRecherchePocheModel rechercheModel) {
//     return BloodBagInfo(
//       id: rechercheModel.id,
//       // Assurez-vous que ces propriétés existent
//       isActivated: rechercheModel.isActivated,
//       identifier: rechercheModel.identifier,
//       createdAt: DateTime.parse(rechercheModel.createdAt),
//       // Assurez-vous que c'est au bon format
//       bloodTypeId: rechercheModel.bloodTypeId,
//       bloodRhesusId: rechercheModel.bloodRhesusId,
//       bloodVolumeId: rechercheModel.bloodVolumeId,
//       bloodTypeInfo:
//           BloodTypeInfoModel.fromRecherche(rechercheModel.bloodTypeInfo),
//       bloodRhesusInfo:
//           BloodRhesusInfoModel.fromRecherche(rechercheModel.bloodRhesusInfo),
//       bloodVolumeInfo:
//           BloodVolumeInfoModel.fromRecherche(rechercheModel.bloodVolumeInfo),
//     );
//   }
//
//   factory BloodBagInfo.fromJson(Map<String, dynamic> json) => BloodBagInfo(
//         id: json["_id"],
//         isActivated: json["is_activated"],
//         identifier: json["identifier"],
//         createdAt: DateTime.parse(json["createdAt"]),
//         bloodTypeId: json["blood_type_id"],
//         bloodRhesusId: json["blood_rhesus_id"],
//         bloodVolumeId: json["blood_volume_id"],
//         bloodTypeInfo: BloodTypeInfoModel.fromJson(json["blood_type_info"]),
//         bloodRhesusInfo:
//             BloodRhesusInfoModel.fromJson(json["blood_rhesus_info"]),
//         bloodVolumeInfo:
//             BloodVolumeInfoModel.fromJson(json["blood_volume_info"]),
//       );
//
//   Map<String, dynamic> toJson() => {
//         "_id": id,
//         "is_activated": isActivated,
//         "identifier": identifier,
//         "createdAt": createdAt.toIso8601String(),
//         "blood_type_id": bloodTypeId,
//         "blood_rhesus_id": bloodRhesusId,
//         "blood_volume_id": bloodVolumeId,
//         "blood_type_info": bloodTypeInfo.toJson(),
//         "blood_rhesus_info": bloodRhesusInfo.toJson(),
//         "blood_volume_info": bloodVolumeInfo.toJson(),
//       };
// }
