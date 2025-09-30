import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart' as getx;
import '../config/AppConfig.dart';

/// Dio HTTP client service for eBlood Makila App
class DioClient extends getx.GetxService {
  static final DioClient _instance = DioClient._internal();
  
  /// Singleton instance
  factory DioClient() => _instance;

  DioClient._internal();
  
  late Dio _dio;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  // API Configuration
  String get _baseUrl => AppConfig.instance.baseUrl;
  String get _baseApiUrl => AppConfig.instance.baseApiUrl;
  String get _apiConsumer => AppConfig.instance.apiConsumer;
  final String _tokenKey = 'auth_token';
  final String _refreshTokenKey = 'refresh_token';
  
  /// Access the Dio instance
  Dio get dio => _dio;

  /// Initialize the Dio client
  Future<void> init() async {
    _dio = Dio(BaseOptions(
      baseUrl: _baseApiUrl,
      connectTimeout: const Duration(milliseconds: 30000),
      receiveTimeout: const Duration(milliseconds: 30000),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Accept-Language': getx.Get.locale?.languageCode ?? 'fr',
      },
    ));

    // Add interceptors
    _dio.interceptors.add(DeviceInfoInterceptor());
    _dio.interceptors.add(AuthInterceptor(_secureStorage, _apiConsumer));
    _dio.interceptors.add(ErrorInterceptor(_secureStorage));
    
    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: true,
        responseBody: true,
        requestHeader: true,
        responseHeader: false,
        error: true,
        logPrint: (obj) => debugPrint('🌐 DIO: ${obj.toString()}'),
      ));
    }
    
    print('🔌 DioClient initialized with baseURL: $_baseApiUrl');
  }

  /// Login with username and password
  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    try {
      // Check connectivity
      final connectivityResult = await Connectivity().checkConnectivity();
      if (connectivityResult.contains(ConnectivityResult.none)) {
        return {
          'success': false,
          'message': 'No internet connection. Please check your network and try again.',
          'status_code': 503,
        };
      }

      final response = await _dio.post(
        '/auth/login',
        data: {
          'username': username.trim().toLowerCase(),
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        
        // Store tokens if available
        if (data['access_token'] != null) {
          await _secureStorage.write(key: _tokenKey, value: data['access_token']);
        }
        
        if (data['refresh_token'] != null) {
          await _secureStorage.write(key: _refreshTokenKey, value: data['refresh_token']);
        }
        
        return data;
      }

      return {
        'success': false,
        'message': 'Login failed. Please try again.',
        'status_code': response.statusCode,
      };
    } on DioException catch (e) {
      return _handleDioException(e);
    } catch (e) {
      debugPrint('Login error: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred. Please try again.',
        'status_code': 500,
      };
    }
  }

  /// Get OTP for authentication
  Future<Map<String, dynamic>> getOtp({required String mfaType}) async {
    try {
      final response = await _dio.get(
        '/auth/get-specific-otp',
        queryParameters: {'mfa_type': mfaType},
      );

      if (response.statusCode == 200) {
        return response.data;
      }

      return {
        'success': false,
        'message': 'Failed to send OTP',
        'status_code': response.statusCode,
      };
    } on DioException catch (e) {
      return _handleDioException(e);
    }
  }

  /// Validate OTP code
  Future<Map<String, dynamic>> validateOtp({
    required String otpCode,
    required String mfaType,
  }) async {
    try {
      final response = await _dio.post(
        '/auth/validate-otp',
        queryParameters: {'mfa_type': mfaType},
        data: {
          'otp': otpCode,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;
        
        // Store tokens if available
        if (data['access_token'] != null) {
          await _secureStorage.write(key: _tokenKey, value: data['access_token']);
        }
        
        if (data['refresh_token'] != null) {
          await _secureStorage.write(key: _refreshTokenKey, value: data['refresh_token']);
        }
        
        return data;
      }

      return {
        'success': false,
        'message': 'Invalid OTP. Please try again.',
        'status_code': response.statusCode,
      };
    } on DioException catch (e) {
      return _handleDioException(e);
    }
  }

  /// Refresh authentication token
  Future<Map<String, dynamic>> refreshToken() async {
    try {
      final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
      if (refreshToken == null) {
        return {
          'success': false,
          'message': 'No refresh token available',
          'status_code': 401,
        };
      }

      final response = await _dio.get('/auth/refresh-token');

      if (response.statusCode == 200) {
        final data = response.data;
        
        // Store new tokens if available
        if (data['access_token'] != null) {
          await _secureStorage.write(key: _tokenKey, value: data['access_token']);
        }
        
        return data;
      }

      return {
        'success': false,
        'message': 'Failed to refresh token',
        'status_code': response.statusCode,
      };
    } on DioException catch (e) {
      return _handleDioException(e);
    }
  }

  /// Logout user and clear tokens
  Future<Map<String, dynamic>> logout() async {
    try {
      await _dio.get('/auth/logout');
      
      // Clear stored tokens
      await _secureStorage.delete(key: _tokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);
      
      return {
        'success': true,
        'message': 'Logged out successfully',
        'status_code': 200,
      };
    } catch (e) {
      // Even if logout fails, clear local tokens
      await _secureStorage.delete(key: _tokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);
      
      return {
        'success': true,
        'message': 'Logged out locally',
        'status_code': 200,
      };
    }
  }

  /// GET request wrapper
  Future<Map<String, dynamic>> get(String endpoint, {
    Map<String, dynamic>? queryParams,
    bool requireAuth = true,
    String? customBaseUrl,
  }) async {
    try {
      final String url = customBaseUrl != null ? '$customBaseUrl$endpoint' : endpoint;
      final response = await _dio.get(
        url,
        queryParameters: queryParams,
        options: Options(
          headers: requireAuth ? null : {'Authorization': ''},
        ),
      );
      
      return response.data;
    } on DioException catch (e) {
      return _handleDioException(e);
    }
  }

  /// POST request wrapper
  Future<Map<String, dynamic>> post(String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParams,
    bool requireAuth = true,
    String? customBaseUrl,
  }) async {
    try {
      final String url = customBaseUrl != null ? '$customBaseUrl$endpoint' : endpoint;
      final response = await _dio.post(
        url,
        data: data,
        queryParameters: queryParams,
        options: Options(
          headers: requireAuth ? null : {'Authorization': ''},
        ),
      );
      
      return response.data;
    } on DioException catch (e) {
      return _handleDioException(e);
    }
  }

  /// PUT request wrapper
  Future<Map<String, dynamic>> put(String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParams,
    bool requireAuth = true,
    String? customBaseUrl,
  }) async {
    try {
      final String url = customBaseUrl != null ? '$customBaseUrl$endpoint' : endpoint;
      final response = await _dio.put(
        url,
        data: data,
        queryParameters: queryParams,
        options: Options(
          headers: requireAuth ? null : {'Authorization': ''},
        ),
      );
      
      return response.data;
    } on DioException catch (e) {
      return _handleDioException(e);
    }
  }

  /// DELETE request wrapper
  Future<Map<String, dynamic>> delete(String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParams,
    bool requireAuth = true,
    String? customBaseUrl,
  }) async {
    try {
      final String url = customBaseUrl != null ? '$customBaseUrl$endpoint' : endpoint;
      final response = await _dio.delete(
        url,
        data: data,
        queryParameters: queryParams,
        options: Options(
          headers: requireAuth ? null : {'Authorization': ''},
        ),
      );
      
      return response.data;
    } on DioException catch (e) {
      return _handleDioException(e);
    }
  }

  /// PATCH request wrapper
  Future<Map<String, dynamic>> patch(String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParams,
    bool requireAuth = true,
    String? customBaseUrl,
  }) async {
    try {
      final String url = customBaseUrl != null ? '$customBaseUrl$endpoint' : endpoint;
      final response = await _dio.patch(
        url,
        data: data,
        queryParameters: queryParams,
        options: Options(
          headers: requireAuth ? null : {'Authorization': ''},
        ),
      );
      
      return response.data;
    } on DioException catch (e) {
      return _handleDioException(e);
    }
  }

  /// Upload file
  Future<Map<String, dynamic>> uploadFile(String endpoint, {
    required String filePath,
    required String fieldName,
    Map<String, dynamic>? extraData,
    Function(int, int)? onSendProgress,
    String? customBaseUrl,
  }) async {
    try {
      final formData = FormData();
      
      // Add the file
      formData.files.add(MapEntry(
        fieldName,
        await MultipartFile.fromFile(filePath, filename: filePath.split('/').last)
      ));
      
      // Add any extra data
      extraData?.forEach((key, value) {
        formData.fields.add(MapEntry(key, value.toString()));
      });
      
      final String url = customBaseUrl != null ? '$customBaseUrl$endpoint' : endpoint;
      final response = await _dio.post(
        url,
        data: formData,
        onSendProgress: onSendProgress,
      );
      
      return response.data;
    } on DioException catch (e) {
      return _handleDioException(e);
    }
  }

  /// Get stored auth token
  Future<String?> getToken() async {
    return await _secureStorage.read(key: _tokenKey);
  }

  /// Check if user is authenticated
  Future<bool> isAuthenticated() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  /// Handle Dio exceptions and return a standardized response format
  Map<String, dynamic> _handleDioException(DioException e) {
    String message = 'An error occurred';
    int statusCode = 500;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        message = 'Connection timeout. Please check your internet connection.';
        statusCode = 408;
        break;
      case DioExceptionType.badResponse:
        statusCode = e.response?.statusCode ?? 500;
        final data = e.response?.data;
        if (data is Map<String, dynamic>) {
          message = data['message'] ?? 'Server error occurred';
        }
        break;
      case DioExceptionType.cancel:
        message = 'Request was cancelled';
        break;
      case DioExceptionType.connectionError:
        message = 'No internet connection';
        statusCode = 503;
        break;
      default:
        message = 'An unexpected error occurred';
    }

    return {
      'success': false,
      'message': message,
      'status_code': statusCode,
    };
  }
}

