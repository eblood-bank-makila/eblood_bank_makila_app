/// Blood Search Service Implementation
/// Connects to existing blood search API

import '../../domain/services/service_interfaces.dart';
import '../../domain/entities/search_flow_state.dart';
import '../../../apps/config/api/dio_client.dart';

class BloodSearchServiceImpl implements IBloodSearchService {
  BloodSearchServiceImpl();

  @override
  Future<List<BloodSearchResult>> searchBlood({
    required String cityId,
    required String bloodType,
    String? authToken,
    double? userLatitude,
    double? userLongitude,
    double? hospitalLatitude,
    double? hospitalLongitude,
  }) async {
    try {
      // Build search key from blood type (e.g., "A+", "O-", "AB+")
      // The API expects a search_key parameter, not city_id/blood_type
      final searchKey = bloodType;
      
      print('🔍 Searching blood bags with search_key: $searchKey');
      
      final queryParams = <String, dynamic>{
        'search_key': searchKey,
        'page': 0,
        'limit': 50,
      };

      // Add coordinate params if available
      if (userLatitude != null && userLongitude != null) {
        queryParams['user_latitude'] = userLatitude;
        queryParams['user_longitude'] = userLongitude;
      }
      if (hospitalLatitude != null && hospitalLongitude != null) {
        queryParams['hospital_latitude'] = hospitalLatitude;
        queryParams['hospital_longitude'] = hospitalLongitude;
      }

      final response = await getWithDio(
        '/eblood-connect/blood-bags/search-simple',
        queryParams: queryParams,
      );

      print('📡 Search API response success: ${response.success}');

      if (response.success && response.data != null) {
        // Handle nested data structure - API returns {data: [...], total: N}
        final dataContent = response.data;
        List<dynamic> results = [];
        
        if (dataContent is Map && dataContent['data'] is List) {
          results = dataContent['data'];
        } else if (dataContent is List) {
          results = dataContent;
        }
        
        print('📊 Found ${results.length} blood bags');
        
        return results.map((item) => BloodSearchResult.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print('❌ BloodSearchService error: $e');
      rethrow;
    }
  }
}
