import 'package:flutter_test/flutter_test.dart';

import 'package:eblood_bank_mak_app/apps/translations/AppTranslations.dart';
import 'package:eblood_bank_mak_app/core/services/location_access.dart';

/// GetX's `.tr` shows the raw key when a locale lacks it, so every string the
/// Localisation row and the "location needed" card can display must exist in
/// all five locales.
void main() {
  final locales = AppTranslations().keys;

  final keys = <String>[
    ...LocationAccessStatus.values.map(LocationAccess.statusLabelKey),
    'location_access_title',
    'location_access_needed_title',
    'location_access_needed_message',
    'location_access_enable',
    'retry',
  ];

  test('every location access key is translated in every locale', () {
    final missing = <String>[];
    for (final entry in locales.entries) {
      for (final key in keys) {
        final value = entry.value[key];
        if (value == null || value.trim().isEmpty) missing.add('${entry.key}: $key');
      }
    }
    expect(missing, isEmpty);
  });
}
