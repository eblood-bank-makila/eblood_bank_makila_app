import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../network/dio_client.dart';
import '../models/system_country.dart';

class LocationService {
  final DioClient _dioClient = DioClient();

  // Get all countries
  Future<List<SystemCountry>> getCountries() async {
    try {
      final response = await _dioClient.get<Map<String, dynamic>>(
        AppConfig.countriesEndpoint,
      );

      if (response['data'] == null) {
        return [];
      }

      final List<dynamic> countriesData = response['data'] as List<dynamic>;
      return countriesData
          .map((countryData) => SystemCountry.fromJson(countryData))
          .toList();
    } on DioException catch (e) {
      _handleDioError('Failed to fetch countries', e);
      return [];
    } catch (e) {
      _handleGenericError('Failed to fetch countries', e);
      return [];
    }
  }

  // Get provinces by country ID
  Future<List<SystemProvince>> getProvincesByCountry(String countryId) async {
    try {
      final response = await _dioClient.get<Map<String, dynamic>>(
        '${AppConfig.provincesEndpoint}?country_id=$countryId',
      );

      if (response['data'] == null) {
        return [];
      }

      final List<dynamic> provincesData = response['data'] as List<dynamic>;
      return provincesData
          .map((provinceData) => SystemProvince.fromJson(provinceData))
          .toList();
    } on DioException catch (e) {
      _handleDioError('Failed to fetch provinces', e);
      return [];
    } catch (e) {
      _handleGenericError('Failed to fetch provinces', e);
      return [];
    }
  }

  // Get towns by province ID
  Future<List<SystemTown>> getTownsByProvince(String provinceId) async {
    try {
      final response = await _dioClient.get<Map<String, dynamic>>(
        '${AppConfig.townsEndpoint}?province_id=$provinceId',
      );

      if (response['data'] == null) {
        return [];
      }

      final List<dynamic> townsData = response['data'] as List<dynamic>;
      return townsData
          .map((townData) => SystemTown.fromJson(townData))
          .toList();
    } on DioException catch (e) {
      _handleDioError('Failed to fetch towns', e);
      return [];
    } catch (e) {
      _handleGenericError('Failed to fetch towns', e);
      return [];
    }
  }

  // Helper method for handling Dio errors
  void _handleDioError(String operation, DioException e) {
    String errorMessage = '$operation: ${e.message}';
    
    if (e.response != null) {
      errorMessage += ' - Status code: ${e.response?.statusCode}';
      
      // Handle specific status codes
      if (e.response?.statusCode == 204) {
        errorMessage = '$operation: No content available';
      } else if (e.response?.statusCode == 401) {
        errorMessage = '$operation: Authentication required';
      } else if (e.response?.statusCode == 403) {
        errorMessage = '$operation: Access forbidden';
      } else if (e.response?.statusCode == 404) {
        errorMessage = '$operation: Resource not found';
      } else if (e.response?.statusCode == 500) {
        errorMessage = '$operation: Server error';
      }
    } else if (e.error is SocketException) {
      errorMessage = '$operation: No internet connection';
    }
    
    if (kDebugMode) {
      print(errorMessage);
      if (e.response?.data != null) {
        print('Error response data: ${e.response?.data}');
      }
    }
  }

  // Helper method for handling generic errors
  void _handleGenericError(String operation, dynamic e) {
    if (kDebugMode) {
      print('$operation: ${e.toString()}');
    }
  }
}