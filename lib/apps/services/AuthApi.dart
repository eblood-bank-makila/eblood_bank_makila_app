import 'package:dio/dio.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

// Use the improved Dio client that is initialized at app startup
import '../../core/network/dio_client_improved.dart';
import '../../utilisateurs/business/models/code_otp/DatumCodeOtpModele.dart';

class AuthApi {
  AuthApi._();
  static final AuthApi instance = AuthApi._();

  final GetStorage _storage = GetStorage();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  Dio get _dio => DioClient().dio;

  static const String _loginEndpoint = '/eblood/auth/login';
  static const String _getOtpEndpoint = '/eblood/auth/get-specific-otp';
  static const String _resendOtpEndpoint = '/eblood/auth/resend-otp';
  static const String _validateOtpEndpoint = '/eblood/auth/mobile-validate-otp';
  static const String _userProfileEndpoint = '/auth/user-profile';

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      // Explicitly clear Authorization to avoid injecting any stale token on login
      final response = await _dio.post(
        _loginEndpoint,
        data: {
          'username': email.trim().toLowerCase(),
          'password': password,
        },
        options: Options(headers: {
          'Authorization': '',
        }),
      );

      final data = response.data as Map<String, dynamic>;

      // MFA required path
      if (data['redirect_to_mfa'] == true) {
        final String? mfaAccessToken = data['access_token'];
        final String? defaultMfa = data['default_mfa']?['flag']?['real_value']?.toString();

        if (mfaAccessToken != null && mfaAccessToken.isNotEmpty) {
          // Store MFA access token temporarily (not the full auth token)
          await _storage.write('mfa_access_token', mfaAccessToken);
        }
        if (defaultMfa != null && defaultMfa.isNotEmpty) {
          await _storage.write('mfa_type', defaultMfa);
        }

        return {
          'success': true,
          'requiresMfa': true,
          'mfaType': defaultMfa ?? 'email',
          'message': data['message'] ?? 'MFA required',
        };
      }

      // Complete login without MFA
      if (data['status_code'] == 200) {
        final String? accessToken = data['access_token'];
        final String? refreshToken = data['refresh_token'];

        if (accessToken != null && accessToken.isNotEmpty) {
          await _storage.write('auth_token', accessToken);
          await _secureStorage.write(key: 'auth_token', value: accessToken);
        }
        if (refreshToken != null && refreshToken.isNotEmpty) {
          await _storage.write('refresh_token', refreshToken);
          await _secureStorage.write(key: 'refresh_token', value: refreshToken);
        }

        // Optionally store user data if provided
        if (data['user'] != null) {
          await _storage.write('user_data', data['user']);
          // Store socket hash if available
          final socketHash = data['user']['user_account_socket_hash'];
          if (socketHash != null && socketHash.toString().isNotEmpty) {
            await _storage.write('socket_hash', socketHash);
          }
        }

        // Store user profiles (ensure it's always a List to avoid cast errors downstream)
        final dynamic profilesRaw = data['user_profils'];
        List<dynamic> normalizedProfiles = <dynamic>[];
        if (profilesRaw is List) {
          normalizedProfiles = profilesRaw;
          await _storage.write('user_profiles', normalizedProfiles);
        } else {
          // Write an empty list to keep consumers safe from null casts
          await _storage.write('user_profiles', normalizedProfiles);
        }

        // Derive and persist a normalized account_type used by UI routing
        final String accountType = _deriveAccountTypeFromProfiles(normalizedProfiles);
        await _storage.write('account_type', accountType);

        return {
          'success': true,
          'requiresMfa': false,
          'message': data['message'] ?? 'Login successful',
        };
      }

