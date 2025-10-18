import 'package:flutter/foundation.dart';
import 'location_tracking_service.dart';

/// Service to initialize all app services on startup
class AppInitializationService {
  static final AppInitializationService _instance = AppInitializationService._internal();
  factory AppInitializationService() => _instance;
  AppInitializationService._internal();

  bool _isInitialized = false;
  
  /// Initialize all app services
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('ℹ️ App services already initialized');
      return;
    }
    
    try {
      debugPrint('🚀 Initializing app services...');
      
      // Initialize location tracking service
      await _initializeLocationService();
      
      // Add other service initializations here
      // await _initializeNotificationService();
      // await _initializeAnalyticsService();
      
      _isInitialized = true;
      debugPrint('✅ All app services initialized successfully');
    } catch (e) {
      debugPrint('❌ Error initializing app services: $e');
      // Don't throw - allow app to continue even if some services fail
    }
  }
  
  /// Initialize location tracking service
  Future<void> _initializeLocationService() async {
    try {
      debugPrint('📍 Initializing location tracking service...');
      final locationService = LocationTrackingService();
      await locationService.initialize();
      debugPrint('✅ Location tracking service initialized');
    } catch (e) {
      debugPrint('❌ Error initializing location service: $e');
    }
  }
  
  /// Stop all services (call on app dispose)
  void dispose() {
    try {
      debugPrint('🛑 Disposing app services...');
      
      // Dispose location service
      LocationTrackingService().dispose();
      
      _isInitialized = false;
      debugPrint('✅ App services disposed');
    } catch (e) {
      debugPrint('❌ Error disposing app services: $e');
    }
  }
}

