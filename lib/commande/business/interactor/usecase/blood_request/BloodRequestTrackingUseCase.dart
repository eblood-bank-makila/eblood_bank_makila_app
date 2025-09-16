import 'dart:convert';
import 'dart:math';
import 'package:http/http.dart' as http;
import '../../../model/blood_request/BloodRequestModel.dart';

class BloodRequestTrackingUseCase {
  static const String baseUrl = 'http://10.37.3.43:3101'; // Your API base URL
  
  /// Parse action_data to extract tracking information
  static BloodRequestTrackingInfo? parseActionData(String? actionData) {
    if (actionData == null || actionData.isEmpty) {
      return null;
    }
    
    // Parse format: "eblood___request___6716aa7d1eeea2ebade97c18___6716aafd1eeea2ebade97c33"
    final parts = actionData.split('___');
    if (parts.length >= 4) {
      return BloodRequestTrackingInfo(
        platform: parts[0], // "eblood"
        type: parts[1], // "request"
        requestId: parts[2], // "6716aa7d1eeea2ebade97c18"
        deliveryId: parts[3], // "6716aafd1eeea2ebade97c33"
        rawActionData: actionData,
      );
    }
    
    return null;
  }
  
  /// Check if a blood request can be tracked (has action_data and is in delivery)
  static bool canTrackDelivery(BloodRequestModel request) {
    return request.actionData != null && 
           request.actionData!.isNotEmpty &&
           (request.status == BloodRequestStatus.inProgressDelivery ||
            request.status == BloodRequestStatus.pendingDelivery);
  }
  
  /// Fetch GPS position for a delivery using action_data
  static Future<DeliveryGpsPosition?> fetchDeliveryGpsPosition(String actionData) async {
    try {
      final trackingInfo = parseActionData(actionData);
      if (trackingInfo == null) {
        print('❌ Invalid action_data format: $actionData');
        return null;
      }
      
      // Construct GPS tracking endpoint
      final url = '$baseUrl/api/delivery/gps/${trackingInfo.deliveryId}';
      print('🌍 Fetching GPS position from: $url');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data['success'] == true && data['position'] != null) {
          final position = data['position'];
          return DeliveryGpsPosition(
            latitude: double.tryParse(position['latitude']?.toString() ?? '0') ?? 0.0,
            longitude: double.tryParse(position['longitude']?.toString() ?? '0') ?? 0.0,
            altitude: double.tryParse(position['altitude']?.toString() ?? '0') ?? 0.0,
            timestamp: DateTime.tryParse(position['timestamp'] ?? '') ?? DateTime.now(),
            deliveryId: trackingInfo.deliveryId,
            status: position['status'] ?? 'unknown',
          );
        }
      } else {
        print('❌ GPS fetch failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('❌ Error fetching GPS position: $e');
    }
    
    return null;
  }
  
  /// Get delivery status with GPS tracking
  static Future<DeliveryTrackingStatus> getDeliveryTrackingStatus(BloodRequestModel request) async {
    if (!canTrackDelivery(request)) {
      return DeliveryTrackingStatus(
        canTrack: false,
        status: request.status,
        message: 'Suivi GPS non disponible pour cette demande',
      );
    }
    
    final gpsPosition = await fetchDeliveryGpsPosition(request.actionData!);
    
    return DeliveryTrackingStatus(
      canTrack: true,
      status: request.status,
      gpsPosition: gpsPosition,
      message: gpsPosition != null 
          ? 'Position GPS mise à jour' 
          : 'Position GPS non disponible',
      trackingInfo: parseActionData(request.actionData!),
    );
  }
  
  /// Format GPS coordinates for display
  static String formatGpsCoordinates(double latitude, double longitude) {
    return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }
  
  /// Calculate distance between two GPS points (approximate)
  static double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const double earthRadius = 6371; // Earth radius in kilometers

    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLon = _degreesToRadians(lon2 - lon1);

    final double a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
        sin(dLon / 2) * sin(dLon / 2);

    final double c = 2 * asin(sqrt(a));

    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (pi / 180);
  }
}

/// Model for parsed action_data information
class BloodRequestTrackingInfo {
  final String platform;
  final String type;
  final String requestId;
  final String deliveryId;
  final String rawActionData;
  
  BloodRequestTrackingInfo({
    required this.platform,
    required this.type,
    required this.requestId,
    required this.deliveryId,
    required this.rawActionData,
  });
}

/// Model for GPS position data
class DeliveryGpsPosition {
  final double latitude;
  final double longitude;
  final double altitude;
  final DateTime timestamp;
  final String deliveryId;
  final String status;
  
  DeliveryGpsPosition({
    required this.latitude,
    required this.longitude,
    required this.altitude,
    required this.timestamp,
    required this.deliveryId,
    required this.status,
  });
  
  bool get isValidPosition => latitude != 0.0 && longitude != 0.0;
}

/// Model for delivery tracking status
class DeliveryTrackingStatus {
  final bool canTrack;
  final BloodRequestStatus status;
  final DeliveryGpsPosition? gpsPosition;
  final String message;
  final BloodRequestTrackingInfo? trackingInfo;
  
  DeliveryTrackingStatus({
    required this.canTrack,
    required this.status,
    this.gpsPosition,
    required this.message,
    this.trackingInfo,
  });
}
