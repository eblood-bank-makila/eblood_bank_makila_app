/// Mirrors backend enum app.modules.core.enums.type_enum.ERegistrationOrigin
/// and provides string values expected by the API.
enum ERegistrationOrigin {
  emailRegistration,
  phoneNumberRegistration,
  registration,
  google,
  facebook,
  twitter,
  github,
}

extension ERegistrationOriginX on ERegistrationOrigin {
  /// Backend string value
  String get value {
    switch (this) {
      case ERegistrationOrigin.emailRegistration:
        return 'email_registration';
      case ERegistrationOrigin.phoneNumberRegistration:
        return 'phone_number_registration';
      case ERegistrationOrigin.registration:
        return 'registration';
      case ERegistrationOrigin.google:
        return 'google';
      case ERegistrationOrigin.facebook:
        return 'facebook';
      case ERegistrationOrigin.twitter:
        return 'twitter';
      case ERegistrationOrigin.github:
        return 'github';
    }
  }
}

/// Map a UI verification/login mode to a registration origin.
/// Examples of [mode]: 'email', 'phone', 'google', 'facebook', 'twitter', 'github'
ERegistrationOrigin registrationOriginFromVerificationMode(String? mode) {
  final m = (mode ?? '').toLowerCase().trim();
  switch (m) {
    case 'phone':
    case 'sms':
    case 'otp':
      return ERegistrationOrigin.phoneNumberRegistration;
    case 'google':
      return ERegistrationOrigin.google;
    case 'facebook':
      return ERegistrationOrigin.facebook;
    case 'twitter':
      return ERegistrationOrigin.twitter;
    case 'github':
      return ERegistrationOrigin.github;
    case 'email':
    default:
      return ERegistrationOrigin.emailRegistration;
  }
}
