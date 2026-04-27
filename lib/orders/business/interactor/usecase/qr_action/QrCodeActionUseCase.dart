import '../../../../../utilisateurs/business/service/utilisateurLocalService.dart';
import '../../../model/delivery/DeliveryValidationModel.dart';
import '../../../service/DeliveryValidationNetworkService.dart';

class QrCodeActionUseCase {
  final QrCodeActionNetworkService network;
  final UtilisateurLocalService local;

  QrCodeActionUseCase(this.network, this.local);

  /// Executes a QR code action (delivery validation, password request, etc.)
  /// 
  /// [actionType] - The type of action ('delivery_validation', 'password', etc.)
  /// [qrCodeData] - The scanned QR code data
  /// Returns [QrCodeActionResponseModel] with action result
  Future<QrCodeActionResponseModel?> run(String actionType, String qrCodeData) async {
    try {
      // Validate QR code format first
      if (!_isValidQrCodeFormat(qrCodeData)) {
        return QrCodeActionResponseModel(
          success: false,
          message: "Format de QR code invalide. Le QR code doit commencer par 'eblood___request___'",
        );
      }

      // Get authentication token
      final token = await local.recupererTokenOtp();
      if (token == null || token.isEmpty) {
        return QrCodeActionResponseModel(
          success: false,
          message: "Token d'authentification manquant. Veuillez vous reconnecter.",
        );
      }

      // Call network service to execute the action
      final result = await network.executeQrCodeAction(actionType, qrCodeData, token);
      
      return result;
    } catch (e) {
      print("💥 Error in QrCodeActionUseCase: $e");
      return QrCodeActionResponseModel(
        success: false,
        message: "Erreur lors de l'exécution: $e",
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

  /// Gets the action description for display purposes
  String getActionDescription(String actionType) {
    switch (actionType) {
      case 'delivery_validation':
        return 'Validation de livraison';
      case 'password':
        return 'Demande de mot de passe';
      default:
        return 'Action QR Code';
    }
  }

  /// Gets the success message for different action types
  String getSuccessMessage(String actionType) {
    switch (actionType) {
      case 'delivery_validation':
        return 'Livraison confirmée avec succès !';
      case 'password':
        return 'Demande de mot de passe envoyée avec succès !';
      default:
        return 'Action exécutée avec succès !';
    }
  }
}
