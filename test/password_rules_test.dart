import 'package:flutter_test/flutter_test.dart';

import 'package:eblood_bank_mak_app/apps/utils/password_rules.dart';

/// The API rejects weak passwords in BloodBankDonorRegistrationRequest:
/// at least 8 characters, and at least one uppercase, one lowercase, one
/// digit and one special character. The form used to check only the length,
/// so the user learned about the rest from a server round-trip.
void main() {
  group('passwordRuleKey', () {
    test('accepts a password that satisfies every server rule', () {
      expect(passwordRuleKey('Passw0rd!'), isNull);
    });

    test('requires a value', () {
      expect(passwordRuleKey(''), 'password_required');
      expect(passwordRuleKey(null), 'password_required');
    });

    test('requires at least 8 characters', () {
      expect(passwordRuleKey('Pa0!bc'), 'password_min_length');
    });

    test('requires an uppercase letter', () {
      expect(passwordRuleKey('passw0rd!'), 'password_needs_uppercase');
    });

    test('requires a lowercase letter', () {
      expect(passwordRuleKey('PASSW0RD!'), 'password_needs_lowercase');
    });

    test('requires a digit', () {
      expect(passwordRuleKey('Password!'), 'password_needs_digit');
    });

    test('requires a special character', () {
      expect(passwordRuleKey('Passw0rdd'), 'password_needs_special');
    });

    test('accepts each special character the API allows', () {
      for (final c in r'!@#$%^&*(),.?":{}|<>'.split('')) {
        expect(
          passwordRuleKey('Passw0rd$c'),
          isNull,
          reason: 'the API accepts "$c" as a special character',
        );
      }
    });

    test('reports the length rule before the character rules', () {
      // "abc" fails several rules at once; the shortest fix comes first.
      expect(passwordRuleKey('abc'), 'password_min_length');
    });
  });
}
