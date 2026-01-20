/// Visitor Registration Service Implementation

import 'package:dio/dio.dart';
import '../../domain/services/service_interfaces.dart';
import '../../../core/network/dio_client.dart';

class VisitorRegistrationServiceImpl implements IVisitorRegistrationService {
  late final Dio _dio;

  VisitorRegistrationServiceImpl() {
    _dio = DioClient().dio;
  }

  @override
  Future<String> registerVisitor({
    required String phoneNumber,
    required String hospitalId,
    String? locationId,
  }) async {
    try {
      final response = await _dio.post(
        '/eblood-connect/users/register-visitor',
        data: {
          'phone_number': phoneNumber,
          'hospital_id': hospitalId,
          if (locationId != null) 'location_id': locationId,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data['success'] == true) {
          return data['data']['session_id']?.toString() ?? 
                 data['session_id']?.toString() ?? 
                 '';
        }
        throw Exception(data['message'] ?? 'Registration failed');
      }
      throw Exception('Registration failed with status ${response.statusCode}');
    } catch (e) {
      print('VisitorRegistrationService.registerVisitor error: $e');
      rethrow;
    }
  }

  @override
  Future<bool> sendOtp(String sessionId) async {
    try {
      final response = await _dio.post(
        '/eblood/auth/send-otp',
        data: {'session_id': sessionId},
      );

      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      print('VisitorRegistrationService.sendOtp error: $e');
      return false;
    }
  }

  @override
  Future<String?> verifyOtp({
    required String sessionId,
    required String otpCode,
  }) async {
    try {
      final response = await _dio.post(
        '/eblood/auth/validate-otp',
        data: {
          'session_id': sessionId,
          'otp_code': otpCode,
        },
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        return data['token']?.toString() ?? 
               data['access_token']?.toString();
      }
      return null;
    } catch (e) {
      print('VisitorRegistrationService.verifyOtp error: $e');
      return null;
    }
  }

  @override
  Future<bool> resendOtp(String sessionId) async {
    try {
      final response = await _dio.post(
        '/eblood/auth/resend-otp',
        data: {'session_id': sessionId},
      );

      return response.statusCode == 200 && response.data['success'] == true;
    } catch (e) {
      print('VisitorRegistrationService.resendOtp error: $e');
      return false;
    }
  }
}
