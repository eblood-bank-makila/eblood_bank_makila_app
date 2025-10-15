// To parse this JSON data, do
//
//     final tMfaModel = tMfaModelFromJson(jsonString);

import 'dart:convert';

TMfaModel tMfaModelFromJson(Map<String, dynamic> json) =>
    TMfaModel.fromJson(json);

String tMfaModelToJson(TMfaModel data) => json.encode(data.toJson());

class TMfaModel {
  Id id;
  ConfigDescription identifier;
  Name name;
  ConfigDescription configDescription;
  Flag flag;
  Is isActivated;
  Is isDefault;
  Flag purpose;
  ConfigDescription usageDescription;
  CreatedAt createdAt;
  Icon icon;

  TMfaModel({
    required this.id,
    required this.identifier,
    required this.name,
    required this.configDescription,
    required this.flag,
    required this.isActivated,
    required this.isDefault,
    required this.purpose,
    required this.usageDescription,
    required this.createdAt,
    required this.icon,
  });

  factory TMfaModel.fromJson(Map<String, dynamic> json) => TMfaModel(
        id: json.containsKey('id') && json['id'] != null
            ? Id.fromJson(json['id'])
            : Id.empty(),

        identifier: json.containsKey('identifier') && json['identifier'] != null
            ? ConfigDescription.fromJson(json["identifier"])
            : ConfigDescription.empty(),

        name: json.containsKey('name') && json['name'] != null
            ? Name.fromJson(json["name"])
            : Name.empty(),

        configDescription: json.containsKey('config_description') &&
                json['config_description'] != null
            ? ConfigDescription.fromJson(json["config_description"])
            : ConfigDescription.empty(),

        flag: json.containsKey('flag') && json['flag'] != null
            ? Flag.fromJson(json["flag"])
            : Flag.empty(),
        // flag: Flag.fromJson(json["flag"]),
        isActivated:
            json.containsKey('is_activated') && json['is_activated'] != null
                ? Is.fromJson(json["is_activated"])
                : Is.empty(),
        // isActivated: Is.fromJson(json["is_activated"]),
        isDefault: json.containsKey('is_default') && json['is_default'] != null
            ? Is.fromJson(json["is_default"])
            : Is.empty(),
        // isDefault: Is.fromJson(json["is_default"]),
        purpose: json.containsKey('purpose') && json['purpose'] != null
            ? Flag.fromJson(json["purpose"])
            : Flag.empty(),
        // purpose: Flag.fromJson(json["purpose"]),
        usageDescription: json.containsKey('usage_description') &&
                json['usage_description'] != null
            ? ConfigDescription.fromJson(json["usage_description"])
            : ConfigDescription.empty(),
        // usageDescription: ConfigDescription.fromJson(json["usage_description"]),
        createdAt: json.containsKey('created_at') && json['created_at'] != null
            ? CreatedAt.fromJson(json["created_at"])
            : CreatedAt.empty(),
        // createdAt: CreatedAt.fromJson(json["created_at"]),
        icon: json.containsKey('icon') && json['icon'] != null
            ? Icon.fromJson(json["icon"])
            : Icon.empty(),
        // icon: Icon.fromJson(json["icon"]),
      );

