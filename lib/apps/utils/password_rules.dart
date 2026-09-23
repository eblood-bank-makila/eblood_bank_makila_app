/// Password rules, mirroring the API's own validator.
///
/// `BloodBankDonorRegistrationRequest.validate_password` (eblood_apps_api)
/// requires at least 8 characters and at least one uppercase letter, one
/// lowercase letter, one digit and one special character. Checking the same
/// rules here turns a server round-trip into an inline field error.
library;

/// The special characters the API accepts: `!@#$%^&*(),.?":{}|<>`
final RegExp _special = RegExp(r'[!@#$%^&*(),.?":{}|<>]');
final RegExp _uppercase = RegExp(r'[A-Z]');
final RegExp _lowercase = RegExp(r'[a-z]');
final RegExp _digit = RegExp(r'\d');

/// Returns the translation key of the first rule [value] breaks, or null when
/// it satisfies all of them.
///
/// Rules are reported in the order a user can act on them: length first, then
/// the missing character classes.
String? passwordRuleKey(String? value) {
  if (value == null || value.isEmpty) return 'password_required';
  if (value.length < 8) return 'password_min_length';
  if (!_uppercase.hasMatch(value)) return 'password_needs_uppercase';
  if (!_lowercase.hasMatch(value)) return 'password_needs_lowercase';
  if (!_digit.hasMatch(value)) return 'password_needs_digit';
  if (!_special.hasMatch(value)) return 'password_needs_special';
  return null;
}
