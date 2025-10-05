import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Unified application configuration that combines features from both implementations
class AppConfig {
  // Singleton instance
  static final AppConfig _instance = AppConfig._internal();
  static bool _isInitialized = false;
  
  // Version details
  String _appVersion = '';
  String _appName = '';
  String _buildNumber = '';
  String _packageName = '';
  
  // Private constructor
  AppConfig._internal();
  
  /// Initialize the configuration
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Load environment variables
      await dotenv.load(fileName: ".env");
      
      // Set version info from environment if available
      _instance._appVersion = dotenv.env['APP_VERSION'] ?? '1.0.0';
      _instance._buildNumber = dotenv.env['BUILD_NUMBER'] ?? '1';
      _instance._appName = dotenv.env['APP_NAME'] ?? 'eBlood Bank';
      _instance._packageName = dotenv.env['PACKAGE_NAME'] ?? 'com.ebloodbank.app';
      
      _isInitialized = true;
      
      // Log configuration
      if (kDebugMode) {
        print("🔧 AppConfig initialized:");
        print("  - API_BASE_URL: '${apiBaseUrl}'");
        print("  - BASE_URL: '${baseUrl}'");
        print("  - API_VERSION: '${apiVersion}'");
        print("  - ENVIRONMENT: '${environment}'");
        print("  - API_CONSUMER: ${apiConsumerKey.isNotEmpty ? '(set)' : '(not set)'}");
      }
    } catch (e) {
      print("⚠️ Error initializing AppConfig: $e");
    }
  }

  /// Get the API base URL
  static String get apiBaseUrl {
    final baseUrl = dotenv.env['API_BASE_URL'] ?? dotenv.env['BASE_API_URL'];
    if (baseUrl == null || baseUrl.isEmpty) {
      // Try fallback to BASE_URL + /api/v1
      final rootUrl = dotenv.env['BASE_URL'];
      if (rootUrl != null && rootUrl.isNotEmpty) {
        return '$rootUrl/api/${apiVersion.toLowerCase()}';
      }
      
      // Ultimate fallback
      if (kDebugMode) {
        print('⚠️ Warning: No API_BASE_URL or BASE_URL found in .env file. Using fallback URL.');
      }
      return 'https://api.ebloodbank.com';
    }
    return baseUrl;
  }
  
  /// Get the base URL (without /api/v1)
  static String get baseUrl {
    final url = dotenv.env['BASE_URL'];
    if (url == null || url.isEmpty) {
      // Try to extract base URL from API URL if possible
      final apiUrl = apiBaseUrl;
      if (apiUrl.contains('/api/')) {
        return apiUrl.split('/api/')[0];
      }
      
      if (kDebugMode) {
        print('⚠️ Warning: BASE_URL not found in .env file. Using fallback URL.');
      }
      return 'https://ebloodbank.com';
    }
    return url;
  }
  
  /// Get the API consumer key
  static String get apiConsumerKey {
    final apiConsumer = dotenv.env['API_CONSUMER'];
    if (apiConsumer == null || apiConsumer.isEmpty) {
      if (kDebugMode) {
        print('⚠️ Warning: API_CONSUMER not found in .env file.');
      }
      return '';
    }
    return apiConsumer;
  }
  
  /// Get the API consumer hash key
  static String get apiConsumerHashKey {
    final key = dotenv.env['API_CONSUMER_HASH_KEY'];
    if (key == null || key.isEmpty) {
      if (kDebugMode) {
        print('⚠️ Warning: API_CONSUMER_HASH_KEY not found in .env file.');
      }
      return '';
    }
    return key;
  }

  /// Get the file storage API URL
  static String get fsApiBaseUrl {
    final fsBaseUrl = dotenv.env['FS_API_BASE_URL'];
    if (fsBaseUrl == null || fsBaseUrl.isEmpty) {
      if (kDebugMode) {
        print('⚠️ Warning: FS_API_BASE_URL not found in .env file. Using fallback URL.');
      }
      return 'https://fs.ebloodbank.com';
    }
    return fsBaseUrl;
  }

  /// Get the authentication API URL
  static String get authApiBaseUrl {
    final authBaseUrl = dotenv.env['AUTH_API_BASE_URL'];
    if (authBaseUrl == null || authBaseUrl.isEmpty) {
      if (kDebugMode) {
        print('⚠️ Warning: AUTH_API_BASE_URL not found in .env file. Using fallback URL.');
      }
      return 'https://auth.ebloodbank.com';
    }
    return authBaseUrl;
  }

  /// Get the current environment
  static String get environment {
    final env = dotenv.env['ENVIRONMENT'];
    if (env == null || env.isEmpty) {
      return kDebugMode ? 'development' : 'production';
    }
    return env;
  }

  /// Get the API version
  static String get apiVersion {
    final version = dotenv.env['API_VERSION'];
    if (version == null || version.isEmpty) {
      return 'v1';
    }
    return version;
  }

  /// Check if running in development environment
  static bool get isDevelopment => environment == 'development';
  
  /// Check if running in production environment
  static bool get isProduction => environment == 'production';
  
  /// Check if running in staging environment
  static bool get isStaging => environment == 'staging';
  
  /// Check if debug mode is enabled
  static bool get isDebugMode {
    final debugMode = dotenv.env['DEBUG_MODE']?.toLowerCase();
    if (debugMode == null || debugMode.isEmpty) {
      return kDebugMode;
    }
    return debugMode == 'true';
  }
  
  /// Get app name
  static String get appName => _instance._appName;
  
  /// Get package name
  static String get packageName => _instance._packageName;
  
  /// Get app version
  static String get version => _instance._appVersion;
  
  /// Get app build number
  static String get buildNumber => _instance._buildNumber;
  
  /// Get full version string (version+build)
  static String get fullVersion => '$version+$buildNumber';
  
  /// Get the full API URL with version
  static String get fullApiUrl {
    if (apiBaseUrl.contains('/eblood-hstdapi/')) {
      // URL already contains the API path
      return apiBaseUrl;
    } else if (apiBaseUrl.contains('/api/')) {
      // URL already contains the API path with version
      return apiBaseUrl;
    } else {
      // Append API path and version
      return '$baseUrl/eblood-hstdapi/$apiVersion';
    }
  }
  
  /// Get environment variable value with fallback
  static String getEnvValue(String key, {String defaultValue = ''}) {
    return dotenv.env[key] ?? defaultValue;
  }
  
  /// Check if environment variable exists and is not empty
  static bool hasEnvValue(String key) {
    return dotenv.env.containsKey(key) && dotenv.env[key]!.isNotEmpty;
  }
  
  /// Get all environment variables (for debugging)
  static Map<String, String> get allEnvVars => Map.from(dotenv.env);
  
  /// Check if configuration is valid
  static bool isValid() {
    return baseUrl.isNotEmpty && apiBaseUrl.isNotEmpty;
  }
  
  /// Get configuration summary for debugging
  static Map<String, dynamic> getConfigSummary() {
    return {
      'baseUrl': baseUrl,
      'apiBaseUrl': apiBaseUrl,
      'fullApiUrl': fullApiUrl,
      'apiVersion': apiVersion,
      'isDebugMode': isDebugMode,
      'environment': environment,
      'hasApiConsumer': apiConsumerKey.isNotEmpty,
      'hasApiConsumerHashKey': apiConsumerHashKey.isNotEmpty,
      'appName': appName,
      'version': fullVersion,
      'isValid': isValid(),
    };
  }
  
  // API endpoints
  static const String locationEndpoint = '/system-countries/locations';
  static const String countriesEndpoint = '/system-countries/countries';
  static const String provincesEndpoint = '/system-countries/provinces';
  static const String townsEndpoint = '/system-countries/towns';
  
  // Registration endpoints
  static const String registerEndpoint = '/auth/register';
  static const String verifyOtpEndpoint = '/auth/validate-otp';
  static const String getOtpEndpoint = '/auth/get-specific-otp';
  
  // Authentication endpoints
  static const String loginEndpoint = '/auth/login';
  static const String refreshTokenEndpoint = '/auth/refresh-token';
  static const String logoutEndpoint = '/auth/logout';
  
  // User profile endpoints
  static const String userProfileEndpoint = '/user/profile';
  static const String updateProfileEndpoint = '/user/profile/update';
  
  // Blood donation endpoints
  static const String donationHistoryEndpoint = '/donations/history';
  static const String donationScheduleEndpoint = '/donations/schedule';
  
  // Blood request endpoints
  static const String bloodRequestEndpoint = '/blood-requests';
  static const String bloodRequestHistoryEndpoint = '/blood-requests/history';
  
  // Notifications endpoints
  static const String notificationsEndpoint = '/notifications';
  static const String updateNotificationSettingsEndpoint = '/notifications/settings';
}