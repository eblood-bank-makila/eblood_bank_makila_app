class SystemCountry {
  final String id;
  final String name;
  final String code;
  final String? flagUrl;
  final List<SystemProvince> provinces;

  SystemCountry({
    required this.id,
    required this.name,
    required this.code,
    this.flagUrl,
    this.provinces = const [],
  });

  factory SystemCountry.fromJson(Map<String, dynamic> json) {
    List<SystemProvince> provinces = [];
    if (json['provinces'] != null) {
      provinces = (json['provinces'] as List)
          .map((provinceJson) => SystemProvince.fromJson(provinceJson))
          .toList();
    }

    return SystemCountry(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      code: json['code'] ?? '',
      flagUrl: json['flag_url'],
      provinces: provinces,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'code': code,
      'flag_url': flagUrl,
      'provinces': provinces.map((province) => province.toJson()).toList(),
    };
  }

  @override
  String toString() => name;
}

class SystemProvince {
  final String id;
  final String name;
  final String countryId;
  final List<SystemTown> towns;

  SystemProvince({
    required this.id,
    required this.name,
    required this.countryId,
    this.towns = const [],
  });

  factory SystemProvince.fromJson(Map<String, dynamic> json) {
    List<SystemTown> towns = [];
    if (json['towns'] != null) {
      towns = (json['towns'] as List)
          .map((townJson) => SystemTown.fromJson(townJson))
          .toList();
    }

    return SystemProvince(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      countryId: json['country_id'].toString(),
      towns: towns,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'country_id': countryId,
      'towns': towns.map((town) => town.toJson()).toList(),
    };
  }

  @override
  String toString() => name;
}

class SystemTown {
  final String id;
  final String name;
  final String provinceId;

  SystemTown({
    required this.id,
    required this.name,
    required this.provinceId,
  });

  factory SystemTown.fromJson(Map<String, dynamic> json) {
    return SystemTown(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      provinceId: json['province_id'].toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'province_id': provinceId,
    };
  }

  @override
  String toString() => name;
}