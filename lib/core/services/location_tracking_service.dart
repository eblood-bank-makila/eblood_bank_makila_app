import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

/// Production-ready GPS location tracking service
/// - Gets real device GPS coordinates
/// - Updates regularly in background
/// - Saves location for reuse
/// - Handles all permission scenarios
class LocationTrackingService {
  static final LocationTrackingService _instance = LocationTrackingService._internal();
  factory LocationTrackingService() => _instance;
  LocationTrackingService._internal();

  // Storage
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  
  // Location tracking
  StreamSubscription<Position>? _positionStreamSubscription;
  Position? _currentPosition;
  Timer? _backgroundUpdateTimer;
  
  // Storage keys
  static const String _keyLatitude = 'user_latitude';
  static const String _keyLongitude = 'user_longitude';
  static const String _keyAltitude = 'user_altitude';
  static const String _keyAccuracy = 'user_accuracy';
  static const String _keyTimestamp = 'user_location_timestamp';
  
  // Configuration
  static const Duration _backgroundUpdateInterval = Duration(minutes: 15); // Update every 15 minutes
  static const Duration _locationTimeout = Duration(seconds: 30);
  static const int _maxLocationAge = 3600000; // 1 hour in milliseconds
  
  // Getters
  Position? get currentPosition => _currentPosition;
  bool get isTracking => _positionStreamSubscription != null;
  
  /// Initialize the location service
  Future<void> initialize() async {
    try {
      debugPrint('🗺️ Initializing LocationTrackingService...');
      
      // Load saved location
      await _loadSavedLocation();
      
      // Request permissions
      final hasPermission = await _requestLocationPermission();
      
      if (hasPermission) {
        // Get initial location
        await updateLocation();
        
        // Start background tracking
        startBackgroundTracking();
        
        debugPrint('✅ LocationTrackingService initialized successfully');
      } else {
        debugPrint('⚠️ Location permission not granted, using saved location only');
      }
    } catch (e) {
      debugPrint('❌ Error initializing LocationTrackingService: $e');
    }
  }
  