  factory TMfaModel.empty() => TMfaModel(
        id: Id(
          displayTitle: "",
          displayValue: "",
          realValue: RealValue.empty(),
          dataType: ConfigDescriptionDataType(isString: true),
          meta: ConfigDescriptionMeta(
            toBeTranslatedInFront: false,
            missingTranslation: false,
          ),
        ),
        identifier: ConfigDescription(
          displayTitle: "",
          displayValue: "",
          realValue: "",
          dataType: ConfigDescriptionDataType(isString: true),
          meta: ConfigDescriptionMeta(
            toBeTranslatedInFront: false,
            missingTranslation: false,
          ),
        ),
        name: Name(
          displayTitle: "",
          displayValue: "",
          realValue: "",
          dataType: ConfigDescriptionDataType(isString: true),
          meta: PurpleMeta(
            toBeTranslatedInFront: false,
            missingTranslation: false,
            displayValueOnInputSelect: false,
            displayValueOnTree: false,
            displayValueOnCascade: false,
          ),
        ),
        configDescription: ConfigDescription(
          displayTitle: "",
          displayValue: "",
          realValue: "",
          dataType: ConfigDescriptionDataType(isString: true),
          meta: ConfigDescriptionMeta(
            toBeTranslatedInFront: false,
            missingTranslation: false,
          ),
        ),
        flag: Flag(
          displayTitle: "",
          displayValue: "",
          realValue: "",
          dataType: FlagDataType(isEnum: true),
          meta: ConfigDescriptionMeta(
            toBeTranslatedInFront: false,
            missingTranslation: false,
          ),
        ),
        isActivated: Is(
          displayTitle: "",
          displayValue: false,
          realValue: false,
          dataType: IsActivatedDataType(isBoolean: true),
          meta: ConfigDescriptionMeta(
            toBeTranslatedInFront: false,
            missingTranslation: false,
          ),
        ),
        isDefault: Is(
          displayTitle: "",
          displayValue: false,
          realValue: false,
          dataType: IsActivatedDataType(isBoolean: true),
          meta: ConfigDescriptionMeta(
            toBeTranslatedInFront: false,
            missingTranslation: false,
          ),
        ),
        purpose: Flag(
          displayTitle: "",
          displayValue: "",
          realValue: "",
          dataType: FlagDataType(isEnum: true),
          meta: ConfigDescriptionMeta(
            toBeTranslatedInFront: false,
            missingTranslation: false,
          ),
        ),
        usageDescription: ConfigDescription(
          displayTitle: "",
          displayValue: "",
          realValue: "",
          dataType: ConfigDescriptionDataType(isString: true),
          meta: ConfigDescriptionMeta(
            toBeTranslatedInFront: false,
            missingTranslation: false,
          ),
        ),
        createdAt: CreatedAt(
          displayTitle: "",
          displayValue: DateTime.now(),
          dataType: CreatedAtDataType(isDate: true),
          meta: CreatedAtMeta(canBeTranslated: false),
        ),
        icon: Icon(
          id: Id(
            displayTitle: "",
            displayValue: "",
            realValue: RealValue.empty(),
            dataType: ConfigDescriptionDataType(isString: true),
            meta: ConfigDescriptionMeta(
              toBeTranslatedInFront: false,
              missingTranslation: false,
            ),
          ),
          identifier: ConfigDescription(
            displayTitle: "",
            displayValue: "",
            realValue: "",
            dataType: ConfigDescriptionDataType(isString: true),
            meta: ConfigDescriptionMeta(
              toBeTranslatedInFront: false,
              missingTranslation: false,
            ),
          ),
          name: ConfigDescription(
            displayTitle: "",
            displayValue: "",
            realValue: "",
            dataType: ConfigDescriptionDataType(isString: true),
            meta: ConfigDescriptionMeta(
              toBeTranslatedInFront: false,
              missingTranslation: false,
            ),
          ),
          description: Description(
            displayTitle: "",
            displayValue: null,
            realValue: null,
            dataType: DescriptionDataType(isString: true, isNullable: true),
            meta: ConfigDescriptionMeta(
              toBeTranslatedInFront: false,
              missingTranslation: false,
            ),
          ),
          flag: Flag(
            displayTitle: "",
            displayValue: "",
            realValue: "",
            dataType: FlagDataType(isEnum: true),
            meta: ConfigDescriptionMeta(
              toBeTranslatedInFront: false,
              missingTranslation: false,
            ),
          ),
          hardCodeFlag: ConfigDescription(
            displayTitle: "",
            displayValue: "",
            realValue: "",
            dataType: ConfigDescriptionDataType(isString: true),
            meta: ConfigDescriptionMeta(
              toBeTranslatedInFront: false,
              missingTranslation: false,
            ),
          ),
          icon: ConfigDescription(
            displayTitle: "",
            displayValue: "",
            realValue: "",
            dataType: ConfigDescriptionDataType(isString: true),
            meta: ConfigDescriptionMeta(
              toBeTranslatedInFront: false,
              missingTranslation: false,
            ),
          ),
          isActivated: Is(
            displayTitle: "",
            displayValue: false,
            realValue: false,
            dataType: IsActivatedDataType(isBoolean: true),
            meta: ConfigDescriptionMeta(
              toBeTranslatedInFront: false,
              missingTranslation: false,
            ),
          ),
          isDefault: Is(
            displayTitle: "",
            displayValue: false,
            realValue: false,
            dataType: IsActivatedDataType(isBoolean: true),
            meta: ConfigDescriptionMeta(
              toBeTranslatedInFront: false,
              missingTranslation: false,
            ),
          ),
          createdAt: CreatedAt(
            displayTitle: "",
            displayValue: DateTime.now(),
            dataType: CreatedAtDataType(isDate: true),
            meta: CreatedAtMeta(canBeTranslated: false),
          ),
        ),
      );

