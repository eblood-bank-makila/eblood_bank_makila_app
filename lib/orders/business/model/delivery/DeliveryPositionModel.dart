import 'dart:convert';

/// Model for hospital position information
class HospitalPositionInfo {
  final double longitude;
  final double latitude;

  HospitalPositionInfo({
    required this.longitude,
    required this.latitude,
  });

  factory HospitalPositionInfo.fromJson(Map<String, dynamic> json) {
    return HospitalPositionInfo(
      longitude: double.tryParse(json['longitude']?.toString() ?? '0') ?? 0.0,
      latitude: double.tryParse(json['latitude']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'longitude': longitude,
      'latitude': latitude,
    };
  }

  @override
  String toString() {
    return 'HospitalPositionInfo(longitude: $longitude, latitude: $latitude)';
  }
}

/// Model for cool box position information
class CoolBoxPositionInfo {
  final double longitude;
  final double latitude;

  CoolBoxPositionInfo({
    required this.longitude,
    required this.latitude,
  });

  factory CoolBoxPositionInfo.fromJson(Map<String, dynamic> json) {
    return CoolBoxPositionInfo(
      longitude: double.tryParse(json['longitude']?.toString() ?? '0') ?? 0.0,
      latitude: double.tryParse(json['latitude']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'longitude': longitude,
      'latitude': latitude,
    };
  }

  @override
  String toString() {
    return 'CoolBoxPositionInfo(longitude: $longitude, latitude: $latitude)';
  }
}

/// Model for delivery position response from backend
class DeliveryPositionResponseModel {
  final bool success;
  final String message;
  final DeliveryPositionInfo? info;

  DeliveryPositionResponseModel({
    required this.success,
    required this.message,
    this.info,
  });

  factory DeliveryPositionResponseModel.fromJson(Map<String, dynamic> json) {
    return DeliveryPositionResponseModel(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      info: json['data'] != null ? DeliveryPositionInfo.fromJson(json['data']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': info?.toJson(),
    };
  }

  @override
  String toString() {
    return 'DeliveryPositionResponseModel(success: $success, message: $message, info: $info)';
  }
}

/// Model for delivery position information
class DeliveryPositionInfo {
  final HospitalPositionInfo hospital;
  final CoolBoxPositionInfo coolBox;
  final double distance;
  final String deliveryPerson;

  DeliveryPositionInfo({
    required this.hospital,
    required this.coolBox,
    required this.distance,
    required this.deliveryPerson,
  });

  factory DeliveryPositionInfo.fromJson(Map<String, dynamic> json) {
    return DeliveryPositionInfo(
      hospital: HospitalPositionInfo.fromJson(json['hospital'] ?? {}),
      coolBox: CoolBoxPositionInfo.fromJson(json['cool_box'] ?? {}),
      distance: _parseDistance(json['distance']?.toString() ?? '0'),
      deliveryPerson: json['delivery_person']?.toString() ?? 'Inconnu',
    );
  }

  /// Parse distance string that may include units (e.g., "3.24 km", "500 m")
  static double _parseDistance(String distanceStr) {
    if (distanceStr.isEmpty) return 0.0;

    // Remove common units and whitespace, then try to parse the number
    String cleanDistance = distanceStr
        .toLowerCase()
        .replaceAll('km', '')
        .replaceAll('m', '')
        .replaceAll(' ', '')
        .trim();

    double? parsedDistance = double.tryParse(cleanDistance);
    if (parsedDistance == null) return 0.0;

    // If original string contained 'm' but not 'km', convert meters to kilometers
    if (distanceStr.toLowerCase().contains('m') && !distanceStr.toLowerCase().contains('km')) {
      return parsedDistance / 1000; // Convert meters to kilometers
    }

    return parsedDistance;
  }

  Map<String, dynamic> toJson() {
    return {
      'hospital': hospital.toJson(),
      'cool_box': coolBox.toJson(),
      'distance': distance,
      'delivery_person': deliveryPerson,
    };
  }

  /// Get formatted distance string
  String get formattedDistance {
    if (distance == 0.0) {
      return 'Distance inconnue';
    } else if (distance < 1) {
      return '${(distance * 1000).toStringAsFixed(0)} m';
    } else {
      return '${distance.toStringAsFixed(2)} km';
    }
  }

  /// Get hospital coordinates as formatted string
  String get hospitalCoordinates {
    return '${hospital.latitude.toStringAsFixed(6)}, ${hospital.longitude.toStringAsFixed(6)}';
  }

  /// Get cool box coordinates as formatted string
  String get coolBoxCoordinates {
    return '${coolBox.latitude.toStringAsFixed(6)}, ${coolBox.longitude.toStringAsFixed(6)}';
  }

  /// Check if hospital position is valid
  bool get hasValidHospitalPosition {
    return hospital.latitude != 0.0 && hospital.longitude != 0.0;
  }

  /// Check if cool box position is valid
  bool get hasValidCoolBoxPosition {
    return coolBox.latitude != 0.0 && coolBox.longitude != 0.0;
  }

  /// Check if both positions are valid
  bool get hasValidPositions {
    return hasValidHospitalPosition && hasValidCoolBoxPosition;
  }

  @override
  String toString() {
    return 'DeliveryPositionInfo(hospital: $hospital, coolBox: $coolBox, distance: $distance, deliveryPerson: $deliveryPerson)';
  }
}

/// Model for delivery position request
class DeliveryPositionRequestModel {
  final String requestedAction;
  final String actionData;

  DeliveryPositionRequestModel({
    required this.requestedAction,
    required this.actionData,
  });

  Map<String, dynamic> toJson() {
    return {
      'requested_action': requestedAction,
      'action_data': actionData,
    };
  }

  factory DeliveryPositionRequestModel.fromJson(Map<String, dynamic> json) {
    return DeliveryPositionRequestModel(
      requestedAction: json['requested_action'] ?? '',
      actionData: json['action_data'] ?? '',
    );
  }

  String toJsonString() => json.encode(toJson());

  @override
  String toString() {
    return 'DeliveryPositionRequestModel(requestedAction: $requestedAction, actionData: $actionData)';
  }
}
