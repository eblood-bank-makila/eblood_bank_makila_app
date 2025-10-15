import 'package:flutter/foundation.dart';

class Donor {
  final String id;
  final String? donorCode;
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String? email;
  final String gender;
  final String bloodType;
  final String dateOfBirth;
  final String? address;
  final String? emergencyContactName;
  final String? emergencyContactPhone;
  final String? photoUrl;
  final String? lastDonationDate;
  final int? totalDonations;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Donor({
    required this.id,
    this.donorCode,
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    this.email,
    required this.gender,
    required this.bloodType,
    required this.dateOfBirth,
    this.address,
    this.emergencyContactName,
    this.emergencyContactPhone,
    this.photoUrl,
    this.lastDonationDate,
    this.totalDonations = 0,
    required this.createdAt,
    this.updatedAt,
  });

  // Full name convenience getter
  String get fullName => '$firstName $lastName';

  // Convert API response to Donor object
  factory Donor.fromJson(Map<String, dynamic> json) {
    try {
      debugPrint('Parsing donor JSON with keys: ${json.keys.toList()}');
      
      // Handle complex blood_type field which might be a string or an object
      String bloodTypeValue = '';
      if (json.containsKey('blood_type')) {
        final bloodType = json['blood_type'];
        if (bloodType is String) {
          bloodTypeValue = bloodType;
        } else if (bloodType is Map<String, dynamic>) {
          // Extract the name from the blood_type object
          bloodTypeValue = bloodType['name'] ?? '';
          debugPrint('Extracted blood type name: $bloodTypeValue');
        }
      } else if (json.containsKey('bloodType')) {
        bloodTypeValue = json['bloodType'] ?? '';
      }
      
      // Handle profile photo URL which might be in different formats
      String photoUrlValue = '';
      if (json.containsKey('photo_url')) {
        photoUrlValue = json['photo_url'] ?? '';
      } else if (json.containsKey('photoUrl')) {
        photoUrlValue = json['photoUrl'] ?? '';
      } else if (json.containsKey('profile_photo_url')) {
        photoUrlValue = json['profile_photo_url'] ?? '';
      }
      
      return Donor(
        id: json['id']?.toString() ?? '',
        donorCode: json['donor_code'] ?? json['donorCode'],
        firstName: json['first_name'] ?? json['firstName'] ?? '',
        lastName: json['last_name'] ?? json['lastName'] ?? '',
        phoneNumber: json['phone_number'] ?? json['phoneNumber'] ?? '',
        email: json['email'],
        gender: json['gender'] ?? '',
        bloodType: bloodTypeValue,
        dateOfBirth: json['date_of_birth'] ?? json['dateOfBirth'] ?? '',
        address: json['address'],
        emergencyContactName: json['emergency_contact_name'] ?? json['emergencyContactName'],
        emergencyContactPhone: json['emergency_contact_phone'] ?? json['emergencyContactPhone'],
        photoUrl: photoUrlValue,
        lastDonationDate: json['last_donation_date'] ?? json['lastDonationDate'],
        totalDonations: json['total_donations'] ?? json['totalDonations'] ?? 0,
        createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at'])
          : (json['createdAt'] != null 
            ? DateTime.parse(json['createdAt']) 
            : DateTime.now()),
        updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at'])
          : (json['updatedAt'] != null 
            ? DateTime.parse(json['updatedAt']) 
            : null),
      );
    } catch (e) {
      debugPrint('Error parsing donor data: $e');
      debugPrint('Problematic JSON: $json');
      rethrow;
    }
  }

  // Convert Donor object to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'donor_code': donorCode,
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phoneNumber,
      'email': email,
      'gender': gender,
      'blood_type': bloodType,
      'date_of_birth': dateOfBirth,
      'address': address,
      'emergency_contact_name': emergencyContactName,
      'emergency_contact_phone': emergencyContactPhone,
      'photo_url': photoUrl,
      'last_donation_date': lastDonationDate,
      'total_donations': totalDonations,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}