/// Parses the HEAD API response into a list of [DynamicFormField].
///
/// Mirrors Angular's `CommonService.formateCreationFormInput()`.
library;

import '../models/dynamic_form_field.dart';

class DynamicFormParser {
  /// Parse the raw HEAD response (a Map where each key is a property name
  /// and each value describes the field).
  List<DynamicFormField> parse(Map<String, dynamic> data) {
    final fields = <DynamicFormField>[];

    for (final entry in data.entries) {
      final value = entry.value;
      if (value is! Map<String, dynamic>) continue;

      final propertyName = (value['property_name'] ?? entry.key).toString();
      final displayTitle = (value['display_title'] ?? value['display_value'] ?? propertyName).toString();
      final dataType = value['data_type'] as Map<String, dynamic>? ?? {};
      final extraMetas = value['extra_metas'] as Map<String, dynamic>? ?? {};
      final defaultVal = value['default_value'];
      final dataList = value['data_list'] as List? ?? [];
      final isRequired = extraMetas['is_required'] == true;
      final isOptional = dataType['is_optional'] == true;
      final minLen = extraMetas['min_length'] as int?;
      final maxLen = extraMetas['max_length'] as int?;

      final bool isHidden =
          extraMetas.containsKey('skip_on_view') && extraMetas.containsKey('has_default_value');

      final options = dataList
          .whereType<Map<String, dynamic>>()
          .map(SelectOption.fromMap)
          .toList();

      DynamicFieldType? fieldType;

      if (dataType['is_string'] == true) {
        fieldType = DynamicFieldType.text;
      } else if (dataType['is_email'] == true) {
        fieldType = DynamicFieldType.email;
      } else if (dataType['is_phone_number'] == true) {
        fieldType = DynamicFieldType.phone;
      } else if (dataType['is_password'] == true) {
        fieldType = DynamicFieldType.password;
      } else if (dataType['is_long_string'] == true) {
        fieldType = DynamicFieldType.longText;
      } else if (dataType['is_number'] == true || dataType['is_int'] == true) {
        fieldType = DynamicFieldType.number;
      } else if (dataType['is_amount'] == true) {
        fieldType = DynamicFieldType.number;
      } else if (dataType['is_date'] == true) {
        fieldType = DynamicFieldType.date;
      } else if (dataType['is_boolean'] == true) {
        fieldType = DynamicFieldType.checkbox;
      } else if (dataType['is_radio'] == true) {
        fieldType = DynamicFieldType.radio;
      } else if (dataType['is_enum'] == true) {
        fieldType = DynamicFieldType.enumField;
      } else if (dataType['is_select'] == true) {
        fieldType = DynamicFieldType.select;
      } else if (dataType['is_cascade'] == true) {
        fieldType = DynamicFieldType.cascade;
      } else if (dataType['is_profile_file'] == true) {
        fieldType = DynamicFieldType.file;
      } else if (dataType['is_html_editor'] == true || dataType['is_html_input'] == true) {
        fieldType = DynamicFieldType.htmlEditor;
      }

      if (fieldType == null) continue;

      fields.add(DynamicFormField(
        name: propertyName,
        label: displayTitle,
        fieldType: fieldType,
        isRequired: isRequired,
        isOptional: isOptional,
        isHiddenPreFilled: isHidden,
        minLength: minLen,
        maxLength: maxLen,
        options: options,
        defaultValue: defaultVal,
        extraMetas: extraMetas,
        value: isHidden ? defaultVal : null,
      ));
    }

    return fields;
  }

  /// Collect form values from a list of fields into a submission payload.
  Map<String, dynamic> collectValues(List<DynamicFormField> fields) {
    final payload = <String, dynamic>{};
    for (final f in fields) {
      payload[f.name] = f.value ?? f.defaultValue;
    }
    return payload;
  }
}