  Map<String, dynamic> toJson() => {
        "id": id.toJson(),
        "identifier": identifier.toJson(),
        "name": name.toJson(),
        "config_description": configDescription.toJson(),
        "flag": flag.toJson(),
        "is_activated": isActivated.toJson(),
        "is_default": isDefault.toJson(),
        "purpose": purpose.toJson(),
        "usage_description": usageDescription.toJson(),
        "created_at": createdAt.toJson(),
        "icon": icon.toJson(),
      };

  @override
  String toString() => '''
    {
        "id": $id,
        "identifier": $identifier,
        "name": $name,
        "config_description": $configDescription,
        "flag": $flag,
        "is_activated": $isActivated,
        "is_default": $isDefault,
        "purpose": $purpose,
        "usage_description": $usageDescription,
        "created_at": $createdAt,
        "icon": $icon
    }
  ''';
}

class ConfigDescription {
  String displayTitle;
  String displayValue;
  String realValue;
  ConfigDescriptionDataType dataType;
  ConfigDescriptionMeta meta;

  ConfigDescription({
    required this.displayTitle,
    required this.displayValue,
    required this.realValue,
    required this.dataType,
    required this.meta,
  });

  factory ConfigDescription.fromJson(Map<String, dynamic> json) =>
      ConfigDescription(
        displayTitle: json["display_title"] ?? "",
        displayValue: json["display_value"] ?? "",
        realValue: json["real_value"] ?? "",
        dataType: ConfigDescriptionDataType.fromJson(json["data_type"]),
        meta: ConfigDescriptionMeta.fromJson(json["meta"]),
      );
  factory ConfigDescription.empty() => ConfigDescription(
        displayTitle: "",
        displayValue: "",
        realValue: "",
        dataType: ConfigDescriptionDataType(isString: true),
        meta: ConfigDescriptionMeta(
          toBeTranslatedInFront: false,
          missingTranslation: false,
        ),
      );

  Map<String, dynamic> toJson() => {
        "display_title": displayTitle,
        "display_value": displayValue,
        "real_value": realValue,
        "data_type": dataType.toJson(),
        "meta": meta.toJson(),
      };
}

class ConfigDescriptionDataType {
  bool isString;

  ConfigDescriptionDataType({
    required this.isString,
  });

  factory ConfigDescriptionDataType.fromJson(Map<String, dynamic> json) =>
      ConfigDescriptionDataType(
        isString: json["is_string"] ?? false,
      );

  Map<String, dynamic> toJson() => {
        "is_string": isString,
      };
}

class ConfigDescriptionMeta {
  bool toBeTranslatedInFront;
  bool missingTranslation;

  ConfigDescriptionMeta({
    required this.toBeTranslatedInFront,
    required this.missingTranslation,
  });

