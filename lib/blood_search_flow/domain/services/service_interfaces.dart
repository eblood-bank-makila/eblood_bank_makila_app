/// Blood Search Flow - Service Interfaces
/// Abstract interfaces for the data layer

import '../entities/search_flow_state.dart';

/// Search service interface for blood bag search
abstract class IBloodSearchService {
  /// Search for blood bags by city and blood type
  Future<List<BloodSearchResult>> searchBlood({
    required String cityId,
    required String bloodType,
    String? authToken,
  });
}

/// Hospital identification service interface
abstract class IHospitalIdentificationService {
  /// Identify hospital by 8-digit code
  Future<IdentifiedHospital?> identifyByCode(String code);

  /// Identify hospital from QR code content
  Future<IdentifiedHospital?> identifyFromQrContent(String qrContent);

  /// Parse deep link and identify hospital
  Future<IdentifiedHospital?> identifyFromDeepLink(String deepLinkUri);
}

/// Visitor registration service interface
abstract class IVisitorRegistrationService {
  /// Register visitor with phone number, returns session ID
  Future<String> registerVisitor({
    required String phoneNumber,
    required String hospitalId,
    String? locationId,
  });

  /// Send OTP to registered phone number
  Future<bool> sendOtp(String sessionId);

  /// Verify OTP and get auth token
  Future<String?> verifyOtp({
    required String sessionId,
    required String otpCode,
  });

  /// Resend OTP
  Future<bool> resendOtp(String sessionId);
}

/// Payment service interface
abstract class IPaymentService {
  /// Get price for address view
  Future<double> getAddressViewPrice();

  /// Get price for delivery
  Future<double> getDeliveryPrice();

  /// Process payment for address view
  Future<PaymentResult> payForAddressView({
    required String hospitalId,
    required String authToken,
    required Map<String, dynamic> paymentDetails,
  });

  /// Process payment for delivery
  Future<PaymentResult> payForDelivery({
    required String hospitalId,
    required List<String> bloodBagIds,
    required String authToken,
    required Map<String, dynamic> paymentDetails,
  });
}

/// Address unlock service interface
abstract class IAddressUnlockService {
  /// Get unlocked address after payment
  Future<String> getUnlockedAddress({
    required String hospitalId,
    required String transactionId,
    required String authToken,
  });
}

/// Delivery tracking service interface
abstract class IDeliveryTrackingService {
  /// Get current delivery status
  Future<DeliveryTrackingInfo> getDeliveryStatus({
    required String trackingId,
    required String authToken,
  });

  /// Stream delivery updates
  Stream<DeliveryTrackingInfo> streamDeliveryUpdates({
    required String trackingId,
    required String authToken,
  });
}

/// Authentication service interface
abstract class IAuthService {
  /// Check if user is currently authenticated
  Future<bool> isAuthenticated();

  /// Get current auth token
  Future<String?> getAuthToken();

  /// Get user profile type (visitor, donor, hospital, etc.)
  Future<String?> getUserProfileType();

  /// Check if user is a visitor (limited access)
  Future<bool> isVisitor();
}

/// QR code service interface
abstract class IQrCodeService {
  /// Decode QR code from image file path
  Future<String?> decodeFromImage(String imagePath);

  /// Parse hospital info from QR content
  HospitalQrData? parseHospitalQr(String content);
}

/// Parsed hospital QR data
class HospitalQrData {
  final String? hospitalId;
  final String? hospitalCode;
  final String? deepLinkUri;

  const HospitalQrData({
    this.hospitalId,
    this.hospitalCode,
    this.deepLinkUri,
  });

  bool get isValid => hospitalId != null || hospitalCode != null || deepLinkUri != null;
}
