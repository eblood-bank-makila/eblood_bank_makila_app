import 'dart:convert';
import 'dart:io';
import 'package:eblood_bank_mak_app/apps/config/api/dio_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_storage/get_storage.dart';
import 'package:path/path.dart' as path;
import '../config/AppConfig.dart';
import '../constants/api_constants.dart';
import '../models/UserInfoValidation.dart';
import '../models/api_response.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:eblood_bank_mak_app/core/rbac/providers/rbac_provider.dart';
import 'package:eblood_bank_mak_app/core/rbac/data/rbac_local_storage.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:path_provider/path_provider.dart';
import 'AuthApi.dart';

class AuthService {
  final String baseApiUrl = AppConfig.instance.baseApiUrl;

  static const String _deviceNotAllowedInfoKey = 'device_not_allowed_info';
  static const String _canNavigateToDeviceNotAllowedKey = 'can_navigate_to_device_not_allowed';

  static const String _logoutEndpoint = '/auth/logout';
   // Secure storage for sensitive data
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final GetStorage _storage = GetStorage();

  String _normalizeEndpoint(String endpoint) {
    if (endpoint.isEmpty) {
      return endpoint;
    }

    final trimmedEndpoint = endpoint.trim();
    final normalizedBase = baseApiUrl.endsWith('/')
        ? baseApiUrl.substring(0, baseApiUrl.length - 1)
        : baseApiUrl;

    if (trimmedEndpoint.startsWith(normalizedBase)) {
      final suffix = trimmedEndpoint.substring(normalizedBase.length);
      if (suffix.isEmpty) {
        return '/';
      }
      return suffix.startsWith('/') ? suffix : '/$suffix';
    }

    if (trimmedEndpoint.startsWith('http')) {
      final uri = Uri.parse(trimmedEndpoint);
      final baseUri = Uri.parse(normalizedBase);
      var path = uri.path;
      if (baseUri.path.isNotEmpty && path.startsWith(baseUri.path)) {
        path = path.substring(baseUri.path.length);
      }
      if (!path.startsWith('/')) {
        path = '/$path';
      }
      final query = uri.hasQuery ? '?${uri.query}' : '';
      return '$path$query';
    }

    return trimmedEndpoint.startsWith('/') ? trimmedEndpoint : '/$trimmedEndpoint';
  }

  // Store auth token for subsequent requests (both secure and fast cache)
  Future<void> setAuthToken(String token) async {
    try {
      await _secureStorage.write(key: 'auth_token', value: token);
      await _storage.write('auth_token', token);
      debugPrint('🔐 Auth token saved');
    } catch (e) {
      debugPrint('Error saving auth token: $e');
    }
  }

  // Handle complete auto-login after Google registration/login (save token + user profile)
  // This mimics the OTP validation success flow
  Future<void> handleAutoLoginAfterRegistration(Map<String, dynamic> registrationResponse) async {
    try {
      debugPrint('🔄 handleAutoLoginAfterRegistration called');
      debugPrint('📦 Response structure: ${registrationResponse.keys}');

      final data = registrationResponse['data'] as Map<String, dynamic>?;
      final accessToken = data?['access_token'] as String?;
      final userObj = data?['user'] as Map<String, dynamic>?;
      final profilsRaw = data?['user_profils'];

      debugPrint('🔑 Access token present: ${accessToken != null && accessToken.isNotEmpty}');
      debugPrint('👤 User object present: ${userObj != null}');

      if (accessToken != null && accessToken.isNotEmpty) {
        // Save token to both secure storage and fast cache
        debugPrint('💾 Saving token to auth_token key...');
        await setAuthToken(accessToken);
        debugPrint('✅ Token saved to auth_token');

        // Also save to the OTP token key for compatibility with existing auth flow
        // This is what OtpCodeCtrl does after successful OTP validation
        await _secureStorage.write(key: 'OTP_TOKENKey', value: accessToken);
        debugPrint('✅ Token saved to OTP_TOKENKey');

        // Verify token was saved
        final savedToken = await _secureStorage.read(key: 'auth_token');
        debugPrint('🔍 Verification - Token in secure storage: ${savedToken != null && savedToken.isNotEmpty}');

        // Save user data to GetStorage for immediate access
        if (userObj != null) {
          await _storage.write('user_data', userObj);
          debugPrint('✅ User data saved to GetStorage');

          // Store socket hash if available
          final socketHash = userObj['user_account_socket_hash'];
          if (socketHash != null && socketHash.toString().isNotEmpty) {
            await _storage.write('socket_hash', socketHash);
            debugPrint('✅ Socket hash saved: $socketHash');
          }
        }

        // Store user profiles for routing compatibility
        if (profilsRaw is List) {
          debugPrint('📥 Google auth - storing profiles: $profilsRaw');
          await _storage.write('user_profils', profilsRaw);
          await _storage.write('user_profiles', profilsRaw); // legacy key
          debugPrint('💾 Stored user_profils with ${profilsRaw.length} entries');
        }

        debugPrint('✅ Auto-login token and user data saved to GetStorage');

        // CRITICAL: Fetch and save user profile to Sembast database
        // This is what ProfileCtrl expects to find
        try {
          debugPrint('🔄 Fetching user profile from network...');
          final authApi = AuthApi.instance;
          final userProfile = await authApi.getUserProfile();
          if (userProfile != null) {
            debugPrint('✅ User profile fetched and saved to Sembast: ${userProfile.uPrenom} ${userProfile.uNom}');
          } else {
            debugPrint('⚠️ Failed to fetch user profile from network');
          }
        } catch (e) {
          debugPrint('⚠️ Error fetching user profile: $e');
          // Non-fatal: ProfileCtrl will try to fetch it again
        }
      } else {
        debugPrint('⚠️ No access token found in registration response');
        debugPrint('📦 Data object: $data');
      }
    } catch (e, stackTrace) {
      debugPrint('⚠️ Error handling auto-login: $e');
      debugPrint('📍 Stack trace: $stackTrace');
      // Non-fatal: navigation can still proceed
    }
  }


