import 'dart:convert';

BanqueListeModele banqueListeModeleFromJson(String str) =>
    BanqueListeModele.fromJson(json.decode(str));

String banqueListeModeleToJson(BanqueListeModele data) =>
    json.encode(data.toJson());

class BanqueListeModele {
  final String page;

  BanqueListeModele({
    required this.page,
  });

  factory BanqueListeModele.fromJson(Map json) => BanqueListeModele(
        page: json['page'],
      );

  Map<String, dynamic> toJson() => {
        'page': page,
      };
}
