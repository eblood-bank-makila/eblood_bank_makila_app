import 'dart:convert';

RecupererListePanierModele recupererListeModeleFromJson(String str) =>
    RecupererListePanierModele.fromJson(json.decode(str));

String recupererListeModeleToJson(RecupererListePanierModele data) =>
    json.encode(data.toJson());

class RecupererListePanierModele {
  final String page;

  RecupererListePanierModele({
    required this.page,
  });

  factory RecupererListePanierModele.fromJson(Map json) => RecupererListePanierModele(
    page: json['page'],
  );

  Map<String, dynamic> toJson() => {
    'page': page,
  };
}
