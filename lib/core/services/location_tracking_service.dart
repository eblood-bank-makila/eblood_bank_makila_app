import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

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
  static const String _keyPermissionStatus = 'location_permission_status';
  static const String _keyPermissionCheckedAt = 'location_permission_checked_at';
  
  // Configuration
  static const Duration _backgroundUpdateInterval = Duration(minutes: 15); // Update every 15 minutes
  static const Duration _locationTimeout = Duration(seconds: 30);
  static const int _maxLocationAge = 3600000; // 1 hour in milliseconds
  static const int _permissionCacheAge = 86400000; // 24 hours in milliseconds
  
  // Getters
  Position? get currentPosition => _currentPosition;
  bool get isTracking => _positionStreamSubscription != null;
  
  /// Initialize the location service
  Future<void> initialize() async {
    try {
      debugPrint('🗺️ Initializing LocationTrackingService...');
      
      // Load saved location (blocking - fast)
      await _loadSavedLocation();
      
      // Check cached permission status first (fast, non-blocking)
      final cachedPermission = await _getCachedPermissionStatus();
      bool hasPermission = false;
      
      if (cachedPermission == 'granted') {
        // Use cached permission (instant)
        debugPrint('✅ Using cached permission status: granted');
        hasPermission = true;
        
        // Verify permission in background (non-blocking)
        _verifyPermissionInBackground();
      } else if (cachedPermission == 'denied' || cachedPermission == 'deniedForever') {
        // Permission was denied, don't request again immediately
        debugPrint('⚠️ Using cached permission status: $cachedPermission');
        debugPrint('💡 Call requestPermission() to show permission dialog or redirect to settings');
        hasPermission = false;
      } else {
        // Unknown or first time - need to check/request permission
        debugPrint('🔍 No cached permission, checking permission...');
        hasPermission = await _requestLocationPermission();
      }
      
      if (hasPermission) {
        // Start background tracking immediately (non-blocking)
        startBackgroundTracking();
        
        // Get initial location in background (non-blocking)
        // Use fire-and-forget pattern
        updateLocation().then((_) {
          debugPrint('✅ Initial location fetched in background');
        }).catchError((error) {
          debugPrint('⚠️ Initial location fetch failed: $error');
        });
        
        debugPrint('✅ LocationTrackingService initialized successfully (using cached location)');
      } else {
        debugPrint('⚠️ Location permission not granted, using saved location only');
      }
    } catch (e) {
      debugPrint('❌ Error initializing LocationTrackingService: $e');
    }
  }
  
  /// Get cached permission status from storage
  Future<String?> _getCachedPermissionStatus() async {
    try {
      final statusStr = await _secureStorage.read(key: _keyPermissionStatus);
      final checkedAtStr = await _secureStorage.read(key: _keyPermissionCheckedAt);
      
      if (statusStr != null && checkedAtStr != null) {
        final checkedAt = DateTime.fromMillisecondsSinceEpoch(int.parse(checkedAtStr));
        final age = DateTime.now().difference(checkedAt).inMilliseconds;
        
        // Only use cache if it's less than 24 hours old
        if (age < _permissionCacheAge) {
          debugPrint('📦 Using cached permission status: $statusStr (age: ${(age / 3600000).toStringAsFixed(1)}h)');
          return statusStr;
        } else {
          debugPrint('⏰ Cached permission status expired (age: ${(age / 3600000).toStringAsFixed(1)}h)');
        }
      }
      return null;
    } catch (e) {
      debugPrint('❌ Error reading cached permission: $e');
      return null;
    }
  }
  
  /// Save permission status to storage
  Future<void> _savePermissionStatus(String status) async {
    try {
      await _secureStorage.write(key: _keyPermissionStatus, value: status);
      await _secureStorage.write(key: _keyPermissionCheckedAt, value: DateTime.now().millisecondsSinceEpoch.toString());
      debugPrint('💾 Saved permission status: $status');
    } catch (e) {
      debugPrint('❌ Error saving permission status: $e');
    }
  }
  
  /// Verify permission in background (non-blocking)
  void _verifyPermissionInBackground() {
    // Check permission without blocking
    _hasLocationPermission().then((hasPermission) {
      final status = hasPermission ? 'granted' : 'denied';
      _savePermissionStatus(status);
      
      if (!hasPermission) {
        debugPrint('⚠️ Background permission check: permission revoked');
        stopBackgroundTracking();
      }
    }).catchError((error) {
      debugPrint('⚠️ Background permission verification failed: $error');
    });
  }
  
  /// Request location permissions
  Future<bool> _requestLocationPermission() async {
    try {
      // Check if location services are enabled (fast check)
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('⚠️ Location services are disabled');
        await _savePermissionStatus('servicesDisabled');
        return false;
      }
      
      // Check current permission status (fast check)
      LocationPermission permission = await Geolocator.checkPermission();
      
      // If already granted, return immediately
      if (permission == LocationPermission.always || 
          permission == LocationPermission.whileInUse) {
        debugPrint('✅ Location permission already granted: $permission');
        await _savePermissionStatus('granted');
        return true;
      }
      
      // Handle denied forever case
      if (permission == LocationPermission.deniedForever) {
        debugPrint('⚠️ Location permission permanently denied');
        await _savePermissionStatus('deniedForever');
        return false;
      }
      
      // Only request if denied (this is fast on subsequent launches)
      if (permission == LocationPermission.denied) {
        debugPrint('📝 Requesting location permission...');
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('⚠️ Location permission denied by user');
          await _savePermissionStatus('denied');
          return false;
        }
      }
      
      debugPrint('✅ Location permission granted: $permission');
      await _savePermissionStatus('granted');
      return true;
    } catch (e) {
      debugPrint('❌ Error requesting location permission: $e');
      await _savePermissionStatus('error');
      return false;
    }
  }
  
  /// Manually request location permission (for UI button)
  /// Shows permission dialog or opens app settings if denied forever
  Future<bool> requestPermission() async {
    debugPrint('🔐 Manually requesting location permission...');
    
    // Clear cached status to force fresh check
    await _secureStorage.delete(key: _keyPermissionStatus);
    await _secureStorage.delete(key: _keyPermissionCheckedAt);
    
    final hasPermission = await _requestLocationPermission();
    
    if (hasPermission) {
      // Start tracking if permission granted
      startBackgroundTracking();
      updateLocation().then((_) {
        debugPrint('✅ Location fetched after permission granted');
      }).catchError((error) {
        debugPrint('⚠️ Failed to fetch location: $error');
      });
    }
    
    return hasPermission;
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
  
  /// Get location for API calls (with fallback) - DEPRECATED: Use getCachedLocationSync instead
  @Deprecated('Use getCachedLocationSync for non-blocking access')
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
  
  /// Get cached location synchronously (non-blocking)
  /// Returns immediately with stored location or default coordinates
  Map<String, double> getCachedLocationSync() {
    // Trigger background update (fire and forget)
    _triggerBackgroundUpdate();
    
    // Use cached location if available
    if (_currentPosition != null) {
      debugPrint('📍 Using cached location for API (sync)');
      return {
        'latitude': _currentPosition!.latitude,
        'longitude': _currentPosition!.longitude,
      };
    }
    
    // Fallback to default location (Kigali, Rwanda)
    debugPrint('⚠️ No cached location, using default (Kigali)');
    return {
      'latitude': -1.9441,
      'longitude': 30.0619,
    };
  }
  
  /// Trigger background location update (non-blocking)
  void _triggerBackgroundUpdate() {
    // Don't await - let it run in background
    _hasLocationPermission().then((hasPermission) {
      if (hasPermission) {
        updateLocation().catchError((error) {
          debugPrint('⚠️ Background location update failed: $error');
          return null;
        });
      }
    }).catchError((error) {
      debugPrint('⚠️ Permission check failed: $error');
    });
  }
  
  /// Check location permission status synchronously (from last check)
  /// Returns: 'granted', 'denied', 'deniedForever', 'servicesDisabled', 'unknown'
  Future<String> checkPermissionStatus() async {
    try {
      // Check if services are enabled
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        return 'servicesDisabled';
      }
      
      // Check permission
      final permission = await Geolocator.checkPermission();
      
      switch (permission) {
        case LocationPermission.always:
        case LocationPermission.whileInUse:
          return 'granted';
        case LocationPermission.denied:
          return 'denied';
        case LocationPermission.deniedForever:
          return 'deniedForever';
        default:
          return 'unknown';
      }
    } catch (e) {
      debugPrint('❌ Error checking permission status: $e');
      return 'unknown';
    }
  }
  
  /// Check if location permission is granted (simple check)
  Future<bool> isPermissionGranted() async {
    final status = await checkPermissionStatus();
    return status == 'granted';
  }
  
  /// Dispose resources
  void dispose() {
    stopBackgroundTracking();
  }
}

