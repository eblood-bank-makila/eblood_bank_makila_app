/// Blood Search Flow - Service Interfaces
/// Abstract interfaces for the data layer

import '../entities/search_flow_state.dart';
import '../../../payments/business/service/PaymentApi.dart' show PaymentInitiateResult;

/// Search service interface for blood bag search
abstract class IBloodSearchService {
  /// Search for blood bags by city and blood type
  Future<List<BloodSearchResult>> searchBlood({
    required String cityId,
    required String bloodType,
    String? authToken,
    double? userLatitude,
    double? userLongitude,
    double? hospitalLatitude,
    double? hospitalLongitude,
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

/// Outcome of an OTP send.
///
/// [expiryMinutes] carries the backend's `otp_expiry_minutes` — how long the
/// code stays valid. It drives how long the UI keeps listening for the SMS,
/// so the listener dies with the code instead of spinning forever. Null when
/// the backend didn't say.
class OtpSendResult {
  final bool success;
  final int? expiryMinutes;

  const OtpSendResult({required this.success, this.expiryMinutes});
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
  /// [appSignature] is for SMS Retriever API auto-read on Android
  Future<OtpSendResult> sendOtp(String sessionId, {String? appSignature});

  /// Verify OTP and get auth token
  Future<String?> verifyOtp({
    required String sessionId,
    required String otpCode,
  });

  /// Resend OTP
  /// [appSignature] is for SMS Retriever API auto-read on Android
  Future<bool> resendOtp(String sessionId, {String? appSignature});

  /// Check if visitor has a verified phone number
  Future<bool> hasVisitorPhoneNumber();

  /// Save visitor phone number after verification
  Future<void> saveVisitorPhone(String phone);
}

/// Payment service interface
abstract class IPaymentService {
  /// Get price for address view
  Future<double> getAddressViewPrice();

  /// Get price for delivery
  Future<double> getDeliveryPrice();

  /// Create the payment intent + gateway session for an address-view
  /// payment and return the full lokotro checkout config. The UI then
  /// launches the SDK checkout with this result; the payment is only
  /// actually collected when the SDK reports success.
  Future<PaymentInitiateResult> initiateAddressViewPayment({
    required String hospitalId,
    required String authToken,
    required Map<String, dynamic> paymentDetails,
  });

  /// Create the payment intent + gateway session for a delivery payment
  /// and return the full lokotro checkout config (see above).
  Future<PaymentInitiateResult> initiateDeliveryPayment({
    required String hospitalId,
    required List<String> bloodBagIds,
    required String authToken,
    required Map<String, dynamic> paymentDetails,
  });

  /// Check payment status by request identifier (polls backend)
  Future<PaymentResult> checkPaymentStatus({
    required String requestIdentifier,
    required String authToken,
    double? progressPercent,
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

  const HospitalQrData({this.hospitalId, this.hospitalCode, this.deepLinkUri});

  bool get isValid =>
      hospitalId != null || hospitalCode != null || deepLinkUri != null;
}
