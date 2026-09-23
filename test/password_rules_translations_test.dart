import 'package:flutter_test/flutter_test.dart';

import 'package:eblood_bank_mak_app/apps/translations/AppTranslations.dart';
import 'package:eblood_bank_mak_app/apps/utils/password_rules.dart';

/// GetX's `.tr` returns the raw key when a locale is missing it, so a key
/// defined only in fr/en shows up on screen as "password_needs_uppercase"
/// for an es / ln / ru user. Every key passwordRuleKey can return has to
/// exist in every locale.
void main() {
  final locales = AppTranslations().keys;

  /// Every key passwordRuleKey is able to return.
  const ruleKeys = <String>[
    'password_required',
    'password_min_length',
    'password_needs_uppercase',
    'password_needs_lowercase',
    'password_needs_digit',
    'password_needs_special',
  ];

  test('the app still ships the five locales this guard covers', () {
    expect(
      locales.keys.toSet(),
      {'fr_FR', 'en_US', 'es_ES', 'ln_CD', 'ru_RU'},
      reason: 'a new locale needs the password rule keys too',
    );
  });

  test('every password rule key is translated in every locale', () {
    final missing = <String>[];
    for (final entry in locales.entries) {
      for (final key in ruleKeys) {
        final value = entry.value[key];
        if (value == null || value.trim().isEmpty) {
          missing.add('${entry.key}: $key');
        }
      }
    }
    expect(missing, isEmpty, reason: 'untranslated keys render as the raw key on screen');
  });

  test('passwordRuleKey only ever returns a key this guard covers', () {
    final produced = <String?>{
      passwordRuleKey(null),
      passwordRuleKey(''),
      passwordRuleKey('abc'),
      passwordRuleKey('passw0rd!'),
      passwordRuleKey('PASSW0RD!'),
      passwordRuleKey('Password!'),
      passwordRuleKey('Passw0rdd'),
      passwordRuleKey('Passw0rd!'),
    }..remove(null);

    expect(
      produced.difference(ruleKeys.toSet()),
      isEmpty,
      reason: 'a new rule needs its key added to every locale and to this list',
    );
  });
}
