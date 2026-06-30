import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../users/business/models/code_otp/DatumCodeOtpModele.dart';
import '../../core/services/session_user_store.dart';
import '../config/api/dio_client.dart';

class AuthApi {
  AuthApi._();
  static final AuthApi instance = AuthApi._();

  final GetStorage _storage = GetStorage();
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  /// Safely read from FlutterSecureStorage, handling corrupted encryption keys.
  /// On Android, a BadPaddingException can occur when the Keystore key is
  /// invalidated (OS update, app reinstall, backup restore). In that case
  /// the corrupted entry is deleted and null is returned.
  Future<String?> _safeSecureRead(String key) async {
    try {
      return await _secureStorage.read(key: key);
    } on PlatformException catch (e) {
      debugPrint('⚠️ SecureStorage corrupted for key "$key": ${e.message} — clearing entry');
      try {
        await _secureStorage.delete(key: key);
      } catch (_) {}
      return null;
    }
  }

  // Dio get _dio => DioClient().dio;

  static const String _loginEndpoint = '/eblood/auth/login';
  static const String _getOtpEndpoint = '/eblood/auth/get-specific-otp';
  static const String _resendOtpEndpoint = '/eblood/auth/resend-otp';
  static const String _validateOtpEndpoint = '/eblood/auth/mobile-validate-otp';
  static const String _userProfileEndpoint = '/auth/user-profile';
  // Sprint 16 — split the old single /eblood-connect/users/login-visitor
  // endpoint (which was overloaded as GET=check and POST=create) into the
  // new clean POST-only surface:
  //   /api/v1/auth/visitor/check-existing  -> already-linked device check
  //   /api/v1/auth/visitor/create-visitor  -> first-time enrolment
  static const String _visitorCheckExistingEndpoint = '/auth/visitor/check-existing';
  static const String _visitorCreateEndpoint = '/auth/visitor/create-visitor';

  // Visitor endpoints
  Future<Map<String, dynamic>> visitorLoginCheck() async {
    try {
      // Sprint 16: was GET, now POST (no body) on the new clean surface.
      final response = await postWithDio(
        _visitorCheckExistingEndpoint,
        // No body — identification is by device fingerprint headers handled
        // server-side. Anonymous: no stale Authorization should interfere.
      );

      final bool success = response.success;
      final raw = response.raw;
      final bool needsEntity = (raw is Map<String, dynamic>) 
          ? (raw['needs_entity'] == true)
          : false;

      if (success && response.data is Map) {
        final responseData = response.data as Map<String, dynamic>;
        
        // Store access and refresh tokens
        final String? accessToken = responseData['access_token'];
        final String? refreshToken = responseData['refresh_token'];

        if (accessToken != null && accessToken.isNotEmpty) {
          await _storage.write('auth_token', accessToken);
          await _secureStorage.write(key: 'auth_token', value: accessToken);
        }
        if (refreshToken != null && refreshToken.isNotEmpty) {
          await _storage.write('refresh_token', refreshToken);
          await _secureStorage.write(key: 'refresh_token', value: refreshToken);
        }

        // Store user data if provided
        if (responseData['user'] != null) {
          await _storage.write('user_data', responseData['user']);
          // Store socket hash if available
          final socketHash = responseData['user']['user_account_socket_hash'];
          if (socketHash != null && socketHash.toString().isNotEmpty) {
            await _storage.write('socket_hash', socketHash);
          }
        }

        // Store user profiles (ensure it's always a List)
        final dynamic profilesRaw = responseData['user_profils'];
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

        // Durable secure-storage copy for the logged-in user bar.
        await SessionUserStore.saveFromUserData(
          userData: responseData['user'] is Map ? responseData['user'] as Map : null,
          accountType: accountType,
        );

        return {
          'success': true,
          'nextAction': 'login',
          'message': response.message ?? (raw is Map<String, dynamic> ? raw['message']?.toString() : null) ?? 'Logged in as visitor',
        };
      }

      if (needsEntity) {
        return {
          'success': false,
          'nextAction': 'select_entity',
          'message': response.message ?? (raw is Map<String, dynamic> ? raw['message']?.toString() : null) ?? 'Please select your location to continue as visitor.',
        };
      }

      return {
        'success': false,
        'nextAction': 'unknown',
        'message': response.message ?? (raw is Map<String, dynamic> ? raw['message']?.toString() : null) ?? 'Unable to login as visitor',
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'nextAction': 'error',
        'message': 'Visitor check failed: ${e.message ?? 'Unknown error'}',
      };
    } catch (e) {
      return {
        'success': false,
        'nextAction': 'error',
        'message': 'Visitor check failed: $e',
      };
    }
  }

