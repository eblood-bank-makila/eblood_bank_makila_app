import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:http_parser/http_parser.dart';
import '../../../apps/config/api/dio_client.dart';
import '../../../apps/models/api_response.dart';
import 'package:dio/dio.dart';

// Define endpoints for donor registration
class BloodDonorEndpoints {
  static const String register = '/eblood-connect/blood-donors/register';
  static const String photoUpload = '/eblood-connect/blood-donors/profil-photo-upload';
}

class BloodDonorApiService {
  BloodDonorApiService();
  
  // Method to register a new blood donor
  Future<IApiResponse> registerDonor(Map<String, dynamic> donorData) async {
    try {
      final response = await postWithDio(
        BloodDonorEndpoints.register,
        body: donorData,
      );
      
      return response;
    } catch (e) {
      debugPrint('Error registering donor: $e');
      return IApiResponse(
        success: false,
        message: 'Network error: $e',
      );
    }
  }
  
  // Method to upload a donor photo
  Future<IApiResponse> uploadDonorPhoto(String donorId, File photo) async {
    try {
      final fileName = path.basename(photo.path);
      final fileExtension = path.extension(fileName).toLowerCase();
      
      // Determine media type based on file extension
      String contentType;
      if (fileExtension == '.jpg' || fileExtension == '.jpeg') {
        contentType = 'image/jpeg';
      } else if (fileExtension == '.png') {
        contentType = 'image/png';
      } else {
        contentType = 'application/octet-stream';
      }
      
      // Create form data for photo upload
      final formData = FormData();
      
      // Add donor ID to form data
      formData.fields.add(MapEntry('donorId', donorId));
      
      // Add photo file
      formData.files.add(
        MapEntry(
          'photo',
          await MultipartFile.fromFile(
            photo.path,
            filename: fileName,
            contentType: MediaType.parse(contentType),
          ),
        ),
      );
      
      // Use a custom method for FormData upload since the standard postWithDio
      // might not support FormData directly
      try {
        // Create a separate custom call for FormData upload
        final response = await uploadFormData(
          BloodDonorEndpoints.photoUpload,
          formData
        );
        return response;
      } catch (e) {
        debugPrint('Photo upload failed: $e');
        return IApiResponse(
          success: false,
          message: 'Upload error: $e',
        );
      }
    } catch (e) {
      debugPrint('Error preparing photo upload: $e');
      return IApiResponse(
        success: false,
        message: 'Network error: $e',
      );
    }
  }
}

// Custom function for FormData uploads that leverages the existing token management
Future<IApiResponse> uploadFormData(String endpoint, FormData formData) async {
  try {
    // This will use the configured Dio instance with all interceptors
    final dio = await getDioInstance();
    
    final response = await dio.post(
      endpoint,
      data: formData,
    );
    
    if (response.statusCode == 200 || response.statusCode == 201) {
      return IApiResponse.fromData(response.data);
    } else {
      return IApiResponse(
        success: false,
        message: 'Failed with status: ${response.statusCode}',
        data: response.data,
      );
    }
  } catch (e) {
    return IApiResponse(
      success: false,
      message: 'Network error: $e',
    );
  }
}

// Helper method to get a configured Dio instance
Future<Dio> getDioInstance() async {
  // We can use the same function used in the dio_client.dart
  return _configureDio();
}

// Provider for the donor API service
final bloodDonorApiServiceProvider = Provider<BloodDonorApiService>((ref) {
  return BloodDonorApiService();
});