  factory ConfigDescriptionMeta.fromJson(Map<String, dynamic> json) =>
      ConfigDescriptionMeta(
        toBeTranslatedInFront: json["to_be_translated_in_front"] ?? false,
        missingTranslation: json["missing_translation"] ?? false,
      );
  factory ConfigDescriptionMeta.empty() => ConfigDescriptionMeta(
        toBeTranslatedInFront: false,
        missingTranslation: false,
      );

  Map<String, dynamic> toJson() => {
        "to_be_translated_in_front": toBeTranslatedInFront,
        "missing_translation": missingTranslation,
      };
}

class CreatedAt {
  String displayTitle;
  DateTime displayValue;
  CreatedAtDataType dataType;
  CreatedAtMeta meta;

  CreatedAt({
    required this.displayTitle,
    required this.displayValue,
    required this.dataType,
    required this.meta,
  });

  factory CreatedAt.fromJson(Map<String, dynamic> json) => CreatedAt(
        displayTitle: json["display_title"] ?? "",
        displayValue: json["display_value"] != null
            ? DateTime.parse(json["display_value"])
            : DateTime.now(),
        dataType: CreatedAtDataType.fromJson(json["data_type"]),
        meta: CreatedAtMeta.fromJson(json["meta"]),
      );
  factory CreatedAt.empty() => CreatedAt(
        displayTitle: "",
        displayValue: DateTime.now(),
        dataType: CreatedAtDataType.empty(),
        meta: CreatedAtMeta.empty(),
      );

  Map<String, dynamic> toJson() => {
        "display_title": displayTitle,
        "display_value": displayValue.toIso8601String(),
        "data_type": dataType.toJson(),
        "meta": meta.toJson(),
      };
}

class CreatedAtDataType {
  bool isDate;

  CreatedAtDataType({
    required this.isDate,
  });

  factory CreatedAtDataType.fromJson(Map<String, dynamic> json) =>
      CreatedAtDataType(
        isDate: json["is_date"] ?? false,
      );
  factory CreatedAtDataType.empty() => CreatedAtDataType(
        isDate: false,
      );

  Map<String, dynamic> toJson() => {
        "is_date": isDate,
      };
}

class CreatedAtMeta {
  bool canBeTranslated;

  CreatedAtMeta({
    required this.canBeTranslated,
  });

  factory CreatedAtMeta.fromJson(Map<String, dynamic> json) => CreatedAtMeta(
        canBeTranslated: json["can_be_translated"] ?? false,
      );
  factory CreatedAtMeta.empty() => CreatedAtMeta(
        canBeTranslated: false,
      );

  Map<String, dynamic> toJson() => {
        "can_be_translated": canBeTranslated,
      };
}

class Flag {
  String displayTitle;
  String displayValue;
  String realValue;
  FlagDataType dataType;
  ConfigDescriptionMeta meta;

  Flag({
    required this.displayTitle,
    required this.displayValue,
    required this.realValue,
    required this.dataType,
    required this.meta,
  });

  factory Flag.fromJson(Map<String, dynamic> json) => Flag(
        displayTitle: json["display_title"] ?? "",
        displayValue: json["display_value"] ?? "",
        realValue: json["real_value"] ?? "",
        dataType: FlagDataType.fromJson(json["data_type"]),
        meta: ConfigDescriptionMeta.fromJson(json["meta"]),
      );
  factory Flag.empty() => Flag(
        displayTitle: "",
        displayValue: "",
        realValue: "",
        dataType: FlagDataType.empty(),
        meta: ConfigDescriptionMeta(
          toBeTranslatedInFront: false,
          missingTranslation: false,
          // displayValueOnTree:false,
          // displayValueOnCascade:false,
          // displayValueOnInputSelect: false,
        ),
      );

  Map<String, dynamic> toJson() => {
        "display_title": displayTitle,
        "display_value": displayValue,
        "real_value": realValue,
        "data_type": dataType.toJson(),
        "meta": meta.toJson(),
      };
}

class FlagDataType {
  bool isEnum;

  FlagDataType({
    required this.isEnum,
  });