      return {
        'success': false,
        'requiresMfa': false,
        'message': data['message'] ?? 'Login failed',
      };
    } on DioException catch (e) {
      String message = 'An unexpected error occurred. Please try again.';
      if (e.response?.data is Map<String, dynamic>) {
        message = (e.response!.data['message'] ?? message).toString();
      }
      return {
        'success': false,
        'requiresMfa': false,
        'message': message,
      };
    } catch (e) {
      return {
        'success': false,
        'requiresMfa': false,
        'message': 'An unexpected error occurred. Please try again.',
      };
    }
  }

  Future<Map<String, dynamic>> getOtp({
    required String mfaType,
  }) async {
    try {
      final mfaAccessToken = _storage.read('mfa_access_token');
      final options = Options(
        headers: {
          if (mfaAccessToken != null && mfaAccessToken.toString().isNotEmpty)
            'Authorization': 'Bearer $mfaAccessToken',
        },
      );

      final response = await _dio.get(
        _getOtpEndpoint,
        queryParameters: {'mfa_type': mfaType},
        options: options,
      );

      final data = response.data as Map<String, dynamic>;
      final success = (data['success'] == true) || (data['status_code'] == 200);

      return {
        'success': success,
        'message': data['message'] ?? (success ? 'OTP sent' : 'Failed to send OTP'),
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': (e.response?.data is Map<String, dynamic>)
            ? (e.response!.data['message']?.toString() ?? 'Failed to send OTP')
            : 'Failed to send OTP',
      };
    }
  }

  Future<Map<String, dynamic>> resendOtp({
    required String mfaType,
  }) async {
    try {
      final mfaAccessToken = _storage.read('mfa_access_token');
      final options = Options(
        headers: {
          if (mfaAccessToken != null && mfaAccessToken.toString().isNotEmpty)
            'Authorization': 'Bearer $mfaAccessToken',
        },
      );

      final response = await _dio.get(
        _resendOtpEndpoint,
        queryParameters: {'mfa_type': mfaType},
        options: options,
      );

      final data = response.data as Map<String, dynamic>;
      final success = (data['success'] == true) || (data['status_code'] == 200);

      return {
        'success': success,
        'message': data['message'] ?? (success ? 'OTP resent' : 'Failed to resend OTP'),
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': (e.response?.data is Map<String, dynamic>)
            ? (e.response!.data['message']?.toString() ?? 'Failed to resend OTP')
            : 'Failed to resend OTP',
      };
    }
  }

  Future<Map<String, dynamic>> validateOtp({
    required String otpCode,
    required String mfaType,
  }) async {
    try {
      final mfaAccessToken = _storage.read('mfa_access_token');
      final options = Options(
        headers: {
          if (mfaAccessToken != null && mfaAccessToken.toString().isNotEmpty)
            'Authorization': 'Bearer $mfaAccessToken',
        },
      );

      final response = await _dio.post(
        '$_validateOtpEndpoint?mfa_type=$mfaType',
        data: {'otp': otpCode},
        options: options,
      );

      final data = response.data as Map<String, dynamic>;
      final success = (data['success'] == true) || (data['status_code'] == 200);

      if (success) {
        final String? accessToken = data['access_token'];
        final String? refreshToken = data['refresh_token'];

        if (accessToken != null && accessToken.isNotEmpty) {
          await _storage.write('auth_token', accessToken);
          await _secureStorage.write(key: 'auth_token', value: accessToken);
        }
        if (refreshToken != null && refreshToken.isNotEmpty) {
          await _storage.write('refresh_token', refreshToken);
          await _secureStorage.write(key: 'refresh_token', value: refreshToken);
        }
        if (data['user'] != null) {
          await _storage.write('user_data', data['user']);
          // Store socket hash if available
          final socketHash = data['user']['user_account_socket_hash'];
          if (socketHash != null && socketHash.toString().isNotEmpty) {
            await _storage.write('socket_hash', socketHash);
          }
        }

        // Store user profiles with robust extraction across common shapes
        final Map<String, dynamic>? userObj = (data['user'] is Map)
            ? (data['user'] as Map).cast<String, dynamic>()
            : null;

        dynamic profilesRaw = data['user_profils'];
        profilesRaw ??= data['user_profiles'];
        profilesRaw ??= (data['data'] is Map) ? (data['data'] as Map)['user_profils'] : null;
        profilesRaw ??= (data['data'] is Map) ? (data['data'] as Map)['user_profiles'] : null;
        profilesRaw ??= userObj?['user_profils'] ?? userObj?['user_profiles'] ?? userObj?['profiles'];

        List<dynamic> normalizedProfiles = <dynamic>[];
        if (profilesRaw is List) {
          normalizedProfiles = profilesRaw;
        }
        await _storage.write('user_profiles', normalizedProfiles);

        // Derive a normalized account_type used by UI routing
        String accountType = _deriveAccountTypeFromProfiles(normalizedProfiles);

        // Fallback: derive from user object if profiles are missing/ambiguous
        if (accountType.isEmpty || accountType == 'hospital') {
          final String? userAccountType = (userObj?['account_type'] ?? userObj?['uAccountType'])?.toString();
          if (userAccountType != null && userAccountType.isNotEmpty) {
            final lower = userAccountType.toLowerCase().trim();
            if (lower.contains('blood') || lower.contains('banque')) {
              accountType = 'blood_bank';
            } else if (lower.contains('delivery') || lower.contains('livreur')) {
              accountType = 'delivery';
            } else {
              // personal/simple user/health_structure -> hospital navigation
              accountType = 'hospital';
            }
          } 
        }

        await _storage.write('account_type', accountType);

        // Clear MFA temporary token after successful login
        await _storage.remove('mfa_access_token');
        // Also clear any pending MFA/UI context keys persisted during login flow
        await _storage.remove('pending_mfa_type');
        await _storage.remove('pending_login_email');
        await _storage.remove('pending_login_phone');
        // Optional: clear auxiliary mfa_type if set by login()
        await _storage.remove('mfa_type');
      }

      return {
        'success': success,
        'message': data['message'] ?? (success ? 'Login successful' : 'Invalid OTP'),
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': (e.response?.data is Map<String, dynamic>)
            ? (e.response!.data['message']?.toString() ?? 'Invalid OTP')
            : 'Invalid OTP',
      };
    }
  }
  
  /// Fetches user profile information after successful authentication
  /// Uses the current auth token from secure storage
  Future<DatumCodeOtpModele?> getUserProfile() async {
    try {
      final String? token = await _secureStorage.read(key: 'auth_token');
      if (token == null || token.isEmpty) {
        print("⚠️ getUserProfile called with empty token");
        return null;
      }

      final response = await _dio.get(
        _userProfileEndpoint,
        options: Options(
          headers: {
            "Authorization": "Bearer $token",
            "Content-Type": "application/json",
            // Required by middleware
            "eblood-lockkeys": "0af4ebc066accceff45fad9ee6f2e9a9a24f6051ddb59b73f188dff0326c1e31",
          },
        ),
      );

      print('💾 API RESPNSED with ${response.data} entries');

      // Fast exit on non-200 responses
      if (response.statusCode != 200) {
        print("❌ Failed to fetch user profile: ${response.statusCode}");
        return null;
      }

      final Map<String, dynamic> responseData = response.data as Map<String, dynamic>;

      // Expected response format: { user: {...}, user_profils: [...] }
      final dynamic userRaw = responseData['user'];
      if (userRaw is! Map) {
        print("⚠️ Unexpected profile payload, 'user' is missing or invalid");
        return null;
      }

      // Store user profiles for routing compatibility
      final dynamic profilsRaw = responseData['user_profils'];
      if (profilsRaw is List) {
        await _storage.write('user_profils', profilsRaw);
        await _storage.write('user_profiles', profilsRaw); // legacy key
        print('💾 Stored user_profils with ${profilsRaw.length} entries');
      }

      final Map<String, dynamic> userMap = userRaw.cast<String, dynamic>();
      
      // Map API user payload to our DatumCodeOtpModele structure
      final String userId = userMap['id']?.toString() ?? '';
      final String email = userMap['email_address']?.toString() ?? '';
      final String phone = userMap['phone_number']?.toString() ?? '';

      // Extract profile type information from the first profile if available
      String profilTypeFlag = '';
      String profilTypeName = '';
      if (profilsRaw is List && profilsRaw.isNotEmpty) {
        final firstProfile = profilsRaw[0] as Map<dynamic, dynamic>;
        profilTypeFlag = firstProfile['profil_type_flag']?.toString() ?? '';
        profilTypeName = firstProfile['profil_type_name']?.toString() ?? '';
      }

      // Choose where the login token was received from (best-effort)
      String uReceveLoginTokenBy = '';
      if (email.isNotEmpty) {
        uReceveLoginTokenBy = 'email';
      } else if (phone.isNotEmpty) {
        uReceveLoginTokenBy = 'phone';
      }

      // Create the data structure needed for DatumCodeOtpModele
      final Map<String, dynamic> mappedData = {
        // Required auth + identity
        "authBarear": token,
        "uSocket": userMap['user_account_socket_hash']?.toString() ?? '',
        "uUserName": userMap['username']?.toString() ?? '',
        "uNom": userMap['last_name']?.toString() ?? '',
        "uPrenom": userMap['first_name']?.toString() ?? '',
        "uSexe": userMap['gender']?.toString() ?? '',
        // Delivery method for OTP (optional hint)
        "uReceveLoginTokenBy": uReceveLoginTokenBy,
        // Contacts
        "uCourriels": email.isNotEmpty
            ? [
                {"email": email, "_id": userId}
              ]
            : [],
        "uTelephones": phone.isNotEmpty
            ? [
                {"phone_number": phone, "_id": userId}
              ]
            : [],
        // Additional fields
        "uAccountType": userMap['account_type']?.toString() ?? '',
        "uAccountFrom": userMap['uAccountFrom']?.toString() ?? '',
        "country_id": userMap['country_id']?.toString() ?? '',
        "city": userMap['city']?.toString() ?? '',
        "uAdresse": userMap['address']?.toString() ?? '',
        // Include profile type information
        "profil_type_flag": profilTypeFlag,
        "profil_type_name": profilTypeName,
        // Use current timestamp
        "uLastUpdate": DateTime.now().toIso8601String(),
        // Default country and coordinates (if missing)
        "country": {
          "id": "",
          "countryCode": "",
          "countryName": "",
          "countryFlag": "",
          "nationality": "",
          "currencies": [],
          "minPhoneNumberChars": 0,
          "maxPhoneNumberChars": 0,
          "phoneNumberPrefixes": [],
          "countryCodes": [],
          "isActivated": false,
          "homeCountryId": ""
        },
        "cordonates": {
          "longitude": 0.0,
          "latitude": 0.0
        }
      };

      // Create the DatumCodeOtpModele instance
      final user = DatumCodeOtpModele.fromJson(mappedData);
      return user;
    } catch (e) {
      print("💥 Error in getUserProfile: $e");
      return null;
    }
  }
  
  /// Log out the current user
  /// Clears all tokens and user data from storage
  Future<bool> logout() async {
    try {
      final token = await _secureStorage.read(key: 'auth_token');
      
      if (token != null && token.isNotEmpty) {
        try {
          // Attempt server-side logout
          await _dio.get(
            '/auth/logout',
            options: Options(
              headers: {
                "Authorization": "Bearer $token",
                "Content-Type": "application/json",
                "eblood-lockkeys": "0af4ebc066accceff45fad9ee6f2e9a9a24f6051ddb59b73f188dff0326c1e31"
              },
            ),
          );
        } catch (e) {
          // Continue with local logout even if server-side fails
          print("Warning: Server-side logout failed: $e");
        }
      }

      // Clear local storage
      await _secureStorage.delete(key: 'auth_token');
      await _secureStorage.delete(key: 'refresh_token');
      
      await _storage.remove('auth_token');
      await _storage.remove('refresh_token');
      await _storage.remove('user_data');
      await _storage.remove('user_profiles');
      await _storage.remove('user_profils');
      await _storage.remove('account_type');
      await _storage.remove('socket_hash');
      
      return true;
    } catch (e) {
      print("💥 Error during logout: $e");
      return false;
    }
  }
}

// Helper: Map backend profile flags to a normalized account type string used by UI
String _deriveAccountTypeFromProfiles(List<dynamic> profiles) {
  // Default to hospital to match existing UI fallback
  const String fallback = 'hospital';
  if (profiles.isEmpty) return fallback;

  // Collect flags safely
  final flags = profiles
      .whereType<Map>()
      .map((e) => (e['profil'] ?? e['flag'] ?? '').toString())
      .where((s) => s.isNotEmpty)
      .toSet();

  // New backend semantics and priority:
  // 1) Blood bank takes precedence
  if (flags.contains('mobile_app_blood_bank_profil')) return 'blood_bank';
  // 2) Health structure next
  if (flags.contains('mobile_app_health_structure_profil')) return 'hospital';
  // 3) Consumer group: simple user alone or combined with donor and/or delivery
  if (flags.contains('mobile_app_simple_user_profil') ||
      flags.contains('mobile_app_blood_donor_profil') ||
      flags.contains('mobile_app_delivery_person_profil')) {
    return 'customer'; // explicit customer UI (consumer bottom nav)
  }

  return fallback;
}
