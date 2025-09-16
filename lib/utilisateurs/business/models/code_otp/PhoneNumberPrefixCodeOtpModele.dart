class PhoneNumberPrefixCodeOtpModele {
  String prefix;
  String id;

  PhoneNumberPrefixCodeOtpModele({
   required this.prefix,
  required  this.id,
  });

  factory  PhoneNumberPrefixCodeOtpModele.fromJson(Map<String, dynamic> json) =>  PhoneNumberPrefixCodeOtpModele(
    prefix: json["prefix"],
    id: json["_id"],
  );

  Map<String, dynamic> toJson() => {
    "prefix": prefix,
    "_id": id,
  };
}