  Future<Map<String, dynamic>> createVisitor({
    required String locationId,
  }) async {
    try {
      // Sprint 16: was POST /eblood-connect/users/login-visitor, now
      // POST /api/v1/auth/visitor/create-visitor.
      final response = await postWithDio(
        _visitorCreateEndpoint,
        body: {
          'location_id': locationId,
        },
      );

      final bool success = response.success;
      final raw = response.raw;
      
      if (success && response.data is Map) {
        final responseData = response.data as Map<String, dynamic>;
        
        debugPrint('createVisitor response: $responseData',wrapWidth: 1000);
        // Store access and refresh tokens
        final String? accessToken = responseData['access_token'];
        final String? refreshToken = responseData['refresh_token'];

        if (accessToken != null && accessToken.isNotEmpty) {
          await _storage.write('auth_token', accessToken);
          await _secureStorage.write(key: 'auth_token', value: accessToken);
        }
        if (refreshToken != null && refreshToken.isNotEmpty) {
          await _storage.write('refresh_token', refreshToken);
          await _secureStorage.write(key: 'refresh_token', value: refreshToken);
        }

        // Store user data if provided
        if (responseData['user'] != null) {
          await _storage.write('user_data', responseData['user']);
          // Store socket hash if available
          final socketHash = responseData['user']['user_account_socket_hash'];
          if (socketHash != null && socketHash.toString().isNotEmpty) {
            await _storage.write('socket_hash', socketHash);
          }
        }

        // Store user profiles (ensure it's always a List)
        final dynamic profilesRaw = responseData['user_profils'];
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

        // Durable secure-storage copy for the logged-in user bar.
        await SessionUserStore.saveFromUserData(
          userData: responseData['user'] is Map ? responseData['user'] as Map : null,
          accountType: accountType,
        );

        return {
          'success': true,
          'message': response.message ?? (raw is Map<String, dynamic> ? raw['message']?.toString() : null) ?? 'Visitor created and logged in successfully',
        };
      }

      return {
        'success': false,
        'message': response.message ?? (raw is Map<String, dynamic> ? raw['message']?.toString() : null) ?? 'Unable to create visitor',
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': 'Create visitor failed: ${e.message ?? 'Unknown error'}',
      };
    } catch (e) {
      debugPrint('Create visitor failed: $e',wrapWidth: 1000);
      return {
        'success': false,
        'message': 'Create visitor failed: $e',
      };
    }
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    bool rememberMe = false,
  }) async {
    try {
      // Explicitly clear Authorization to avoid injecting any stale token on login
      final response = await postWithDio(
        _loginEndpoint,
        body: {
          'username': email.trim().toLowerCase(),
          'password': password,
        },
      );

      // IMPORTANT: backend returns top-level fields (no nested "data");
      // prefer raw payload and safely cast to a map.
      final Map<String, dynamic> data = (response.raw is Map)
          ? (response.raw as Map).cast<String, dynamic>()
          : (response.data is Map)
              ? (response.data as Map).cast<String, dynamic>()
              : <String, dynamic>{};

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

        // Extract and save identifier + user_entity info
        await _extractAndSaveIdentifier(
          profiles: normalizedProfiles,
          accountType: accountType,
          userData: data['user'] is Map ? (data['user'] as Map).cast<String, dynamic>() : null,
        );

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
      
      final response = await getWithDio(
        '$_getOtpEndpoint?mfa_type=$mfaType',
        headers: {
          if (mfaAccessToken != null && mfaAccessToken.toString().isNotEmpty)
            'Authorization': 'Bearer $mfaAccessToken',
        },
      );

      final bool success = response.success;
      final raw = response.raw;

      return {
        'success': success,
        'message': response.message ?? (raw is Map<String, dynamic> ? raw['message']?.toString() : null) ?? (success ? 'OTP sent' : 'Failed to send OTP'),
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': 'Failed to send OTP: ${e.message ?? 'Unknown error'}',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to send OTP: $e',
      };
    }
  }

  Future<Map<String, dynamic>> resendOtp({
    required String mfaType,
  }) async {
    try {
      final mfaAccessToken = _storage.read('mfa_access_token');
      
      final response = await getWithDio(
        '$_resendOtpEndpoint?mfa_type=$mfaType',
        headers: {
          if (mfaAccessToken != null && mfaAccessToken.toString().isNotEmpty)
            'Authorization': 'Bearer $mfaAccessToken',
        },
      );

      final bool success = response.success;
      final raw = response.raw;

      return {
        'success': success,
        'message': response.message ?? (raw is Map<String, dynamic> ? raw['message']?.toString() : null) ?? (success ? 'OTP resent' : 'Failed to resend OTP'),
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': 'Failed to resend OTP: ${e.message ?? 'Unknown error'}',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Failed to resend OTP: $e',
      };
    }
  }

  Future<Map<String, dynamic>> validateOtp({
    required String otpCode,
    required String mfaType,
  }) async {
    try {
      final mfaAccessToken = _storage.read('mfa_access_token');
      
      final response = await postWithDio(
        '$_validateOtpEndpoint?mfa_type=$mfaType',
        body: {'otp': otpCode},
        headers: {
          if (mfaAccessToken != null && mfaAccessToken.toString().isNotEmpty)
            'Authorization': 'Bearer $mfaAccessToken',
        },
      );

      final bool success = response.success;
      final raw = response.raw;
      final Map<String, dynamic> payload =
          (raw is Map)
              ? (raw as Map).cast<String, dynamic>()
              : (response.data is Map)
                  ? (response.data as Map).cast<String, dynamic>()
                  : <String, dynamic>{};

      if (success) {
        final String? accessToken = payload['access_token']?.toString();
        final String? refreshToken = payload['refresh_token']?.toString();

        if (accessToken != null && accessToken.isNotEmpty) {
          await _storage.write('auth_token', accessToken);
          await _secureStorage.write(key: 'auth_token', value: accessToken);
        }
        if (refreshToken != null && refreshToken.isNotEmpty) {
          await _storage.write('refresh_token', refreshToken);
          await _secureStorage.write(key: 'refresh_token', value: refreshToken);
        }

        final Map<String, dynamic>? userObj =
            (payload['user'] is Map) ? (payload['user'] as Map).cast<String, dynamic>() : null;
        if (userObj != null) {
          await _storage.write('user_data', userObj);
          // Store socket hash if available
          final socketHash = userObj['user_account_socket_hash'];
          if (socketHash != null && socketHash.toString().isNotEmpty) {
            await _storage.write('socket_hash', socketHash);
          }
        }

        // Store user profiles for routing compatibility
        final dynamic profilsRaw = payload['user_profils'];
        if (profilsRaw is List) {
          print('📥 OTP validation - storing profiles: $profilsRaw');
          await _storage.write('user_profils', profilsRaw);
          await _storage.write('user_profiles', profilsRaw); // legacy key
          print('💾 Stored user_profils with ${profilsRaw.length} entries');

          // Derive and persist account_type from profiles
          if (profilsRaw.isNotEmpty) {
            final String accountType = _deriveAccountTypeFromProfiles(profilsRaw.cast<dynamic>());
            await _storage.write('account_type', accountType);
            print('💾 Stored account_type: $accountType');

            // Extract and save identifier + user_entity info
            await _extractAndSaveIdentifier(
              profiles: profilsRaw.cast<dynamic>(),
              accountType: accountType,
              userData: userObj,
            );
          }
        }

        // Clear MFA temporary token after successful login
        await _storage.remove('mfa_access_token');
        // Also clear any pending MFA/UI context keys persisted during login flow
        await _storage.remove('pending_mfa_type');
        await _storage.remove('pending_login_email');
        await _storage.remove('pending_login_phone');
        // Optional: clear auxiliary mfa_type if set by login()
        await _storage.remove('mfa_type');

        // Transform user data to DatumCodeOtpModele format for proper storage
        DatumCodeOtpModele? transformedUser;
        if (userObj != null && accessToken != null) {
          transformedUser = _transformUserDataToDatumModel(
            userObj,
            accessToken,
            profilsRaw is List ? profilsRaw : null,
          );
        }
      }

      return {
        'success': success,
        'access_token': payload['access_token']?.toString(),
        'user': payload['user'], // Original user data
        'user_profils': payload['user_profils'], // Original profiles
        'transformed_user': success ? (payload['user'] != null && payload['access_token'] != null
            ? _transformUserDataToDatumModel(
                (payload['user'] as Map).cast<String, dynamic>(),
                payload['access_token'].toString(),
                payload['user_profils'] is List ? payload['user_profils'] : null,
              )
            : null) : null,
        'message': response.message ??
            (payload['message']?.toString() ?? (success ? 'Login successful' : 'Invalid OTP')),
      };
    } on DioException catch (e) {
      return {
        'success': false,
        'message': 'Invalid OTP: ${e.message ?? 'Unknown error'}',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Invalid OTP: $e',
      };
    }
  }
  
  /// Transform user data from backend format to DatumCodeOtpModele format
  /// This is used after OTP validation or Google registration to save user data properly
  DatumCodeOtpModele? _transformUserDataToDatumModel(
    Map<String, dynamic> userMap,
    String token,
    List<dynamic>? profilsRaw,
  ) {
    try {
      final String userId = userMap['id']?.toString() ?? '';
      final String email = userMap['email_address']?.toString() ?? '';
      final String phone = userMap['phone_number']?.toString() ?? '';

      // Extract profile type information from the first profile if available
      String profilTypeFlag = '';
      String profilTypeName = '';
      if (profilsRaw != null && profilsRaw.isNotEmpty) {
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
        "account_status": userMap['account_status']?.toString() ?? '',
        // User entity information (for visitors and regular users)
        "user_entity": userMap['user_entity'] ?? {},
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
      print('🔨 Creating DatumCodeOtpModele from backend data...');
      final user = DatumCodeOtpModele.fromJson(mappedData);
      print('✅ Successfully created DatumCodeOtpModele: ${user.uPrenom} ${user.uNom}');
      return user;
    } catch (e, stackTrace) {
      print("💥 Error transforming user data: $e");
      print("📍 Stack trace: $stackTrace");
      return null;
    }
  }

  /// Fetches user profile information after successful authentication
  /// Uses the current auth token from secure storage
  Future<DatumCodeOtpModele?> getUserProfile() async {
    try {
      final String? token = await _safeSecureRead('auth_token');
      if (token == null || token.isEmpty) {
        print("⚠️ getUserProfile called with empty token");
        return null;
      }

      final response = await getWithDio(
        _userProfileEndpoint,
        // headers: {
        //   "Authorization": "Bearer $token",
        //   "Content-Type": "application/json",
        //   // Required by middleware
        //   "eblood-lockkeys": "0af4ebc066accceff45fad9ee6f2e9a9a24f6051ddb59b73f188dff0326c1e31",
        // },
      );

      print('💾 API RESPONDED with success=${response.success}, statusCode=${response.statusCode}');

      // Fast exit on unsuccessful responses
      if (!response.success) {
        print("❌ Failed to fetch user profile: ${response.statusCode}");
        return null;
      }

      // Use raw response data instead of parsed data to avoid TUserModel parsing issues
      final Map<String, dynamic>? responseData = (response.raw is Map) 
          ? (response.raw as Map).cast<String, dynamic>() 
          : null;
      
      if (responseData == null) {
        print("⚠️ Invalid response data format");
        return null;
      }

      // Expected response format: { user: {...}, user_profils: [...] }
      final dynamic userRaw = responseData['user'];
      if (userRaw is! Map) {
        print("⚠️ Unexpected profile payload, 'user' is missing or invalid");
        return null;
      }

      // Store user profiles for routing compatibility
      final dynamic profilsRaw = responseData['user_profils'];
      if (profilsRaw is List) {
        print('📥 About to store profiles: $profilsRaw');
        await _storage.write('user_profils', profilsRaw);
        await _storage.write('user_profiles', profilsRaw); // legacy key
        print('💾 Stored user_profils with ${profilsRaw.length} entries');
        
        // Verify the write
        final verification = _storage.read('user_profils');
        print('✅ Verification - user_profils now contains: $verification');
      } else {
        print('⚠️ user_profils is not a List: $profilsRaw');
      }

      final Map<String, dynamic> userMap = userRaw.cast<String, dynamic>();
      
      // Store user data (including user_entity and address) for consistent access
      await _storage.write('user_data', userMap);
      print('💾 Stored user_data with ${userMap.keys.length} fields');
      
      // Store socket hash if available
      final socketHash = userMap['user_account_socket_hash'];
      if (socketHash != null && socketHash.toString().isNotEmpty) {
        await _storage.write('socket_hash', socketHash);
      }

      // Derive and persist account_type from profiles
      if (profilsRaw is List && profilsRaw.isNotEmpty) {
        final String accountType = _deriveAccountTypeFromProfiles(profilsRaw.cast<dynamic>());
        await _storage.write('account_type', accountType);
        print('💾 Stored account_type: $accountType');

        // Extract and save identifier + user_entity info
        await _extractAndSaveIdentifier(
          profiles: profilsRaw.cast<dynamic>(),
          accountType: accountType,
          userData: userMap,
        );
      }
      
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
        "account_status": userMap['account_status']?.toString() ?? '',
        // User entity information (for visitors and regular users)
        "user_entity": userMap['user_entity'] ?? {},
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
      print('🔨 Creating DatumCodeOtpModele from mappedData...');
      final user = DatumCodeOtpModele.fromJson(mappedData);
      print('✅ Successfully created DatumCodeOtpModele');
      return user;
    } catch (e, stackTrace) {
      print("💥 Error in getUserProfile: $e");
      print("📍 Stack trace: $stackTrace");
      return null;
    }
  }
  
  /// Log out the current user
  /// Clears all tokens and user data from storage
  Future<bool> logout() async {
    try {
      final token = await _safeSecureRead('auth_token');

      if (token != null && token.isNotEmpty) {
        try {
          // Attempt server-side logout
          await getWithDio(
            '/auth/logout',
            // headers: {
            //   "Authorization": "Bearer $token",
            //   "Content-Type": "application/json",
            //   "eblood-lockkeys": "0af4ebc066accceff45fad9ee6f2e9a9a24f6051ddb59b73f188dff0326c1e31"
            // },
          );
        } catch (e) {
          // Continue with local logout even if server-side fails
          print("Warning: Server-side logout failed: $e");
        }
      }

      // Clear local storage
      await _secureStorage.delete(key: 'auth_token');
      await _secureStorage.delete(key: 'refresh_token');
      await SessionUserStore.clear();

      await _storage.remove('auth_token');
      await _storage.remove('refresh_token');
      await _storage.remove('user_data');
      await _storage.remove('user_profiles');
      await _storage.remove('user_profils');
      await _storage.remove('account_type');
      await _storage.remove('socket_hash');
      
      // Clear cached health structure data
      await _storage.remove('cached_health_structure');
      await _storage.remove('cached_health_structure_timestamp');

      // Sign out from Firebase Auth (Google Sign-In)
      try {
        final firebaseAuth = FirebaseAuth.instance;
        final googleSignIn = GoogleSignIn();
        await googleSignIn.signOut();
        await firebaseAuth.signOut();
        print('🔐 Firebase sign-out successful');
      } catch (e) {
        print('⚠️ Firebase sign-out failed: $e');
        // Continue with logout even if Firebase sign-out fails
      }

      return true;
    } catch (e) {
      print("💥 Error during logout: $e");
      return false;
    }
  }

  /// Extract identifier from user profiles and persist along with user_entity info.
  /// This stores 'user_identifier' and 'user_entity_id'/'user_entity_name' to GetStorage
  /// so the search flow can auto-identify hospital accounts.
  Future<void> _extractAndSaveIdentifier({
    required List<dynamic> profiles,
    required String accountType,
    Map<String, dynamic>? userData,
  }) async {
    // 1. Extract identifier from profiles matching the derived account type
    String identifier = '';
    for (final p in profiles) {
      if (p is Map) {
        final id = (p['identifier'] ?? '').toString().trim();
        if (id.isNotEmpty) {
          identifier = id;
          break; // take the first non-empty identifier
        }
      }
    }
    await _storage.write('user_identifier', identifier);
    print('💾 Stored user_identifier: $identifier');

    // 2. Persist user_entity id & name for hospital auto-identification
    if (userData != null && userData['user_entity'] is Map) {
      final entity = (userData['user_entity'] as Map).cast<String, dynamic>();
      final entityId = (entity['id'] ?? entity['_id'] ?? '').toString();
      final entityName = (entity['entity_name'] ?? entity['name'] ?? '').toString();
      await _storage.write('user_entity_id', entityId);
      await _storage.write('user_entity_name', entityName);
      print('💾 Stored user_entity_id: $entityId, user_entity_name: $entityName');
    }

    // 3. Persist a durable, secure-storage copy of the display info so the
    // logged-in user bar (blood-search / QR page) survives an app kill or hot
    // restart even when the GetStorage `user_data` cache is missing.
    await SessionUserStore.saveFromUserData(
      userData: userData,
      accountType: accountType,
    );
  }
}

