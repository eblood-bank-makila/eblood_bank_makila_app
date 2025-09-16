import 'package:flutter/material.dart';
import '../../../../../utilisateurs/business/service/utilisateurLocalService.dart';
import '../../../model/blood_request/BloodRequestModel.dart';
import '../../../service/blood_request/BloodRequestNetworkService.dart';

class BloodRequestUseCase {
  final BloodRequestNetworkService network;
  final UtilisateurLocalService local;

  BloodRequestUseCase(this.network, this.local);

  /// Fetches pending delivery blood requests
  Future<BloodRequestResponseModel?> getPendingDeliveryRequests(int page) async {
    try {
      final token = await local.recupererTokenOtp();
      if (token == null || token.isEmpty) {
        return BloodRequestResponseModel(
          success: false,
          message: "Token d'authentification manquant. Veuillez vous reconnecter.",
          data: [],
        );
      }

      return await network.getPendingDeliveryRequests(page, token);
    } catch (e) {
      print("💥 Error in getPendingDeliveryRequests: $e");
      return BloodRequestResponseModel(
        success: false,
        message: "Erreur lors de la récupération des demandes en attente: $e",
        data: [],
      );
    }
  }

  /// Fetches in-progress delivery blood requests
  Future<BloodRequestResponseModel?> getInProgressDeliveryRequests(int page) async {
    try {
      final token = await local.recupererTokenOtp();
      if (token == null || token.isEmpty) {
        return BloodRequestResponseModel(
          success: false,
          message: "Token d'authentification manquant. Veuillez vous reconnecter.",
          data: [],
        );
      }

      return await network.getInProgressDeliveryRequests(page, token);
    } catch (e) {
      print("💥 Error in getInProgressDeliveryRequests: $e");
      return BloodRequestResponseModel(
        success: false,
        message: "Erreur lors de la récupération des livraisons en cours: $e",
        data: [],
      );
    }
  }

  /// Fetches delivered blood requests
  Future<BloodRequestResponseModel?> getDeliveredRequests(int page) async {
    try {
      final token = await local.recupererTokenOtp();
      if (token == null || token.isEmpty) {
        return BloodRequestResponseModel(
          success: false,
          message: "Token d'authentification manquant. Veuillez vous reconnecter.",
          data: [],
        );
      }

      return await network.getDeliveredRequests(page, token);
    } catch (e) {
      print("💥 Error in getDeliveredRequests: $e");
      return BloodRequestResponseModel(
        success: false,
        message: "Erreur lors de la récupération des demandes livrées: $e",
        data: [],
      );
    }
  }

  /// Generic method to fetch blood requests by status
  Future<BloodRequestResponseModel?> getBloodRequestsByStatus(
    BloodRequestStatus status,
    int page,
  ) async {
    switch (status) {
      case BloodRequestStatus.pendingDelivery:
        return await getPendingDeliveryRequests(page);
      case BloodRequestStatus.inProgressDelivery:
        return await getInProgressDeliveryRequests(page);
      case BloodRequestStatus.delivered:
        return await getDeliveredRequests(page);
    }
  }

  /// Gets the appropriate status color for UI display
  static Color getStatusColor(BloodRequestStatus status) {
    switch (status) {
      case BloodRequestStatus.pendingDelivery:
        return const Color(0xFFFF9800); // Orange
      case BloodRequestStatus.inProgressDelivery:
        return const Color(0xFF2196F3); // Blue
      case BloodRequestStatus.delivered:
        return const Color(0xFF4CAF50); // Green
    }
  }

  /// Gets the appropriate status icon for UI display
  static IconData getStatusIcon(BloodRequestStatus status) {
    switch (status) {
      case BloodRequestStatus.pendingDelivery:
        return Icons.schedule;
      case BloodRequestStatus.inProgressDelivery:
        return Icons.local_shipping;
      case BloodRequestStatus.delivered:
        return Icons.check_circle;
    }
  }

  /// Formats date for display
  static String formatDate(DateTime date) {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }

  /// Formats date and time for display
  static String formatDateTime(DateTime date) {
    return "${formatDate(date)} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  /// Gets time ago string for display
  static String getTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return "Il y a ${difference.inDays} jour${difference.inDays > 1 ? 's' : ''}";
    } else if (difference.inHours > 0) {
      return "Il y a ${difference.inHours} heure${difference.inHours > 1 ? 's' : ''}";
    } else if (difference.inMinutes > 0) {
      return "Il y a ${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''}";
    } else {
      return "À l'instant";
    }
  }
}
