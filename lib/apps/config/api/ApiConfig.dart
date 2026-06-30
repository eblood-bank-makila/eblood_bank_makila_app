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
  // Sprint 12 — migrated to the donor self-service module.
  static const String donorEligibility = '/blood-donors/eligibility';
  static const String inventorySettings = '/eblood/inventory/settings';

  // Blood requests endpoints
  // Blood Bank endpoint: for blood banks to see requests targeting them
  static const String bankBloodRequestsList = '/eblood-connect/blood-requests/list';
  // Hospital endpoint: for hospitals to see their own requests
  static const String hospitalBloodRequestsList = '/eblood-connect/blood-requests/hospital/list';

  // Hospital statistics (comprehensive stats including requests, inventory, patients, operations)
  // Note: hospital_id is derived from authenticated user's sys_organization_id
  static const String hospitalStatistics = '/eblood/hospitals/statistics';

  // Inventory
  static const String hospitalsList = '/eblood/hospitals/list';
  static const String patientsList = '/eblood/patients/list';
  static String hospitalInventoryStats(String hospitalId) => '/eblood/inventory/statistics/$hospitalId';
  static const String inventoryItemsList = '/eblood/inventory/items/list';
  static String inventoryItemUpdate(String itemId) => '/eblood/inventory/items/$itemId';
  static String inventoryItemTransfuse(String itemId) => '/eblood/inventory/items/$itemId/transfuse';

  // Deliveries
  static String deliveriesForHospitalDelivered(String hospitalId) => '/eblood/deliveries/delivered/$hospitalId';
  static String receiveDelivery(String deliveryId) => '/eblood/deliveries/$deliveryId/receive';

  // Delivery confirmation & blood bag operations
  static const String confirmDelivery = '/eblood-connect/blood-requests/confirm-delivery';
  static const String markBloodBagUsed = '/eblood-connect/blood-requests/blood-bags/mark-used';

  // E-wallet (per-profile: blood bank / CNTS). Backend scopes to the caller's org.
  static const String ewalletMyWallets = '/eblood-connect/ewallet/my-wallets';
  static const String ewalletHistory = '/eblood-connect/ewallet/history';
  static const String ewalletWithdraw = '/eblood-connect/ewallet/withdraw';
  static const String ewalletUpdateSettings = '/eblood-connect/ewallet/settings';

  // Sprint 17 — IoT coolbox access gate. The legacy URL was
  // /eblood-connect/blood-requests/deliveries/request-coolbox-password
  // and took only ops_delivery_id; the new endpoint requires the full
  // RBAC context (requester id, role, org_ids) plus the QR token from
  // the scan that triggered the request.
  static const String requestCoolboxPassword = '/coolbox/request-password';

  static String confirmDeliveryForRequest(String requestId) =>
      '$confirmDelivery?request_id=$requestId';
  static String markBloodBagUsedFor(String bloodBagId) =>
      '$markBloodBagUsed?blood_bag_id=$bloodBagId';

  // Users & Roles
  static const String usersList = '/users/fetch';
  static const String userSearch = '/users/search';
  static const String userCreate = '/organizations/add/users';
  static String userUpdate(String userId) => '/organizations/update/sys_user/$userId';
  static const String userDelete = '/organizations/hard-delete/user';
  static const String rolesList = '/cores/get-config-roles';

  // Request operations (blood bank legacy)
  static String approveRequest(String requestId) => '/blood-bank/requests/$requestId/approve';
  static String rejectRequest(String requestId) => '/blood-bank/requests/$requestId/reject';

  // Stock operations (blood bank legacy)
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
