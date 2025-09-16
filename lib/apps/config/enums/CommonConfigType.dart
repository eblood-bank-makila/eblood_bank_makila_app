/// Common configuration types for different user profiles
enum ECommonConfigType {
  none('none'),
  personal('personal'),
  system('system'),
  bloodBank('blood_bank'),
  hospital('hospital'),
  deliveryPerson('delivery_person');

  const ECommonConfigType(this.value);
  final String value;

  /// Get display name in French
  String get displayName {
    switch (this) {
      case ECommonConfigType.bloodBank:
        return 'Banque de sang';
      case ECommonConfigType.hospital:
        return 'Hôpital';
      case ECommonConfigType.deliveryPerson:
        return 'Livreur';
      case ECommonConfigType.system:
        return 'System';
      case ECommonConfigType.personal:
        return 'Privé';
      case ECommonConfigType.none:
        return 'Non défini';
    }
  }

  /// Get icon for the account type
  String get iconName {
    switch (this) {
      case ECommonConfigType.bloodBank:
        return 'bloodtype';
      case ECommonConfigType.hospital:
        return 'hospital';
      case ECommonConfigType.deliveryPerson:
        return 'truck';
      case ECommonConfigType.system:
        return 'setting_2';
      case ECommonConfigType.personal:
        return 'user';
      case ECommonConfigType.none:
        return 'profile_circle';
    }
  }

  /// Get color for the account type
  int get colorValue {
    switch (this) {
      case ECommonConfigType.bloodBank:
        return 0xFFE53E3E; // Red
      case ECommonConfigType.hospital:
        return 0xFF38A169; // Green
      case ECommonConfigType.deliveryPerson:
        return 0xFF3182CE; // Blue
      case ECommonConfigType.system:
        return 0xFF805AD5; // Purple
      case ECommonConfigType.personal:
        return 0xFF718096; // Grey
      case ECommonConfigType.none:
        return 0xFF9CA3AF; // Light grey
    }
  }

  /// Create from string value
  static ECommonConfigType fromString(String value) {
    switch (value.toLowerCase()) {
      case 'blood_bank':
        return ECommonConfigType.bloodBank;
      case 'hospital':
        return ECommonConfigType.hospital;
      case 'delivery_person':
        return ECommonConfigType.deliveryPerson;
      case 'system':
        return ECommonConfigType.system;
      case 'personal':
        return ECommonConfigType.personal;
      case 'none':
      default:
        return ECommonConfigType.none;
    }
  }

  /// Check if this is a medical facility type
  bool get isMedicalFacility {
    return this == ECommonConfigType.bloodBank || this == ECommonConfigType.hospital;
  }

  /// Check if this is a service provider type
  bool get isServiceProvider {
    return this == ECommonConfigType.deliveryPerson;
  }

  /// Check if this is an administrative type
  bool get isAdministrative {
    return this == ECommonConfigType.system;
  }
}
