import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:eblood_bank_mak_app/apps/models/api_response.dart';
import 'package:eblood_bank_mak_app/apps/services/AuthService.dart';
import 'package:eblood_bank_mak_app/apps/services/error_navigation_service.dart';
import 'package:eblood_bank_mak_app/core/services/location_tracking_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// import 'package:ebloodbankauth/model/api_response.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:ebloodbankauth/services/auth_service.dart';
// import 'package:ebloodbankauth/services/error_navigation_service.dart';

final _baseUrl = dotenv.env['BASE_API_URL'] ?? 'http://localhost';
final _apiConsumer = dotenv.env['API_CONSUMER'] ?? '';
final _secureStorage = const FlutterSecureStorage();

// Get token from secure storage
Future<String?> _getToken() async {
  try {
    debugPrint('🔍 AuthInterceptor: Reading token from secure storage (key: auth_token)...');
    final token = await _secureStorage.read(key: 'auth_token');
    if (token != null && token.isNotEmpty) {
      debugPrint('✅ AuthInterceptor: Token found: ${token.substring(0, 20)}...');
    } else {
      debugPrint('⚠️ AuthInterceptor: No token found in secure storage');
    }
    return token;
  } catch (e) {
    debugPrint('❌ AuthInterceptor: Error retrieving token: $e');
    return null;
  }
}

class DeviceInfoInterceptor extends Interceptor {
  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final DeviceInfoPlugin deviceInfoPlugin = DeviceInfoPlugin();
    String deviceInfo = '';

    if (options.headers['mobile_device_infos'] == null) {
      if (Platform.isAndroid) {
        final AndroidDeviceInfo androidInfo =
            await deviceInfoPlugin.androidInfo;
        deviceInfo = jsonEncode({
          'manufacturer': androidInfo.manufacturer,
          'model': androidInfo.model,
          'device_id': androidInfo.id,
          'version': androidInfo.version.release, // Android version like "11", "12", etc.
          'version_sdk': androidInfo.version.sdkInt, // SDK version like 30, 31, etc.
          'version_codename': androidInfo.version.codename, // Codename like "REL"
          'version_incremental': androidInfo.version.incremental, // Build incremental
          'version_security_patch': androidInfo.version.securityPatch, // Security patch date
          'android_id': androidInfo.id, // Android ID
          'brand': androidInfo.brand, // Device brand
          'device': androidInfo.device, // Device name
          'display': androidInfo.display, // Build display
          'fingerprint': androidInfo.fingerprint, // Build fingerprint
          'hardware': androidInfo.hardware, // Hardware name
          'host': androidInfo.host, // Build host
          'product': androidInfo.product, // Product name
          'supported32BitAbis': androidInfo.supported32BitAbis, // Supported 32-bit ABIs
          'supported64BitAbis': androidInfo.supported64BitAbis, // Supported 64-bit ABIs
          'supportedAbis': androidInfo.supportedAbis, // All supported ABIs
          'tags': androidInfo.tags, // Build tags
          'type': androidInfo.type, // Build type
          'isPhysicalDevice': androidInfo.isPhysicalDevice, // Is physical device
        });
      } else if (Platform.isIOS) {
        final IosDeviceInfo iosInfo = await deviceInfoPlugin.iosInfo;
        deviceInfo = jsonEncode({
          'manufacturer': 'Apple', // iOS devices are always Apple
          'name': iosInfo.name, // Device name set by user
          'model': iosInfo.model, // Device model
          'device_id': iosInfo.identifierForVendor, // Unique identifier
          'version': iosInfo.systemVersion, // iOS version like "15.0", "16.1", etc.
          'system_name': iosInfo.systemName, // "iOS" or "iPadOS"
          'localized_model': iosInfo.localizedModel, // Localized model name
          'machine': iosInfo.utsname.machine, // Hardware identifier like "iPhone14,2"
          'is_physical_device': iosInfo.isPhysicalDevice, // Is physical device
          'brand': 'Apple', // Brand is always Apple for iOS
        });
      }
    }
    options.headers['mobile_device_infos'] = deviceInfo;
    // debugPrint('DeviceInfoInterceptor - Headers: ${options.headers}');
    super.onRequest(options, handler);
  }
}

class LocationInterceptor extends Interceptor {
  LocationInterceptor();

  final LocationTrackingService _locationService = LocationTrackingService();

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      // Use synchronous cached location - no blocking!
      final location = _locationService.getCachedLocationSync();
      final latitude = location['latitude'];
      final longitude = location['longitude'];

      if (latitude != null && latitude.isFinite) {
        options.headers['latitude'] = latitude.toString();
      }
      if (longitude != null && longitude.isFinite) {
        options.headers['longitude'] = longitude.toString();
      }

