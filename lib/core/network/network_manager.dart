import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import '../utils/api_initializer.dart';

/// Simple network connectivity manager to handle backend availability
class NetworkManager {
  static final NetworkManager _instance = NetworkManager._internal();
  factory NetworkManager() => _instance;

  // Private constructor
  NetworkManager._internal();
  
  // Stream controller for backend availability status
  final StreamController<bool> _backendStatusController = StreamController<bool>.broadcast();
  
  // Current backend availability status - default to true to avoid false negatives
  bool _isBackendAvailable = true;
  // Last known good (successful API interaction) timestamp
  DateTime? _lastSuccessfulInteraction;

  // Debounce handling
  bool _pendingBackendDownFlag = false;
  Timer? _debounceTimer;

  // Connectivity subscription for real-time network changes
  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;

  // Stream of backend availability status
  Stream<bool> get backendStatus => _backendStatusController.stream;
  
  // Getter for current status
  bool get isBackendAvailable => _isBackendAvailable;
  
  // Timer for periodic connectivity checks
  Timer? _connectivityCheckTimer;
  
  // Last check timestamp
  DateTime? _lastBackendCheck;
  
  /// Initialize the network manager and start periodic checks
  Future<void> initialize({bool skipInitialCheck = false}) async {
    // Only perform the initial check if not skipped
    if (!skipInitialCheck) {
      await checkBackendAvailability();
    }
    
    // Start periodic checks
    _connectivityCheckTimer = Timer.periodic(
      const Duration(minutes: 2), // Check every 2 minutes
      (_) => checkBackendAvailability()
    );

    // Listen to connectivity changes to trigger faster re-checks
    _connectivitySub = Connectivity().onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        if (kDebugMode) {
          print('🌐 NetworkManager: Connectivity changed - $results');
        }
        // Trigger an immediate backend availability check when connectivity changes
        _lastBackendCheck = null; // force check
        checkBackendAvailability();
      },
      onError: (error) {
        if (kDebugMode) {
          print('⚠️ NetworkManager: Connectivity stream error - $error');
        }
      },
    );
  }
  
  /// Check if backend is available using API connection test
  Future<bool> checkBackendAvailability() async {
    // Don't check too frequently
    if (_lastBackendCheck != null && 
        DateTime.now().difference(_lastBackendCheck!) < const Duration(seconds: 10)) {
      return _isBackendAvailable;
    }
    
    _lastBackendCheck = DateTime.now();
    
    try {
      // First check basic internet connectivity with a simple DNS lookup
      bool hasInternetConnection = await _checkInternetConnection();
      
      if (!hasInternetConnection) {
        _updateBackendStatus(false);
        return false;
      }
      
      // If internet is available, check backend API
      final backendAvailable = await ApiInitializer.retryConnectionTest();
      _updateBackendStatus(backendAvailable);
      return backendAvailable;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ NetworkManager: Error checking backend availability - $e');
      }
      _updateBackendStatus(false);
      return false;
    }
  }
  
  /// Check internet connection with a simple DNS lookup
  Future<bool> _checkInternetConnection() async {
    try {
      final result = await InternetAddress.lookup('google.com')
        .timeout(const Duration(seconds: 5));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } on TimeoutException catch (_) {
      return false;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ NetworkManager: Error checking internet connection - $e');
      }
      return false;
    }
  }
  
  /// Update the backend status and notify listeners if changed
  void _updateBackendStatus(bool isAvailable) {
    // Debounce transient down states: require two consecutive down indications separated by 1.5s
    if (!isAvailable) {
      // If we recently had success (< 30s), treat single failure as transient
      if (_lastSuccessfulInteraction != null &&
          DateTime.now().difference(_lastSuccessfulInteraction!) < const Duration(seconds: 30)) {
        if (kDebugMode) {
          print('🌐 NetworkManager: Transient backend failure ignored (recent success)');
        }
        return;
      }
      if (!_pendingBackendDownFlag) {
        _pendingBackendDownFlag = true;
        _debounceTimer?.cancel();
        _debounceTimer = Timer(const Duration(milliseconds: 1500), () {
          if (_pendingBackendDownFlag) {
            if (_isBackendAvailable != false) {
              _isBackendAvailable = false;
              _backendStatusController.add(false);
              if (kDebugMode) {
                print('🌐 NetworkManager: Backend marked DOWN after debounce');
              }
            }
            _pendingBackendDownFlag = false;
          }
        });
        return; // Wait for debounce to complete
      } else {
        // Already pending; ignore further downs until timer fires
        return;
      }
    } else { // isAvailable == true
      _pendingBackendDownFlag = false;
      _debounceTimer?.cancel();
      if (_isBackendAvailable != true) {
        _isBackendAvailable = true;
        _backendStatusController.add(true);
        if (kDebugMode) {
          print('🌐 NetworkManager: Backend marked UP');
        }
      }
      _lastSuccessfulInteraction = DateTime.now();
    }
  }
  
  /// Manually mark backend as available (for use when an API call is successful)
  void markBackendAsAvailable() {
    _updateBackendStatus(true);
  }
  
  /// Manually retry connection to backend
  Future<bool> retryBackendConnection() async {
    // Force a new check by resetting the last check timestamp
    _lastBackendCheck = null;
    return await checkBackendAvailability();
  }
  
  /// Dispose resources
  void dispose() {
    _connectivityCheckTimer?.cancel();
    _debounceTimer?.cancel();
    _connectivitySub?.cancel();
    _backendStatusController.close();
  }
}