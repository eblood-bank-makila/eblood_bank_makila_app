//
//
// class CordonatesCodeOtpModele {
//   final double longitude;
//   final double latitude;
//
//   CordonatesCodeOtpModele({
//   required  this.longitude,
//    required this.latitude,
//   });
//
//   factory CordonatesCodeOtpModele.fromJson(Map<String, dynamic> json) => CordonatesCodeOtpModele(
//     longitude: json["longitude"],
//     latitude: json["latitude"],
//   );
//
//   Map<String, dynamic> toJson() => {
//     "longitude": longitude,
//     "latitude": latitude,
//   };
// }

class CordonatesCodeOtpModele {
  final double longitude;
  final double latitude;

  CordonatesCodeOtpModele({
    required this.longitude,
    required this.latitude,
  });

  factory CordonatesCodeOtpModele.fromJson(Map<String, dynamic> json) =>
      CordonatesCodeOtpModele(
        longitude: json["longitude"] != null
            ? double.parse(json["longitude"].toString())
            : 0.0, // Conversion correcte
        latitude: json["latitude"] != null
            ? double.parse(json["latitude"].toString())
            : 0.0, // Conversion correcte
      );

  Map<String, dynamic> toJson() => {
        "longitude": longitude,
        "latitude": latitude,
      };
}