/// Device info interceptor to add device information to requests
class DeviceInfoInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    String deviceInfo = '';

    try {
      if (options.headers['mobile_device_infos'] == null) {
        if (Platform.isAndroid) {
          final AndroidDeviceInfo androidInfo = await deviceInfoPlugin.androidInfo;
          deviceInfo = jsonEncode({
            'manufacturer': androidInfo.manufacturer,
            'model': androidInfo.model,
            'device_id': androidInfo.id,
            'version': androidInfo.version.release,
            'version_sdk': androidInfo.version.sdkInt,
            'brand': androidInfo.brand,
            'device': androidInfo.device,
            'isPhysicalDevice': androidInfo.isPhysicalDevice,
          });
        } else if (Platform.isIOS) {
          final IosDeviceInfo iosInfo = await deviceInfoPlugin.iosInfo;
          deviceInfo = jsonEncode({
            'manufacturer': 'Apple',
            'name': iosInfo.name,
            'model': iosInfo.model,
            'device_id': iosInfo.identifierForVendor,
            'version': iosInfo.systemVersion,
            'system_name': iosInfo.systemName,
            'is_physical_device': iosInfo.isPhysicalDevice,
            'brand': 'Apple',
          });
        }
        options.headers['mobile_device_infos'] = deviceInfo;
      }
    } catch (e) {
      print('⚠️ Error setting device info: $e');
      // If there's an error getting device info, continue without it
    }
    
    super.onRequest(options, handler);
  }
}

