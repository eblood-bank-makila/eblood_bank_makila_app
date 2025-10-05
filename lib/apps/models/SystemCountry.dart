class CountryCode {
  final String id;
  final String countryCode;

  CountryCode({
    required this.id,
    required this.countryCode,
  });

  factory CountryCode.fromJson(Map<String, dynamic> json) {
    return CountryCode(
      id: json['id'] as String,
      countryCode: json['country_code'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'country_code': countryCode,
    };
  }
}

class TelephonePrefix {
  final String id;
  final String prefix;

  TelephonePrefix({
    required this.id,
    required this.prefix,
  });

  factory TelephonePrefix.fromJson(Map<String, dynamic> json) {
    return TelephonePrefix(
      id: json['id'] as String,
      prefix: json['prefix'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'prefix': prefix,
    };
  }
}

class SystemCountry {
  final String id;
  final String name;
  final String namedEntityFlag;
  final String? systemCountryId;
  final List<CountryCode>? countryCodes;
  final List<TelephonePrefix>? telephonePrefixes;
  final String? countryFlag;
  final List<SystemCountry> children;

  SystemCountry({
    required this.id,
    required this.name,
    required this.namedEntityFlag,
    this.systemCountryId,
    this.countryCodes,
    this.telephonePrefixes,
    this.countryFlag,
    required this.children,
  });

  factory SystemCountry.fromJson(Map<String, dynamic> json) {
    return SystemCountry(
      id: json['id'] as String,
      name: json['name'] as String,
      namedEntityFlag: json['named_entity_flag'] as String,
      systemCountryId: json['system_country_id'] as String?,
      countryCodes: json['country_codes'] != null
          ? (json['country_codes'] as List<dynamic>)
              .map((e) => CountryCode.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      telephonePrefixes: json['telephone_prefixes'] != null
          ? (json['telephone_prefixes'] as List<dynamic>)
              .map((e) => TelephonePrefix.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      countryFlag: json['country_flag'] as String?,
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
      if (countryCodes != null)
        'country_codes': countryCodes!.map((code) => code.toJson()).toList(),
      if (telephonePrefixes != null)
        'telephone_prefixes': telephonePrefixes!.map((prefix) => prefix.toJson()).toList(),
      if (countryFlag != null) 'country_flag': countryFlag,
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