import 'dart:async';
import '../../../apps/config/api/dio_client.dart';
import '../../../apps/models/api_response.dart';

// Define endpoints for health structures
class HealthStructureEndpoints {
  static const String listByType = '/eblood/health-structures/list-by-type';
  static const String list = '/eblood/hospitals/list';
  static const String details = '/eblood/hospitals'; // + /{hospital_id}
  static const String register = '/eblood/health-structures/register';
  static const String update = '/eblood/hospitals'; // + /{hospital_id}
}

class HealthStructureApiService {
  HealthStructureApiService();
  
  /// Get health structures filtered by type flag (enum-based)
  /// 
  /// [healthStructureTypeFlag] - Filter by type: blood_bank, general_hospital, clinic, etc.
  /// [page] - Page number for pagination
  /// [limit] - Number of items per page
  /// [searchQuery] - Search query for name, address, or identifier
  /// [hasEmergencyServices] - Filter by emergency services
  /// [city] - Filter by city
  /// [state] - Filter by state
  /// [sortBy] - Sort field (name, created_at, etc.)
  /// [sortOrder] - Sort order (asc/desc)
  Future<IApiResponse> getHealthStructuresByType({
    String? healthStructureTypeFlag,
    int page = 0,
    int limit = 20,
    bool allData = false,
    String? searchQuery,
    bool? hasEmergencyServices,
    String? city,
    String? state,
    String sortBy = 'name',
    String sortOrder = 'asc',
  }) async {
    try {
      // Build query parameters
      Map<String, dynamic> queryParams = {
        'page': page,
        'limit': limit,
        'all_data': allData,
        'sort_by': sortBy,
        'sort_order': sortOrder,
      };
      
      if (healthStructureTypeFlag != null && healthStructureTypeFlag.isNotEmpty) {
        queryParams['health_structure_type_flag'] = healthStructureTypeFlag;
      }
      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParams['search_query'] = searchQuery;
      }
      if (hasEmergencyServices != null) {
        queryParams['has_emergency_services'] = hasEmergencyServices;
      }
      if (city != null && city.isNotEmpty) {
        queryParams['city'] = city;
      }
      if (state != null && state.isNotEmpty) {
        queryParams['state'] = state;
      }
      
      final response = await getWithDio(
        HealthStructureEndpoints.listByType,
        queryParams: queryParams,
      );

      return response;
    } catch (e) {
      return IApiResponse(
        success: false,
        message: 'Network error: $e',
      );
    }
  }
  
  /// Get all health structures (without type filter)
  Future<IApiResponse> getAllHealthStructures({
    int page = 0,
    int limit = 20,
    bool allData = false,
    String? searchQuery,
  }) async {
    try {
      Map<String, dynamic> queryParams = {
        'page': page,
        'limit': limit,
        'all_data': allData,
      };
      
      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParams['search_query'] = searchQuery;
      }
      
      final response = await getWithDio(
        HealthStructureEndpoints.list,
        queryParams: queryParams,
      );

      return response;
    } catch (e) {
      return IApiResponse(
        success: false,
        message: 'Network error: $e',
      );
    }
  }
  
  /// Get health structure details by ID
  Future<IApiResponse> getHealthStructureDetails({
    required String healthStructureId,
    bool includeStatistics = false,
  }) async {
    try {
      Map<String, dynamic> queryParams = {
        'include_statistics': includeStatistics,
      };
      
      final response = await getWithDio(
        '${HealthStructureEndpoints.details}/$healthStructureId',
        queryParams: queryParams,
      );

      return response;
    } catch (e) {
      return IApiResponse(
        success: false,
        message: 'Network error: $e',
      );
    }
  }
  
  /// Register a new health structure
  Future<IApiResponse> registerHealthStructure({
    required Map<String, dynamic> data,
  }) async {
    try {
      final response = await postWithDio(
        HealthStructureEndpoints.register,
        body: data,
      );

      return response;
    } catch (e) {
      return IApiResponse(
        success: false,
        message: 'Network error: $e',
      );
    }
  }
  
  /// Update health structure information
  Future<IApiResponse> updateHealthStructure({
    required String healthStructureId,
    required Map<String, dynamic> data,
  }) async {
    try {
      // Using POST for update since putWithDio is not available
      final response = await postWithDio(
        '${HealthStructureEndpoints.update}/$healthStructureId',
        body: data,
      );

      return response;
    } catch (e) {
      return IApiResponse(
        success: false,
        message: 'Network error: $e',
      );
    }
  }
}