      debugPrint('LocationInterceptor - Location: $latitude, $longitude');
    } catch (e) {
      debugPrint('LocationInterceptor - Error: $e');
    }

    super.onRequest(options, handler);
  }
}

class AuthInterceptor extends Interceptor {
  @override
  void onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    debugPrint('🔐 AuthInterceptor: Processing request to ${options.path}');

    // Only set Authorization header if it's not already set (preserve custom headers)
    if (!options.headers.containsKey('Authorization') ||
        options.headers['Authorization'] == null ||
        options.headers['Authorization'] == '') {
      final String? token = await _getToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
        debugPrint('✅ AuthInterceptor: Added Authorization header to request');
      } else {
        options.headers['Authorization'] = '';
        debugPrint('⚠️ AuthInterceptor: No token available, Authorization header set to empty');
      }
    } else {
      debugPrint('ℹ️ AuthInterceptor: Preserving existing Authorization header');
    }

    options.headers['api-consumer'] = _apiConsumer;

    // Get current app language from shared preferences
    final String currentLanguage = await _getCurrentLanguage();
    options.headers['accept-language'] = currentLanguage;

    debugPrint('AuthInterceptor - Path: ${options.path}');
    super.onRequest(options, handler);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // debugPrint('AuthInterceptor - Response: ${response.data}', wrapWidth: 1024);
    super.onResponse(response, handler);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    debugPrint('AuthInterceptor - Error: ${err.message}', wrapWidth: 1024);
    debugPrint('AuthInterceptor - Response: ${err.response?.data}',
        wrapWidth: 1024);

    try {
      // Handle special error cases first
      await _handleSpecialErrors(err);

      // LOGOUT ON 401 ERROR
      final String? token = await _getToken();
      if (err.response?.statusCode == 401 && token != null) {
        debugPrint('AuthInterceptor - 401 Error: ${err.message}',
            wrapWidth: 1024);
        debugPrint('AuthInterceptor - 401 Response: ${err.response?.data}',
            wrapWidth: 1024);
        // LOGOUT USER (with timeout to prevent hanging)
        await AuthService().logout(silent: true).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint('AuthInterceptor - Logout timeout, continuing...');
            return false; // Return false on timeout
          },
        );
      }
    } catch (e) {
      debugPrint('AuthInterceptor - Error during logout: $e');
      // Continue with error handling even if logout fails
    }

    // Always continue with the error to prevent hanging
    handler.next(err);
  }

  /// Handle special error cases like device/account related issues
  Future<void> directHandleSpecialErrors(dynamic response) async {
    final responseData = response;
    debugPrint('AuthInterceptor - Response > : $responseData', wrapWidth: 1024);


    if (responseData == null || responseData is! Map<String, dynamic>) {
      return;
    }

    // Check for device related issues
    if (responseData.containsKey('is_device_related_issue')) {
      debugPrint('AuthInterceptor - Device related issue detected');
      await _handleDeviceRelatedIssue(responseData);
      return;
    }

    // Check for account related issues
    if (responseData.containsKey('is_account_related_issue')) {
      debugPrint('AuthInterceptor - Account related issue detected');
      await _handleAccountRelatedIssue(responseData);
      return;
    }
  }
  Future<void> _handleSpecialErrors(DioException err) async {
    final responseData = err.response?.data;
    debugPrint('AuthInterceptor - Response > : $responseData', wrapWidth: 1024);


    if (responseData == null || responseData is! Map<String, dynamic>) {
      return;
    }

    // Check for device related issues
    if (responseData.containsKey('is_device_related_issue')) {
      debugPrint('AuthInterceptor - Device related issue detected');
      await _handleDeviceRelatedIssue(responseData);
      return;
    }

    // Check for account related issues
    if (responseData.containsKey('is_account_related_issue')) {
      debugPrint('AuthInterceptor - Account related issue detected');
      await _handleAccountRelatedIssue(responseData);
      return;
    }
  }

  /// Handle device related issues
  Future<void> _handleDeviceRelatedIssue(Map<String, dynamic> errorData) async {
    try {
      final authService = AuthService();

      // Store device not allowed info
      await authService.setDeviceNotAllowedInfo(
        token: errorData['token']?.toString() ?? '',
        message: errorData['message']?.toString() ?? 'Device not allowed',
        supportEmail: errorData['support_email']?.toString() ?? '',
      );

      // Handle token encryption if token is provided
      if (errorData['token'] != null) {
        await authService.handleTokenEncryption(errorData['token'].toString(), false);
      }

      // Set navigation flag
      await authService.setCanNavigateToDeviceNotAllowed(true);

      // Navigate to device not allowed screen
      await _navigateToDeviceNotAllowed();

    } catch (e) {
      debugPrint('Error handling device related issue: $e');
    }
  }

  /// Handle account related issues
  Future<void> _handleAccountRelatedIssue(Map<String, dynamic> errorData) async {
    try {
      final authService = AuthService();

      // Store account not allowed info (reusing device info structure)
      await authService.setDeviceNotAllowedInfo(
        token: errorData['token']?.toString() ?? '',
        message: errorData['message']?.toString() ?? 'Account not allowed',
        supportEmail: errorData['support_email']?.toString() ?? '',
      );

      // Handle token encryption if token is provided
      if (errorData['token'] != null) {
        await authService.handleTokenEncryption(errorData['token'].toString(), false);
      }

      // Set navigation flag
      await authService.setCanNavigateToDeviceNotAllowed(true);

      // Navigate to account not allowed screen
      await _navigateToAccountNotAllowed();

    } catch (e) {
      debugPrint('Error handling account related issue: $e');
    }
  }

  /// Navigate to device not allowed screen
  Future<void> _navigateToDeviceNotAllowed() async {
    try {
      await ErrorNavigationService.navigateToDeviceNotAllowed();
      debugPrint('Navigated to device not allowed screen');
    } catch (e) {
      debugPrint('Error navigating to device not allowed screen: $e');
    }
  }

  /// Navigate to account not allowed screen
  Future<void> _navigateToAccountNotAllowed() async {
    try {
      await ErrorNavigationService.navigateToAccountNotAllowed();
      debugPrint('Navigated to account not allowed screen');
    } catch (e) {
      debugPrint('Error navigating to account not allowed screen: $e');
    }
  }
}

class AppTypeInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['App-Type'] = 'mobile';
    // debugPrint('AppTypeInterceptor - Headers: ${options.headers}',
    //     wrapWidth: 1024);
    super.onRequest(options, handler);
  }
}

Dio _configureDio({Duration timeoutDuration = const Duration(seconds: 120)}) {
  final dio = Dio();
  dio.options
    ..baseUrl = _baseUrl
    ..connectTimeout = timeoutDuration //
    ..receiveTimeout = timeoutDuration
    ..headers = <String, dynamic>{} // ensure non-null headers map
    // Configure Dio to NOT throw exceptions for HTTP status codes
    // This prevents app freezing on 4xx and 5xx responses
    ..validateStatus = (status) => true; // Accept all status codes

  dio.interceptors.addAll([
    DeviceInfoInterceptor(),
    LocationInterceptor(),
    AuthInterceptor(),
    AppTypeInterceptor(),
    // LogInterceptor(
    //   request: true,
    //   requestHeader: true,
    //   requestBody: true,
    //   responseHeader: true,
    //   responseBody: true,
    //   error: true,
    //   logPrint: (log) => debugPrint("$log"),
    // ),
  ]);

  return dio;
}

/// Handle special error cases like device/account related issues for successful responses
Future<void> _directHandleSpecialErrors(dynamic response) async {
  debugPrint('DirectHandleSpecialErrors - Response > : $response', wrapWidth: 1024);

  // Extract data from response object if it's a Response, otherwise use as-is
  dynamic responseData;
  if (response != null && response.runtimeType.toString().contains('Response')) {
    responseData = response.data;
  } else {
    responseData = response;
  }

  if (responseData == null || responseData is! Map<String, dynamic>) {
    return;
  }

  debugPrint('DirectHandleSpecialErrors - Checking for special issues in: $responseData');

  // Check for device related issues
  if (responseData.containsKey('is_device_related_issue')) {
    debugPrint('DirectHandleSpecialErrors - Device related issue detected: ${responseData['is_device_related_issue']}');
    await _handleDeviceRelatedIssueStandalone(responseData);
    return;
  }

  // Check for account related issues
  if (responseData.containsKey('is_account_related_issue')) {
    debugPrint('DirectHandleSpecialErrors - Account related issue detected: ${responseData['is_account_related_issue']}');
    await _handleAccountRelatedIssueStandalone(responseData);
    return;
  }

  debugPrint('DirectHandleSpecialErrors - No special issues detected');
}

