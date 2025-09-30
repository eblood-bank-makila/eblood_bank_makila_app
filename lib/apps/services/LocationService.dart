import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/AppConfig.dart';
import '../models/SystemCountry.dart';
import '../services/HttpInterceptorService.dart';

class LocationService {
  final HttpInterceptorService _httpInterceptor = HttpInterceptorService();
  final String baseApiUrl = AppConfig.instance.baseApiUrl;

  Future<SystemCountryResponse> fetchLocationData() async {
    try {
      // Using the HTTP interceptor to get proper headers
      final headers = await _httpInterceptor.getHeaders();
      
      print('🔄 Fetching locations from: $baseApiUrl/system-countries/countries/fetch/registration-system-countries');
      print('🔑 Headers: $headers');
      
      final response = await http.get(
        Uri.parse('$baseApiUrl/system-countries/countries/fetch/registration-system-countries'),
        headers: headers,
      );
      
      print('📊 Response status code: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        print('📦 Response data received successfully');
        
        // Debug raw JSON structure
        print('RAW JSON DATA STRUCTURE:');
        final jsonString = const JsonEncoder.withIndent('  ').convert(jsonData);
        print(jsonString);
        
        // Parse response
        final result = SystemCountryResponse.fromJson(jsonData);
        
        // Debug parsed data
        print('PARSED DATA VALIDATION:');
        print('Countries: ${result.data.length}');
        for (var country in result.data) {
          print('Country: ${country.name} (${country.namedEntityFlag})');
          print('Children: ${country.children.length}');
          for (var child in country.children) {
            print('  - ${child.name} (${child.namedEntityFlag}): ${child.children.length} children');
          }
        }
        
        return result;
      } else {
        print('❌ Error response body: ${response.body}');
        throw Exception('Failed to load location data. Status code: ${response.statusCode}');
      }
    } catch (e) {
      print('⚠️ Error fetching location data: $e');
      throw Exception('Error fetching location data: $e');
    }
  }
}