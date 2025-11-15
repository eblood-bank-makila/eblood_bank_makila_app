import 'package:eblood_bank_mak_app/apps/models/api_response.dart';
import '../../model/blood_request/BloodRequestModel.dart';

abstract class BloodRequestNetworkService {
  /// Fetches pending delivery blood requests
  Future<BloodRequestResponseModel?> getPendingDeliveryRequests(
    int page,
    String authToken,
  );

  /// Fetches in-progress delivery blood requests
  Future<BloodRequestResponseModel?> getInProgressDeliveryRequests(
    int page,
    String authToken,
  );

  /// Fetches delivered blood requests
  Future<BloodRequestResponseModel?> getDeliveredRequests(
    int page,
    String authToken,
  );

  /// Fetches completed blood requests (used blood bags)
  Future<BloodRequestResponseModel?> getCompletedRequests(
    int page,
    String authToken,
  );

  /// Generic method to fetch blood requests by status
  Future<BloodRequestResponseModel?> getBloodRequestsByStatus(
    BloodRequestStatus status,
    int page,
    String authToken,
  );

  /// Confirm delivery using verification code (manual or QR)
  Future<IApiResponse> confirmDelivery(
    String requestId,
    String verificationCode,
    String confirmationMethod,
  );

  /// Mark a blood bag request item as used
  Future<IApiResponse> markBloodBagUsed(
    String bloodBagRequestId, {
    String? patientId,
    String? usageNotes,
  });

  /// Request the coolbox password for a delivery/request
  Future<IApiResponse> requestCoolboxPassword(
    String deliveryId,
  );
}