/// Handle device related issues (standalone version)
Future<void> _handleDeviceRelatedIssueStandalone(Map<String, dynamic> errorData) async {
  try {
    debugPrint('Handling device related issue with data: $errorData');
    final authService = AuthService();

    // Store device not allowed info
    await authService.setDeviceNotAllowedInfo(
      token: errorData['token']?.toString() ?? '',
      message: errorData['message']?.toString() ?? 'Device not allowed',
      supportEmail: errorData['support_email']?.toString() ?? '',
    );
    debugPrint('Device not allowed info stored');

    // Handle token encryption if token is provided
    if (errorData['token'] != null) {
      await authService.handleTokenEncryption(errorData['token'].toString(), false);
      debugPrint('Token encryption handled');
    }

    // Set navigation flag
    await authService.setCanNavigateToDeviceNotAllowed(true);
    debugPrint('Navigation flag set to true');

    // Navigate to device not allowed screen with error handling
    // Add small delay to ensure UI is ready
    await Future.delayed(const Duration(milliseconds: 100));
    await _navigateToDeviceNotAllowedStandalone();

  } catch (e) {
    debugPrint('Error handling device related issue: $e');
  }
}

/// Handle account related issues (standalone version)
Future<void> _handleAccountRelatedIssueStandalone(Map<String, dynamic> errorData) async {
  try {
    debugPrint('Handling account related issue with data: $errorData');
    final authService = AuthService();

    // Store account not allowed info (reusing device info structure)
    await authService.setDeviceNotAllowedInfo(
      token: errorData['token']?.toString() ?? '',
      message: errorData['message']?.toString() ?? 'Account not allowed',
      supportEmail: errorData['support_email']?.toString() ?? '',
    );
    debugPrint('Account not allowed info stored');

    // Handle token encryption if token is provided
    if (errorData['token'] != null) {
      await authService.handleTokenEncryption(errorData['token'].toString(), false);
      debugPrint('Token encryption handled');
    }

    // Set navigation flag
    await authService.setCanNavigateToDeviceNotAllowed(true);
    debugPrint('Navigation flag set to true');

    // Navigate to account not allowed screen with error handling
    await _navigateToAccountNotAllowedStandalone();

  } catch (e) {
    debugPrint('Error handling account related issue: $e');
  }
}

/// Navigate to device not allowed screen (standalone version)
Future<void> _navigateToDeviceNotAllowedStandalone() async {
  try {
    debugPrint('Attempting to navigate to device not allowed screen');
    await ErrorNavigationService.navigateToDeviceNotAllowed();
    debugPrint('Successfully navigated to device not allowed screen');
  } catch (e) {
    debugPrint('Error navigating to device not allowed screen: $e');
  }
}

/// Navigate to account not allowed screen (standalone version)
Future<void> _navigateToAccountNotAllowedStandalone() async {
  try {
    debugPrint('Attempting to navigate to account not allowed screen');
    await ErrorNavigationService.navigateToAccountNotAllowed();
    debugPrint('Successfully navigated to account not allowed screen');
  } catch (e) {
    debugPrint('Error navigating to account not allowed screen: $e');
  }
}

FutureOr<IApiResponse> postWithDio(
  String endpoint, {
  Map<String, dynamic>? body,
  Map<String, String>? headers,
  Duration timeoutDuration = const Duration(seconds: 60),
}) async {
  final dio = _configureDio(timeoutDuration: timeoutDuration);
  final url = _baseUrl + endpoint;
  debugPrint('POST Request to: $url with body: $body', wrapWidth: 1024);

  try {
    final response = await dio.post(
      url,
      data: body,
      options: Options(headers: headers != null ? Map<String, dynamic>.from(headers) : <String, dynamic>{}),
    );

    debugPrint('POST Response to: $response');
    await _directHandleSpecialErrors(response);
    if (response.statusCode == 200 || response.statusCode == 201) {
      // debugPrint('POST Response to: ${response.data}');
      return IApiResponse.fromData(response.data);
    } else {
      // Check if response contains a message property, otherwise use default message
      final errorMessage = _extractErrorMessage(
        response.data,
        'Request failed with status: ${response.statusCode}'
      );

      return IApiResponse(
        success: false,
        message: errorMessage,
        statusCode: response.statusCode,
      );
    }
  } on DioException catch (e) {
    debugPrint('POST Error: ${e.message}');
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return IApiResponse(
        success: false,
        message: 'Request to $endpoint timed out',
        statusCode: 408, // Request Timeout
      );
    } else if (e.type == DioExceptionType.badResponse) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 401) {
        return IApiResponse(
          success: false,
          message: 'Unauthorized',
          statusCode: 401,
        );
      }
      return IApiResponse(
        success: false,
        message: e.response?.data?['message'] ?? 'Request failed',
        statusCode: statusCode ?? 500,
      );
    } else if (e.type == DioExceptionType.connectionError) {
      return IApiResponse(
        success: false,
        message: 'Connection error - please check your internet connection',
        statusCode: 503, // Service Unavailable
      );
    }
    return IApiResponse(
      success: false,
      message: e.message ?? 'Unknown error',
      statusCode: 500,
    );
  } catch (e) {
    debugPrint('POST Unknown Error: $e');
    return IApiResponse(
      success: false,
      message: 'Unknown error occurred',
      statusCode: 500,
    );
  }
}

