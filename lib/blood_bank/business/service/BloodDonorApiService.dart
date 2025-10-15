import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../apps/config/api/dio_client.dart';
import '../../../apps/models/api_response.dart';

// Define endpoints for donor operations
class BloodDonorEndpoints {
  static const String register = '/eblood-connect/blood-donors/register';
  static const String photoUpload = '/eblood-connect/blood-donors/profil-photo-upload';
  static const String list = '/eblood-connect/blood-donors/list';
  static const String faceSearch = '/eblood-connect/blood-donors/face-search';
  static const String statistics = '/eblood-connect/blood-donors/statistics';
}

class BloodDonorApiService {
  BloodDonorApiService();
  
  // Secure storage for retrieving auth token
  final _secureStorage = const FlutterSecureStorage();
  
  // Helper method to standardize gender format for API
  // Converts 'M' to 'm' and 'F' to 'f' as required by the API
  String _normalizeGender(String gender) {
    return gender.toLowerCase(); // API expects lowercase 'm' or 'f'
  }
  
  // Method to search donors by photo using multipart upload
  Future<IApiResponse> searchDonorsByPhoto({
    required File photo,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final fileName = path.basename(photo.path);

      debugPrint('Starting face search upload for file: $fileName');

      final dio = Dio();

      final fileExtension = path.extension(fileName).toLowerCase();
      String contentType = 'application/octet-stream';
      if (fileExtension == '.jpg' || fileExtension == '.jpeg') {
        contentType = 'image/jpeg';
      } else if (fileExtension == '.png') {
        contentType = 'image/png';
      }

      final formData = FormData.fromMap({
        'metadata': jsonEncode(metadata ?? const {}),
        'upload_file': await MultipartFile.fromFile(
          photo.path,
          filename: fileName,
          contentType: MediaType.parse(contentType),
        ),
      });

      final baseUrl = dotenv.env['BASE_API_URL'] ?? 'http://localhost';

      final dioResponse = await dio.post(
        '$baseUrl${BloodDonorEndpoints.faceSearch}',
        data: formData,
        options: Options(
          headers: {
            'Authorization': await _getAuthToken(),
            'api-consumer': dotenv.env['API_CONSUMER'] ?? '',
          },
          contentType: 'multipart/form-data',
        ),
      );

      debugPrint('Face search response status: ${dioResponse.statusCode}');

      return IApiResponse.fromData(dioResponse.data);
    } catch (e) {
      debugPrint('Error performing face search: $e');
      String errorMessage = 'Erreur lors de la recherche par photo';
      if (e is DioException) {
        if (e.response != null) {
          errorMessage += ' - Status: ${e.response?.statusCode}';
          if (e.response?.data != null) {
            errorMessage += ' - ${e.response?.data.toString()}';
          }
        } else {
          errorMessage += ' - ${e.type.toString()}: ${e.message}';
        }
      } else {
        errorMessage += ': $e';
      }

      return IApiResponse(
        success: false,
        message: errorMessage,
        statusCode: 503,
      );
    }
  }

  // Helper method to get the authentication token
  Future<String> _getAuthToken() async {
    try {
      final token = await _secureStorage.read(key: 'auth_token');
      return token != null ? 'Bearer $token' : '';
    } catch (e) {
      debugPrint('Error retrieving auth token: $e');
      return '';
    }
  }
  
  // Method to register a new blood donor
  Future<IApiResponse> registerDonor(Map<String, dynamic> donorData) async {
    try {
      // Convert gender from uppercase (M/F) to lowercase (m/f) as expected by the API
      if (donorData.containsKey('gender')) {
        final String gender = donorData['gender'];
        donorData['gender'] = _normalizeGender(gender); // Convert 'M' to 'm' and 'F' to 'f'
      }
      
      final response = await postWithDio(
        BloodDonorEndpoints.register,
        body: donorData,
      );
      
      // Enhanced logging for debugging
      debugPrint('Register donor response - Success: ${response.success}, Status: ${response.statusCode}');
      debugPrint('Response message: ${response.message}');
      debugPrint('Response data type: ${response.data?.runtimeType}');
      debugPrint('Response data: ${response.data}');
      
      if (!response.success) {
        debugPrint('Register donor failed: ${response.message}');
      }
      
      return response;
    } catch (e) {
      debugPrint('Error registering donor: $e');
      return IApiResponse(
        success: false,
        message: 'Erreur de connexion: $e',
        statusCode: 503, // Service unavailable
      );
    }
  }
  
