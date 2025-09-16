import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../apps/config/api/ApiConfig.dart';
import '../model/BloodStock.dart';

class BloodBankApiService {
  // Get authorization headers
  Future<Map<String, String>> _getHeaders() async {
    // For now, return default headers - will be updated with proper token management
    return ApiConfig.defaultHeaders;
  }

  // Blood Stock Management
  Future<ApiResponse<List<BloodStock>>> getBloodStock() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(ApiConfig.buildUrl(ApiConfig.bloodStock)),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<BloodStock> stocks = (data['data'] as List)
            .map((item) => BloodStock.fromJson(item))
            .toList();
        
        return ApiResponse.success(stocks);
      } else {
        return ApiResponse.error('Failed to load blood stock');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  Future<ApiResponse<BloodStock>> addBloodStock(BloodStock stock) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(ApiConfig.buildUrl(ApiConfig.bloodStock)),
        headers: headers,
        body: json.encode(stock.toJson()),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        final newStock = BloodStock.fromJson(data['data']);
        return ApiResponse.success(newStock);
      } else {
        return ApiResponse.error('Failed to add blood stock');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  Future<ApiResponse<BloodStock>> updateBloodStock(String id, BloodStock stock) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse(ApiConfig.buildUrl(ApiConfig.updateStock(id))),
        headers: headers,
        body: json.encode(stock.toJson()),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final updatedStock = BloodStock.fromJson(data['data']);
        return ApiResponse.success(updatedStock);
      } else {
        return ApiResponse.error('Failed to update blood stock');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  Future<ApiResponse<bool>> deleteBloodStock(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse(ApiConfig.buildUrl(ApiConfig.deleteStock(id))),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return ApiResponse.success(true);
      } else {
        return ApiResponse.error('Failed to delete blood stock');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  // Blood Requests Management
  Future<ApiResponse<List<BloodRequest>>> getBloodRequests() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(ApiConfig.buildUrl(ApiConfig.bloodRequests)),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<BloodRequest> requests = (data['data'] as List)
            .map((item) => BloodRequest.fromJson(item))
            .toList();
        
        return ApiResponse.success(requests);
      } else {
        return ApiResponse.error('Failed to load blood requests');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  Future<ApiResponse<BloodRequest>> approveBloodRequest(String requestId, String notes) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(ApiConfig.buildUrl(ApiConfig.approveRequest(requestId))),
        headers: headers,
        body: json.encode({
          'notes': notes,
          'approvedAt': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final approvedRequest = BloodRequest.fromJson(data['data']);
        return ApiResponse.success(approvedRequest);
      } else {
        return ApiResponse.error('Failed to approve request');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  Future<ApiResponse<BloodRequest>> rejectBloodRequest(String requestId, String reason) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(ApiConfig.buildUrl(ApiConfig.rejectRequest(requestId))),
        headers: headers,
        body: json.encode({
          'reason': reason,
          'rejectedAt': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rejectedRequest = BloodRequest.fromJson(data['data']);
        return ApiResponse.success(rejectedRequest);
      } else {
        return ApiResponse.error('Failed to reject request');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  // Statistics and Analytics
  Future<ApiResponse<BloodBankStats>> getBloodBankStats() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(ApiConfig.buildUrl(ApiConfig.bloodBankStats)),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final stats = BloodBankStats.fromJson(data['data']);
        return ApiResponse.success(stats);
      } else {
        return ApiResponse.error('Failed to load statistics');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  // Blood Type Availability
  Future<ApiResponse<Map<String, int>>> getBloodTypeAvailability() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(ApiConfig.buildUrl(ApiConfig.bloodTypeAvailability)),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final availability = Map<String, int>.from(data['data']);
        return ApiResponse.success(availability);
      } else {
        return ApiResponse.error('Failed to load availability');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  // Expiring Stock
  Future<ApiResponse<List<BloodStock>>> getExpiringStock({int days = 7}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(ApiConfig.buildUrlWithParams(ApiConfig.expiringStock, {'days': days})),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<BloodStock> expiringStock = (data['data'] as List)
            .map((item) => BloodStock.fromJson(item))
            .toList();
        
        return ApiResponse.success(expiringStock);
      } else {
        return ApiResponse.error('Failed to load expiring stock');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  // Low Stock Alert
  Future<ApiResponse<List<BloodStock>>> getLowStock({int threshold = 5}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(ApiConfig.buildUrlWithParams(ApiConfig.lowStock, {'threshold': threshold})),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<BloodStock> lowStock = (data['data'] as List)
            .map((item) => BloodStock.fromJson(item))
            .toList();
        
        return ApiResponse.success(lowStock);
      } else {
        return ApiResponse.error('Failed to load low stock');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  // Recent Activity
  Future<ApiResponse<List<BloodBankActivity>>> getRecentActivity({int limit = 10}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(ApiConfig.buildUrlWithParams(ApiConfig.recentActivity, {'limit': limit})),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<BloodBankActivity> activities = (data['data'] as List)
            .map((item) => BloodBankActivity.fromJson(item))
            .toList();
        
        return ApiResponse.success(activities);
      } else {
        return ApiResponse.error('Failed to load recent activity');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }
}

// Generic API Response wrapper
class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? error;

  ApiResponse._({
    required this.success,
    this.data,
    this.error,
  });

  factory ApiResponse.success(T data) {
    return ApiResponse._(success: true, data: data);
  }

  factory ApiResponse.error(String error) {
    return ApiResponse._(success: false, error: error);
  }
}

// Blood Bank Activity Model
class BloodBankActivity {
  final String id;
  final String type;
  final String title;
  final String description;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  BloodBankActivity({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.timestamp,
    this.metadata,
  });

  factory BloodBankActivity.fromJson(Map<String, dynamic> json) {
    return BloodBankActivity(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      timestamp: DateTime.parse(json['timestamp']),
      metadata: json['metadata'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
      'metadata': metadata,
    };
  }
}
