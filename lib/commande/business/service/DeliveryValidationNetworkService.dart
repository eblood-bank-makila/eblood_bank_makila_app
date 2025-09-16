import '../model/delivery/DeliveryValidationModel.dart';

abstract class QrCodeActionNetworkService {
  Future<QrCodeActionResponseModel?> executeQrCodeAction(
    String requestedAction,
    String qrCodeData,
    String authToken,
  );
}

// Keep the old interface for backward compatibility
abstract class DeliveryValidationNetworkService {
  Future<DeliveryValidationResponseModel?> validateDelivery(
    String qrCodeData,
    String authToken,
  );
}
