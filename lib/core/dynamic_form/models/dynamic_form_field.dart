/// Mirrors Angular's `TFieldFormFieldType` (API HEAD response) and
/// `IFormatedFormFields` (formatted for rendering).
///
/// A single class handles both roles to keep the Flutter layer lean.
library;

enum DynamicFieldType {
  text,
  email,
  phone,
  password,
  number,
  date,
  checkbox,
  radio,
  select,
  enumField,
  cascade,
  longText,
  file,
  htmlEditor,
}

class DynamicFormField {
  final String name;
  final String label;
  final DynamicFieldType fieldType;
  final bool isRequired;
  final bool isOptional;
  final bool isHiddenPreFilled;
  final int? minLength;
  final int? maxLength;
  final List<SelectOption> options;
  final dynamic defaultValue;
  final Map<String, dynamic> extraMetas;

  dynamic value;

  DynamicFormField({
    required this.name,
    required this.label,
    required this.fieldType,
    this.isRequired = false,
    this.isOptional = false,
    this.isHiddenPreFilled = false,
    this.minLength,
    this.maxLength,
    this.options = const [],
    this.defaultValue,
    this.extraMetas = const {},
    this.value,
  });
}

class SelectOption {
  final String id;
  final String displayValue;
  final String propertyName;
  final bool isLeaf;
  final List<SelectOption> children;

  const SelectOption({
    required this.id,
    required this.displayValue,
    this.propertyName = '',
    this.isLeaf = true,
    this.children = const [],
  });

  factory SelectOption.fromMap(Map<String, dynamic> m) {
    return SelectOption(
      id: (m['id'] ?? m['_id'] ?? '').toString(),
      displayValue: _resolveDisplay(m),
      propertyName: (m['property_name'] ?? '').toString(),
      isLeaf: m['is_leaf'] == true,
      children: m['children'] is List
          ? (m['children'] as List)
              .whereType<Map<String, dynamic>>()
              .map(SelectOption.fromMap)
              .toList()
          : const [],
    );
  }

  static String _resolveDisplay(Map<String, dynamic> m) {
    final dv = m['display_value'];
    if (dv is String) return dv;
    if (dv is Map) return (dv['fr'] ?? dv['en'] ?? '').toString();
    return (m['name'] ?? m['label'] ?? m['code'] ?? m['id'] ?? '').toString();
  }
}
