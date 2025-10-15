import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../business/service/BloodDonorApiService.dart';

// Model for donor data
class DonorData {
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String email;
  final String gender;
  final String bloodType;
  final String dateOfBirth;
  final String address;
  final String emergencyContactName;
  final String emergencyContactPhone;
  final File? photo;
  final bool createAccount;
  final String? username;
  final String? password;

  DonorData({
    required this.firstName,
    required this.lastName,
    required this.phoneNumber,
    required this.gender,
    required this.bloodType,
    required this.dateOfBirth,
    this.email = '',
    this.address = '',
    this.emergencyContactName = '',
    this.emergencyContactPhone = '',
    this.photo,
    this.createAccount = false,
    this.username,
    this.password,
  });

  // Convert to JSON for API submission
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'first_name': firstName,
      'last_name': lastName,
      'phone_number': phoneNumber,
      'gender': gender,
      'blood_type': bloodType,
      'date_of_birth': dateOfBirth,
    };

    if (email.isNotEmpty) {
      data['email'] = email;
    }
    
    if (address.isNotEmpty) {
      data['address'] = address;
    }
    
    if (emergencyContactName.isNotEmpty) {
      data['emergency_contact_name'] = emergencyContactName;
    }
    
    if (emergencyContactPhone.isNotEmpty) {
      data['emergency_contact_phone'] = emergencyContactPhone;
    }

    if (createAccount && username != null && password != null) {
      data['create_account'] = true;
      data['username'] = username;
      data['password'] = password;
    } else {
      data['create_account'] = false;
    }

    return data;
  }
}

// Controller for donor registration
class DonorRegistrationController extends StateNotifier<AsyncValue<void>> {
  DonorRegistrationController(this._apiService) : super(const AsyncValue.data(null));
  
  // Use the API service for requests
  final BloodDonorApiService _apiService;
  
  // Store the donor ID and code for access after registration
  String? _donorId;
  String? _donorCode;
  
  String get donorId => _donorId ?? 'N/A';
  String get donorCode => _donorCode ?? 'N/A';
  
  // Method to register a new donor
  Future<Map<String, dynamic>> registerDonor(DonorData donorData) async {
    try {
      state = const AsyncValue.loading();
      
      // Step 1: Register the donor and get donor details
      final donorDetails = await _registerDonorData(donorData);
      
      // Store the donor ID and code for later access
      _donorId = donorDetails['donor_id'];
      _donorCode = donorDetails['donor_code'];
      
      // Step 2: If donor registration was successful and we have a photo, upload it
      if (_donorId != null && donorData.photo != null) {
        await _uploadDonorPhoto(_donorId!, donorData.photo!);
      }
      
      state = const AsyncValue.data(null);
      return {
        'success': true, 
        'donorId': _donorId,
        'donorCode': _donorCode,
        'message': 'Inscription réussie! Le donneur a été enregistré avec succès.'
      };
    } catch (e, stackTrace) {
      // Update state to error and include the stack trace
      state = AsyncValue.error(e, stackTrace);
      
      // Format a user-friendly error message
      String errorMessage;
      if (e is Exception) {
        errorMessage = e.toString().replaceAll('Exception: ', '');
      } else {
        errorMessage = 'Une erreur inattendue est survenue. Veuillez réessayer.';
      }
      
      debugPrint('Registration error: $e');
      debugPrint('Stack trace: $stackTrace');
      
      return {
        'success': false,
        'message': 'Erreur lors de l\'inscription: $errorMessage'
      };
    }
  }
  
  // Step 1: Register donor data and return donor details
  Future<Map<String, String?>> _registerDonorData(DonorData donorData) async {
    try {
      // Convert donor data to JSON
      final jsonData = donorData.toJson();
      
      // Use the API service to register the donor
      final response = await _apiService.registerDonor(jsonData);
      
      if (response.success) {
        // Initialize donor details map
        Map<String, String?> donorDetails = {
          'donor_id': null,
          'donor_code': null,
        };
        
        debugPrint('API response data type: ${response.data.runtimeType}');
        
        // Handle different API response formats
        if (response.data is String) {
          // If the data is directly the donor ID string (old format)
          donorDetails['donor_id'] = response.data as String;
          donorDetails['donor_code'] = 'DC-${donorDetails['donor_id']?.substring(0, 8)}'; // Generate a code from ID
        } else if (response.data is Map) {
          // If the data is a map with donor_id and donor_code properties (new format)
          final dataMap = response.data as Map;
          
          // Check for different key formats the API might return
          if (dataMap.containsKey('donor_id')) {
            donorDetails['donor_id'] = dataMap['donor_id']?.toString();
          } else if (dataMap.containsKey('donorId')) {
            donorDetails['donor_id'] = dataMap['donorId']?.toString();
          }
          
          if (dataMap.containsKey('donor_code')) {
            donorDetails['donor_code'] = dataMap['donor_code']?.toString();
          } else if (dataMap.containsKey('donorCode')) {
            donorDetails['donor_code'] = dataMap['donorCode']?.toString();
          }
        }
        
        debugPrint('Extracted donor ID: ${donorDetails['donor_id']}');
        debugPrint('Extracted donor code: ${donorDetails['donor_code']}');
        
        return donorDetails;
      } else {
        // For real API failures, propagate the error with specific message
        final int statusCode = response.statusCode ?? 0;
        final String errorMsg = response.message ?? 'Failed to register donor';
        debugPrint('API error: $errorMsg (Status: $statusCode)');
        throw Exception(errorMsg);
      }
    } catch (e) {
      debugPrint('Error registering donor: $e');
      throw Exception('Failed to register donor: $e');
    }
  }
  
  // Step 2: Upload donor photo
  Future<void> _uploadDonorPhoto(String donorId, File photo) async {
    try {
      // Use the API service to upload the donor photo
      final response = await _apiService.uploadDonorPhoto(donorId, photo);
      
      if (response.success) {
        debugPrint('Photo uploaded successfully for donor $donorId');
      } else {
        final int statusCode = response.statusCode ?? 0;
        debugPrint('Photo upload failed: ${response.message} (Status: $statusCode)');
        // We don't throw here since registration was successful,
        // but we log the error for debugging purposes
      }
    } catch (e) {
      debugPrint('Error uploading donor photo: $e');
      // We don't want to throw an exception here since the registration was successful,
      // but we should log the error and possibly show a warning to the user
    }
  }
}

// Provider for donor registration
final donorRegistrationProvider = StateNotifierProvider<DonorRegistrationController, AsyncValue<void>>((ref) {
  final apiService = ref.watch(bloodDonorApiServiceProvider);
  return DonorRegistrationController(apiService);
});