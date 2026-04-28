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

  /// Request the coolbox password for a delivery.
  ///
  /// Sprint 17 contract — the backend gate verifies:
  ///   * the requester user_id is a member of one of [user_org_ids]
  ///   * one of those org_ids is on the delivery (supplier or buyer)
  ///   * [qrToken] matches the delivery's currently-active token
  ///
  /// Caller must scan the QR sticker on the coolbox first; the dialog
  /// no longer auto-opens without that.
  Future<IApiResponse> requestCoolboxPassword({
    required String deliveryId,
    required String qrToken,
  });
}