/// Authentication interceptor to add auth token to requests
class AuthInterceptor extends Interceptor {
  final FlutterSecureStorage _secureStorage;
  final String _apiConsumer;

  AuthInterceptor(this._secureStorage, this._apiConsumer);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      // Add API consumer header
      if (_apiConsumer.isNotEmpty) {
        options.headers['api-consumer'] = _apiConsumer;
      }

      // Add language header
      options.headers['accept-language'] = getx.Get.locale?.languageCode ?? 'fr';

      // Skip auth if explicitly specified with empty Authorization
      if (options.headers.containsKey('Authorization') && options.headers['Authorization'] == '') {
        options.headers.remove('Authorization');
      } 
      // Otherwise add auth token
      else if (!options.headers.containsKey('Authorization') || options.headers['Authorization'] == null) {
        final String? token = await _secureStorage.read(key: 'auth_token');
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
      }
    } catch (e) {
      print('⚠️ Error in Auth Interceptor: $e');
    }

    super.onRequest(options, handler);
  }
}

/// Error interceptor to handle common errors
class ErrorInterceptor extends Interceptor {
  final FlutterSecureStorage _secureStorage;

  ErrorInterceptor(this._secureStorage);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Handle 401 unauthorized errors - refresh token or logout
    if (err.response?.statusCode == 401) {
      // Try to refresh token
      try {
        final dioClient = DioClient();
        final refreshResponse = await dioClient.refreshToken();

        if (refreshResponse['success'] == true) {
          // Retry the original request with the new token
          final options = err.requestOptions;
          final token = await dioClient.getToken();
          
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
            
            try {
              final response = await Dio().fetch(options);
              handler.resolve(response);
              return;
            } catch (e) {
              print('⚠️ Error retrying request after refresh: $e');
              // If retry fails, continue with original error
            }
          }
        } else {
          // Refresh failed, logout the user
          await _secureStorage.delete(key: 'auth_token');
          await _secureStorage.delete(key: 'refresh_token');
          
          // You might want to redirect to login screen or show a notification
          if (getx.Get.routing.current != '/login' && getx.Get.routing.current != '/welcome') {
            getx.Get.offAllNamed('/login');
            getx.Get.snackbar(
              'Session Expired', 
              'Your session has expired. Please login again.',
              snackPosition: getx.SnackPosition.BOTTOM,
              backgroundColor: Colors.red[700],
              colorText: Colors.white,
            );
          }
        }
      } catch (e) {
        print('⚠️ Error in refresh token flow: $e');
      }
    }

    super.onError(err, handler);
  }
}