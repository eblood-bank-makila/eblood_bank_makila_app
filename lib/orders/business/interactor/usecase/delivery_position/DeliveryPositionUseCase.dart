import 'dart:math';
import '../../../model/delivery/DeliveryPositionModel.dart';
import '../../../model/blood_request/BloodRequestModel.dart';
import '../../../service/DeliveryValidationNetworkService.dart';
import '../../../../../users/business/service/utilisateurLocalService.dart';

class DeliveryPositionUseCase {
  final QrCodeActionNetworkService network;
  final UtilisateurLocalService local;

  DeliveryPositionUseCase(this.network, this.local);

  /// Fetches delivery position using action_data from blood request
  /// 
  /// [actionData] - The action_data from BloodRequestModel (format: eblood___request___id1___id2)
  /// Returns [DeliveryPositionResponseModel] with position information
  Future<DeliveryPositionResponseModel?> fetchDeliveryPosition(String actionData) async {
    try {
      print("🌍 Starting delivery position fetch");
      print("📍 Action data: $actionData");

      // Validate action_data format
      if (!_isValidActionDataFormat(actionData)) {
        return DeliveryPositionResponseModel(
          success: false,
          message: "Format d'action_data invalide. Le format attendu est 'eblood___request___id1___id2'",
        );
      }

      // Get authentication token
      final token = await local.recupererTokenOtp();
      if (token == null || token.isEmpty) {
        return DeliveryPositionResponseModel(
          success: false,
          message: "Token d'authentification manquant. Veuillez vous reconnecter.",
        );
      }

      print("🔑 Auth token retrieved: ${token.length} characters");

      // Call network service to fetch position with 'distance' action
      final result = await network.executeQrCodeAction('distance', actionData, token);
      
      if (result != null) {
        print("📡 Network response received: ${result.success}");
        print("📄 Response data: ${result.data}");

        // Convert QrCodeActionResponseModel to DeliveryPositionResponseModel
        return DeliveryPositionResponseModel(
          success: result.success,
          message: result.message,
          info: result.success && result.data != null 
              ? DeliveryPositionInfo.fromJson(result.data!)
              : null,
        );
      } else {
        return DeliveryPositionResponseModel(
          success: false,
          message: "Aucune réponse du serveur",
        );
      }
    } catch (e) {
      print("💥 Error in DeliveryPositionUseCase: $e");
      return DeliveryPositionResponseModel(
        success: false,
        message: "Erreur lors de la récupération de la position: $e",
      );
    }
  }

  /// Fetches delivery position from BloodRequestModel
  Future<DeliveryPositionResponseModel?> fetchPositionFromRequest(BloodRequestModel request) async {
    if (request.actionData == null || request.actionData!.isEmpty) {
      return DeliveryPositionResponseModel(
        success: false,
        message: "Aucune donnée d'action disponible pour cette demande",
      );
    }

    return await fetchDeliveryPosition(request.actionData!);
  }

  /// Checks if a blood request can have its position fetched
  /// Position is only available for blood requests with "in progress delivery" status
  static bool canFetchPosition(BloodRequestModel request) {
    print("🔍 Checking if position can be fetched for request: ${request.requestId}");
    print("  - Action Data: ${request.actionData}");
    print("  - Status: ${request.status.displayName}");

    bool hasActionData = request.actionData != null && request.actionData!.isNotEmpty;
    bool validFormat = hasActionData ? _isValidActionDataFormat(request.actionData!) : false;
    // Position is only available for blood requests in progress (delivery in progress)
    bool validStatus = request.status == BloodRequestStatus.inProgressDelivery;

    print("  - Has Action Data: $hasActionData");
    print("  - Valid Format: $validFormat");
    print("  - Valid Status: $validStatus");

    bool canFetch = hasActionData && validFormat && validStatus;
    print("  - Can Fetch Position: $canFetch");

    return canFetch;
  }

  /// Validates the action_data format
  static bool _isValidActionDataFormat(String actionData) {
    if (actionData.isEmpty) return false;
    
    // Expected format: eblood___request___id1___id2
    final parts = actionData.split('___');
    return parts.length >= 4 && 
           parts[0] == 'eblood' && 
           parts[1] == 'request' &&
           parts[2].isNotEmpty &&
           parts[3].isNotEmpty;
  }

  /// Extracts request ID from action_data
  static String? extractRequestId(String actionData) {
    if (!_isValidActionDataFormat(actionData)) {
      return null;
    }
    
    final parts = actionData.split('___');
    return parts[2];
  }

  /// Extracts delivery ID from action_data
  static String? extractDeliveryId(String actionData) {
    if (!_isValidActionDataFormat(actionData)) {
      return null;
    }
    
    final parts = actionData.split('___');
    return parts[3];
  }

  /// Calculates distance between two GPS points using Haversine formula
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

  /// Formats distance for display
  static String formatDistance(double distanceKm) {
    if (distanceKm < 1) {
      return '${(distanceKm * 1000).toStringAsFixed(0)} m';
    } else {
      return '${distanceKm.toStringAsFixed(2)} km';
    }
  }

  /// Formats GPS coordinates for display
  static String formatCoordinates(double latitude, double longitude) {
    return '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}';
  }

  /// Gets status message based on distance
  static String getDistanceStatus(double distanceKm) {
    if (distanceKm < 0.1) {
      return 'Très proche de la destination';
    } else if (distanceKm < 0.5) {
      return 'Proche de la destination';
    } else if (distanceKm < 2.0) {
      return 'En route vers la destination';
    } else if (distanceKm < 10.0) {
      return 'En cours de livraison';
    } else {
      return 'Livraison en cours';
    }
  }

  /// Gets color based on distance for UI
  static int getDistanceColor(double distanceKm) {
    if (distanceKm < 0.1) {
      return 0xFF4CAF50; // Green - Very close
    } else if (distanceKm < 0.5) {
      return 0xFF8BC34A; // Light green - Close
    } else if (distanceKm < 2.0) {
      return 0xFFFF9800; // Orange - En route
    } else {
      return 0xFF2196F3; // Blue - In progress
    }
  }

  /// Validates if position data is complete and valid
  static bool isValidPositionData(DeliveryPositionInfo info) {
    return info.hasValidHospitalPosition && 
           info.hasValidCoolBoxPosition &&
           info.distance >= 0 &&
           info.deliveryPerson.isNotEmpty;
  }
}