FutureOr<IApiResponse> getWithDio(
  String endpoint, {
  Map<String, dynamic>? queryParams,
  Map<String, String>? headers,
  Duration timeoutDuration = const Duration(seconds: 120),
}) async {
  final dio = _configureDio(timeoutDuration: timeoutDuration);
  final url = _baseUrl + endpoint;
  debugPrint('GET Request to: $url');

  try {
    final response = await dio.get(
      url,
      queryParameters: queryParams,
      options: Options(headers: headers != null ? Map<String, dynamic>.from(headers) : <String, dynamic>{}),
    );

    // Handle all status codes since validateStatus = true
    await _directHandleSpecialErrors(response);
    if (response.statusCode == 200) {
      return IApiResponse.fromData(response.data);
    } else if (response.statusCode == 401) {
      return IApiResponse(
        success: false,
        message: 'Unauthorized',
        statusCode: 401,
      );
    } else if (response.statusCode == 404) {
      return IApiResponse(
        success: false,
        message: 'Resource not found',
        statusCode: 404,
      );
    } else if (response.statusCode! >= 400 && response.statusCode! < 500) {
      // Client errors (4xx)
      String errorMessage = 'Client error';
      if (response.data != null && response.data is Map<String, dynamic>) {
        final responseData = response.data as Map<String, dynamic>;
        if (responseData.containsKey('message') && responseData['message'] != null) {
          errorMessage = responseData['message'].toString();
        }
      }
      return IApiResponse(
        success: false,
        message: errorMessage,
        statusCode: response.statusCode!,
      );
    } else if (response.statusCode! >= 500) {
      // Server errors (5xx)
      String errorMessage = 'Server error';
      if (response.data != null && response.data is Map<String, dynamic>) {
        final responseData = response.data as Map<String, dynamic>;
        if (responseData.containsKey('message') && responseData['message'] != null) {
          errorMessage = responseData['message'].toString();
        }
      }
      return IApiResponse(
        success: false,
        message: errorMessage,
        statusCode: response.statusCode!,
      );
    } else {
      // Other status codes
      String errorMessage = 'Unexpected response: ${response.statusCode}';
      if (response.data != null && response.data is Map<String, dynamic>) {
        final responseData = response.data as Map<String, dynamic>;
        if (responseData.containsKey('message') && responseData['message'] != null) {
          errorMessage = responseData['message'].toString();
        }
      }
      return IApiResponse(
        success: false,
        message: errorMessage,
        statusCode: response.statusCode!,
      );
    }
  } on DioException catch (e) {
    debugPrint('GET Error: ${e.message}');
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return IApiResponse(
        success: false,
        message: 'Request to $endpoint timed out',
        statusCode: 408,
      );
    } else if (e.type == DioExceptionType.connectionError) {
      return IApiResponse(
        success: false,
        message: 'Connection error - please check your internet connection',
        statusCode: 503,
      );
    }
    return IApiResponse(
      success: false,
      message: e.message ?? 'Unknown error',
      statusCode: 500,
    );
  } catch (e) {
    debugPrint('GET Unknown Error: $e');
    return IApiResponse(
      success: false,
      message: 'Unknown error occurred',
    );
  }
}
FutureOr<IApiResponse> getWithDioWithBaseUrl(
  String endpoint, {
  Map<String, dynamic>? queryParams,
  Map<String, String>? headers,
  Duration timeoutDuration = const Duration(seconds: 60),
}) async {
  final dio = _configureDio(timeoutDuration: timeoutDuration);
  final url =  endpoint;
  debugPrint('GET Request to: $url');

  try {
    final response = await dio.get(
      url,
      queryParameters: queryParams,
      options: Options(headers: headers != null ? Map<String, dynamic>.from(headers) : <String, dynamic>{}),
    );

    // Handle all status codes since validateStatus = true
    await _directHandleSpecialErrors(response);
    if (response.statusCode == 200) {
      return IApiResponse.fromData(response.data);
    } else if (response.statusCode == 401) {
      return IApiResponse(
        success: false,
        message: 'Unauthorized',
        statusCode: 401,
      );
    } else if (response.statusCode == 404) {
      return IApiResponse(
        success: false,
        message: 'Resource not found',
        statusCode: 404,
      );
    } else if (response.statusCode! >= 400 && response.statusCode! < 500) {
      // Client errors (4xx)
      String errorMessage = 'Client error';
      if (response.data != null && response.data is Map<String, dynamic>) {
        final responseData = response.data as Map<String, dynamic>;
        if (responseData.containsKey('message') && responseData['message'] != null) {
          errorMessage = responseData['message'].toString();
        }
      }
      return IApiResponse(
        success: false,
        message: errorMessage,
        statusCode: response.statusCode!,
      );
    } else if (response.statusCode! >= 500) {
      // Server errors (5xx)
      String errorMessage = 'Server error';
      if (response.data != null && response.data is Map<String, dynamic>) {
        final responseData = response.data as Map<String, dynamic>;
        if (responseData.containsKey('message') && responseData['message'] != null) {
          errorMessage = responseData['message'].toString();
        }
      }
      return IApiResponse(
        success: false,
        message: errorMessage,
        statusCode: response.statusCode!,
      );
    } else {
      // Other status codes
      String errorMessage = 'Unexpected response: ${response.statusCode}';
      if (response.data != null && response.data is Map<String, dynamic>) {
        final responseData = response.data as Map<String, dynamic>;
        if (responseData.containsKey('message') && responseData['message'] != null) {
          errorMessage = responseData['message'].toString();
        }
      }
      return IApiResponse(
        success: false,
        message: errorMessage,
        statusCode: response.statusCode!,
      );
    }
  } on DioException catch (e) {
    debugPrint('GET Error: ${e.message}');
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return IApiResponse(
        success: false,
        message: 'Request to $endpoint timed out',
        statusCode: 408,
      );
    } else if (e.type == DioExceptionType.connectionError) {
      return IApiResponse(
        success: false,
        message: 'Connection error - please check your internet connection',
        statusCode: 503,
      );
    }
    return IApiResponse(
      success: false,
      message: e.message ?? 'Unknown error',
      statusCode: 500,
    );
  } catch (e) {
    debugPrint('GET Unknown Error: $e');
    return IApiResponse(
      success: false,
      message: 'Unknown error occurred',
    );
  }
}