  /// Request location permissions
  Future<bool> _requestLocationPermission() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('⚠️ Location services are disabled');
        return false;
      }
      
      // Check current permission status
      LocationPermission permission = await Geolocator.checkPermission();
      
      if (permission == LocationPermission.denied) {
        // Request permission
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('⚠️ Location permission denied');
          return false;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        debugPrint('⚠️ Location permission permanently denied');
        // Optionally open app settings
        await ph.Permission.location.request();
        return false;
      }
      
      // Check for background location permission (iOS)
      if (defaultTargetPlatform == TargetPlatform.iOS) {
        if (permission == LocationPermission.whileInUse) {
          // Request always permission for background tracking
          permission = await Geolocator.requestPermission();
        }
      }
      
      debugPrint('✅ Location permission granted: $permission');
      return true;
    } catch (e) {
      debugPrint('❌ Error requesting location permission: $e');
      return false;
    }
  }
  
  /// Get current location and save it
  Future<Position?> updateLocation() async {
    try {
      debugPrint('📍 Getting current location...');
      
      // Check permission first
      final hasPermission = await _hasLocationPermission();
      if (!hasPermission) {
        debugPrint('⚠️ No location permission, returning saved location');
        return _currentPosition;
      }
      
      // Get current position
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      ).timeout(
        _locationTimeout,
        onTimeout: () {
          debugPrint('⏱️ Location request timed out');
          throw TimeoutException('Location request timed out');
        },
      );
      
      // Update current position
      _currentPosition = position;
      
      // Save to storage
      await _saveLocation(position);
      
      debugPrint('✅ Location updated: ${position.latitude}, ${position.longitude}');
      debugPrint('   Accuracy: ${position.accuracy}m, Altitude: ${position.altitude}m');
      
      return position;
    } catch (e) {
      debugPrint('❌ Error updating location: $e');
      return _currentPosition; // Return last known location
    }
  }
  
  /// Start background location tracking
  void startBackgroundTracking() {
    try {
      debugPrint('🔄 Starting background location tracking...');
      
      // Stop existing tracking
      stopBackgroundTracking();
      
      // Start periodic updates with timer (more battery efficient)
      _backgroundUpdateTimer = Timer.periodic(_backgroundUpdateInterval, (timer) async {
        debugPrint('⏰ Background location update triggered');
        await updateLocation();
      });
      
      // Also listen to position stream for real-time updates when app is active
      _startPositionStream();
      
      debugPrint('✅ Background tracking started (updates every ${_backgroundUpdateInterval.inMinutes} minutes)');
    } catch (e) {
      debugPrint('❌ Error starting background tracking: $e');
    }
  }
  
  /// Start position stream for real-time updates
  void _startPositionStream() {
    try {
      const locationSettings = LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100, // Update when moved 100 meters
      );
      
      _positionStreamSubscription = Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen(
        (Position position) {
          debugPrint('📍 Position stream update: ${position.latitude}, ${position.longitude}');
          _currentPosition = position;
          _saveLocation(position);
        },
        onError: (error) {
          debugPrint('❌ Position stream error: $error');
        },
      );
    } catch (e) {
      debugPrint('❌ Error starting position stream: $e');
    }
  }
  
  /// Stop background location tracking
  void stopBackgroundTracking() {
    try {
      debugPrint('🛑 Stopping background location tracking...');
      
      // Cancel timer
      _backgroundUpdateTimer?.cancel();
      _backgroundUpdateTimer = null;
      
      // Cancel stream subscription
      _positionStreamSubscription?.cancel();
      _positionStreamSubscription = null;
      
      debugPrint('✅ Background tracking stopped');
    } catch (e) {
      debugPrint('❌ Error stopping background tracking: $e');
    }
  }
  
  /// Save location to secure storage
  Future<void> _saveLocation(Position position) async {
    try {
      await _secureStorage.write(key: _keyLatitude, value: position.latitude.toString());
      await _secureStorage.write(key: _keyLongitude, value: position.longitude.toString());
      await _secureStorage.write(key: _keyAltitude, value: position.altitude.toString());
      await _secureStorage.write(key: _keyAccuracy, value: position.accuracy.toString());
      await _secureStorage.write(key: _keyTimestamp, value: position.timestamp.millisecondsSinceEpoch.toString());
      
      debugPrint('💾 Location saved to storage');
    } catch (e) {
      debugPrint('❌ Error saving location: $e');
    }
  }
  
  /// Load saved location from storage
  Future<void> _loadSavedLocation() async {
    try {
      final latStr = await _secureStorage.read(key: _keyLatitude);
      final lngStr = await _secureStorage.read(key: _keyLongitude);
      final altStr = await _secureStorage.read(key: _keyAltitude);
      final accStr = await _secureStorage.read(key: _keyAccuracy);
      final timeStr = await _secureStorage.read(key: _keyTimestamp);
      
      if (latStr != null && lngStr != null && timeStr != null) {
        final latitude = double.parse(latStr);
        final longitude = double.parse(lngStr);
        final altitude = double.tryParse(altStr ?? '0') ?? 0.0;
        final accuracy = double.tryParse(accStr ?? '0') ?? 0.0;
        final timestamp = DateTime.fromMillisecondsSinceEpoch(int.parse(timeStr));
        
        // Check if location is not too old
        final age = DateTime.now().difference(timestamp).inMilliseconds;
        if (age < _maxLocationAge) {
          _currentPosition = Position(
            latitude: latitude,
            longitude: longitude,
            timestamp: timestamp,
            accuracy: accuracy,
            altitude: altitude,
            altitudeAccuracy: 0.0,
            heading: 0.0,
            headingAccuracy: 0.0,
            speed: 0.0,
            speedAccuracy: 0.0,
          );
          
          debugPrint('✅ Loaded saved location: $latitude, $longitude');
          debugPrint('   Age: ${(age / 60000).toStringAsFixed(1)} minutes');
        } else {
          debugPrint('⚠️ Saved location is too old (${(age / 60000).toStringAsFixed(1)} minutes)');
        }
      } else {
        debugPrint('ℹ️ No saved location found');
      }
    } catch (e) {
      debugPrint('❌ Error loading saved location: $e');
    }
  }
  
  /// Check if we have location permission
  Future<bool> _hasLocationPermission() async {
    try {
      final permission = await Geolocator.checkPermission();
      return permission != LocationPermission.denied && 
             permission != LocationPermission.deniedForever;
    } catch (e) {
      return false;
    }
  }
  
  /// Get location for API calls (with fallback)
  Future<Map<String, double>> getLocationForApi() async {
    try {
      // Try to get fresh location if permission is granted
      final hasPermission = await _hasLocationPermission();
      if (hasPermission) {
        final position = await updateLocation();
        if (position != null) {
          return {
            'latitude': position.latitude,
            'longitude': position.longitude,
          };
        }
      }
      
      // Use saved location if available
      if (_currentPosition != null) {
        debugPrint('📍 Using saved location for API');
        return {
          'latitude': _currentPosition!.latitude,
          'longitude': _currentPosition!.longitude,
        };
      }
      
      // Fallback to default location (Kigali, Rwanda)
      debugPrint('⚠️ No location available, using default (Kigali)');
      return {
        'latitude': -1.9441,
        'longitude': 30.0619,
      };
    } catch (e) {
      debugPrint('❌ Error getting location for API: $e');
      // Return default location
      return {
        'latitude': -1.9441,
        'longitude': 30.0619,
      };
    }
  }
  
  /// Dispose resources
  void dispose() {
    stopBackgroundTracking();
  }
}

