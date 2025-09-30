import 'dart:io';
import 'package:dio/dio.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import '../config/app_config.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();
  late Dio _dio;
  final GetStorage _storage = GetStorage();

  // Singleton pattern
  factory DioClient() => _instance;

  DioClient._internal() {
    _initDio();
  }

  Dio get dio => _dio;

  Future<void> _initDio() async {
    final BaseOptions options = BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(milliseconds: 30000),
      receiveTimeout: const Duration(milliseconds: 30000),
      responseType: ResponseType.json,
      headers: await _getDefaultHeaders(),
    );

    _dio = Dio(options);
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) async {
          // Add auth token if it exists
          final String? token = _storage.read<String>('auth_token');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          // Update headers on each request to ensure they're current
          options.headers.addAll(await _getDefaultHeaders());

          if (kDebugMode) {
            print('REQUEST[${options.method}] => PATH: ${options.path}');
            print('Headers: ${options.headers}');
            print('Data: ${options.data}');
          }

          return handler.next(options);
        },
        onResponse: (Response response, ResponseInterceptorHandler handler) {
          if (kDebugMode) {
            print('RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
          }
          return handler.next(response);
        },
        onError: (DioException e, ErrorInterceptorHandler handler) async {
          if (kDebugMode) {
            print('ERROR[${e.response?.statusCode}] => PATH: ${e.requestOptions.path}');
            print('Error message: ${e.message}');
          }

          // Handle authentication errors (401)
          if (e.response?.statusCode == 401) {
            // Attempt to refresh token or logout user
            await _handleTokenExpiration();
          }

          return handler.next(e);
        },
      ),
    );
  }

  Future<void> _handleTokenExpiration() async {
    // Implement token refresh logic here if applicable
    // If refresh fails, clear storage and redirect to login
    _storage.remove('auth_token');
    // You could use GetX to navigate to login screen
    // Get.offAllNamed(AppRoutes.login);
  }

  Future<Map<String, dynamic>> _getDefaultHeaders() async {
    final Map<String, dynamic> headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'api-consumer': AppConfig.apiConsumerKey, // Use API consumer from config
    };

    // Add device info for tracking/analytics
    try {
      final deviceInfo = await _getDeviceInfo();
      headers.addAll(deviceInfo);
    } catch (e) {
      if (kDebugMode) {
        print('Could not get device info: $e');
      }
    }

    return headers;
  }

  Future<Map<String, dynamic>> _getDeviceInfo() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    final Map<String, dynamic> deviceInfoHeaders = {};

    try {
      if (Platform.isAndroid) {
        final AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
        deviceInfoHeaders['device-id'] = androidInfo.id;
        deviceInfoHeaders['device-model'] = androidInfo.model;
        deviceInfoHeaders['device-os'] = 'Android ${androidInfo.version.release}';
      } else if (Platform.isIOS) {
        final IosDeviceInfo iosInfo = await deviceInfo.iosInfo;
        deviceInfoHeaders['device-id'] = iosInfo.identifierForVendor;
        deviceInfoHeaders['device-model'] = iosInfo.model;
        deviceInfoHeaders['device-os'] = '${iosInfo.systemName} ${iosInfo.systemVersion}';
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error getting device info: $e');
      }
    }

    return deviceInfoHeaders;
  }

  // Generic GET request with type safety
  Future<T> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final Response response = await _dio.get(
        path,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response.data as T;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // Generic POST request with type safety
  Future<T> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final Response response = await _dio.post(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response.data as T;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // Generic PUT request with type safety
  Future<T> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final Response response = await _dio.put(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response.data as T;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // Generic DELETE request with type safety
  Future<T> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final Response response = await _dio.delete(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response.data as T;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // Generic PATCH request with type safety
  Future<T> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      final Response response = await _dio.patch(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response.data as T;
    } on DioException catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // Generic method to handle errors
  void _handleError(DioException e) {
    String errorMessage = 'Something went wrong. Please try again.';
    
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        errorMessage = 'Connection timeout. Please check your internet connection.';
        break;
      case DioExceptionType.badResponse:
        if (e.response?.statusCode == 400) {
          errorMessage = 'Bad request. Please check your input.';
        } else if (e.response?.statusCode == 401) {
          errorMessage = 'Unauthorized. Please log in again.';
        } else if (e.response?.statusCode == 403) {
          errorMessage = 'Access denied. You don\'t have permission.';
        } else if (e.response?.statusCode == 404) {
          errorMessage = 'Resource not found.';
        } else if (e.response?.statusCode == 500) {
          errorMessage = 'Server error. Please try again later.';
        } else if (e.response?.statusCode == 204) {
          errorMessage = 'No content available.';
        }
        break;
      case DioExceptionType.cancel:
        errorMessage = 'Request cancelled.';
        break;
      case DioExceptionType.connectionError:
        errorMessage = 'Connection error. Please check your internet connection.';
        break;
      case DioExceptionType.unknown:
      default:
        if (e.error is SocketException) {
          errorMessage = 'No internet connection.';
        }
        break;
    }
    
    if (kDebugMode) {
      print('DioError: $errorMessage');
      print('DioError details: ${e.message}');
    }
    
    // You can throw a custom exception here or use a centralized error handler
    // throw CustomException(errorMessage);
  }
}