FutureOr<IApiResponse> putWithDio(
  String endpoint, {
  Map<String, dynamic>? body,
  Map<String, dynamic>? queryParams,
  Map<String, String>? headers,
  Duration timeoutDuration = const Duration(seconds: 60),
}) async {
  final dio = _configureDio(timeoutDuration: timeoutDuration);
  final url = _baseUrl + endpoint;
  debugPrint('PUT Request to: $url with body: $body');

  try {
    final response = await dio.put(
      url,
      data: body,
      queryParameters: queryParams,
      options: Options(headers: headers != null ? Map<String, dynamic>.from(headers) : <String, dynamic>{}),
    );

    debugPrint('PUT Response: $response');
    await _directHandleSpecialErrors(response);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return IApiResponse.fromData(response.data);
    } else {
      final errorMessage = _extractErrorMessage(
        response.data,
        'Request failed with status: ${response.statusCode}'
      );

      return IApiResponse(
        success: false,
        message: errorMessage,
        statusCode: response.statusCode,
      );
    }
  } on DioException catch (e) {
    debugPrint('PUT Error: ${e.message}');
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return IApiResponse(
        success: false,
        message: 'Request to $endpoint timed out',
        statusCode: 408,
      );
    } else if (e.type == DioExceptionType.badResponse) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 401) {
        return IApiResponse(
          success: false,
          message: 'Unauthorized',
          statusCode: 401,
        );
      }
      return IApiResponse(
        success: false,
        message: e.response?.data?['message'] ?? 'Request failed',
        statusCode: statusCode ?? 500,
      );
    } else if (e.type == DioExceptionType.connectionError) {
      return IApiResponse(
        success: false,
        message: 'Connection error - please check your internet connection',
        statusCode: 503,
      );
    }
    return IApiResponse(
      success: false,
      message: e.message ?? 'Unknown error',
      statusCode: 500,
    );
  } catch (e) {
    debugPrint('PUT Unknown Error: $e');
    return IApiResponse(
      success: false,
      message: 'Unknown error occurred',
      statusCode: 500,
    );
  }
}

