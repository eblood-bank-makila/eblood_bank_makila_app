import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as path;
import 'package:eblood_bank_mak_app/core/rbac/models/rbac_models.dart';
import 'package:eblood_bank_mak_app/core/rbac/services/rbac_url_helper.dart';
import 'package:eblood_bank_mak_app/core/rbac/providers/rbac_provider.dart';
import '../../../apps/config/api/dio_client.dart';
import '../../../apps/models/api_response.dart';

class BloodDonorApiService {
  /// Donors list menu — fetch_url/main, create_processing_url/face_search_url
  final List<RbacCollectionCrudItem> _donorsCrudInfo;
  /// Donor register menu — create_processing_url/main, create_processing_url/upload_donor_photo_url
  final List<RbacCollectionCrudItem> _registerCrudInfo;
  /// Donor statistics menu — fetch_url/main
  final List<RbacCollectionCrudItem> _statsCrudInfo;
  final RbacUrlHelper _urlHelper = RbacUrlHelper();

  BloodDonorApiService({
    required List<RbacCollectionCrudItem> donorsCrudInfo,
    required List<RbacCollectionCrudItem> registerCrudInfo,
    required List<RbacCollectionCrudItem> statsCrudInfo,
  })  : _donorsCrudInfo = donorsCrudInfo,
        _registerCrudInfo = registerCrudInfo,
        _statsCrudInfo = statsCrudInfo;
  
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

      // Use uploadFile helper (includes device info, auth, location headers)
      final response = await uploadFile(
        path: photo.path,
        filename: fileName,
        endpoint: _urlHelper.getCreateProcessingUrl(_donorsCrudInfo, 'face_search_url'),
        fileFieldName: 'upload_file',
        extraData: {'metadata': jsonEncode(metadata ?? const {})},
        timeoutDuration: const Duration(seconds: 120),
      );

      debugPrint('Face search response - Success: ${response.success}, Status: ${response.statusCode}');
      return response;
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
  
  // Method to register a new blood donor
  Future<IApiResponse> registerDonor(Map<String, dynamic> donorData) async {
    try {
      // Convert gender from uppercase (M/F) to lowercase (m/f) as expected by the API
      if (donorData.containsKey('gender')) {
        final String gender = donorData['gender'];
        donorData['gender'] = _normalizeGender(gender); // Convert 'M' to 'm' and 'F' to 'f'
      }
      
      final response = await postWithDio(
        _urlHelper.getCreateProcessingUrl(_registerCrudInfo),
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
      debugPrint('Uploading photo: $fileName for donor: $donorId');
      
      // Use uploadFile helper (includes device info, auth, location headers)
      final response = await uploadFile(
        path: photo.path,
        filename: fileName,
        endpoint: _urlHelper.getCreateProcessingUrl(_registerCrudInfo, 'upload_donor_photo_url'),
        fileFieldName: 'upload_file',
        extraData: {'id': donorId},
        timeoutDuration: const Duration(seconds: 120),
      );
      
      debugPrint('Photo upload response - Success: ${response.success}, Status: ${response.statusCode}');
      debugPrint('Photo upload message: ${response.message}');
      
      if (!response.success) {
        debugPrint('Photo upload failed: ${response.message}');
      }
      
      return response;
    } catch (e) {
      debugPrint('Error uploading donor photo: $e');
      
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
        statusCode: 503,
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
        _urlHelper.getFetchUrl(_donorsCrudInfo),
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
      final response = await getWithDio(_urlHelper.getFetchUrl(_statsCrudInfo));
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
  List<RbacCollectionCrudItem> _resolve(String bbFlag, String cntsFlag) {
    final rbac = ref.read(rbacProvider.notifier);
    var info = rbac.getCrudInfoByPath(bbFlag);
    if (info.isEmpty) info = rbac.getCrudInfoByPath(cntsFlag);
    return info;
  }

  return BloodDonorApiService(
    donorsCrudInfo: _resolve(
      'flutter_apps_eblood_bank_bb_home_donors',
      'flutter_apps_eblood_bank_cnts_home_donors',
    ),
    registerCrudInfo: _resolve(
      'flutter_apps_eblood_bank_bb_donors_register',
      'flutter_apps_eblood_bank_cnts_donors_register',
    ),
    statsCrudInfo: _resolve(
      'flutter_apps_eblood_bank_bb_donors_statistics',
      'flutter_apps_eblood_bank_cnts_donors_statistics',
    ),
  );
});