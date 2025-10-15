// Health Structure Type Enum matching backend EHealthStructureType
enum EHealthStructureType {
  bloodBank('blood_bank', 'Banque de Sang', 'Blood Bank'),
  generalHospital('general_hospital', 'Hôpital Général', 'General Hospital'),
  clinic('clinic', 'Clinique', 'Clinic'),
  pharmacy('pharmacy', 'Pharmacie', 'Pharmacy'),
  healthCenter('health_center', 'Centre de Santé', 'Health Center'),
  maternity('maternity', 'Maternité', 'Maternity'),
  medicalLab('medical_lab', 'Laboratoire Médical', 'Medical Lab'),
  rehabilitationCenter('rehabilitation_center', 'Centre de Réhabilitation', 'Rehabilitation Center'),
  healthCareCenter('health_care_center', 'Centre de Soins', 'Health Care Center'),
  mentalHealthCenter('mental_health_center', 'Centre de Santé Mentale', 'Mental Health Center'),
  retirementHome('retirement_home', 'Maison de Retraite', 'Retirement Home'),
  emergencyCenter('emergency_center', 'Centre d\'Urgence', 'Emergency Center'),
  universityHospital('university_hospital', 'Hôpital Universitaire', 'University Hospital'),
  privatePractice('private_practice', 'Cabinet Privé', 'Private Practice'),
  none('none', 'Non Spécifié', 'None');

  final String value;
  final String labelFr;
  final String labelEn;

  const EHealthStructureType(this.value, this.labelFr, this.labelEn);

  String get label => labelFr; // Default to French

  static EHealthStructureType fromString(String value) {
    return EHealthStructureType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => EHealthStructureType.none,
    );
  }
}

// Health Structure Model
class HealthStructureModel {
  final String id;
  final String identifier;
  final String name;
  final String? address;
  final String? email;
  final String? phoneNumber;
  final double? latitude;
  final double? longitude;
  final double? altitude;
  final bool isActivated;
  final bool isVerified;
  final bool hasEmergencyServices;
  final EHealthStructureType healthStructureTypeFlag;
  final String? refHealthStructureTypeId;
  final String? sysOrganizationId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<EmailInfo>? emails;
  final List<PhoneNumberInfo>? phoneNumbers;
  final ContactPersonInfo? contactPerson;

  HealthStructureModel({
    required this.id,
    required this.identifier,
    required this.name,
    this.address,
    this.email,
    this.phoneNumber,
    this.latitude,
    this.longitude,
    this.altitude,
    this.isActivated = true,
    this.isVerified = false,
    this.hasEmergencyServices = false,
    this.healthStructureTypeFlag = EHealthStructureType.none,
    this.refHealthStructureTypeId,
    this.sysOrganizationId,
    this.createdAt,
    this.updatedAt,
    this.emails,
    this.phoneNumbers,
    this.contactPerson,
  });

  factory HealthStructureModel.fromJson(Map<String, dynamic> json) {
    return HealthStructureModel(
      id: json['_id'] ?? json['id'] ?? '',
      identifier: json['identifier'] ?? '',
      name: json['name'] ?? '',
      address: json['address'],
      email: json['email'],
      phoneNumber: json['phone_number'],
      latitude: json['latitude'] != null ? (json['latitude'] as num).toDouble() : null,
      longitude: json['longitude'] != null ? (json['longitude'] as num).toDouble() : null,
      altitude: json['altitude'] != null ? (json['altitude'] as num).toDouble() : null,
      isActivated: json['is_activated'] ?? true,
      isVerified: json['is_verified'] ?? false,
      hasEmergencyServices: json['has_emergency_services'] ?? false,
      healthStructureTypeFlag: json['health_structure_type_flag'] != null
          ? EHealthStructureType.fromString(json['health_structure_type_flag'])
          : EHealthStructureType.none,
      refHealthStructureTypeId: json['ref_health_structure_type_id'],
      sysOrganizationId: json['sys_organization_id'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      emails: json['emails'] != null
          ? (json['emails'] as List).map((e) => EmailInfo.fromJson(e)).toList()
          : null,
      phoneNumbers: json['phone_numbers'] != null
          ? (json['phone_numbers'] as List).map((e) => PhoneNumberInfo.fromJson(e)).toList()
          : null,
      contactPerson: json['contact_person'] != null
          ? ContactPersonInfo.fromJson(json['contact_person'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'identifier': identifier,
      'name': name,
      'address': address,
      'email': email,
      'phone_number': phoneNumber,
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'is_activated': isActivated,
      'is_verified': isVerified,
      'has_emergency_services': hasEmergencyServices,
      'health_structure_type_flag': healthStructureTypeFlag.value,
      'ref_health_structure_type_id': refHealthStructureTypeId,
      'sys_organization_id': sysOrganizationId,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'emails': emails?.map((e) => e.toJson()).toList(),
      'phone_numbers': phoneNumbers?.map((e) => e.toJson()).toList(),
      'contact_person': contactPerson?.toJson(),
    };
  }

  // Calculate distance from current location
  double? distanceFrom(double targetLat, double targetLon) {
    if (latitude == null || longitude == null) return null;
    
    // Haversine formula
    const R = 6371; // Earth radius in km
    final dLat = _toRadians(targetLat - latitude!);
    final dLon = _toRadians(targetLon - longitude!);
    final a = 
      _sin(dLat / 2) * _sin(dLat / 2) +
      _cos(_toRadians(latitude!)) * _cos(_toRadians(targetLat)) *
      _sin(dLon / 2) * _sin(dLon / 2);
    final c = 2 * _atan2(_sqrt(a), _sqrt(1 - a));
    return R * c;
  }

  double _toRadians(double degrees) => degrees * 3.14159265359 / 180;
  double _sin(double x) => x; // Simplified for demo
  double _cos(double x) => 1; // Simplified for demo
  double _sqrt(double x) => x; // Simplified for demo
  double _atan2(double y, double x) => y / x; // Simplified for demo
}

// Supporting classes
class EmailInfo {
  final String email;
  final String? type;

  EmailInfo({required this.email, this.type});

  factory EmailInfo.fromJson(Map<String, dynamic> json) {
    return EmailInfo(
      email: json['email'] ?? '',
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'type': type,
    };
  }
}

class PhoneNumberInfo {
  final String phoneNumber;
  final String? type;

  PhoneNumberInfo({required this.phoneNumber, this.type});

  factory PhoneNumberInfo.fromJson(Map<String, dynamic> json) {
    return PhoneNumberInfo(
      phoneNumber: json['phone_number'] ?? json['phoneNumber'] ?? '',
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phone_number': phoneNumber,
      'type': type,
    };
  }
}

class ContactPersonInfo {
  final String? name;
  final String? email;
  final String? phoneNumber;
  final String? position;

  ContactPersonInfo({
    this.name,
    this.email,
    this.phoneNumber,
    this.position,
  });

  factory ContactPersonInfo.fromJson(Map<String, dynamic> json) {
    return ContactPersonInfo(
      name: json['name'],
      email: json['email'],
      phoneNumber: json['phone_number'] ?? json['phoneNumber'],
      position: json['position'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'email': email,
      'phone_number': phoneNumber,
      'position': position,
    };
  }
}
