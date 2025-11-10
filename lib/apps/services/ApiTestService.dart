import 'package:http/http.dart' as http;
import '../config/AppConfig.dart';
import '../services/HttpInterceptorService.dart';

class ApiTestService {
  final HttpInterceptorService _httpInterceptor = HttpInterceptorService();
  
  /// Test API connection by making a request to fetch location data
  Future<void> testLocationApi() async {
    final baseApiUrl = AppConfig.instance.baseApiUrl;
    final headers = await _httpInterceptor.getHeaders();
    
    print('🔄 Testing API connection...');
    print('🔄 URL: $baseApiUrl/health');
    print('🔄 Headers: $headers');
    
    try {
      final response = await http.get(
        Uri.parse('$baseApiUrl/health'),
        headers: headers,
      );
      
      print('📊 Response Status: ${response.statusCode}');
      if (response.statusCode == 200) {
        print('✅ API connection successful');
        print('📦 Response Body (first 200 chars): ${response.body.substring(0, response.body.length > 200 ? 200 : response.body.length)}...');
      } else {
        print('❌ API connection failed with status code: ${response.statusCode}');
        print('📦 Response Body: ${response.body}');
      }
    } catch (e) {
      print('❌ API connection error: $e');
    }
  }
}