  factory FlagDataType.fromJson(Map<String, dynamic> json) => FlagDataType(
        isEnum: json["is_enum"] ?? false,
      );
  factory FlagDataType.empty() => FlagDataType(
        isEnum: false,
      );

  Map<String, dynamic> toJson() => {
        "is_enum": isEnum,
      };
}

class Icon {
  Id id;
  ConfigDescription identifier;
  ConfigDescription name;
  Description description;
  Flag flag;
  ConfigDescription hardCodeFlag;
  ConfigDescription icon;
  Is isActivated;
  Is isDefault;
  CreatedAt createdAt;

  Icon({
    required this.id,
    required this.identifier,
    required this.name,
    required this.description,
    required this.flag,
    required this.hardCodeFlag,
    required this.icon,
    required this.isActivated,
    required this.isDefault,
    required this.createdAt,
  });

  factory Icon.fromJson(Map<String, dynamic> json) => Icon(
        id: json.containsKey('id') && json['id'] != null
            ? Id.fromJson(json["id"])
            : Id.empty(),
        identifier: json.containsKey('identifier') && json['identifier'] != null
            ? ConfigDescription.fromJson(json["identifier"])
            : ConfigDescription.empty(),
        name: json.containsKey('name') && json['name'] != null
            ? ConfigDescription.fromJson(json["name"])
            : ConfigDescription.empty(),
        description:
            json.containsKey('description') && json['description'] != null
                ? Description.fromJson(json["description"])
                : Description.empty(),
        flag: json.containsKey('flag') && json['flag'] != null
            ? Flag.fromJson(json["flag"])
            : Flag.empty(),
        hardCodeFlag:
            json.containsKey('hard_code_flag') && json['hard_code_flag'] != null
                ? ConfigDescription.fromJson(json["hard_code_flag"])
                : ConfigDescription.empty(),
        icon: json.containsKey('icon') && json['icon'] != null
            ? ConfigDescription.fromJson(json["icon"])
            : ConfigDescription.empty(),
        isActivated:
            json.containsKey('is_activated') && json['is_activated'] != null
                ? Is.fromJson(json["is_activated"])
                : Is.empty(),
        isDefault: json.containsKey('is_default') && json['is_default'] != null
            ? Is.fromJson(json["is_default"])
            : Is.empty(),
        createdAt: json.containsKey('created_at') && json['created_at'] != null
            ? CreatedAt.fromJson(json["created_at"])
            : CreatedAt.empty(),

        // identifier: ConfigDescription.fromJson(json["identifier"]),
        // name: ConfigDescription.fromJson(json["name"]),
        // description: Description.fromJson(json["description"]),
        // flag: Flag.fromJson(json["flag"]),
        // hardCodeFlag: ConfigDescription.fromJson(json["hard_code_flag"]),
        // icon: ConfigDescription.fromJson(json["icon"]),
        // isActivated: Is.fromJson(json["is_activated"]),
        // isDefault: Is.fromJson(json["is_default"]),
        // createdAt: CreatedAt.fromJson(json["created_at"]),
      );
  factory Icon.empty() => Icon(
        id: Id.empty(),
        identifier: ConfigDescription.empty(),
        name: ConfigDescription.empty(),
        description: Description.empty(),
        flag: Flag.empty(),
        hardCodeFlag: ConfigDescription.empty(),
        icon: ConfigDescription.empty(),
        isActivated: Is.empty(),
        isDefault: Is.empty(),
        createdAt: CreatedAt.empty(),
      );

  Map<String, dynamic> toJson() => {
        "id": id.toJson(),
        "identifier": identifier.toJson(),
        "name": name.toJson(),
        "description": description.toJson(),
        "flag": flag.toJson(),
        "hard_code_flag": hardCodeFlag.toJson(),
        "icon": icon.toJson(),
        "is_activated": isActivated.toJson(),
        "is_default": isDefault.toJson(),
        "created_at": createdAt.toJson(),
      };
}

class Description {
  String displayTitle;
  dynamic displayValue;
  dynamic realValue;
  DescriptionDataType dataType;
  ConfigDescriptionMeta meta;

