/// Visitor Registration Service Implementation

import 'package:dio/dio.dart';
import 'package:get_storage/get_storage.dart';
import '../../domain/services/service_interfaces.dart';
import '../../../core/network/dio_client.dart';

class VisitorRegistrationServiceImpl implements IVisitorRegistrationService {
  late final Dio _dio;
  final GetStorage _storage = GetStorage();

  VisitorRegistrationServiceImpl() {
    _dio = DioClient().dio;
  }

  /// Check if visitor is already saved locally
  Future<bool> hasLocalVisitor() async {
    try {
      final token = _storage.read('visitor_token');
      return token != null && token.toString().isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Check if visitor has a verified phone number locally
  @override
  Future<bool> hasVisitorPhoneNumber() async {
    try {
      final phone = _storage.read('visitor_phone');
      final isVerified = _storage.read('visitor_phone_verified') == true;
      return phone != null && phone.toString().isNotEmpty && isVerified;
    } catch (e) {
      return false;
    }
  }

  /// Get locally stored visitor token
  Future<String?> getLocalVisitorToken() async {
    try {
      return _storage.read('visitor_token');
    } catch (e) {
      return null;
    }
  }

  /// Save visitor phone number after verification
  @override
  Future<void> saveVisitorPhone(String phone) async {
    await _storage.write('visitor_phone', phone);
    await _storage.write('visitor_phone_verified', true);
  }

  /// Check if device already has a visitor account linked (GET request)
  /// Returns: {success, needs_entity, needs_phone_verification, data}
  Future<Map<String, dynamic>?> checkVisitorLogin() async {
    try {
      final response = await _dio.get('/eblood-connect/users/login-visitor');

      if (response.statusCode == 200) {
        final data = response.data;
        if (data['success'] == true && data['data'] != null) {
          // Device already linked, save the token
          final token =
              data['data']['access_token']?.toString() ??
              data['data']['token']?.toString();
          if (token != null && token.isNotEmpty) {
            await _storage.write('visitor_token', token);
            await _storage.write('is_visitor', true);
          }

          // Check if user has a real phone number (not fake)
          final user = data['data']['user'];
          String? phoneNumber;
          if (user != null) {
            phoneNumber =
                user['phone_number']?.toString() ??
                user['phoneNumber']?.toString() ??
                user['phone']?.toString();
          }

          // Check if phone is fake (starts with +1- which is the fake format)
          final bool hasFakePhone =
              phoneNumber == null ||
              phoneNumber.isEmpty ||
              phoneNumber.startsWith('+1-') ||
              phoneNumber.contains('XXX');

          // Check local storage for verified phone
          final hasLocalPhone = await hasVisitorPhoneNumber();

          // Add needs_phone_verification flag to response
          final result = Map<String, dynamic>.from(data);
          result['needs_phone_verification'] = hasFakePhone && !hasLocalPhone;

          return result;
        }
        // needs_entity == true means user needs to provide location_id
        return data;
      }
      return null;
    } catch (e) {
      print('VisitorRegistrationService.checkVisitorLogin error: $e');
      return null;
    }
  }

  /// Create visitor account with location_id (POST request)
  Future<Map<String, dynamic>?> createVisitorAccount({
    required String locationId,
  }) async {
    try {
      final response = await _dio.post(
        '/eblood-connect/users/login-visitor',
        data: {'location_id': locationId},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data['success'] == true && data['data'] != null) {
          // Save the token
          final token =
              data['data']['access_token']?.toString() ??
              data['data']['token']?.toString();
          if (token != null && token.isNotEmpty) {
            await _storage.write('visitor_token', token);
            await _storage.write('is_visitor', true);
          }

          // New visitor always needs phone verification
          final result = Map<String, dynamic>.from(data);
          result['needs_phone_verification'] = true;

          return result;
        }
        return data;
      }
      return null;
    } catch (e) {
      print('VisitorRegistrationService.createVisitorAccount error: $e');
      return null;
    }
  }

  @override
  Future<String> registerVisitor({
    required String phoneNumber,
    required String hospitalId,
    String? locationId,
  }) async {
    try {
      // First check if device already has a visitor account
      final checkResult = await checkVisitorLogin();
      if (checkResult != null && checkResult['success'] == true) {
        // Already logged in
        return checkResult['data']?['session_id']?.toString() ??
            checkResult['data']?['token']?.toString() ??
            '';
      }

      // If needs_entity, create visitor with location_id
      if (checkResult?['needs_entity'] == true && locationId != null) {
        final createResult = await createVisitorAccount(locationId: locationId);
        if (createResult != null && createResult['success'] == true) {
          return createResult['data']?['session_id']?.toString() ??
              createResult['data']?['token']?.toString() ??
              '';
        }
      }

      throw Exception('Unable to register visitor');
    } catch (e) {
      print('VisitorRegistrationService.registerVisitor error: $e');
      rethrow;
    }
  }

  @override
  Future<bool> sendOtp(String sessionId, {String? appSignature}) async {
    // Note: sessionId is actually the phone number for visitor OTP
    try {
      final response = await _dio.post(
        '/eblood-connect/users/visitor-send-phone-otp',
        data: {
          'phone_number': sessionId,
          if (appSignature != null) 'app_signature': appSignature,
        },
      );

      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      print('VisitorRegistrationService.sendOtp error: $e');
      return false;
    }
  }

  /// Send OTP to phone number (for visitor phone verification)
  Future<bool> sendPhoneOtp(String phoneNumber, {String? appSignature}) async {
    try {
      final response = await _dio.post(
        '/eblood-connect/users/visitor-send-phone-otp',
        data: {
          'phone_number': phoneNumber,
          if (appSignature != null) 'app_signature': appSignature,
        },
      );

      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      print('VisitorRegistrationService.sendPhoneOtp error: $e');
      return false;
    }
  }

  @override
  Future<String?> verifyOtp({
    required String sessionId,
    required String otpCode,
  }) async {
    // Note: sessionId is actually the phone number for visitor OTP
    try {
      print('🔐 Sending OTP verification: phone=$sessionId, otp=$otpCode');
      
      final response = await _dio.post(
        '/eblood-connect/users/visitor-verify-phone-otp',
        data: {'phone_number': sessionId, 'otp_code': otpCode},
      );

      print('📬 OTP verify response: ${response.statusCode} - ${response.data}');

      if (response.statusCode == 200 && response.data['success'] == true) {
        // Phone verified, return the phone number as confirmation
        return sessionId;
      }
      print('⚠️ OTP verification failed: success=${response.data['success']}');
      return null;
    } on DioException catch (e) {
      print('❌ VisitorRegistrationService.verifyOtp DioError: ${e.response?.statusCode} - ${e.response?.data}');
      // Rethrow with more details for error handling
      if (e.response?.data != null && e.response?.data['detail'] != null) {
        throw Exception(e.response?.data['detail']);
      }
      rethrow;
    } catch (e) {
      print('❌ VisitorRegistrationService.verifyOtp error: $e');
      rethrow;
    }
  }

  /// Verify phone OTP (for visitor phone verification)
  Future<bool> verifyPhoneOtp({
    required String phoneNumber,
    required String otpCode,
  }) async {
    try {
      final response = await _dio.post(
        '/eblood-connect/users/visitor-verify-phone-otp',
        data: {'phone_number': phoneNumber, 'otp_code': otpCode},
      );

      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      print('VisitorRegistrationService.verifyPhoneOtp error: $e');
      return false;
    }
  }

  @override
  Future<bool> resendOtp(String sessionId, {String? appSignature}) async {
    // Note: sessionId is actually the phone number for visitor OTP
    try {
      final response = await _dio.post(
        '/eblood-connect/users/visitor-send-phone-otp',
        data: {
          'phone_number': sessionId,
          if (appSignature != null) 'app_signature': appSignature,
        },
      );

      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      print('VisitorRegistrationService.resendOtp error: $e');
      return false;
    }
  }
}
