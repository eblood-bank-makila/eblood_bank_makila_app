import 'dart:io';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart' as getx;

import '../config/app_config.dart';
// Use shared interceptors from dio_client helpers (device info, location, app type)
import '../../../apps/config/api/dio_client.dart' show DeviceInfoInterceptor, LocationInterceptor, AppTypeInterceptor;

/// Improved DioClient that consolidates functionality from multiple implementations
class DioClient {
  // Singleton instance
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;
  
  // Private constructor
  DioClient._internal();
  
  // Dio instance
  late final Dio _dio;
  
  // Secure storage for tokens
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  // Storage keys
  final String _tokenKey = 'auth_token';
  final String _refreshTokenKey = 'refresh_token';
  
  // Getters
  Dio get dio => _dio;

  /// Initialize the Dio client
  Future<void> init() async {
    try {
      print('🔧 DioClient: Initializing...');
      
      // Get base URL from AppConfig
      final baseApiUrl = AppConfig.apiBaseUrl;
      final apiConsumer = AppConfig.apiConsumerKey;
      
      print('🔧 DioClient: Base URL = $baseApiUrl');
      print('🔧 DioClient: API Consumer set = ${apiConsumer.isNotEmpty}');
      
      // Create Dio with base configuration - extended timeouts
      _dio = Dio(BaseOptions(
        baseUrl: baseApiUrl,
        connectTimeout: const Duration(milliseconds: 45000), // Increased to 45s
        receiveTimeout: const Duration(milliseconds: 60000), // Increased to 60s
        sendTimeout: const Duration(milliseconds: 45000),    // Increased to 45s
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Accept-Language': getx.Get.locale?.languageCode ?? 'fr',
        },
      ));
      
      // Shared interceptors aligned with dio_client helpers (getWithDio, postWithDio, etc.)
      // These add device_id, mobile_device_infos, location, App-Type headers
      _dio.interceptors.add(DeviceInfoInterceptor());
      _dio.interceptors.add(LocationInterceptor());
      _dio.interceptors.add(_createAuthInterceptor());
      _dio.interceptors.add(AppTypeInterceptor());
      _dio.interceptors.add(_createErrorInterceptor());
      
      // Add logging in debug mode
      if (kDebugMode) {
        _dio.interceptors.add(LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: true,
          responseHeader: true,
          error: true,
          logPrint: (obj) => debugPrint('🌐 DIO: ${obj.toString()}'),
        ));
      }
      
