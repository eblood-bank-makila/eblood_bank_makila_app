
import 'PocheModel.dart';

class ReponsePocheModel {
  bool twoFactor;
  bool resetpassword;
  List<PocheModel> data;
  bool success;
  int max;
  int perpage;

  ReponsePocheModel({
    this.twoFactor=false,
    this.resetpassword =false,
    required this.data,
    this.success = false,
    required this.max,
    required this.perpage,
  });

  factory ReponsePocheModel.fromJson(Map<String, dynamic> json) => ReponsePocheModel(
    twoFactor: json["two_factor"],
    resetpassword: json["resetpassword"],
    data: List<PocheModel>.from(json["data"].map((x) => PocheModel.fromJson(x))),
    success: json["success"],
    max: json["max"],
    perpage: json["perpage"],
  );

  Map<String, dynamic> toJson() => {
    "two_factor": twoFactor,
    "resetpassword": resetpassword,
    "data": List<dynamic>.from(data.map((x) => x.toJson())),
    "success": success,
    "max": max,
    "perpage": perpage,
  };
}