FutureOr<IApiResponse> deleteWithDio(
  String endpoint, {
  Map<String, dynamic>? queryParams,
  Map<String, String>? headers,
  Duration timeoutDuration = const Duration(seconds: 60),
}) async {
  final dio = _configureDio(timeoutDuration: timeoutDuration);
  final url = _baseUrl + endpoint;
  debugPrint('DELETE Request to: $url');

  try {
    final response = await dio.delete(
      url,
      queryParameters: queryParams,
      options: Options(headers: headers != null ? Map<String, dynamic>.from(headers) : <String, dynamic>{}),
    );

    // Handle all status codes since validateStatus = true
    await _directHandleSpecialErrors(response);
    if (response.statusCode == 200) {
      return IApiResponse.fromData(response.data);
    } else if (response.statusCode == 401) {
      return IApiResponse(
        success: false,
        message: 'Unauthorized',
        statusCode: 401,
      );
    } else if (response.statusCode == 404) {
      return IApiResponse(
        success: false,
        message: 'Resource not found',
        statusCode: 404,
      );
    } else if (response.statusCode! >= 400 && response.statusCode! < 500) {
      // Client errors (4xx)
      String errorMessage = 'Client error';
      if (response.data != null && response.data is Map<String, dynamic>) {
        final responseData = response.data as Map<String, dynamic>;
        if (responseData.containsKey('message') && responseData['message'] != null) {
          errorMessage = responseData['message'].toString();
        }
      }
      return IApiResponse(
        success: false,
        message: errorMessage,
        statusCode: response.statusCode!,
      );
    } else if (response.statusCode! >= 500) {
      // Server errors (5xx)
      String errorMessage = 'Server error';
      if (response.data != null && response.data is Map<String, dynamic>) {
        final responseData = response.data as Map<String, dynamic>;
        if (responseData.containsKey('message') && responseData['message'] != null) {
          errorMessage = responseData['message'].toString();
        }
      }
      return IApiResponse(
        success: false,
        message: errorMessage,
        statusCode: response.statusCode!,
      );
    } else {
      // Other status codes
      String errorMessage = 'Unexpected response: ${response.statusCode}';
      if (response.data != null && response.data is Map<String, dynamic>) {
        final responseData = response.data as Map<String, dynamic>;
        if (responseData.containsKey('message') && responseData['message'] != null) {
          errorMessage = responseData['message'].toString();
        }
      }
      return IApiResponse(
        success: false,
        message: errorMessage,
        statusCode: response.statusCode!,
      );
    }
  } on DioException catch (e) {
    debugPrint('DELETE Error: ${e.message}');
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return IApiResponse(
        success: false,
        message: 'Request to $endpoint timed out',
        statusCode: 408, // Request Timeout
      );
    } else if (e.type == DioExceptionType.badResponse) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 401) {
        return IApiResponse(
          success: false,
          message: 'Unauthorized',
          statusCode: 401,
        );
      }
      return IApiResponse(
        success: false,
        message: e.response?.data?['message'] ?? 'Request failed',
        statusCode: statusCode ?? 500,
      );
    } else if (e.type == DioExceptionType.connectionError) {
      return IApiResponse(
        success: false,
        message: 'Connection error - please check your internet connection',
        statusCode: 503, // Service Unavailable
      );
    }
    return IApiResponse(
      success: false,
      message: e.message ?? 'Unknown error',
      statusCode: 500,
    );
  } catch (e) {
    debugPrint('DELETE Unknown Error: $e');
    return IApiResponse(
      success: false,
      message: 'Unknown error occurred',
      statusCode: 500,
    );
  }
}

