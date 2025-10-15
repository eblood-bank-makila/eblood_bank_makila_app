import 'package:flutter_dotenv/flutter_dotenv.dart';

/// API configuration for the E-Blood Bank application
class ApiConfig {
  /// Get the base URL for API calls from environment variables
  static String get BASE_URL {
    // Get base URL from .env file
    String baseUrl = dotenv.env['BASE_API_URL'] ?? '';
    
    // Log for debugging
    print('📡 API Config: Loading BASE_URL from .env: "$baseUrl"');
    
    // Provide fallback if environment variable is missing
    if (baseUrl.isEmpty) {
      const fallbackUrl = 'http://localhost:8000';
      print('⚠️ Warning: BASE_URL not found in .env file! Using fallback URL: $fallbackUrl');
      return fallbackUrl;
    }
    
    return baseUrl;
  }

  /// API endpoints for blood bank operations
  static const String bloodStock = '/eblood/inventory/items/list';
  static const String bloodStockCreate = '/eblood/inventory/items/create';
  static const String bloodRequests = '/eblood/requests';
  static const String bloodBankStats = '/eblood/stats/blood-inventory';
  static const String bloodTypeAvailability = '/eblood/availability';
  static const String expiringStock = '/eblood/stock/expiring';
  static const String lowStock = '/eblood/stock/low';
  static const String recentActivity = '/blood-bank/activity';
  static const String donorEligibility = '/eblood-connect/blood-donors/eligibility';
  static const String inventorySettings = '/eblood/inventory/settings';

  // Request operations
  static String approveRequest(String requestId) => '/blood-bank/requests/$requestId/approve';
  static String rejectRequest(String requestId) => '/blood-bank/requests/$requestId/reject';

  // Stock operations
  static String updateStock(String stockId) => '/blood-bank/stock/$stockId';
  static String deleteStock(String stockId) => '/blood-bank/stock/$stockId';

  /// HTTP headers for API requests
  static Map<String, String> get defaultHeaders {
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'User-Agent': 'E-Blood-Bank-Mobile/1.0.0',
    };
  }

  /// Get headers with authorization token
  static Map<String, String> getAuthHeaders(String token) {
    final headers = Map<String, String>.from(defaultHeaders);
    headers['Authorization'] = 'Bearer $token';
    return headers;
  }

  /// Build full URL for an endpoint
  static String buildUrl(String endpoint) {
    final baseUrl = BASE_URL;
    if (endpoint.startsWith('/')) {
      return '$baseUrl$endpoint';
    } else {
      return '$baseUrl/$endpoint';
    }
  }

  /// Build URL with query parameters
  static String buildUrlWithParams(String endpoint, Map<String, dynamic> params) {
    final baseUrl = buildUrl(endpoint);
    if (params.isEmpty) return baseUrl;

    final queryParams = params.entries
        .where((entry) => entry.value != null)
        .map((entry) => '${entry.key}=${Uri.encodeComponent(entry.value.toString())}')
        .join('&');

    return queryParams.isNotEmpty ? '$baseUrl?$queryParams' : baseUrl;
  }
}