  // Register a new user
  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      final registrationEndpoint = _normalizeEndpoint(ApiConstants.USERS_REGISTER);

      print('🔄 Registering user at: $registrationEndpoint');
      print('📦 Registration data: ${jsonEncode(userData)}');

      if (baseApiUrl.isEmpty) {
        print('⚠️ Base API URL is empty! Check your .env file.');
        return {
          'success': false,
          'message': 'API URL configuration is missing. Please contact support.',
        };
      }

      final response = await postWithDio(
        registrationEndpoint,
        body: userData,
        headers: const {'Content-Type': 'application/json'},
        timeoutDuration: const Duration(seconds: 30),
      );

      print('📊 Registration response: $response');

      if (response.success) {
        return {
          'success': true,
          'data': response.data,
          'message': response.message ?? 'Registration successful',
          'phoneNumber': userData['phone_number'],
          'email': userData['email'],
          'statusCode': response.statusCode ?? 200,
        };
      }

      final raw = response.raw;
      final errors = raw is Map<String, dynamic> ? raw['errors'] : null;
      return {
        'success': false,
        'data': response.data,
        'errors': errors,
        'message': response.message ?? 'Registration failed',
        'statusCode': response.statusCode ?? 500,
      };
    } catch (e) {
      print('⚠️ Registration error: $e');
      return {
        'success': false,
        'message': 'Error occurred during registration: $e',
      };
    }
  }

  // Generic social provider registration; provider examples: google, facebook, apple
  Future<Map<String, dynamic>> socialRegister(String provider, Map<String, dynamic> userData) async {
    try {
      // Decide endpoint based on account type
      final bool isHealthStructure = (userData['account_type'] == 'health_structure') || userData.containsKey('health_structure');
      final endpointUrl = isHealthStructure
          ? ApiConstants.healthStructureSocialRegister(provider)
          : ApiConstants.userSocialRegister(provider);
      final endpoint = _normalizeEndpoint(endpointUrl);

      print('🔄 Social($provider) registering user (healthStructure=$isHealthStructure) at: $endpoint');
      print('📦 Social registration data: ${jsonEncode(userData)}');

      if (baseApiUrl.isEmpty) {
        return {
          'success': false,
          'message': 'API URL configuration is missing. Please contact support.'
        };
      }

      final response = await postWithDio(
        endpoint,
        body: userData,
        headers: const {'Content-Type': 'application/json'},
        timeoutDuration: const Duration(seconds: 30),
      );

      final String prettyProvider = provider.isEmpty ? 'Provider' : provider[0].toUpperCase() + provider.substring(1);
      print('� Social($provider) registration response: $response');

      if (response.success) {
        return {
          'success': true,
          'data': response.data,
          'message': response.message ?? '$prettyProvider registration successful',
          'statusCode': response.statusCode ?? 200,
        };
      }

      final raw = response.raw;
      final message = response.message ??
          (raw is Map<String, dynamic> ? raw['message']?.toString() : null) ??
          '$prettyProvider registration failed';
      return {
        'success': false,
        'data': response.data,
        'errors': raw is Map<String, dynamic> ? raw['errors'] : null,
        'message': message,
        'statusCode': response.statusCode ?? 500,
      };
    } catch (e) {
      print('⚠️ Social($provider) registration error: $e');
      final String prettyProvider = provider.isEmpty ? 'Provider' : provider[0].toUpperCase() + provider.substring(1);
      return {'success': false, 'message': 'Error during $prettyProvider registration: $e'};
    }
  }

  // Backward compatible googleRegister using generic handler
  Future<Map<String, dynamic>> googleRegister(Map<String, dynamic> userData) {
    return socialRegister('google', userData);
  }

  // Google Login - authenticate existing user with Google
  Future<Map<String, dynamic>> googleLogin(Map<String, dynamic> loginData) async {
    try {
      final endpoint = _normalizeEndpoint('$baseApiUrl/eblood-connect/users/google/login');

      print('🔄 Google login at: $endpoint');
      print('📤 Login data: ${jsonEncode(loginData)}');

      final response = await postWithDio(
        endpoint,
        body: loginData,
        headers: const {'Content-Type': 'application/json'},
        timeoutDuration: const Duration(seconds: 30),
      );

      print('📊 Google login response: $response');

      if (response.success) {
        return {
          'success': true,
          'data': response.data,
          'message': response.message ?? 'Google login successful',
          'statusCode': response.statusCode ?? 200,
        };
      }

      final raw = response.raw;
      final message = response.message ??
          (raw is Map<String, dynamic> ? raw['message']?.toString() : null) ??
          'Google login failed';
      return {
        'success': false,
        'data': response.data,
        'errors': raw is Map<String, dynamic> ? raw['errors'] : null,
        'message': message,
        'statusCode': response.statusCode ?? 500,
      };
    } catch (e) {
      print('⚠️ Google login error: $e');
      return {'success': false, 'message': 'Error during Google login: $e'};
    }
  }

  // Register as benevol donor (volunteer donor)
  Future<IApiResponse> registerBenevolDonor(Map<String, dynamic> donorData) async {
    try {
      print('🔄 Registering benevol donor with payload: ${jsonEncode(donorData)}');
      final response = await postWithDio(
        '/eblood-connect/blood-donors/become-volonteer-register',
        body: donorData,
        timeoutDuration: const Duration(seconds: 60),
      );
      print('📊 Benevol registration response: $response');
      return response;
    } catch (e) {
      print('⚠️ Benevol donor registration error: $e');
      return IApiResponse.error(
        'Error during benevol donor registration: $e',
        statusCode: 500,
      );
    }
  }

  // Upload volunteer donor profile photo
  Future<IApiResponse> uploadVolunteerDonorPhoto(String sysDonorId, File photo) async {
    try {
      print('🔄 Uploading volunteer donor photo for sys_donor_id: $sysDonorId');

      final response = await uploadFile(
        path: photo.path,
        filename: path.basename(photo.path),
        endpoint: '/eblood-connect/blood-donors/profil-photo-upload-volonteer',
        extraData: {'id': sysDonorId},
        fileFieldName: 'upload_file',
        timeoutDuration: const Duration(seconds: 60),
      );

      print('📊 Photo upload response: $response');
      return response;
    } catch (e) {
      print('⚠️ Volunteer donor photo upload error: $e');
      return IApiResponse.error(
        'Error uploading volunteer donor photo: $e',
        statusCode: 500,
      );
    }
  }

  // Register as donor (non-volunteer)
  Future<IApiResponse> registerDonor(Map<String, dynamic> donorData) async {
    try {
      print('🔄 Registering donor with payload: ${jsonEncode(donorData)}');
      final response = await postWithDio(
        '/eblood-connect/blood-donors/become-donor-register',
        body: donorData,
        timeoutDuration: const Duration(seconds: 60),
      );
      print('📊 Donor registration response: $response');
      return response;
    } catch (e) {
      print('⚠️ Donor registration error: $e');
      return IApiResponse.error(
        'Error during donor registration: $e',
        statusCode: 500,
      );
    }
  }

  // Upload donor profile photo (non-volunteer)
  Future<IApiResponse> uploadDonorPhoto(String sysDonorId, File photo) async {
    try {
      print('🔄 Uploading donor photo for sys_donor_id: $sysDonorId');

      final response = await uploadFile(
        path: photo.path,
        filename: path.basename(photo.path),
        endpoint: '/eblood-connect/blood-donors/profil-photo-upload',
        extraData: {'id': sysDonorId},
        fileFieldName: 'upload_file',
        timeoutDuration: const Duration(seconds: 60),
      );
      print('📊 Donor photo upload response: $response');
      return response;
    } catch (e) {
      print('⚠️ Donor photo upload error: $e');
      return IApiResponse.error(
        'Error uploading donor photo: $e',
        statusCode: 500,
      );
    }
  }


  // Fetch INS request initialization data
  Future<IApiResponse> fetchInsRequestInitInfo() async {
    try {
      print('🔄 Fetching INS request initialization data');

      // Sprint 14 — migrated to the institution-requests module.
      final response = await getWithDio(
        '/institution-requests/get-form-init-data',
        timeoutDuration: const Duration(seconds: 30),
      );

      print('📊 INS init data response: $response');
      return response;
    } catch (e) {
      print('⚠️ INS init data fetch error: $e');
      return IApiResponse.error(
        'Error fetching INS init data: $e',
        statusCode: 500,
      );
    }
  }

  // Submit INS request
  Future<IApiResponse> submitInsRequest(Map<String, dynamic> requestData) async {
    try {
      print('🔄 Submitting INS request with payload: ${jsonEncode(requestData)}');
      // Sprint 14 — migrated to the institution-requests module.
      final response = await postWithDio(
        '/institution-requests/submit-request',
        body: requestData,
        timeoutDuration: const Duration(seconds: 60),
      );
      print('📊 INS request submission response: $response');
      return response;
    } catch (e) {
      print('⚠️ INS request submission error: $e');
      return IApiResponse.error(
        'Error submitting INS request: $e',
        statusCode: 500,
      );
    }
  }

  // Upload INS request photo (ID card image)
  Future<IApiResponse> uploadInsRequestIdPhoto(String sysInsRequestId, File idPhoto) async {
    try {
      print('🔄 Uploading INS request ID photo for sys_ins_request_id: $sysInsRequestId');

      final response = await uploadFile(
        path: idPhoto.path,
        filename: path.basename(idPhoto.path),
        // Sprint 14 — migrated to the institution-requests module.
        endpoint: '/institution-requests/upload-id-photo',
        extraData: {'id': sysInsRequestId},
        fileFieldName: 'upload_file',
        timeoutDuration: const Duration(seconds: 60),
      );

      print('📊 INS ID photo upload response: $response');
      return response;
    } catch (e) {
      print('⚠️ INS ID photo upload error: $e');
      return IApiResponse.error(
        'Error uploading INS ID photo: $e',
        statusCode: 500,
      );
    }
  }

  // Upload INS request face photo
  Future<IApiResponse> uploadInsRequestFacePhoto(String sysInsRequestId, File facePhoto) async {
    try {
      print('🔄 Uploading INS request face photo for sys_ins_request_id: $sysInsRequestId');

      final response = await uploadFile(
        path: facePhoto.path,
        filename: path.basename(facePhoto.path),
        // Sprint 14 — migrated to the institution-requests module.
        endpoint: '/institution-requests/upload-face-photo',
        extraData: {'id': sysInsRequestId},
        fileFieldName: 'upload_file',
        timeoutDuration: const Duration(seconds: 60),
      );

      print('📊 INS face photo upload response: $response');
      return response;
    } catch (e) {
      print('⚠️ INS face photo upload error: $e');
      return IApiResponse.error(
        'Error uploading INS face photo: $e',
        statusCode: 500,
      );
    }
  }

  // Upload INS request profile photos (left and right)
  Future<IApiResponse> uploadInsRequestProfilePhoto(
    String sysInsRequestId,
    File profilePhoto,
    String side // 'left' or 'right'
  ) async {
    try {
      print('🔄 Uploading INS request $side profile photo for sys_ins_request_id: $sysInsRequestId');

      final response = await uploadFile(
        path: profilePhoto.path,
        filename: path.basename(profilePhoto.path),
        // Sprint 14 — migrated to the institution-requests module.
        endpoint: '/institution-requests/upload-profile-photo',
        extraData: {
          'id': sysInsRequestId,
          'side': side,
        },
        fileFieldName: 'upload_file',
        timeoutDuration: const Duration(seconds: 60),
      );

      print('📊 INS $side profile photo upload response: $response');
      return response;
    } catch (e) {
      print('⚠️ INS $side profile photo upload error: $e');
      return IApiResponse.error(
        'Error uploading INS $side profile photo: $e',
        statusCode: 500,
      );
    }
  }

  // Get my INS request (if any)
  Future<IApiResponse> getMyInsRequest() async {
    try {
      print('🔄 Fetching my INS request');
      // Sprint 14 — migrated to the institution-requests module
      // (note: also renamed get-my-ins-request → get-my-request).
      final response = await getWithDio(
        '/institution-requests/get-my-request',
        timeoutDuration: const Duration(seconds: 30),
      );
      print('📊 My INS request response: $response');
      return response;
    } catch (e) {
      print('⚠️ Error fetching my INS request: $e');
      return IApiResponse.error(
        'Error fetching my INS request: $e',
        statusCode: 500,
      );
    }
  }

  // Verify OTP code
  Future<Map<String, dynamic>> verifyOTP({
    required String phoneNumber,
    required String otpCode,
  }) async {
    try {
      final otpEndpoint = _normalizeEndpoint('$baseApiUrl/eblood/users/verify-email');

      print('🔄 Verifying OTP at: $otpEndpoint');

      final response = await postWithDio(
        otpEndpoint,
        body: {
          'phone_number': phoneNumber,
          'code': otpCode,
        },
        headers: const {'Content-Type': 'application/json'},
      );

      final raw = response.raw;
      String? token;
      if (response.data is Map<String, dynamic>) {
        final map = response.data as Map<String, dynamic>;
        token = (map['token'] ?? map['access_token'] ?? map['auth_token'])?.toString();
      }
      if (token == null && raw is Map<String, dynamic>) {
        final data = raw['data'];
        if (data is Map<String, dynamic>) {
          token = (data['token'] ?? data['access_token'] ?? data['auth_token'])?.toString();
        } else {
          token = (raw['token'] ?? raw['access_token'])?.toString();
        }
      }

      if (response.success) {
        print('✅ OTP verification successful');
        return {
          'success': true,
          'data': response.data ?? (raw is Map<String, dynamic> ? raw['data'] : raw),
          'message': response.message ?? 'OTP verification successful',
          'token': token,
          'statusCode': response.statusCode ?? 200,
        };
      }

      final message = response.message ??
          (raw is Map<String, dynamic> ? raw['message']?.toString() : null) ??
          'OTP verification failed';
      print('❌ OTP verification failed: $message');
      return {
        'success': false,
        'data': response.data,
        'message': message,
        'statusCode': response.statusCode ?? 500,
      };
    } catch (e) {
      print('⚠️ OTP verification error: $e');
      return {
        'success': false,
        'message': 'Error occurred during OTP verification: $e',
      };
    }
  }

  // Resend OTP
  Future<Map<String, dynamic>> resendOTP(String phoneNumber) async {
    try {
      final resendEndpoint = _normalizeEndpoint('$baseApiUrl/eblood/users/send-otp');

      print('🔄 Resending OTP to: $phoneNumber');

      final response = await postWithDio(
        resendEndpoint,
        body: {
          'phone_number': phoneNumber,
          'type': 'registration',
        },
        headers: const {'Content-Type': 'application/json'},
      );

      final raw = response.raw;

      if (response.success) {
        print('✅ OTP resent successfully');
        return {
          'success': true,
          'message': response.message ??
              (raw is Map<String, dynamic> ? raw['message']?.toString() : null) ??
              'OTP resent successfully',
          'statusCode': response.statusCode ?? 200,
        };
      }

      final message = response.message ??
          (raw is Map<String, dynamic> ? raw['message']?.toString() : null) ??
          'Failed to resend OTP';
      print('❌ Failed to resend OTP: $message');
      return {
        'success': false,
        'data': response.data,
        'message': message,
        'statusCode': response.statusCode ?? 500,
      };
    } catch (e) {
      print('⚠️ Error resending OTP: $e');
      return {
        'success': false,
        'message': 'Error occurred while resending OTP: $e',
      };
    }
  }

  // Validate user info before registration
  Future<Map<String, dynamic>> validateUserInfo(UserInfoValidation userInfo) async {
    try {
      final endpoint = _normalizeEndpoint('$baseApiUrl/generic/validate-user-infos');

      print('🔄 Validating user info at: $endpoint');
      print('📦 User info data: ${jsonEncode(userInfo.toJson())}');

      final response = await postWithDio(
        endpoint,
        body: userInfo.toJson(),
        headers: const {'Content-Type': 'application/json'},
        timeoutDuration: const Duration(seconds: 30),
      );

      final raw = response.raw;

      if (response.success) {
        print('✅ User info validation successful');
        return {
          'success': true,
          'data': response.data ?? (raw is Map<String, dynamic> ? raw['data'] : raw),
          'message': response.message ??
              (raw is Map<String, dynamic> ? raw['message']?.toString() : null) ??
              'User info validation successful',
          'statusCode': response.statusCode ?? 200,
        };
      }

      final message = response.message ??
          (raw is Map<String, dynamic> ? raw['message']?.toString() : null) ??
          'User info validation failed';
      print('❌ User info validation failed: $message');
      return {
        'success': false,
        'data': response.data,
        'errors': raw is Map<String, dynamic> ? raw['errors'] : null,
        'message': message,
        'statusCode': response.statusCode ?? 500,
      };
    } catch (e) {
      print('⚠️ User info validation error: $e');
      return {
        'success': false,
        'message': 'Error occurred during user info validation: $e',
      };
    }
  }

  // Verify validation code
  Future<Map<String, dynamic>> verifyValidationCode(UserValidationCodeVerification verificationData) async {
    try {
      final endpoint = _normalizeEndpoint('$baseApiUrl/generic/verify-user-validation-code');

      print('🔄 Verifying validation code at: $endpoint');
      print('📦 Verification data: ${jsonEncode(verificationData.toJson())}');

      final response = await postWithDio(
        endpoint,
        body: verificationData.toJson(),
        headers: const {'Content-Type': 'application/json'},
        timeoutDuration: const Duration(seconds: 30),
      );

      final raw = response.raw;

      if (response.success) {
        print('✅ Validation code verification successful');
        return {
          'success': true,
          'data': response.data ?? (raw is Map<String, dynamic> ? raw['data'] : raw),
          'message': response.message ??
              (raw is Map<String, dynamic> ? raw['message']?.toString() : null) ??
              'Validation code verification successful',
          'statusCode': response.statusCode ?? 200,
        };
      }

      final message = response.message ??
          (raw is Map<String, dynamic> ? raw['message']?.toString() : null) ??
          'Validation code verification failed';
      print('❌ Validation code verification failed: $message');
      return {
        'success': false,
        'data': response.data,
        'errors': raw is Map<String, dynamic> ? raw['errors'] : null,
        'message': message,
        'statusCode': response.statusCode ?? 500,
      };
    } catch (e) {
      print('⚠️ Validation code verification error: $e');
      return {
        'success': false,
        'message': 'Error occurred during validation code verification: $e',
      };
    }
  }

  /// Store device not allowed information
  Future<void> setDeviceNotAllowedInfo({
    required String token,
    required String message,
    required String supportEmail,
  }) async {
    try {
      final deviceInfo = {
        'token': token,
        'message': message,
        'support_email': supportEmail,
      };
      await _secureStorage.write(
        key: _deviceNotAllowedInfoKey,
        value: jsonEncode(deviceInfo),
      );
      debugPrint('Device not allowed info stored');
    } catch (e) {
      debugPrint('Error storing device not allowed info: $e');
    }
  }

  /// Get device not allowed information
  Future<Map<String, String>> getDeviceNotAllowedInfo() async {
    try {
      final infoJson = await _secureStorage.read(key: _deviceNotAllowedInfoKey);
      if (infoJson != null) {
        final info = jsonDecode(infoJson) as Map<String, dynamic>;
        return {
          'token': info['token']?.toString() ?? '',
          'message': info['message']?.toString() ?? '',
          'support_email': info['support_email']?.toString() ?? '',
        };
      }
    } catch (e) {
      debugPrint('Error getting device not allowed info: $e');
    }
    return {
      'token': '',
      'message': '',
      'support_email': '',
    };
  }

  /// Set navigation flag for device not allowed screen
  Future<void> setCanNavigateToDeviceNotAllowed(bool canNavigate) async {
    try {
      await _secureStorage.write(
        key: _canNavigateToDeviceNotAllowedKey,
        value: canNavigate.toString(),
      );
      debugPrint('Can navigate to device not allowed: $canNavigate');
    } catch (e) {
      debugPrint('Error setting navigation flag: $e');
    }
  }

  /// Check if can navigate to device not allowed screen
  Future<bool> canNavigateToDeviceNotAllowed() async {
    try {
      final canNavigate = await _secureStorage.read(key: _canNavigateToDeviceNotAllowedKey);
      return canNavigate == 'true';
    } catch (e) {
      debugPrint('Error checking navigation flag: $e');
      return false;
    }
  }

  /// Handle token encryption (placeholder - implement based on your needs)
  Future<void> handleTokenEncryption(String token, bool encrypt) async {
    try {
      if (encrypt) {
        // Implement token encryption logic
        await _secureStorage.write(key: 'encrypted_token', value: token);
      } else {
        // Implement token decryption or storage logic
        await _secureStorage.write(key: 'temp_token', value: token);
      }
      debugPrint('Token encryption handled: encrypt=$encrypt');
    } catch (e) {
      debugPrint('Error handling token encryption: $e');
    }
  }

  /// Clear device/account error information
  Future<void> clearDeviceAccountErrorInfo() async {
    try {
      await _secureStorage.delete(key: _deviceNotAllowedInfoKey);
      await _secureStorage.delete(key: _canNavigateToDeviceNotAllowedKey);
      await _secureStorage.delete(key: 'encrypted_token');
      await _secureStorage.delete(key: 'temp_token');
      debugPrint('Device/Account error info cleared');
    } catch (e) {
      debugPrint('Error clearing device/account error info: $e');
    }
  }

  /// Fetch nearby blood banks based on device location
  Future<Map<String, dynamic>> getNearbyBloodBanks({
    required double latitude,
    required double longitude,
    double radiusKm = 50.0,
    int limit = 10,
  }) async {
    try {
      final endpoint = _normalizeEndpoint('$baseApiUrl/eblood-connect/blood-donors/nearby-blood-banks');

      print('🔄 Fetching nearby blood banks at: $endpoint');
      print('📍 Location: latitude=$latitude, longitude=$longitude, radius=${radiusKm}km');

      final body = {
        'latitude': latitude,
        'longitude': longitude,
        'radius_km': radiusKm,
        'limit': limit,
      };

      final response = await postWithDio(
        endpoint,
        body: body,
        headers: const {'Content-Type': 'application/json'},
        timeoutDuration: const Duration(seconds: 30),
      );

      final raw = response.raw;

      if (response.success) {
        print('✅ Nearby blood banks fetched successfully');
        final dataPayload = response.data ?? (raw is Map<String, dynamic> ? raw['data'] : raw);
        return {
          'success': true,
          'data': dataPayload ?? [],
          'message': response.message ??
              (raw is Map<String, dynamic> ? raw['message']?.toString() : null) ??
              'Nearby blood banks fetched successfully',
          'statusCode': response.statusCode ?? 200,
        };
      }

      final message = response.message ??
          (raw is Map<String, dynamic> ? raw['message']?.toString() : null) ??
          'Failed to fetch nearby blood banks';
      print('❌ Failed to fetch nearby blood banks: $message');
      return {
        'success': false,
        'data': response.data,
        'errors': raw is Map<String, dynamic> ? raw['errors'] : null,
        'message': message,
        'statusCode': response.statusCode ?? 500,
      };
    } catch (e) {
      print('⚠️ Error fetching nearby blood banks: $e');
      return {
        'success': false,
        'message': 'Error occurred while fetching nearby blood banks: $e',
      };
    }
  }

   // Logout user
  Future<bool> logout({bool silent = false, BuildContext? context}) async {
    try {
      // ── Step 1: Clear ALL local data EXCEPT the access token ──
      // (access token is kept so the backend logout call can authenticate)

      // 1a. Clear RBAC local cache
      try {
        await RbacLocalStorage.instance.clearAll();
        debugPrint('🔐 [Logout] RBAC cache cleared');
      } catch (e) {
        debugPrint('⚠️ [Logout] RBAC cache clear failed: $e');
      }

      // 1b. Clear Sembast OTP tokens + user data
      try {
        final dir = await getApplicationDocumentsDirectory();
        final dbPath = path.join(dir.path, 'sembast.db');
        final db = await databaseFactoryIo.openDatabase(dbPath);
        final store = StoreRef.main();
        await store.record('TOKENKey').delete(db);
        await store.record('OTP_TOKENKey').delete(db);
        await store.record('UserKey').delete(db);
        debugPrint('🔐 [Logout] Sembast tokens cleared');
      } catch (e) {
        debugPrint('⚠️ [Logout] Sembast clear failed: $e');
      }

      // 1c. Clear GetStorage (except auth_token — needed for backend call)
      try {
        final storage = GetStorage();
        await storage.remove('refresh_token');
        await storage.remove('user_data');
        await storage.remove('user_profiles');
        await storage.remove('account_type');
        debugPrint('🔐 [Logout] GetStorage cleared (kept auth_token)');
      } catch (e) {
        debugPrint('⚠️ [Logout] GetStorage clear failed: $e');
      }

      // 1d. Sign out from Firebase Auth (Google Sign-In)
      try {
        final firebaseAuth = FirebaseAuth.instance;
        final googleSignIn = GoogleSignIn();
        await googleSignIn.signOut();
        await firebaseAuth.signOut();
        debugPrint('🔐 [Logout] Firebase sign-out done');
      } catch (e) {
        debugPrint('⚠️ [Logout] Firebase sign-out failed: $e');
      }

      // 1e. Reset RBAC in-memory state
      try {
        RbacNotifier.resetIfActive();
        debugPrint('🔐 [Logout] RBAC state reset');
      } catch (e) {
        debugPrint('⚠️ [Logout] RBAC reset failed: $e');
      }

      // ── Step 2: Call backend logout (auth_token still present) ──
      try {
        final connectivityResult = await Connectivity().checkConnectivity();
        if (connectivityResult != ConnectivityResult.none) {
          await Future.value(postWithDio(_logoutEndpoint))
              .timeout(const Duration(seconds: 5));
          debugPrint('🔐 [Logout] Backend logout called');
        }
      } catch (e) {
        debugPrint('⚠️ [Logout] Backend logout failed (non-blocking): $e');
      }

      // ── Step 3: Now clear the access token (last) ──
      final themeMode = await _secureStorage.read(key: 'theme_mode');
      final locale = await _secureStorage.read(key: 'app_locale');

      await _secureStorage.deleteAll();

      try {
        final storage = GetStorage();
        await storage.remove('auth_token');
      } catch (e) {
        debugPrint('⚠️ [Logout] auth_token clear failed: $e');
      }

      // Restore non-auth settings
      if (themeMode != null) {
        await _secureStorage.write(key: 'theme_mode', value: themeMode);
      }
      if (locale != null) {
        await _secureStorage.write(key: 'app_locale', value: locale);
      }
      debugPrint('🔐 [Logout] All tokens cleared');

      // Clear streams and reset to initial state
      // _accessTokenController.add(null);
      // _currentUserController.add(null);
      // _currentLoginMFas.add([]);
      // _currentSelectedLoginMFa.add(TMfaModel.empty());
      // _isAuthenticatedController.add(false);

      // Navigate to login screen if context is provided
      if (context != null && context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
          (route) => false,
        );
      }

      return true;
    } catch (e) {
      debugPrint('Logout error: $e');
      return false;
    } finally {
      // _isLoadingController.add(false);
    }
  }

  // Check if username is already taken
  Future<Map<String, dynamic>> checkUsernameTaken(String username) async {
    try {
      final endpoint = _normalizeEndpoint('$baseApiUrl/generic/check-username-taken');

      print('🔄 Checking username availability at: $endpoint');
      print('📦 Username: $username');

      if (baseApiUrl.isEmpty) {
        print('⚠️ Base API URL is empty! Check your .env file.');
        return {
          'valid': false,
          'username': username,
          'message': 'API URL configuration is missing.',
        };
      }

      final body = {
        'username': username,
      };

      final response = await postWithDio(
        endpoint,
        body: body,
        headers: const {'Content-Type': 'application/json'},
        timeoutDuration: const Duration(seconds: 30),
      );

      final raw = response.raw;

      if (response.success) {
        final payload = response.data ?? (raw is Map<String, dynamic> ? raw : null);
        return {
          'valid': payload is Map<String, dynamic> ? (payload['valid'] ?? false) : (raw is Map<String, dynamic> ? raw['valid'] ?? false : false),
          'username': payload is Map<String, dynamic>
              ? (payload['username'] ?? username)
              : (raw is Map<String, dynamic> ? raw['username'] ?? username : username),
          'message': response.message ??
              (raw is Map<String, dynamic> ? raw['message']?.toString() : null) ??
              'Username availability checked',
          'statusCode': response.statusCode ?? 200,
        };
      }

      final message = response.message ??
          (raw is Map<String, dynamic> ? raw['message']?.toString() : null) ??
          'Failed to check username availability';
      final errors = raw is Map<String, dynamic> ? raw['errors'] : null;

      return {
        'valid': false,
        'username': username,
        'errors': errors,
        'message': message,
        'statusCode': response.statusCode ?? 500,
      };
    } catch (e) {
      print('⚠️ Username check error: $e');
      return {
        'valid': false,
        'username': username,
        'message': 'Error checking username availability: $e',
      };
    }
  }

}