FutureOr<IApiResponse> uploadFile({
  required String path,
  required String filename,
  required String endpoint,
  Map<String, dynamic>? extraData,
  Map<String, String>? headers,
  String fileFieldName = 'file',
  Duration timeoutDuration = const Duration(seconds: 120),
}) async {
  final dio = _configureDio(timeoutDuration: timeoutDuration);
  final url = _baseUrl + endpoint;
  debugPrint('UPLOAD Request to: $url');
  debugPrint('File Path: $path');
  debugPrint('File Field Name: $fileFieldName');

  try {
    final formData = FormData.fromMap({
      fileFieldName: await MultipartFile.fromFile(path, filename: filename),
      if (extraData != null) ...extraData,
    });

    final response = await dio.post(
      url,
      data: formData,
      options: Options(headers: headers != null ? Map<String, dynamic>.from(headers) : <String, dynamic>{}),
    );

    // Handle all status codes since validateStatus = true
    if (response.statusCode == 200 || response.statusCode == 201) {
      return IApiResponse.fromData(response.data);
    } else if (response.statusCode == 401) {
      return IApiResponse(
        success: false,
        message: 'Unauthorized',
        statusCode: 401,
      );
    } else if (response.statusCode == 404) {
      return IApiResponse(
        success: false,
        message: 'Resource not found',
        statusCode: 404,
      );
    } else if (response.statusCode! >= 400 && response.statusCode! < 500) {
      // Client errors (4xx)
      String errorMessage = 'Upload failed - client error';
      if (response.data != null && response.data is Map<String, dynamic>) {
        final responseData = response.data as Map<String, dynamic>;
        if (responseData.containsKey('message') && responseData['message'] != null) {
          errorMessage = responseData['message'].toString();
        }
      }
      return IApiResponse(
        success: false,
        message: errorMessage,
        statusCode: response.statusCode!,
      );
    } else if (response.statusCode! >= 500) {
      // Server errors (5xx)
      String errorMessage = 'Upload failed - server error';
      if (response.data != null && response.data is Map<String, dynamic>) {
        final responseData = response.data as Map<String, dynamic>;
        if (responseData.containsKey('message') && responseData['message'] != null) {
          errorMessage = responseData['message'].toString();
        }
      }
      return IApiResponse(
        success: false,
        message: errorMessage,
        statusCode: response.statusCode!,
      );
    } else {
      // Other status codes
      String errorMessage = 'Upload failed - unexpected response: ${response.statusCode}';
      if (response.data != null && response.data is Map<String, dynamic>) {
        final responseData = response.data as Map<String, dynamic>;
        if (responseData.containsKey('message') && responseData['message'] != null) {
          errorMessage = responseData['message'].toString();
        }
      }
      return IApiResponse(
        success: false,
        message: errorMessage,
        statusCode: response.statusCode!,
      );
    }
  } on DioException catch (e) {
    debugPrint('UPLOAD Error: ${e.message}');
    debugPrint('Error Type: ${e.type}');
    debugPrint('Error Response: ${e.response}');
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return IApiResponse(
        success: false,
        message: 'Upload to $endpoint timed out',
        statusCode: 408, // Request Timeout
      );
    } else if (e.type == DioExceptionType.badResponse) {
      final statusCode = e.response?.statusCode;
      if (statusCode == 401) {
        return IApiResponse(
          success: false,
          message: 'Unauthorized',
          statusCode: 401,
        );
      }
      return IApiResponse(
        success: false,
        message: e.response?.data?['message'] ?? 'Upload failed',
        statusCode: statusCode ?? 500,
      );
    } else if (e.type == DioExceptionType.connectionError) {
      return IApiResponse(
        success: false,
        message: 'Connection error - please check your internet connection',
        statusCode: 503, // Service Unavailable
      );
    }
    return IApiResponse(
      success: false,
      message: e.message ?? 'Upload failed',
      statusCode: 500,
    );
  } catch (e) {
    debugPrint('UPLOAD Unknown Error: $e');
    return IApiResponse(
      success: false,
      message: 'Unknown error occurred during upload',
      statusCode: 500,
    );
  }
}
// // Add this function for file uploads
// FutureOr<IApiResponse> uploadFile({
//   required String path,
//   required String filename,
//   required String endpoint,
//   Map<String, dynamic>? extraData,
//   Map<String, String>? headers,
//   String fileFieldName = 'file', // Added parameter with default value 'file'
//   Duration timeoutDuration = const Duration(seconds: 120),
// }) async {
//   final dio = _configureDio(timeoutDuration: timeoutDuration);
//   final url = _baseUrl + endpoint;
//   debugPrint('UPLOAD Request to: $url');

//   try {
//     final formData = FormData.fromMap({
//       fileFieldName: await MultipartFile.fromFile(path, filename: filename), // Use the fileFieldName parameter
//       if (extraData != null) ...extraData,
//     });

//     final response = await dio.post(
//       url,
//       data: formData,
//       options: Options(headers: headers),
//     );

//     if (response.statusCode == 200 || response.statusCode == 201) {
//       return IApiResponse.fromData(response.data);
//     } else {
//       throw Exception('Error: ${response.statusCode}');
//     }
//   } on DioException catch (e) {
//     debugPrint('UPLOAD Error: ${e.message}');
//     if (e.type == DioExceptionType.connectionTimeout ||
//         e.type == DioExceptionType.receiveTimeout) {
//       throw Exception('Upload to $endpoint timed out');
//     }
//     return IApiResponse(
//       success: false,
//       message: e.message ?? 'Upload failed',
//     );
//   } catch (e) {
//     debugPrint('UPLOAD Unknown Error: $e');
//     return IApiResponse(
//       success: false,
//       message: 'Unknown error occurred during upload',
//     );
//   }
// }

// Helper function to extract error message from response
String _extractErrorMessage(dynamic responseData, String defaultMessage) {
  if (responseData != null && responseData is Map<String, dynamic>) {
    if (responseData.containsKey('message') && responseData['message'] != null) {
      return responseData['message'].toString();
    }
  }
  return defaultMessage;
}

// Add this function to get the current language
Future<String> _getCurrentLanguage() async {
  try {
    final String? language = await _secureStorage.read(key: 'app_language');
    return language ?? 'fr'; // Default to English if no language is set
  } catch (e) {
    debugPrint('Error retrieving language: $e');
    return 'fr'; // Default to English on error
  }
}
