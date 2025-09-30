import 'package:flutter/foundation.dart';
import '../network/dio_client.dart';

class ApiInitializer {
  // Initialize the DioClient singleton
  static Future<void> initialize() async {
    try {
      // Getting an instance will trigger initialization
      final dioClient = DioClient();
      
      if (kDebugMode) {
        print('🚀 DioClient successfully initialized');
        print('🔑 Base URL: ${dioClient.dio.options.baseUrl}');
        print('🔒 Headers configured: ${dioClient.dio.options.headers.keys.join(", ")}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Error initializing DioClient: $e');
      }
    }
  }
}