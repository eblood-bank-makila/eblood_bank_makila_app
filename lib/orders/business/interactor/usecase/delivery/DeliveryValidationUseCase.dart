import '../../../../../users/business/service/utilisateurLocalService.dart';
import '../../../model/delivery/DeliveryValidationModel.dart';
import '../../../service/DeliveryValidationNetworkService.dart';

class DeliveryValidationUseCase {
  final DeliveryValidationNetworkService network;
  final UtilisateurLocalService local;

  DeliveryValidationUseCase(this.network, this.local);

  /// Validates a QR code for delivery confirmation
  /// 
  /// [qrCodeData] - The scanned QR code data
  /// Returns [DeliveryValidationResponseModel] with validation result
  Future<DeliveryValidationResponseModel?> run(String qrCodeData) async {
    try {
      // Validate QR code format first
      if (!_isValidQrCodeFormat(qrCodeData)) {
        return DeliveryValidationResponseModel(
          success: false,
          message: "Format de QR code invalide. Le QR code doit commencer par 'eblood___request___'",
        );
      }

      // Get authentication token
      final token = await local.recupererTokenOtp();
      if (token == null || token.isEmpty) {
        return DeliveryValidationResponseModel(
          success: false,
          message: "Token d'authentification manquant. Veuillez vous reconnecter.",
        );
      }

      // Call network service to validate delivery
      final result = await network.validateDelivery(qrCodeData, token);
      
      return result;
    } catch (e) {
      print("💥 Error in DeliveryValidationUseCase: $e");
      return DeliveryValidationResponseModel(
        success: false,
        message: "Erreur lors de la validation: $e",
      );
    }
  }

  /// Validates the QR code format
  /// Expected format: eblood___request___dynamichospitalidhere___dynamicrequesttransactionidhere
  bool _isValidQrCodeFormat(String qrCodeData) {
    if (qrCodeData.isEmpty) {
      return false;
    }

    // Check if it starts with the expected prefix
    if (!qrCodeData.startsWith('eblood___request___')) {
      return false;
    }

    // Split by the separator and check structure
    final parts = qrCodeData.split('___');
    
    // Expected structure: ['eblood', 'request', 'hospitalId', 'transactionId']
    if (parts.length != 4) {
      return false;
    }

    // Check that hospital ID and transaction ID are not empty
    if (parts[2].isEmpty || parts[3].isEmpty) {
      return false;
    }

    return true;
  }

  /// Extracts hospital ID from QR code
  String? extractHospitalId(String qrCodeData) {
    if (!_isValidQrCodeFormat(qrCodeData)) {
      return null;
    }
    
    final parts = qrCodeData.split('___');
    return parts[2];
  }

  /// Extracts transaction ID from QR code
  String? extractTransactionId(String qrCodeData) {
    if (!_isValidQrCodeFormat(qrCodeData)) {
      return null;
    }
    
    final parts = qrCodeData.split('___');
    return parts[3];
  }
}
