import 'dart:convert';
import 'package:eblood_bank_mak_app/apps/config/api/dio_client.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../config/AppConfig.dart';
import '../services/HttpInterceptorService.dart';
import '../constants/api_constants.dart';
import '../models/UserInfoValidation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class AuthService {
  final HttpInterceptorService _httpInterceptor = HttpInterceptorService();
  final String baseApiUrl = AppConfig.instance.baseApiUrl;

  static const String _deviceNotAllowedInfoKey = 'device_not_allowed_info';
  static const String _canNavigateToDeviceNotAllowedKey = 'can_navigate_to_device_not_allowed';

  static const String _logoutEndpoint = '/auth/logout';
   // Secure storage for sensitive data
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  
  // Register a new user
  Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    try {
      // Using the HTTP interceptor to get proper headers
      final headers = await _httpInterceptor.getHeaders();
      headers['Content-Type'] = 'application/json';
      
      // Using the correct endpoint from the API endpoint file
    final registrationEndpoint = ApiConstants.USERS_REGISTER;
      
      print('🔄 Registering user at: $registrationEndpoint');
      print('📦 Registration data: ${jsonEncode(userData)}');
      print('🔑 Headers: ${headers.toString()}');
      
      // Validate the URL is properly formed
      if (baseApiUrl.isEmpty) {
        print('⚠️ Base API URL is empty! Check your .env file.');
        return {
          'success': false,
          'message': 'API URL configuration is missing. Please contact support.',
        };
      }
      
      try {
        final response = await http.post(
          Uri.parse(registrationEndpoint),
          headers: headers,
          body: jsonEncode(userData),
        ).timeout(
          const Duration(seconds: 30),
          onTimeout: () {
            print('⏱️ Registration request timed out');
            throw Exception('Registration request timed out');
          },
        );
        
        print('📊 Response status code: ${response.statusCode}');
        print('📄 Response body: ${response.body}');
        
        // Check if the response body is valid JSON
        if (response.body.isEmpty) {
          print('⚠️ Empty response received');
          return {
            'success': false,
            'message': 'Server returned an empty response',
          };
        }
        
        Map<String, dynamic> jsonData;
        try {
          jsonData = jsonDecode(response.body);
        } catch (jsonError) {
          print('⚠️ Invalid JSON response: ${response.body}');
          return {
            'success': false,
            'message': 'Server returned an invalid response format',
          };
        }
        
        if (response.statusCode == 200 || response.statusCode == 201) {
          print('✅ Registration successful');
          // Check if we have a standard success response structure
          final bool isSuccess = jsonData['success'] == true ||
              jsonData['status'] == 'success' ||
              (jsonData['status_code'] != null && (jsonData['status_code'] == 200 || jsonData['status_code'] == 201));
          
          // Based on your specific backend response: {"success":true,"status_code":200,"message":"...", "data":null}
          if (isSuccess) {
            return {
              'success': true,
              'data': jsonData['data'],
              'message': jsonData['message'] ?? 'Registration successful',
              'phoneNumber': userData['phone_number'],
              'email': userData['email'],
            };
          } else {
            print('⚠️ Unexpected success response format: $jsonData');
            return {
              'success': true, // Still consider it success based on HTTP status
              'data': jsonData,
              'message': 'Registration request processed',
              'phoneNumber': userData['phone_number'],
              'email': userData['email'],
            };
          }
        } else {
          print('❌ Registration failed: ${jsonData['message'] ?? 'Unknown error'}');
          return {
            'success': false,
            'message': jsonData['message'] ?? jsonData['error'] ?? 'Registration failed',
            'errors': jsonData['errors'],
            'statusCode': response.statusCode,
          };
        }
      } catch (httpError) {
        print('🔴 HTTP Request Error: $httpError');
        return {
          'success': false,
          'message': 'Network error: $httpError',
        };
      }
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
      final headers = await _httpInterceptor.getHeaders();
      headers['Content-Type'] = 'application/json';
      // Decide endpoint based on account type
      final bool isHealthStructure = (userData['account_type'] == 'health_structure') || userData.containsKey('health_structure');
      final endpoint = isHealthStructure
          ? ApiConstants.healthStructureSocialRegister(provider)
          : ApiConstants.userSocialRegister(provider);
      print('🔄 Social($provider) registering user (healthStructure=$isHealthStructure) at: $endpoint');
      print('📦 Social registration data: ${jsonEncode(userData)}');

      if (baseApiUrl.isEmpty) {
        return {
          'success': false,
          'message': 'API URL configuration is missing. Please contact support.'
        };
      }

      final response = await http.post(
        Uri.parse(endpoint),
        headers: headers,
        body: jsonEncode(userData),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception('Google registration timed out'),
      );

  print('📊 Social($provider) registration status: ${response.statusCode}');
  print('📄 Social($provider) registration body: ${response.body}');

      if (response.body.isEmpty) {
        return {'success': false, 'message': 'Empty response from server'};
      }
      Map<String, dynamic> jsonData;
      try {
        jsonData = jsonDecode(response.body);
      } catch (e) {
        return {'success': false, 'message': 'Invalid JSON from server'};
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        final bool isSuccess = jsonData['success'] == true ||
            jsonData['status'] == 'success' ||
            (jsonData['status_code'] != null && (jsonData['status_code'] == 200 || jsonData['status_code'] == 201));
  final String prettyProvider = provider.isEmpty ? 'Provider' : provider[0].toUpperCase() + provider.substring(1);
  if (isSuccess) {
          return {
            'success': true,
            'data': jsonData['data'],
            'message': jsonData['message'] ?? '$prettyProvider registration successful',
          };
        } else {
          return {
            'success': false,
            'message': jsonData['message'] ?? '$prettyProvider registration failed',
          };
        }
      }
      final String prettyProvider = provider.isEmpty ? 'Provider' : provider[0].toUpperCase() + provider.substring(1);
      return {
        'success': false,
        'message': jsonData['message'] ?? '$prettyProvider registration failed',
        'statusCode': response.statusCode,
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
  
  // Verify OTP code
  Future<Map<String, dynamic>> verifyOTP({
    required String phoneNumber,
    required String otpCode,
  }) async {
    try {
      final headers = await _httpInterceptor.getHeaders();
      headers['Content-Type'] = 'application/json';
      
      // Using the correct endpoint for OTP verification
      final otpEndpoint = '$baseApiUrl/eblood/users/verify-email';
      
      print('🔄 Verifying OTP at: $otpEndpoint');
      
      final body = {
        'phone_number': phoneNumber,
        'code': otpCode, // Using 'code' as the parameter name based on the API endpoint
      };
      
      final response = await http.post(
        Uri.parse(otpEndpoint),
        headers: headers,
        body: jsonEncode(body),
      );
      
      print('📊 OTP verification status code: ${response.statusCode}');
      final jsonData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        print('✅ OTP verification successful');
        return {
          'success': true,
          'data': jsonData['data'] ?? jsonData,
          'message': jsonData['message'] ?? 'OTP verification successful',
          'token': jsonData['data']?['token'] ?? jsonData['token'],
        };
      } else {
        print('❌ OTP verification failed: ${jsonData['message']}');
        return {
          'success': false,
          'message': jsonData['message'] ?? 'OTP verification failed',
        };
      }
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
      final headers = await _httpInterceptor.getHeaders();
      headers['Content-Type'] = 'application/json';
      
      // Using the correct endpoint for resending OTP
      final resendEndpoint = '$baseApiUrl/eblood/users/send-otp';
      
      print('🔄 Resending OTP to: $phoneNumber');
      
      final body = {
        'phone_number': phoneNumber,
        'type': 'registration', // Specify the purpose of the OTP
      };
      
      final response = await http.post(
        Uri.parse(resendEndpoint),
        headers: headers,
        body: jsonEncode(body),
      );
      
      print('📊 Resend OTP status code: ${response.statusCode}');
      final jsonData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        print('✅ OTP resent successfully');
        return {
          'success': true,
          'message': jsonData['message'] ?? 'OTP resent successfully',
        };
      } else {
        print('❌ Failed to resend OTP: ${jsonData['message']}');
        return {
          'success': false,
          'message': jsonData['message'] ?? 'Failed to resend OTP',
        };
      }
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
      final headers = await _httpInterceptor.getHeaders();
      headers['Content-Type'] = 'application/json';
      
      final endpoint = '$baseApiUrl/generic/validate-user-infos';
      
      print('🔄 Validating user info at: $endpoint');
      print('📦 User info data: ${jsonEncode(userInfo.toJson())}');
      
      final response = await http.post(
        Uri.parse(endpoint),
        headers: headers,
        body: jsonEncode(userInfo.toJson()),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('⏱️ User validation request timed out');
          throw Exception('User validation request timed out');
        },
      );
      
      print('📊 Response status code: ${response.statusCode}');
      print('📄 Response body: ${response.body}');
      
      if (response.body.isEmpty) {
        print('⚠️ Empty response received');
        return {
          'success': false,
          'message': 'Server returned an empty response',
        };
      }
      
      Map<String, dynamic> jsonData;
      try {
        jsonData = jsonDecode(response.body);
      } catch (jsonError) {
        print('⚠️ Invalid JSON response: ${response.body}');
        return {
          'success': false,
          'message': 'Server returned an invalid response format',
        };
      }
      
      if (response.statusCode == 200) {
        print('✅ User info validation successful');
        return {
          'success': true,
          'data': jsonData['data'] ?? jsonData,
          'message': jsonData['message'] ?? 'User info validation successful',
        };
      } else {
        print('❌ User info validation failed: ${jsonData['message'] ?? 'Unknown error'}');
        return {
          'success': false,
          'message': jsonData['message'] ?? jsonData['error'] ?? 'User info validation failed',
          'errors': jsonData['errors'],
          'statusCode': response.statusCode,
        };
      }
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
      final headers = await _httpInterceptor.getHeaders();
      headers['Content-Type'] = 'application/json';
      
      final endpoint = '$baseApiUrl/generic/verify-user-validation-code';
      
      print('🔄 Verifying validation code at: $endpoint');
      print('📦 Verification data: ${jsonEncode(verificationData.toJson())}');
      
      final response = await http.post(
        Uri.parse(endpoint),
        headers: headers,
        body: jsonEncode(verificationData.toJson()),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          print('⏱️ Verification request timed out');
          throw Exception('Verification request timed out');
        },
      );
      
      print('📊 Response status code: ${response.statusCode}');
      print('📄 Response body: ${response.body}');
      
      if (response.body.isEmpty) {
        print('⚠️ Empty response received');
        return {
          'success': false,
          'message': 'Server returned an empty response',
        };
      }
      
      Map<String, dynamic> jsonData;
      try {
        jsonData = jsonDecode(response.body);
      } catch (jsonError) {
        print('⚠️ Invalid JSON response: ${response.body}');
        return {
          'success': false,
          'message': 'Server returned an invalid response format',
        };
      }
      
      if (response.statusCode == 200) {
        print('✅ Validation code verification successful');
        
        // Check for success field in different formats that might come from the backend
        final bool isSuccess = jsonData['success'] == true || 
                            jsonData['status'] == 'success' ||
                            (jsonData['status_code'] != null && jsonData['status_code'] == 200);
                            
        if (isSuccess) {
          return {
            'success': true,
            'data': jsonData['data'] ?? jsonData,
            'message': jsonData['message'] ?? 'Validation code verification successful',
          };
        } else {
          // This handles the case where we get a 200 status code but the response indicates failure
          print('⚠️ Backend returned 200 but with failure indication: $jsonData');
          return {
            'success': false,
            'message': jsonData['message'] ?? 'Validation failed despite 200 status code',
          };
        }
      } else {
        print('❌ Validation code verification failed: ${jsonData['message'] ?? 'Unknown error'}');
        return {
          'success': false,
          'message': jsonData['message'] ?? jsonData['error'] ?? 'Validation code verification failed',
          'errors': jsonData['errors'],
          'statusCode': response.statusCode,
        };
      }
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

   // Logout user
  Future<bool> logout({bool silent = false, BuildContext? context}) async {
    try {
      // _isLoadingController.add(true);

      // Cancel token refresh timer
      // _tokenRefreshTimer?.cancel();

        try {
          final connectivityResult = await Connectivity().checkConnectivity();
          if (connectivityResult != ConnectivityResult.none) {
            await postWithDio(
              _logoutEndpoint,
              
            );
          }
        } catch (e) {
          debugPrint('Error during logout API call: $e');
          // Continue with local logout even if API call fails
        }

      // Preserve non-auth related settings before clearing storage
      final themeMode = await _secureStorage.read(key: 'theme_mode');
      final locale = await _secureStorage.read(key: 'app_locale');

      // Clear ALL secure storage data (including TOTP accounts and signatures)
      await _secureStorage.deleteAll();

      // Clear database tokens and all related data

      // Clear TOTP accounts and signature data specifically


      // Clear additional auth-related data

      // Restore non-auth related settings if needed
      if (themeMode != null) {
        await _secureStorage.write(key: 'theme_mode', value: themeMode);
      }
      if (locale != null) {
        await _secureStorage.write(key: 'app_locale', value: locale);
      }

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

}