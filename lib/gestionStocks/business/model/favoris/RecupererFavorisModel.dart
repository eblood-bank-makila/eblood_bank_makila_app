import 'dart:convert';

RecupererFavorisModel recupererFavorisModelFromJson(String str) =>
    RecupererFavorisModel.fromJson(json.decode(str));

String recupererFavorisModelToJson(RecupererFavorisModel data) => json.encode(data.toJson());

class RecupererFavorisModel {
  final String page;

  RecupererFavorisModel({
    required this.page,

  });

  factory RecupererFavorisModel.fromJson(Map json) => RecupererFavorisModel(
    page: json['page'],

  );

  Map<String, dynamic> toJson() => {
    'page': page,

  };
}