// Helper: Map backend profile flags to a normalized account type string used by UI
String _deriveAccountTypeFromProfiles(List<dynamic> profiles) {
  // Default to customer (consumer) as fallback
  const String fallback = 'customer';
  if (profiles.isEmpty) return fallback;

  // ✅ FIX: Only collect ENABLED profiles
  // Filter profiles to only include those with enabled=true
  final enabledProfiles = profiles
      .whereType<Map>()
      .where((e) => e['enabled'] != false) // Only enabled profiles
      .toList();

  // If no enabled profiles are available, fall back to raw list (some APIs return enabled=false for legacy accounts)
  final effectiveProfiles = enabledProfiles.isNotEmpty
      ? enabledProfiles
      : profiles.whereType<Map>().toList();

  // Collect flags from enabled profiles only
  final flags = effectiveProfiles
      .map((e) => (e['profil'] ?? e['flag'] ?? '').toString())
      .where((s) => s.isNotEmpty)
      .toSet();

  // Collect profil_type_name / profil_type_flag hints as additional signals
  final typeNames = effectiveProfiles
      .map((e) => (e['profil_type_name'] ?? e['profil_type_flag'] ?? '').toString())
      .where((s) => s.isNotEmpty)
      .map((s) => s.toLowerCase())
      .toSet();

  print('🔍 Deriving account type from profiles:');
  print('   Total profiles: ${profiles.length}');
  print('   Enabled profiles: ${enabledProfiles.length}');
  print('   Flags: $flags');
  if (enabledProfiles.isEmpty) {
    print('   ⚠️ No enabled profiles, falling back to all profile entries.');
  }
  print('   Type names: $typeNames');

  // ⚠️ CRITICAL: Visitor check MUST come first!
  // Visitors may also have mobile_app_simple_user_profil, but visitor status takes precedence
  // 1) Visitor profile - HIGHEST PRIORITY
  if (flags.contains('visitor_user_profil') || typeNames.contains('visitor')) {
    print('   ✅ Derived: visitor (PRIORITY)');
    return 'visitor';
  }
  
  // 2) Blood bank takes precedence (for institutional users)
  if (flags.contains('mobile_app_blood_bank_profil') || typeNames.contains('blood_bank')) {
    print('   ✅ Derived: blood_bank');
    return 'blood_bank';
  }
  // 3) Health structure next
  if (flags.contains('mobile_app_health_structure_profil') || typeNames.contains('health_structure') || typeNames.contains('hospital')) {
    print('   ✅ Derived: hospital');
    return 'hospital';
  }
  // 4) Consumer group: simple user alone or combined with donor and/or delivery
  if (flags.contains('mobile_app_simple_user_profil') ||
      flags.contains('mobile_app_blood_donor_profil') ||
      flags.contains('mobile_app_delivery_person_profil') ||
      typeNames.contains('customer') ||
      typeNames.contains('consumer') ||
      typeNames.contains('personal')) {
    print('   ✅ Derived: customer (consumer)');
    return 'customer'; // explicit customer UI (consumer bottom nav)
  }

  print('   ✅ Derived: $fallback (fallback)');
  return fallback;
}
