

class UCourrielCodeOtpModele {
  String email;
  String id;

  UCourrielCodeOtpModele ({
  required  this.email,
  required  this.id,
  });

  factory UCourrielCodeOtpModele .fromJson(Map<String, dynamic> json) => UCourrielCodeOtpModele (
    email: json["email"],
    id: json["_id"],
  );

  Map<String, dynamic> toJson() => {
    "email": email,
    "_id": id,
  };
}