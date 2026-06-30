class UTelephoneCodeOtpModele {
  String phoneNumber;
  String id;

  UTelephoneCodeOtpModele ({
   required this.phoneNumber,
   required this.id,
  });

  factory UTelephoneCodeOtpModele .fromJson(Map<String, dynamic> json) => UTelephoneCodeOtpModele (
    phoneNumber: json["phone_number"],
    id: json["_id"],
  );

  Map<String, dynamic> toJson() => {
    "phone_number": phoneNumber,
    "_id": id,
  };
}
