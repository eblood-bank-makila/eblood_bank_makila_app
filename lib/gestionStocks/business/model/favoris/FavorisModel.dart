import 'dart:convert';

FavorisModele favorisModeleFromJson(String str) =>
    FavorisModele.fromJson(json.decode(str));

String favorisModeleToJson(FavorisModele data) => json.encode(data.toJson());

class FavorisModele {
  final String blood_bank_id;


  FavorisModele({
    required this.blood_bank_id,

  });

  factory FavorisModele.fromJson(Map json) => FavorisModele(
    blood_bank_id: json['blood_bank_id'],

  );

  Map<String, dynamic> toJson() => {
    'blood_bank_id': blood_bank_id,

  };
}
