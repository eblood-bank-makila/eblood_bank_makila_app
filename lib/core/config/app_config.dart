import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get apiBaseUrl {
    final String? baseUrl = dotenv.env['API_BASE_URL'];
    if (baseUrl == null || baseUrl.isEmpty) {
      // Fallback URL if not configured in .env
      if (kDebugMode) {
        print('Warning: API_BASE_URL not found in .env file. Using fallback URL.');
      }
      return 'https://api.ebloodbank.com';
    }
    return baseUrl;
  }
  
  static String get apiConsumerKey {
    final String? apiConsumer = dotenv.env['API_CONSUMER'];
    if (apiConsumer == null || apiConsumer.isEmpty) {
      if (kDebugMode) {
        print('Warning: API_CONSUMER not found in .env file.');
      }
      return '';
    }
    return apiConsumer;
  }

  static String get fsApiBaseUrl {
    final String? fsBaseUrl = dotenv.env['FS_API_BASE_URL'];
    if (fsBaseUrl == null || fsBaseUrl.isEmpty) {
      if (kDebugMode) {
        print('Warning: FS_API_BASE_URL not found in .env file. Using fallback URL.');
      }
      return 'https://fs.ebloodbank.com';
    }
    return fsBaseUrl;
  }

  static String get authApiBaseUrl {
    final String? authBaseUrl = dotenv.env['AUTH_API_BASE_URL'];
    if (authBaseUrl == null || authBaseUrl.isEmpty) {
      if (kDebugMode) {
        print('Warning: AUTH_API_BASE_URL not found in .env file. Using fallback URL.');
      }
      return 'https://auth.ebloodbank.com';
    }
    return authBaseUrl;
  }

  static String get environment {
    final String? env = dotenv.env['ENVIRONMENT'];
    if (env == null || env.isEmpty) {
      return kDebugMode ? 'development' : 'production';
    }
    return env;
  }

  static bool get isDevelopment => environment == 'development';
  static bool get isProduction => environment == 'production';
  static bool get isStaging => environment == 'staging';
  
  // API endpoints
  static const String locationEndpoint = '/api/v1/locations';
  static const String countriesEndpoint = '/api/v1/countries';
  static const String provincesEndpoint = '/api/v1/provinces';
  static const String townsEndpoint = '/api/v1/towns';
  
  // Registration endpoints
  static const String registerEndpoint = '/api/v1/register';
  static const String verifyOtpEndpoint = '/api/v1/verify-otp';
  
  // Authentication endpoints
  static const String loginEndpoint = '/api/v1/login';
  static const String refreshTokenEndpoint = '/api/v1/refresh-token';
  static const String logoutEndpoint = '/api/v1/logout';
  
  // User profile endpoints
  static const String userProfileEndpoint = '/api/v1/user/profile';
  static const String updateProfileEndpoint = '/api/v1/user/profile/update';
  
  // Blood donation endpoints
  static const String donationHistoryEndpoint = '/api/v1/donations/history';
  static const String donationScheduleEndpoint = '/api/v1/donations/schedule';
  
  // Blood request endpoints
  static const String bloodRequestEndpoint = '/api/v1/blood-requests';
  static const String bloodRequestHistoryEndpoint = '/api/v1/blood-requests/history';
  
  // Notifications endpoints
  static const String notificationsEndpoint = '/api/v1/notifications';
  static const String updateNotificationSettingsEndpoint = '/api/v1/notifications/settings';
}