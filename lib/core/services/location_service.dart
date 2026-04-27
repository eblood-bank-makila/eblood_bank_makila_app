import 'package:flutter/foundation.dart';

import '../../apps/config/api/dio_client.dart';
import '../config/app_config.dart';
import '../models/system_country.dart';

class LocationService {
  // Get all countries
  Future<List<SystemCountry>> getCountries() async {
    try {
      final response = await getWithDio(AppConfig.countriesEndpoint);

      if (!response.success || response.data == null) {
        return [];
      }

      final List<dynamic> countriesData = response.data is List
          ? response.data as List<dynamic>
          : (response.data is Map && response.data['data'] != null)
              ? response.data['data'] as List<dynamic>
              : [];
      return countriesData
          .map((countryData) => SystemCountry.fromJson(countryData))
          .toList();
    } catch (e) {
      if (kDebugMode) print('Failed to fetch countries: $e');
      return [];
    }
  }

  // Get provinces by country ID
  Future<List<SystemProvince>> getProvincesByCountry(String countryId) async {
    try {
      final response = await getWithDio(
        AppConfig.provincesEndpoint,
        queryParams: {'country_id': countryId},
      );

      if (!response.success || response.data == null) {
        return [];
      }

      final List<dynamic> provincesData = response.data is List
          ? response.data as List<dynamic>
          : (response.data is Map && response.data['data'] != null)
              ? response.data['data'] as List<dynamic>
              : [];
      return provincesData
          .map((provinceData) => SystemProvince.fromJson(provinceData))
          .toList();
    } catch (e) {
      if (kDebugMode) print('Failed to fetch provinces: $e');
      return [];
    }
  }

  // Get towns by province ID
  Future<List<SystemTown>> getTownsByProvince(String provinceId) async {
    try {
      final response = await getWithDio(
        AppConfig.townsEndpoint,
        queryParams: {'province_id': provinceId},
      );

      if (!response.success || response.data == null) {
        return [];
      }

      final List<dynamic> townsData = response.data is List
          ? response.data as List<dynamic>
          : (response.data is Map && response.data['data'] != null)
              ? response.data['data'] as List<dynamic>
              : [];
      return townsData
          .map((townData) => SystemTown.fromJson(townData))
          .toList();
    } catch (e) {
      if (kDebugMode) print('Failed to fetch towns: $e');
      return [];
    }
  }
}