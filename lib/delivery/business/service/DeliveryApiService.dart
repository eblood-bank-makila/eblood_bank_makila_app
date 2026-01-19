import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../apps/config/api/ApiConfig.dart';
import '../model/DeliveryModels.dart';

class DeliveryApiService {
  // Get authorization headers
  Future<Map<String, String>> _getHeaders() async {
    // For now, return default headers - will be updated with proper token management
    return ApiConfig.defaultHeaders;
  }

  // Delivery Management
  Future<ApiResponse<List<Delivery>>> getDeliveries() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(ApiConfig.buildUrl('/delivery/deliveries')),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<Delivery> deliveries = (data['data'] as List)
            .map((item) => Delivery.fromJson(item))
            .toList();
        
        return ApiResponse.success(deliveries);
      } else {
        return ApiResponse.error('Failed to load deliveries');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  Future<ApiResponse<List<Delivery>>> getInProgressDeliveries() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(ApiConfig.buildUrlWithParams('/delivery/deliveries', {'status': 'inProgress'})),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<Delivery> deliveries = (data['data'] as List)
            .map((item) => Delivery.fromJson(item))
            .toList();
        
        return ApiResponse.success(deliveries);
      } else {
        return ApiResponse.error('Failed to load in-progress deliveries');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  Future<ApiResponse<List<Delivery>>> getDeliveredDeliveries() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(ApiConfig.buildUrlWithParams('/delivery/deliveries', {'status': 'delivered'})),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<Delivery> deliveries = (data['data'] as List)
            .map((item) => Delivery.fromJson(item))
            .toList();
        
        return ApiResponse.success(deliveries);
      } else {
        return ApiResponse.error('Failed to load delivered deliveries');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  Future<ApiResponse<Delivery>> getDelivery(String deliveryId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(ApiConfig.buildUrl('/delivery/deliveries/$deliveryId')),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final delivery = Delivery.fromJson(data['data']);
        return ApiResponse.success(delivery);
      } else {
        return ApiResponse.error('Failed to load delivery details');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  Future<ApiResponse<Delivery>> updateDeliveryStatus(String deliveryId, DeliveryStatus status, {String? notes}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse(ApiConfig.buildUrl('/delivery/deliveries/$deliveryId/status')),
        headers: headers,
        body: json.encode({
          'status': status.name,
          'notes': notes,
          'updatedAt': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final updatedDelivery = Delivery.fromJson(data['data']);
        return ApiResponse.success(updatedDelivery);
      } else {
        return ApiResponse.error('Failed to update delivery status');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  Future<ApiResponse<Delivery>> startDelivery(String deliveryId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(ApiConfig.buildUrl('/delivery/deliveries/$deliveryId/start')),
        headers: headers,
        body: json.encode({
          'pickupDate': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final updatedDelivery = Delivery.fromJson(data['data']);
        return ApiResponse.success(updatedDelivery);
      } else {
        return ApiResponse.error('Failed to start delivery');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  Future<ApiResponse<Delivery>> completeDelivery(String deliveryId, {String? notes}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(ApiConfig.buildUrl('/delivery/deliveries/$deliveryId/complete')),
        headers: headers,
        body: json.encode({
          'deliveredDate': DateTime.now().toIso8601String(),
          'deliveryNotes': notes,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final completedDelivery = Delivery.fromJson(data['data']);
        return ApiResponse.success(completedDelivery);
      } else {
        return ApiResponse.error('Failed to complete delivery');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  // Statistics and Analytics
  Future<ApiResponse<DeliveryStats>> getDeliveryStats() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(ApiConfig.buildUrl('/delivery/stats')),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final stats = DeliveryStats.fromJson(data['data']);
        return ApiResponse.success(stats);
      } else {
        return ApiResponse.error('Failed to load delivery statistics');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  // Recent Activity
  Future<ApiResponse<List<DeliveryActivity>>> getRecentActivity({int limit = 10}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(ApiConfig.buildUrlWithParams('/delivery/activity', {'limit': limit})),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<DeliveryActivity> activities = (data['data'] as List)
            .map((item) => DeliveryActivity.fromJson(item))
            .toList();
        
        return ApiResponse.success(activities);
      } else {
        return ApiResponse.error('Failed to load recent activity');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  // Location Updates
  Future<ApiResponse<bool>> updateDeliveryLocation(String deliveryId, double latitude, double longitude) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse(ApiConfig.buildUrl('/delivery/deliveries/$deliveryId/location')),
        headers: headers,
        body: json.encode({
          'latitude': latitude,
          'longitude': longitude,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        return ApiResponse.success(true);
      } else {
        return ApiResponse.error('Failed to update location');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  // Emergency Actions
  Future<ApiResponse<bool>> reportEmergency(String deliveryId, String reason) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(ApiConfig.buildUrl('/delivery/deliveries/$deliveryId/emergency')),
        headers: headers,
        body: json.encode({
          'reason': reason,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );

      if (response.statusCode == 200) {
        return ApiResponse.success(true);
      } else {
        return ApiResponse.error('Failed to report emergency');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  // ============================================================================
  // DELIVERY ASSIGNMENT API (Yango-style)
  // ============================================================================

  /// Get pending delivery requests for a delivery person
  Future<ApiResponse<List<PendingDeliveryRequest>>> getPendingDeliveryRequests(String deliveryPersonId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(ApiConfig.buildUrlWithParams(
          '/eblood-connect/delivery-assignment/pending-requests',
          {'delivery_person_id': deliveryPersonId},
        )),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<PendingDeliveryRequest> requests = (data['data'] as List?)
            ?.map((item) => PendingDeliveryRequest.fromJson(item))
            .toList() ?? [];

        return ApiResponse.success(requests);
      } else {
        return ApiResponse.error('Failed to load pending delivery requests');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  /// Get active delivery for a delivery person
  Future<ApiResponse<ActiveDelivery?>> getActiveDelivery(String deliveryPersonId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(ApiConfig.buildUrlWithParams(
          '/eblood-connect/delivery-assignment/active-delivery',
          {'delivery_person_id': deliveryPersonId},
        )),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['data'] != null) {
          return ApiResponse.success(ActiveDelivery.fromJson(data['data']));
        }
        return ApiResponse.success(null);
      } else {
        return ApiResponse.error('Failed to load active delivery');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  /// Accept a delivery request
  Future<ApiResponse<bool>> acceptDeliveryRequest(String deliveryId, String deliveryPersonId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(ApiConfig.buildUrl('/eblood-connect/delivery-assignment/$deliveryId/accept')),
        headers: headers,
        body: json.encode({
          'delivery_person_id': deliveryPersonId,
        }),
      );

      if (response.statusCode == 200) {
        return ApiResponse.success(true);
      } else {
        final data = json.decode(response.body);
        return ApiResponse.error(data['detail'] ?? 'Failed to accept delivery');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  /// Reject a delivery request
  Future<ApiResponse<bool>> rejectDeliveryRequest(String deliveryId, String deliveryPersonId, {String? reason}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(ApiConfig.buildUrl('/eblood-connect/delivery-assignment/$deliveryId/reject')),
        headers: headers,
        body: json.encode({
          'delivery_person_id': deliveryPersonId,
          'reason': reason,
        }),
      );

      if (response.statusCode == 200) {
        return ApiResponse.success(true);
      } else {
        return ApiResponse.error('Failed to reject delivery');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  /// Update delivery phase
  Future<ApiResponse<bool>> updateDeliveryPhase(String deliveryId, String deliveryPersonId, String phase, {LocationInfo? location}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse(ApiConfig.buildUrl('/eblood-connect/delivery-assignment/$deliveryId/phase')),
        headers: headers,
        body: json.encode({
          'delivery_person_id': deliveryPersonId,
          'phase': phase,
          if (location != null) 'location': location.toJson(),
        }),
      );

      if (response.statusCode == 200) {
        return ApiResponse.success(true);
      } else {
        return ApiResponse.error('Failed to update delivery phase');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  /// Update delivery person location
  Future<ApiResponse<bool>> updateDeliveryPersonLocation(String deliveryPersonId, double lat, double lng, {double? accuracy}) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse(ApiConfig.buildUrlWithParams(
          '/eblood-connect/delivery-assignment/update-location',
          {'delivery_person_id': deliveryPersonId},
        )),
        headers: headers,
        body: json.encode({
          'lat': lat,
          'lng': lng,
          if (accuracy != null) 'accuracy': accuracy,
        }),
      );

      if (response.statusCode == 200) {
        return ApiResponse.success(true);
      } else {
        return ApiResponse.error('Failed to update location');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  /// Get delivery tracking info (for hospital)
  Future<ApiResponse<Map<String, dynamic>>> getDeliveryTracking(String deliveryId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(ApiConfig.buildUrl('/eblood-connect/delivery-assignment/$deliveryId/tracking')),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return ApiResponse.success(data['data'] as Map<String, dynamic>);
      } else {
        return ApiResponse.error('Failed to load tracking info');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  /// Confirm delivery receipt (hospital)
  Future<ApiResponse<bool>> confirmDeliveryReceipt(String deliveryId, String hospitalUserId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse(ApiConfig.buildUrl('/eblood-connect/delivery-assignment/$deliveryId/confirm')),
        headers: headers,
        body: json.encode({
          'hospital_user_id': hospitalUserId,
        }),
      );

      if (response.statusCode == 200) {
        return ApiResponse.success(true);
      } else {
        return ApiResponse.error('Failed to confirm delivery');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  /// Get incoming deliveries for hospital (returns ActiveDelivery)
  Future<ApiResponse<List<ActiveDelivery>>> getIncomingDeliveries(String hospitalId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(ApiConfig.buildUrlWithParams(
          '/eblood-connect/delivery-assignment/incoming-deliveries',
          {'hospital_id': hospitalId},
        )),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<ActiveDelivery> deliveries = (data['data'] as List?)
            ?.map((item) => ActiveDelivery.fromJson(item))
            .toList() ?? [];

        return ApiResponse.success(deliveries);
      } else {
        return ApiResponse.error('Failed to load incoming deliveries');
      }
    } catch (e) {
      return ApiResponse.error('Network error: $e');
    }
  }

  /// Get incoming deliveries for hospital (returns IncomingDelivery)
  Future<ApiResponse<List<IncomingDelivery>>> getIncomingDeliveriesForHospital(String hospitalId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse(ApiConfig.buildUrlWithParams(
          '/eblood-connect/delivery-assignment/incoming-deliveries',
          {'hospital_id': hospitalId},
        )),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<IncomingDelivery> deliveries = (data['data'] as List?)
            ?.map((item) => IncomingDelivery.fromJson(item))
            .toList() ?? [];

        return ApiResponse.success(deliveries);
      } else {
        return ApiResponse.error('Failed to load incoming deliveries');
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
