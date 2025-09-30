class SystemCountry {
  final String id;
  final String name;
  final String namedEntityFlag;
  final String? systemCountryId;
  final List<SystemCountry> children;

  SystemCountry({
    required this.id,
    required this.name,
    required this.namedEntityFlag,
    this.systemCountryId,
    required this.children,
  });

  factory SystemCountry.fromJson(Map<String, dynamic> json) {
    return SystemCountry(
      id: json['id'] as String,
      name: json['name'] as String,
      namedEntityFlag: json['named_entity_flag'] as String,
      systemCountryId: json['system_country_id'] as String?,
      children: (json['children'] as List<dynamic>?)
              ?.map((e) => SystemCountry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'named_entity_flag': namedEntityFlag,
      if (systemCountryId != null) 'system_country_id': systemCountryId,
      'children': children.map((child) => child.toJson()).toList(),
    };
  }
}

class SystemCountryResponse {
  final int statusCode;
  final String message;
  final List<SystemCountry> data;

  SystemCountryResponse({
    required this.statusCode,
    required this.message,
    required this.data,
  });

  factory SystemCountryResponse.fromJson(Map<String, dynamic> json) {
    return SystemCountryResponse(
      statusCode: json['status_code'] as int,
      message: json['message'] as String,
      data: (json['data'] as List<dynamic>)
          .map((e) => SystemCountry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}