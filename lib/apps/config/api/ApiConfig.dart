/// API configuration for the E-Blood Bank application
class ApiConfig {
  /// Get the base URL for API calls
  static String get BASE_URL {
    return 'https://api.eblood.com'; // Replace with your actual API URL
  }

  /// API endpoints for blood bank operations
  static const String bloodStock = '/blood-bank/stock';
  static const String bloodRequests = '/blood-bank/requests';
  static const String bloodBankStats = '/blood-bank/stats';
  static const String bloodTypeAvailability = '/blood-bank/availability';
  static const String expiringStock = '/blood-bank/stock/expiring';
  static const String lowStock = '/blood-bank/stock/low';
  static const String recentActivity = '/blood-bank/activity';

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
