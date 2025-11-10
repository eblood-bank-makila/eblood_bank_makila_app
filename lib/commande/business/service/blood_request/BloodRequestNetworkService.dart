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
}
