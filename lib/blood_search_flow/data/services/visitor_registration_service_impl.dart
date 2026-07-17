/// Visitor Registration Service Implementation

import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_storage/get_storage.dart';
import '../../domain/services/service_interfaces.dart';
import '../../domain/entities/search_flow_state.dart';
import '../../../apps/config/api/dio_client.dart';

class VisitorRegistrationServiceImpl implements IVisitorRegistrationService {
  final GetStorage _storage = GetStorage();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  VisitorRegistrationServiceImpl();

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

    // Also update backend to mark phone as verified
    try {
      // Sprint 16 — migrated from PUT /eblood-connect/users/update-visitor-phone
      // to POST /api/v1/auth/visitor/update-phone (clean public surface).
      await postWithDio(
        '/auth/visitor/update-phone',
        body: {'phone_number': phone, 'is_phone_verified': true},
      );
      print('✅ Updated visitor phone verification status on backend');
    } catch (e) {
      print('⚠️ Could not update phone verification on backend: $e');
      // Still proceed, local storage is updated
    }
  }

  /// Save identified hospital to local storage
  Future<void> saveIdentifiedHospital(IdentifiedHospital hospital) async {
    try {
      final hospitalJson = jsonEncode(hospital.toJson());
      await _storage.write('identified_hospital', hospitalJson);
      print('✅ Saved identified hospital: ${hospital.name}');
    } catch (e) {
      print('⚠️ Could not save identified hospital: $e');
    }
  }

  /// Get previously identified hospital from local storage
  Future<IdentifiedHospital?> getIdentifiedHospital() async {
    try {
      final hospitalJson = _storage.read('identified_hospital');
      if (hospitalJson != null && hospitalJson.toString().isNotEmpty) {
        final Map<String, dynamic> json = jsonDecode(hospitalJson);
        final methodName = json['method']?.toString() ?? 'manualCode';
        final method = HospitalIdentificationMethod.values.firstWhere(
          (e) => e.name == methodName,
          orElse: () => HospitalIdentificationMethod.manualCode,
        );
        return IdentifiedHospital.fromJson(json, method);
      }
      return null;
    } catch (e) {
      print('⚠️ Could not retrieve identified hospital: $e');
      return null;
    }
  }

  /// Check if there's a previously identified hospital
  Future<bool> hasIdentifiedHospital() async {
    final hospital = await getIdentifiedHospital();
    return hospital != null;
  }

  /// Clear the saved identified hospital
  Future<void> clearIdentifiedHospital() async {
    try {
      await _storage.remove('identified_hospital');
      print('✅ Cleared identified hospital');
    } catch (e) {
      print('⚠️ Could not clear identified hospital: $e');
    }
  }

  /// Check if device already has a visitor account linked (GET request)
  /// Returns: {success, needs_entity, needs_phone_verification, data}
  Future<Map<String, dynamic>?> checkVisitorLogin() async {
    try {
      // Sprint 16 — migrated from GET /eblood-connect/users/login-visitor to
      // POST /api/v1/auth/visitor/check-existing. The new surface is POST-only
      // for consistency with the rest of the kebab-case verb-noun convention.
      final response = await postWithDio('/auth/visitor/check-existing');

      // Accept successful response
      if (response.success || response.statusCode == 200 || response.statusCode == 201) {
        final data = <String, dynamic>{
          'success': response.success,
          'data': response.data,
          'message': response.message,
        };
        print('✅ Login visitor response: ${response.success}');
        if (response.success && response.data != null) {
          final responseData = response.data as Map<String, dynamic>;
          // Device already linked, save the token
          final token =
              responseData['access_token']?.toString() ??
              responseData['token']?.toString();
          if (token != null && token.isNotEmpty) {
            await _storage.write('visitor_token', token);
            await _storage.write('auth_token', token);
            await _storage.write('is_visitor', true);
            // Also save to FlutterSecureStorage so AuthInterceptor picks it up
            await _secureStorage.write(key: 'auth_token', value: token);
            print('✅ Token saved to both GetStorage and FlutterSecureStorage');
          }

          // Check if user has a real phone number (not fake)
          final user = responseData['user'];
          print('👤 User data from backend: ${user != null ? "exists" : "null"}');
          String? phoneNumber;
          bool? phoneVerified;
          bool? canPayOnDelivery;
          if (user != null) {
            phoneNumber =
                user['phone_number']?.toString() ??
                user['phoneNumber']?.toString() ??
                user['phone']?.toString();
            phoneVerified =
                user['phone_number_verified'] as bool? ??
                user['phoneNumberVerified'] as bool? ??
                user['is_phone_verified'] as bool?;
            canPayOnDelivery =
                user['can_pay_on_delivery'] as bool? ??
                user['canPayOnDelivery'] as bool?;

            print('📞 Phone from backend: $phoneNumber');
            print('✓ Phone verified from backend: $phoneVerified');
            print('💰 Can pay on delivery: $canPayOnDelivery');

            // Save these fields locally
            if (phoneVerified == true) {
              await _storage.write('visitor_phone_verified', true);
              if (phoneNumber != null && phoneNumber.isNotEmpty) {
                await _storage.write('visitor_phone', phoneNumber);
              }
            }
            if (canPayOnDelivery != null) {
              await _storage.write(
                'visitor_can_pay_on_delivery',
                canPayOnDelivery,
              );
            }
          }

          // Check if phone is fake (starts with +1- which is the fake format)
          final bool hasFakePhone =
              phoneNumber == null ||
              phoneNumber.isEmpty ||
              phoneNumber.startsWith('+1-') ||
              phoneNumber.contains('XXX');

          print('🎭 Has fake phone: $hasFakePhone');
          
          // If backend says phone is verified, trust it
          final bool isPhoneVerified = phoneVerified == true;
          print('✅ Is phone verified: $isPhoneVerified');

          // Add needs_phone_verification flag to response
          data['needs_phone_verification'] = hasFakePhone || !isPhoneVerified;
          data['phone_number_verified'] = phoneVerified;
          data['can_pay_on_delivery'] = canPayOnDelivery;

          print('📦 Returning result: ${data['success']}, needs_verification: ${data['needs_phone_verification']}');
          return data;
        }
        // needs_entity == true means user needs to provide location_id
        print('📦 Returning data as-is (needs_entity or other case)');
        return data;
      }
      print('⚠️ Response not successful: ${response.statusCode}');
      return null;
    } catch (e) {
      print('❌ VisitorRegistrationService.checkVisitorLogin error: $e');
      return null;
    }
  }

  /// Create visitor account with location_id (POST request)
  Future<Map<String, dynamic>?> createVisitorAccount({
    required String locationId,
  }) async {
    try {
      // Sprint 16 — migrated from POST /eblood-connect/users/login-visitor to
      // POST /api/v1/auth/visitor/create-visitor.
      final response = await postWithDio(
        '/auth/visitor/create-visitor',
        body: {'location_id': locationId},
      );

      if (response.success) {
        final responseData = response.data as Map<String, dynamic>?;
        if (responseData != null) {
          // Save the token to both storages
          final token =
              responseData['access_token']?.toString() ??
              responseData['token']?.toString();
          if (token != null && token.isNotEmpty) {
            await _storage.write('visitor_token', token);
            await _storage.write('auth_token', token);
            await _storage.write('is_visitor', true);
            // Also save to FlutterSecureStorage so AuthInterceptor picks it up
            await _secureStorage.write(key: 'auth_token', value: token);
            print('✅ Token saved to both GetStorage and FlutterSecureStorage');
          }

          // New visitor always needs phone verification
          final result = <String, dynamic>{
            'success': true,
            'data': responseData,
            'needs_phone_verification': true,
          };

          return result;
        }
        return {'success': response.success, 'data': response.data};
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
  Future<OtpSendResult> sendOtp(String sessionId, {String? appSignature}) async {
    // Note: sessionId is actually the phone number for visitor OTP
    try {
      final response = await postWithDio(
        '/auth/visitor/send-phone-otp',
        body: {
          'phone_number': sessionId,
          if (appSignature != null) 'app_signature': appSignature,
        },
      );

      return OtpSendResult(
        success: response.success,
        expiryMinutes: _parseExpiryMinutes(response.data),
      );
    } catch (e) {
      print('VisitorRegistrationService.sendOtp error: $e');
      return const OtpSendResult(success: false);
    }
  }

  /// Pull the backend's `otp_expiry_minutes` out of the response payload.
  /// Tolerates int, num or String so a backend serialisation change doesn't
  /// silently drop the value and leave the SMS listener running forever.
  int? _parseExpiryMinutes(dynamic data) {
    if (data is! Map) return null;
    final raw = data['otp_expiry_minutes'];
    if (raw is int) return raw;
    if (raw is num) return raw.toInt();
    if (raw is String) return int.tryParse(raw);
    return null;
  }

  /// Send OTP to phone number (for visitor phone verification)
  Future<bool> sendPhoneOtp(String phoneNumber, {String? appSignature}) async {
    try {
      final response = await postWithDio(
        '/auth/visitor/send-phone-otp',
        body: {
          'phone_number': phoneNumber,
          if (appSignature != null) 'app_signature': appSignature,
        },
      );

      return response.success;
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

      final response = await postWithDio(
        '/auth/visitor/verify-phone-otp',
        body: {'phone_number': sessionId, 'otp_code': otpCode},
      );

      print(
        '📬 OTP verify response: ${response.statusCode} - ${response.success}',
      );

      if (response.success) {
        // Phone verified, return the phone number as confirmation
        return sessionId;
      }
      print('⚠️ OTP verification failed: success=${response.success}');
      return null;
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
      final response = await postWithDio(
        '/auth/visitor/verify-phone-otp',
        body: {'phone_number': phoneNumber, 'otp_code': otpCode},
      );

      return response.success;
    } catch (e) {
      print('VisitorRegistrationService.verifyPhoneOtp error: $e');
      return false;
    }
  }

  @override
  Future<bool> resendOtp(String sessionId, {String? appSignature}) async {
    // Note: sessionId is actually the phone number for visitor OTP
    try {
      final response = await postWithDio(
        '/auth/visitor/send-phone-otp',
        body: {
          'phone_number': sessionId,
          if (appSignature != null) 'app_signature': appSignature,
        },
      );

      return response.success;
    } catch (e) {
      print('VisitorRegistrationService.resendOtp error: $e');
      return false;
    }
  }
}
