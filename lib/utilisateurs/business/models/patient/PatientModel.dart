import 'dart:convert';

class PatientDemographics {
  final String firstName;
  final String lastName;
  final String? middleName;
  final String dateOfBirth; // ISO yyyy-mm-dd
  final String gender; // EGender value from backend
  final String? bloodType; // EBloodType string like A+, O-, etc.

  PatientDemographics({
    required this.firstName,
    required this.lastName,
    this.middleName,
    required this.dateOfBirth,
    required this.gender,
    this.bloodType,
  });

  factory PatientDemographics.fromJson(Map<String, dynamic> json) {
    return PatientDemographics(
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      middleName: json['middle_name']?.toString(),
      dateOfBirth: json['date_of_birth']?.toString() ?? '',
      gender: json['gender']?.toString() ?? '',
      bloodType: json['blood_type']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      if (middleName != null && middleName!.isNotEmpty) 'middle_name': middleName,
      'date_of_birth': dateOfBirth,
      'gender': gender,
      if (bloodType != null && bloodType!.isNotEmpty) 'blood_type': bloodType,
    };
  }
}

class PatientContact {
  final String? phonePrimary;
  final String? phoneSecondary;
  final String? email;
  final String? addressLine1;
  final String? addressLine2;
  final String? city;
  final String? stateProvince;

  PatientContact({
    this.phonePrimary,
    this.phoneSecondary,
    this.email,
    this.addressLine1,
    this.addressLine2,
    this.city,
    this.stateProvince,
  });

  factory PatientContact.fromJson(Map<String, dynamic>? json) {
    if (json == null) return PatientContact();
    return PatientContact(
      phonePrimary: json['phone_primary']?.toString(),
      phoneSecondary: json['phone_secondary']?.toString(),
      email: json['email']?.toString(),
      addressLine1: json['address_line1']?.toString(),
      addressLine2: json['address_line2']?.toString(),
      city: json['city']?.toString(),
      stateProvince: json['state_province']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (phonePrimary != null && phonePrimary!.isNotEmpty) 'phone_primary': phonePrimary,
      if (phoneSecondary != null && phoneSecondary!.isNotEmpty) 'phone_secondary': phoneSecondary,
      if (email != null && email!.isNotEmpty) 'email': email,
      if (addressLine1 != null && addressLine1!.isNotEmpty) 'address_line1': addressLine1,
      if (addressLine2 != null && addressLine2!.isNotEmpty) 'address_line2': addressLine2,
      if (city != null && city!.isNotEmpty) 'city': city,
      if (stateProvince != null && stateProvince!.isNotEmpty) 'state_province': stateProvince,
    };
  }
}

class PatientModel {
  final String? id; // backend returns 'id' in OutputDataType.DEFAULT
  final String hospitalId;
  final PatientDemographics demographics;
  final PatientContact contact;
  final String? medicalRecordNumber;
  final String? status; // EPatientStatus value
  final String? category; // EPatientCategory value

  PatientModel({
    required this.id,
    required this.hospitalId,
    required this.demographics,
    required this.contact,
    this.medicalRecordNumber,
    this.status,
    this.category,
  });

  factory PatientModel.fromJson(Map<String, dynamic> json) {
    // Data shape can be flat or nested in some responses; try best-effort extraction
    final demographicsJson = json['demographics'] as Map<String, dynamic>? ?? json;
    final contactJson = json['contact'] as Map<String, dynamic>? ?? json['contact_information'] as Map<String, dynamic>?;

    return PatientModel(
      id: json['id']?.toString() ?? json['_id']?.toString(),
      hospitalId: json['hospital_id']?.toString() ?? '',
      demographics: PatientDemographics.fromJson(demographicsJson),
      contact: PatientContact.fromJson(contactJson),
      medicalRecordNumber: json['medical_record_number']?.toString(),
      status: json['status']?.toString(),
      category: json['category']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {

      'demographics': demographics.toJson(),
      'contact': contact.toJson(),
      if (medicalRecordNumber != null && medicalRecordNumber!.isNotEmpty) 'medical_record_number': medicalRecordNumber,
      if (status != null && status!.isNotEmpty) 'status': status,
      if (category != null && category!.isNotEmpty) 'category': category,
    };
  }

  static List<PatientModel> listFromResponse(dynamic data) {
    if (data is List) {
      return data
          .whereType<Map<String, dynamic>>()
          .map(PatientModel.fromJson)
          .toList();
    }
    if (data is Map<String, dynamic> && data['patients'] is List) {
      return (data['patients'] as List)
          .whereType<Map<String, dynamic>>()
          .map(PatientModel.fromJson)
          .toList();
    }
    return const <PatientModel>[];
  }

  @override
  String toString() => jsonEncode(toJson());
}