  // Method to upload a donor photo
  Future<IApiResponse> uploadDonorPhoto(String donorId, File photo) async {
    try {
      final fileName = path.basename(photo.path);
      
      // Log photo information
      debugPrint('Uploading photo: $fileName for donor: $donorId');
      
      // Create a Dio instance for multipart upload
      final dio = Dio();
      
      // Determine content type based on file extension
      final fileExtension = path.extension(fileName).toLowerCase();
      String contentType = 'application/octet-stream';
      if (fileExtension == '.jpg' || fileExtension == '.jpeg') {
        contentType = 'image/jpeg';
      } else if (fileExtension == '.png') {
        contentType = 'image/png';
      }
      
      // Create FormData with the field names expected by the backend
      final formData = FormData();
      
      // Backend expects 'id' not 'donorId'
      formData.fields.add(MapEntry('id', donorId));
      
      // Add the file with field name 'upload_file' as required by the backend
      formData.files.add(
        MapEntry(
          'upload_file',
          await MultipartFile.fromFile(
            photo.path,
            filename: fileName,
            contentType: MediaType.parse(contentType),
          ),
        ),
      );
      
      // Get the base URL from the same place your other API calls use
      final baseUrl = dotenv.env['BASE_API_URL'] ?? 'http://localhost';
      
      // Send the request
      final dioResponse = await dio.post(
        '$baseUrl${BloodDonorEndpoints.photoUpload}',
        data: formData,
        options: Options(
          headers: {
            'Authorization': await _getAuthToken(),
            'api-consumer': dotenv.env['API_CONSUMER'] ?? '',
          },
          contentType: 'multipart/form-data',
        ),
      );
      
      debugPrint('Upload photo response: ${dioResponse.statusCode}');
      debugPrint('Upload photo response data: ${dioResponse.data}');
      
      // Convert response to IApiResponse format
      final response = IApiResponse.fromData(dioResponse.data);
      
      // Enhanced logging for debugging
      debugPrint('Photo upload response - Success: ${response.success}, Status: ${response.statusCode}');
      debugPrint('Photo upload message: ${response.message}');
      
      if (!response.success) {
        debugPrint('Photo upload failed: ${response.message}');
      }
      
      return response;
    } catch (e) {
      debugPrint('Error uploading donor photo: $e');
      
      // Provide a more detailed error message for debugging
      String errorMessage = 'Erreur lors du téléversement de la photo';
      if (e is DioException) {
        if (e.response != null) {
          errorMessage += ' - Status: ${e.response?.statusCode}';
          if (e.response?.data != null) {
            errorMessage += ' - ${e.response?.data.toString()}';
          }
        } else {
          errorMessage += ' - ${e.type.toString()}: ${e.message}';
        }
      } else {
        errorMessage += ': $e';
      }
      
      return IApiResponse(
        success: false,
        message: errorMessage,
        statusCode: 503, // Service unavailable
      );
    }
  }
  
  // Method to fetch blood donors list
  Future<IApiResponse> getDonorsList({
    String? searchQuery,
    String? searchType,
    String? gender,
    String? bloodType,
    int page = 0, // Start pagination from 0 instead of 1
    int size = 20,
  }) async {
    try {
      // Build query parameters based on provided filters
      final Map<String, dynamic> queryParams = {
        'page': page.toString(), // Pagination starts from 0
        'size': size.toString(),
      };
      
      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParams['query'] = searchQuery;
      }
      
      if (searchType != null && searchType.isNotEmpty) {
        queryParams['search_type'] = searchType;
      }
      
      if (gender != null && gender.isNotEmpty) {
        // API expects lowercase 'm' or 'f'
        queryParams['gender'] = _normalizeGender(gender);
      }
      
      // Only add bloodType parameter if it's not null and not empty
      // When bloodType is null or empty, it means "All" blood types should be returned
      if (bloodType != null && bloodType.isNotEmpty) {
        queryParams['blood_type'] = bloodType;
      }
      
      // Log the request
      debugPrint('Fetching donors with params: $queryParams');
      
      // Make API request
      final response = await getWithDio(
        BloodDonorEndpoints.list,
        queryParams: queryParams.isNotEmpty ? queryParams : null,
      );
      
      // Enhanced logging for debugging
      debugPrint('Get donors list response - Success: ${response.success}, Status: ${response.statusCode}');
      
      if (!response.success) {
        debugPrint('Get donors list failed: ${response.message}');
      } else {
        debugPrint('Response data type: ${response.data.runtimeType}');
        
        if (response.data is Map<String, dynamic>) {
          final map = response.data as Map<String, dynamic>;
          debugPrint('Response data keys: ${map.keys.toList()}');
          
          if (map.containsKey('data')) {
            final innerData = map['data'];
            debugPrint('Inner data type: ${innerData.runtimeType}');
            
            if (innerData is Map<String, dynamic>) {
              debugPrint('Inner data keys: ${innerData.keys.toList()}');
              
              if (innerData.containsKey('donors')) {
                final donors = innerData['donors'];
                debugPrint('Donors type: ${donors.runtimeType}');
                debugPrint('Donors count: ${donors is List ? donors.length : "Not a list"}');
                
                if (donors is List && donors.isNotEmpty) {
                  debugPrint('First donor keys: ${(donors.first as Map<String, dynamic>).keys.toList()}');
                }
              }
            }
          }
        } else if (response.data is List) {
          debugPrint('Donors count: ${(response.data as List).length}');
        }
      }
      
      return response;
    } catch (e) {
      debugPrint('Error fetching donors list: $e');
      return IApiResponse(
        success: false,
        message: 'Erreur lors de la récupération de la liste des donneurs: $e',
        statusCode: 503, // Service unavailable
      );
    }
  }

  Future<IApiResponse> getDonorStatistics() async {
    try {
      final response = await getWithDio(BloodDonorEndpoints.statistics);
      return response;
    } catch (e) {
      debugPrint('Error fetching donor statistics: $e');
      return IApiResponse(
        success: false,
        message: 'Erreur lors de la récupération des statistiques: $e',
        statusCode: 503,
      );
    }
  }
}

// Provider for the donor API service
final bloodDonorApiServiceProvider = Provider<BloodDonorApiService>((ref) {
  return BloodDonorApiService();
});