import 'package:get_storage/get_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import '../config/AppConfig.dart';

class HttpInterceptorService {
  final AppConfig _appConfig = AppConfig.instance;
  final GetStorage _storage = GetStorage();

  /// Gets the API consumer key from environment variables
  String get apiConsumerKey => _appConfig.getEnvValue('API_CONSUMER');

  /// Gets the API consumer hash key from environment variables
  String get apiConsumerHashKey => _appConfig.getEnvValue('API_CONSUMER_HASH_KEY');

  /// Gets the current selected language or falls back to 'fr'
  String get currentLanguage => _storage.read('languageSignal') ?? Get.locale?.languageCode ?? 'fr';

  /// Gets the authentication token if available
  Future<String?> _getAuthToken() async {
    // Prefer fast local cache (GetStorage), fallback to secure storage
    final token = _storage.read('auth_token');
    if (token is String && token.isNotEmpty) return token;
    try {
      const secure = FlutterSecureStorage();
      final t = await secure.read(key: 'auth_token');
      return t;
    } catch (_) {
      return null;
    }
  }

  /// Creates headers for HTTP requests based on whether authentication is needed
  Future<Map<String, String>> getHeaders({bool requiresAuth = false}) async {
    print('🔧 HttpInterceptor: Creating headers (requiresAuth=$requiresAuth)');
    
    // Base headers that all requests should have
    final Map<String, String> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'api-consumer': apiConsumerKey,
      'accept-language': currentLanguage,
    };
    
    // Debug: Check API consumer key
    if (apiConsumerKey.isEmpty) {
      print('⚠️ HttpInterceptor: API consumer key is empty! Check your .env file.');
    } else {
      print('✅ HttpInterceptor: API consumer key is set');
    }

    // Add authentication token if required and available
    if (requiresAuth) {
      final token = await _getAuthToken();
      if (token != null && token.isNotEmpty) {
        headers['authorization'] = 'Bearer $token';
        print('✅ HttpInterceptor: Auth token added to headers');
      } else {
        print('⚠️ HttpInterceptor: Auth token requested but not available');
      }
    }
    
    print('🔄 HttpInterceptor: Final headers = ${headers.toString()}');
    return headers;
  }

  /// Log HTTP request details (for debugging)
  void logRequest(String method, String url, Map<String, String> headers, {dynamic body}) {
    if (_appConfig.isDebugMode) {
      print('📤 HTTP $method: $url');
      print('📤 Headers: $headers');
      if (body != null) {
        print('📤 Body: $body');
      }
    }
  }

  /// Log HTTP response details (for debugging)
  void logResponse(int statusCode, String body) {
    if (_appConfig.isDebugMode) {
      print('📥 Status Code: $statusCode');
      print('📥 Response: $body');
    }
  }
}