  Description({
    required this.displayTitle,
    required this.displayValue,
    required this.realValue,
    required this.dataType,
    required this.meta,
  });

  factory Description.fromJson(Map<String, dynamic> json) => Description(
        displayTitle: json["display_title"] ?? "",
        displayValue: json["display_value"],
        realValue: json["real_value"],
        dataType: DescriptionDataType.fromJson(json["data_type"]),
        meta: ConfigDescriptionMeta.fromJson(json["meta"]),
      );
  factory Description.empty() => Description(
        displayTitle: "",
        displayValue: "",
        realValue: "",
        dataType: DescriptionDataType.empty(),
        meta: ConfigDescriptionMeta.empty(),
      );

  Map<String, dynamic> toJson() => {
        "display_title": displayTitle,
        "display_value": displayValue,
        "real_value": realValue,
        "data_type": dataType.toJson(),
        "meta": meta.toJson(),
      };
}

class DescriptionDataType {
  bool isString;
  bool isNullable;

  DescriptionDataType({
    required this.isString,
    required this.isNullable,
  });

  factory DescriptionDataType.fromJson(Map<String, dynamic> json) =>
      DescriptionDataType(
        isString: json["is_string"] ?? false,
        isNullable: json["is_nullable"] ?? false,
      );
  factory DescriptionDataType.empty() => DescriptionDataType(
        isString: false,
        isNullable: false,
      );

  Map<String, dynamic> toJson() => {
        "is_string": isString,
        "is_nullable": isNullable,
      };
}

class Id {
  String displayTitle;
  String displayValue;
  RealValue realValue;
  ConfigDescriptionDataType dataType;
  ConfigDescriptionMeta meta;

  Id({
    required this.displayTitle,
    required this.displayValue,
    required this.realValue,
    required this.dataType,
    required this.meta,
  });

  factory Id.fromJson(Map<String, dynamic> json) => Id(
        displayTitle: json.containsKey('display_title') && json["display_title"] != null
            ? json["display_title"]: '',
        displayValue: json.containsKey('display_value') && json['display_value'] != null ? json["display_value"]:'',
        realValue: json.containsKey('real_value') && json['real_value'] != null
            ? RealValue.fromJson(json["real_value"])
            : RealValue.empty(),
        // realValue: RealValue.fromJson(json["real_value"]),
        dataType: ConfigDescriptionDataType.fromJson(json["data_type"]),
        meta: ConfigDescriptionMeta.fromJson(json["meta"]),
      );
  factory Id.empty() => Id(
        displayTitle: "",
        displayValue: "",
        realValue: RealValue.empty(),
        dataType: ConfigDescriptionDataType(isString: true),
        meta: ConfigDescriptionMeta(
          toBeTranslatedInFront: false,
          missingTranslation: false,
        ),
      );

  Map<String, dynamic> toJson() => {
        "display_title": displayTitle,
        "display_value": displayValue,
        "real_value": realValue.toJson(),
        "data_type": dataType.toJson(),
        "meta": meta.toJson(),
      };
}

class RealValue {
  dynamic value;

  RealValue({this.value});

  factory RealValue.fromJson(dynamic json) {
    // Handle both Map and primitive types (String, int, etc.)
    if (json is Map<String, dynamic>) {
      return RealValue(value: json);
    } else {
      // For primitive types like String, int, bool, etc.
      return RealValue(value: json);
    }
  }

  factory RealValue.empty() => RealValue(value: null);

  Map<String, dynamic> toJson() {
    if (value is Map<String, dynamic>) {
      return value as Map<String, dynamic>;
    } else if (value != null) {
      return {"value": value};
    } else {
      return {};
    }
  }
}

class Is {
  String displayTitle;
  bool displayValue;
  bool realValue;
  IsActivatedDataType dataType;
  ConfigDescriptionMeta meta;

  Is({
    required this.displayTitle,
    required this.displayValue,
    required this.realValue,
    required this.dataType,
    required this.meta,
  });