      print('🚀 DioClient successfully initialized');
    } catch (e) {
      print('⚠️ Error initializing DioClient: $e');
      throw Exception('Failed to initialize DioClient: $e');
    }
  }

  /// Auth interceptor — handles api-consumer, auth token, and language.
  /// Device info, location, and app-type are handled by shared interceptors.
  Interceptor _createAuthInterceptor() {
    return InterceptorsWrapper(
      onRequest: (RequestOptions options, RequestInterceptorHandler handler) async {
        try {
          // Add API consumer key
          final apiConsumer = AppConfig.apiConsumerKey;
          if (apiConsumer.isNotEmpty) {
            options.headers['api-consumer'] = apiConsumer;
          }
          
          // Add authentication token only if caller didn't already set one
          final bool hasExplicitAuthHeader = options.headers.containsKey('Authorization') &&
              options.headers['Authorization'] != null &&
              (options.headers['Authorization'] as String).isNotEmpty;

          if (hasExplicitAuthHeader) {
            // Respect explicit Authorization header (e.g., temporary MFA token)
          } else if (options.headers['Authorization'] == '') {
            // Remove authorization header if explicitly set to empty
            options.headers.remove('Authorization');
          } else {
            // Otherwise, inject stored auth token if present
            final token = await _secureStorage.read(key: _tokenKey);
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          
          // Add language header
          options.headers['accept-language'] = getx.Get.locale?.languageCode ?? 'fr';
          
          handler.next(options);
        } catch (e) {
          print('⚠️ Error in auth interceptor: $e');
          handler.next(options);
        }
      },
      onResponse: (Response response, ResponseInterceptorHandler handler) {
        if (kDebugMode) {
          print('📥 Response: [${response.statusCode}] ${response.requestOptions.uri}');
          print('📥 Data: ${response.data is Map ? json.encode(response.data) : "Non-JSON data"}');
        }
        handler.next(response);
      },
    );
  }

  /// Error interceptor — handles 401 token refresh + retry
  Interceptor _createErrorInterceptor() {
    return InterceptorsWrapper(
      onError: (DioException err, ErrorInterceptorHandler handler) async {
        if (kDebugMode) {
          print('❌ Error: [${err.response?.statusCode}] ${err.requestOptions.uri}');
          print('❌ Message: ${err.message}');
          if (err.response?.data != null) {
            print('❌ Error Data: ${err.response?.data}');
          }
        }
        
        // Handle 401 unauthorized errors
        if (err.response?.statusCode == 401) {
          // Try to refresh the token
          final refreshed = await _refreshToken();
          if (refreshed) {
            // Retry the original request
            try {
              final token = await _secureStorage.read(key: _tokenKey);
              final options = err.requestOptions;
              options.headers['Authorization'] = 'Bearer $token';
              
              // Create a new request
              final response = await Dio().fetch(options);
              return handler.resolve(response);
            } catch (e) {
              print('⚠️ Error retrying request after token refresh: $e');
            }
          } else {
            // Token refresh failed, logout the user
            await _logout();
          }
        }
        
        // Handle no internet connection
        if (err.type == DioExceptionType.connectionError ||
            err.error is SocketException) {
          print('⚠️ No internet connection');
        }
        
        // Continue with the error
        handler.next(err);
      }
    );
  }

  /// Refresh authentication token
  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _secureStorage.read(key: _refreshTokenKey);
      if (refreshToken == null || refreshToken.isEmpty) {
        return false;
      }
      
      // Create a new Dio instance for token refresh to avoid interceptor loops
      final tokenDio = Dio(BaseOptions(
        baseUrl: _dio.options.baseUrl,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'api-consumer': AppConfig.apiConsumerKey,
        }
      ));
      
      final response = await tokenDio.post(
        '/auth/refresh-token',
        data: {'refresh_token': refreshToken},
      );
      
      if (response.statusCode == 200 && response.data['access_token'] != null) {
        // Save new tokens
        await _secureStorage.write(key: _tokenKey, value: response.data['access_token']);
        
        if (response.data['refresh_token'] != null) {
          await _secureStorage.write(key: _refreshTokenKey, value: response.data['refresh_token']);
        }
        
        return true;
      }
      
      return false;
    } catch (e) {
      print('⚠️ Error refreshing token: $e');
      return false;
    }
  }

  /// Logout user and clear tokens
  Future<void> _logout() async {
    try {
      // Try to call logout endpoint (ignoring result)
      try {
        await _dio.post('/auth/logout');
      } catch (_) {
        // Ignore errors during logout
      }
    } finally {
      // Always clear tokens regardless of API call success
      await _secureStorage.delete(key: _tokenKey);
      await _secureStorage.delete(key: _refreshTokenKey);
      
      // Navigate to login screen
      // You might want to implement this in a separate service
      // Get.offAllNamed('/login');
    }
  }

  /// Test API connection with timeout handling
  Future<bool> testApiConnection({Duration? timeout}) async {
    try {
      print('🔄 Testing API connection...');
      
      // Use a simple endpoint to test connection
      final url = '/health';
      print('🔄 Testing connection to: ${_dio.options.baseUrl}$url');
      
      // Use a shorter timeout for this test to avoid blocking app startup
      final testTimeout = timeout ?? const Duration(seconds: 10);
      
      // Create a timeout for this specific test
      final response = await _dio.get(
        url,
        options: Options(
          // Override the global timeout just for this request
          receiveTimeout: testTimeout,
          sendTimeout: testTimeout,
        ),
      ).timeout(
        testTimeout,
        onTimeout: () {
          print('⏱️ API connection test timed out after ${testTimeout.inSeconds}s');
          throw DioException(
            requestOptions: RequestOptions(path: url),
            error: 'Connection test timeout',
            type: DioExceptionType.connectionTimeout,
          );
        },
      );
      
      print('✅ API connection test successful: ${response.statusCode}');
      return response.statusCode == 200;
    } catch (e) {
      print('❌ API connection test failed: $e');
      return false;
    }
  }

  /// Login with username and password
  Future<Map<String, dynamic>> login({
    required String username, 
    required String password,
  }) async {
    try {
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
      print('Login error: $e');
      return {
        'success': false,
        'message': 'An unexpected error occurred. Please try again.',
        'status_code': 500,
      };
    }
  }

  /// GET request wrapper with standardized error handling
  Future<Map<String, dynamic>> get(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    bool requireAuth = true,
    String? customBaseUrl,
  }) async {
    try {
      final options = Options(
        headers: requireAuth ? null : {'Authorization': ''},
      );
      
      final String url = customBaseUrl != null ? '$customBaseUrl$endpoint' : endpoint;
      final response = await _dio.get(
        url,
        queryParameters: queryParams,
        options: options,
      );
      
      return response.data is Map<String, dynamic> 
          ? response.data 
          : {'data': response.data, 'success': true};
    } on DioException catch (e) {
      return _handleDioException(e);
    }
  }

  /// POST request wrapper with standardized error handling
  Future<Map<String, dynamic>> post(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParams,
    bool requireAuth = true,
    String? customBaseUrl,
  }) async {
    try {
      final options = Options(
        headers: requireAuth ? null : {'Authorization': ''},
      );
      
      final String url = customBaseUrl != null ? '$customBaseUrl$endpoint' : endpoint;
      final response = await _dio.post(
        url,
        data: data,
        queryParameters: queryParams,
        options: options,
      );
      
      return response.data is Map<String, dynamic> 
          ? response.data 
          : {'data': response.data, 'success': true};
    } on DioException catch (e) {
      return _handleDioException(e);
    }
  }

  /// PUT request wrapper with standardized error handling
  Future<Map<String, dynamic>> put(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParams,
    bool requireAuth = true,
    String? customBaseUrl,
  }) async {
    try {
      final options = Options(
        headers: requireAuth ? null : {'Authorization': ''},
      );
      
      final String url = customBaseUrl != null ? '$customBaseUrl$endpoint' : endpoint;
      final response = await _dio.put(
        url,
        data: data,
        queryParameters: queryParams,
        options: options,
      );
      
      return response.data is Map<String, dynamic> 
          ? response.data 
          : {'data': response.data, 'success': true};
    } on DioException catch (e) {
      return _handleDioException(e);
    }
  }

  /// DELETE request wrapper with standardized error handling
  Future<Map<String, dynamic>> delete(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParams,
    bool requireAuth = true,
    String? customBaseUrl,
  }) async {
    try {
      final options = Options(
        headers: requireAuth ? null : {'Authorization': ''},
      );
      
      final String url = customBaseUrl != null ? '$customBaseUrl$endpoint' : endpoint;
      final response = await _dio.delete(
        url,
        data: data,
        queryParameters: queryParams,
        options: options,
      );
      
      return response.data is Map<String, dynamic> 
          ? response.data 
          : {'data': response.data, 'success': true};
    } on DioException catch (e) {
      return _handleDioException(e);
    }
  }

  /// PATCH request wrapper with standardized error handling
  Future<Map<String, dynamic>> patch(
    String endpoint, {
    dynamic data,
    Map<String, dynamic>? queryParams,
    bool requireAuth = true,
    String? customBaseUrl,
  }) async {
    try {
      final options = Options(
        headers: requireAuth ? null : {'Authorization': ''},
      );
      
      final String url = customBaseUrl != null ? '$customBaseUrl$endpoint' : endpoint;
      final response = await _dio.patch(
        url,
        data: data,
        queryParameters: queryParams,
        options: options,
      );
      
      return response.data is Map<String, dynamic> 
          ? response.data 
          : {'data': response.data, 'success': true};
    } on DioException catch (e) {
      return _handleDioException(e);
    }
  }

  /// Upload file with progress tracking
  Future<Map<String, dynamic>> uploadFile(
    String endpoint, {
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
      
      return response.data is Map<String, dynamic> 
          ? response.data 
          : {'data': response.data, 'success': true};
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

  /// Standard error handling for Dio exceptions
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
        statusCode = 499; // Nginx code for client closed request
        break;
      case DioExceptionType.connectionError:
        message = 'No internet connection';
        statusCode = 503;
        break;
      default:
        if (e.error is SocketException) {
          message = 'No internet connection';
          statusCode = 503;
        } else {
          message = 'An unexpected error occurred';
        }
    }

    return {
      'success': false,
      'message': message,
      'status_code': statusCode,
      'error': e.toString(),
    };
  }
}