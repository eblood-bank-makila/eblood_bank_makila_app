import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Application configuration service that loads settings from .env file
class AppConfig {
  static AppConfig? _instance;
  late String _baseUrl;
  late String _apiVersion;
  late bool _isDebugMode;

  AppConfig._internal();

  /// Singleton instance
  static AppConfig get instance {
    _instance ??= AppConfig._internal();
    return _instance!;
  }

  /// Initialize the configuration by loading from .env file
  static Future<void> initialize() async {
    await dotenv.load(fileName: ".env");
    final config = AppConfig.instance;
    
    // Load configuration values
    config._baseUrl = dotenv.env['BASE_URL'] ?? '';
    config._apiVersion = dotenv.env['API_VERSION'] ?? 'v1';
    config._isDebugMode = dotenv.env['DEBUG_MODE']?.toLowerCase() == 'true';
    
    // Debug logging
    print("🔧 AppConfig initialized:");
    print("  - BASE_URL: '${config._baseUrl}'");
    print("  - API_VERSION: '${config._apiVersion}'");
    print("  - DEBUG_MODE: ${config._isDebugMode}");
    
    // Validate required configuration
    if (config._baseUrl.isEmpty) {
      print("⚠️ WARNING: BASE_URL is empty in .env file");
    }
  }

  /// Get the base URL for API calls
  String get baseUrl {
    if (_baseUrl.isEmpty) {
      print("⚠️ WARNING: BASE_URL is empty, using fallback");
      return 'http://localhost:3101/eblood-hstdapi/v1';
    }
    return _baseUrl;
  }

  /// Get the API version
  String get apiVersion => _apiVersion;

  /// Check if debug mode is enabled
  bool get isDebugMode => _isDebugMode;

  /// Get the full API URL with version
  String get fullApiUrl {
    if (_baseUrl.contains('/eblood-hstdapi/')) {
      // URL already contains the API path
      return _baseUrl;
    } else {
      // Append API path and version
      return '$_baseUrl/eblood-hstdapi/$_apiVersion';
    }
  }

  /// Get environment variable value
  String getEnvValue(String key, {String defaultValue = ''}) {
    return dotenv.env[key] ?? defaultValue;
  }

  /// Check if environment variable exists
  bool hasEnvValue(String key) {
    return dotenv.env.containsKey(key) && dotenv.env[key]!.isNotEmpty;
  }

  /// Get all environment variables (for debugging)
  Map<String, String> get allEnvVars => Map.from(dotenv.env);

  /// Validate configuration
  bool isValid() {
    return _baseUrl.isNotEmpty;
  }

  /// Get configuration summary for debugging
  Map<String, dynamic> getConfigSummary() {
    return {
      'baseUrl': _baseUrl,
      'fullApiUrl': fullApiUrl,
      'apiVersion': _apiVersion,
      'isDebugMode': _isDebugMode,
      'isValid': isValid(),
    };
  }

  @override
  String toString() {
    return 'AppConfig(baseUrl: $_baseUrl, apiVersion: $_apiVersion, isDebugMode: $_isDebugMode)';
  }
}
