import 'dart:convert';

RechercheModel banqueListeModeleFromJson(String str) =>
    RechercheModel.fromJson(json.decode(str));

String banqueListeModeleToJson(RechercheModel data) =>
    json.encode(data.toJson());

class RechercheModel {
  final String searchKey;

  RechercheModel({
    required this.searchKey,
  });

  factory RechercheModel.fromJson(Map json) => RechercheModel(
    searchKey: json['searchKey'],
  );

  Map<String, dynamic> toJson() => {
    'searchKey': searchKey,
  };
}
