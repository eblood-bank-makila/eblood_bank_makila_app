class UserInfoValidation {
  final String email;
  final String phoneNumber;
  final String validationType;

  UserInfoValidation({
    required this.email,
    required this.phoneNumber,
    required this.validationType,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'phone_number': phoneNumber,
    'validation_type': validationType,
  };

  factory UserInfoValidation.fromJson(Map<String, dynamic> json) => UserInfoValidation(
    email: json['email'] ?? '',
    phoneNumber: json['phone_number'] ?? '',
    validationType: json['validation_type'] ?? '',
  );
}

class UserValidationCodeVerification {
  final String email;
  final String phoneNumber;
  final String validationType;
  final String validationCode;
  final String validationKey;

  UserValidationCodeVerification({
    required this.email,
    required this.phoneNumber,
    required this.validationType,
    required this.validationCode,
    required this.validationKey,
  });

  Map<String, dynamic> toJson() => {
    'email': email,
    'phone_number': phoneNumber,
    'validation_type': validationType,
    'validation_code': validationCode,
    'validation_key': validationKey,
  };

  factory UserValidationCodeVerification.fromJson(Map<String, dynamic> json) => UserValidationCodeVerification(
    email: json['email'] ?? '',
    phoneNumber: json['phone_number'] ?? '',
    validationType: json['validation_type'] ?? '',
    validationCode: json['validation_code'] ?? '',
    validationKey: json['validation_key'] ?? '',
  );
}