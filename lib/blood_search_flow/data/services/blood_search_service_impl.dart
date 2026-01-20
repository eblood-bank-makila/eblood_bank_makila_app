/// Blood Search Service Implementation
/// Connects to existing blood search API

import 'package:dio/dio.dart';
import '../../domain/services/service_interfaces.dart';
import '../../domain/entities/search_flow_state.dart';
import '../../../core/network/dio_client.dart';
import '../../../apps/config/AppConfig.dart';

class BloodSearchServiceImpl implements IBloodSearchService {
  late final Dio _dio;

  BloodSearchServiceImpl() {
    _dio = DioClient().dio;
  }

  @override
  Future<List<BloodSearchResult>> searchBlood({
    required String cityId,
    required String bloodType,
    String? authToken,
  }) async {
    try {
      // Build search key from blood type (e.g., "A+", "O-", "AB+")
      // The API expects a search_key parameter, not city_id/blood_type
      final searchKey = bloodType;
      
      print('🔍 Searching blood bags with search_key: $searchKey');
      
      final response = await _dio.get(
        '/eblood-connect/blood-bags/search-simple',
        queryParameters: {
          'search_key': searchKey,
          'page': 0,
          'limit': 50,
        },
        options: authToken != null
            ? Options(headers: {'Authorization': 'Bearer $authToken'})
            : null,
      );

      print('📡 Search API response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['data'] != null) {
          // Handle nested data structure - API returns {data: {data: [...], total: N}}
          final dataContent = data['data'];
          List<dynamic> results = [];
          
          if (dataContent is Map && dataContent['data'] is List) {
            results = dataContent['data'];
          } else if (dataContent is List) {
            results = dataContent;
          }
          
          print('📊 Found ${results.length} blood bags');
          
          return results.map((item) => BloodSearchResult.fromJson(item)).toList();
        }
      }
      return [];
    } catch (e) {
      print('❌ BloodSearchService error: $e');
      rethrow;
    }
  }
}