  factory Is.fromJson(Map<String, dynamic> json) => Is(
        displayTitle: json["display_title"] ?? "",
        displayValue: json["display_value"] ?? false,
        realValue: json["real_value"] ?? false,
        dataType: IsActivatedDataType.fromJson(json["data_type"]),
        meta: ConfigDescriptionMeta.fromJson(json["meta"]),
      );
  factory Is.empty() => Is(
        displayTitle: "",
        displayValue: false,
        realValue: false,
        dataType: IsActivatedDataType.empty(),
        meta: ConfigDescriptionMeta(
          toBeTranslatedInFront: false,
          missingTranslation: false,
          // displayValueOnTree:false,
          // displayValueOnCascade:false,
          // displayValueOnInputSelect: false,
        ),
      );

  Map<String, dynamic> toJson() => {
        "display_title": displayTitle,
        "display_value": displayValue,
        "real_value": realValue,
        "data_type": dataType.toJson(),
        "meta": meta.toJson(),
      };
}

class IsActivatedDataType {
  bool isBoolean;

  IsActivatedDataType({
    required this.isBoolean,
  });

  factory IsActivatedDataType.fromJson(Map<String, dynamic> json) =>
      IsActivatedDataType(
        isBoolean: json["is_boolean"] ?? false,
      );
  factory IsActivatedDataType.empty() => IsActivatedDataType(
        isBoolean: false,
      );

  Map<String, dynamic> toJson() => {
        "is_boolean": isBoolean,
      };
}

class Name {
  String displayTitle;
  String displayValue;
  String realValue;
  ConfigDescriptionDataType dataType;
  PurpleMeta meta;

  Name({
    required this.displayTitle,
    required this.displayValue,
    required this.realValue,
    required this.dataType,
    required this.meta,
  });

  factory Name.fromJson(Map<String, dynamic> json) => Name(
        displayTitle: json["display_title"] ?? "",
        displayValue: json["display_value"] ?? "",
        realValue: json["real_value"] ?? "",
        dataType: ConfigDescriptionDataType.fromJson(json["data_type"]),
        meta: PurpleMeta.fromJson(json["meta"]),
      );

  factory Name.empty() => Name(
        displayTitle: "",
        displayValue: "",
        realValue: "",
        dataType: ConfigDescriptionDataType(isString: false),
        meta: PurpleMeta(
          toBeTranslatedInFront: false,
          missingTranslation: false,
          displayValueOnTree: false,
          displayValueOnCascade: false,
          displayValueOnInputSelect: false,
        ),
      );

  Map<String, dynamic> toJson() => {
        "display_title": displayTitle,
        "display_value": displayValue,
        "real_value": realValue,
        "data_type": dataType.toJson(),
        "meta": meta.toJson(),
      };
}

class PurpleMeta {
  bool toBeTranslatedInFront;
  bool missingTranslation;
  bool displayValueOnInputSelect;
  bool displayValueOnTree;
  bool displayValueOnCascade;

  PurpleMeta({
    required this.toBeTranslatedInFront,
    required this.missingTranslation,
    required this.displayValueOnInputSelect,
    required this.displayValueOnTree,
    required this.displayValueOnCascade,
  });

  factory PurpleMeta.fromJson(Map<String, dynamic> json) => PurpleMeta(
        toBeTranslatedInFront: json["to_be_translated_in_front"] ?? false,
        missingTranslation: json["missing_translation"] ?? false,
        displayValueOnInputSelect: json["display_value_on_input_select"] ?? false,
        displayValueOnTree: json["display_value_on_tree"] ?? false,
        displayValueOnCascade: json["display_value_on_cascade"] ?? false,
      );

  Map<String, dynamic> toJson() => {
        "to_be_translated_in_front": toBeTranslatedInFront,
        "missing_translation": missingTranslation,
        "display_value_on_input_select": displayValueOnInputSelect,
        "display_value_on_tree": displayValueOnTree,
        "display_value_on_cascade": displayValueOnCascade,
      };
}
