import 'package:flutter/foundation.dart';
import '../network/dio_client_improved.dart';

/// Utility class for initializing API client
class ApiInitializer {
  // Status of API availability
  static bool _isApiAvailable = false;
  
  /// Get current API availability status
  static bool get isApiAvailable => _isApiAvailable;
  
  /// Initialize the DioClient singleton
  static Future<void> initialize() async {
    try {
      print('🔧 ApiInitializer: Initializing DioClient...');
      
      // Get the DioClient instance and initialize it
      final dioClient = DioClient();
      await dioClient.init();
      
      if (kDebugMode) {
        print('🚀 DioClient successfully initialized');
        print('🔑 Base URL: ${dioClient.dio.options.baseUrl}');
        print('🔒 Headers configured: ${dioClient.dio.options.headers.keys.join(", ")}');
      }
      
      // Test connection with a shorter timeout to avoid blocking app startup
      // This runs in parallel with app initialization
      _testConnectionAsync();
      
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error initializing DioClient: $e');
      }
      // Continue app startup even if DioClient initialization fails
    }
  }
  
  /// Test API connection asynchronously without blocking app startup
  static Future<void> _testConnectionAsync() async {
    try {
      final dioClient = DioClient();
      // Use a shorter 8-second timeout for startup test
      final connectionSuccess = await dioClient.testApiConnection(
        timeout: const Duration(seconds: 8)
      );
      
      // Update API availability status
      _isApiAvailable = connectionSuccess;
      
      if (kDebugMode) {
        print('� Connection test completed: ${connectionSuccess ? "SUCCESS" : "FAILED"}');
      }
    } catch (e) {
      _isApiAvailable = false;
      if (kDebugMode) {
        print('⚠️ Connection test error: $e');
      }
    }
  }
  
  /// Retry API connection test - can be called when needed
  static Future<bool> retryConnectionTest() async {
    try {
      final dioClient = DioClient();
      final connectionSuccess = await dioClient.testApiConnection(
        timeout: const Duration(seconds: 15)
      );
      
      // Update API availability status
      _isApiAvailable = connectionSuccess;
      
      if (kDebugMode) {
        print('� Connection retry result: ${connectionSuccess ? "SUCCESS" : "FAILED"}');
      }
      
      return connectionSuccess;
    } catch (e) {
      _isApiAvailable = false;
      if (kDebugMode) {
        print('⚠️ Connection retry error: $e');
      }
      return false;
    }
  }
}