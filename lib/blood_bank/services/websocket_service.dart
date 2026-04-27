import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;
import '../data/models/blood_request_model.dart';

/// WebSocket connection states
enum WebSocketConnectionState {
  disconnected,
  connecting,
  connected,
  reconnecting,
  error,
}

/// WebSocket service for real-time blood request updates
class BloodRequestWebSocketService {
  // WebSocket channel
  WebSocketChannel? _channel;
  
  // Connection state
  WebSocketConnectionState _connectionState = WebSocketConnectionState.disconnected;
  
  // Stream controllers
  final _connectionStateController = StreamController<WebSocketConnectionState>.broadcast();
  final _bloodRequestUpdateController = StreamController<BloodRequestModel>.broadcast();
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  
  // Configuration
  final String baseUrl;
  final String apiConsumerHashKey;
  final Duration pingInterval;
  final Duration reconnectInterval;
  final int maxReconnectAttempts;
  
  // State
  String? _userAccountSocketHash;
  String? _authToken;
  Timer? _pingTimer;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  bool _isDisposed = false;
  
  BloodRequestWebSocketService({
    required this.baseUrl,
    required this.apiConsumerHashKey,
    this.pingInterval = const Duration(seconds: 30),
    this.reconnectInterval = const Duration(seconds: 5),
    this.maxReconnectAttempts = 5,
  });
  
  // Streams
  Stream<WebSocketConnectionState> get onConnectionStateChange => _connectionStateController.stream;
  Stream<BloodRequestModel> get onBloodRequestUpdate => _bloodRequestUpdateController.stream;
  Stream<Map<String, dynamic>> get onMessage => _messageController.stream;
  
  // Getters
  WebSocketConnectionState get connectionState => _connectionState;
  bool get isConnected => _connectionState == WebSocketConnectionState.connected;
  
  /// Connect to WebSocket server
  Future<bool> connect(String userAccountSocketHash, {String? authToken}) async {
    if (_isDisposed) {
      if (kDebugMode) {
        print('❌ Cannot connect: service is disposed');
      }
      return false;
    }

    _userAccountSocketHash = userAccountSocketHash;
    _authToken = authToken;

    try {
      _updateConnectionState(WebSocketConnectionState.connecting);

      // Construct WebSocket URL
      final socketHash = '${apiConsumerHashKey}___$userAccountSocketHash';
      var wsUrl = baseUrl;

      // Convert HTTP to WebSocket protocol
      if (wsUrl.startsWith('http://')) {
        wsUrl = wsUrl.replaceAll('http://', 'ws://');
      } else if (wsUrl.startsWith('https://')) {
        wsUrl = wsUrl.replaceAll('https://', 'wss://');
      }

      // Remove trailing slash if present
      if (wsUrl.endsWith('/')) {
        wsUrl = wsUrl.substring(0, wsUrl.length - 1);
      }

      // Build WebSocket path - baseUrl already contains /api/v1
      // Pass token as query param (server supports both query param and Authorization header)
      final queryParams = 'user_account_socket_hash=$socketHash'
          '${authToken != null && authToken.isNotEmpty ? '&token=$authToken' : ''}';
      final uri = Uri.parse('$wsUrl/websocket/ws?$queryParams');

      if (kDebugMode) {
        print('🔌 Connecting to WebSocket: $uri');
        print('🔑 Auth token provided: ${authToken != null && authToken.isNotEmpty}');
      }

      // Create WebSocket connection with custom headers using WebSocket.connect
      if (authToken != null && authToken.isNotEmpty) {
        // Use WebSocket.connect with custom headers
        final webSocket = await WebSocket.connect(
          uri.toString(),
          headers: {
            'Authorization': 'Bearer $authToken',
          },
        );
        _channel = IOWebSocketChannel(webSocket);

        if (kDebugMode) {
          print('✅ WebSocket connection created with Authorization header');
        }
      } else {
        // Fallback to standard connection without headers
        _channel = WebSocketChannel.connect(uri);

        if (kDebugMode) {
          print('⚠️ WebSocket connection created without Authorization header');
        }
      }

      // Listen for messages
      _channel!.stream.listen(
        _onMessageReceived,
        onError: _onError,
        onDone: _onDone,
        cancelOnError: false,
      );

      _updateConnectionState(WebSocketConnectionState.connected);
      _reconnectAttempts = 0;
      _startPingTimer();

      if (kDebugMode) {
        print('✅ WebSocket connected successfully');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ WebSocket connection error: $e');
      }
      _onError(e);
      return false;
    }
  }
  
  /// Disconnect from WebSocket server
  void disconnect() {
    if (kDebugMode) {
      print('🔌 Disconnecting WebSocket');
    }
    
    _stopPingTimer();
    _stopReconnectTimer();
    
    _channel?.sink.close(status.goingAway);
    _channel = null;
    
    _updateConnectionState(WebSocketConnectionState.disconnected);
  }
  
  /// Send message to server
  void sendMessage(Map<String, dynamic> message) {
    if (!isConnected || _channel == null) {
      if (kDebugMode) {
        print('⚠️ Cannot send message: not connected');
      }
      return;
    }
    
    try {
      final jsonMessage = jsonEncode(message);
      _channel!.sink.add(jsonMessage);
      
      if (kDebugMode) {
        print('📤 Sent message: $jsonMessage');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error sending message: $e');
      }
    }
  }
  
  /// Handle incoming messages
  void _onMessageReceived(dynamic message) {
    try {
      if (kDebugMode) {
        print('📥 Received message: $message');
      }
      
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      _messageController.add(data);
      
      // Check if it's a blood request update
      if (data['event_type'] == 'blood_request_update' || 
          data['type'] == 'blood_request_update') {
        _handleBloodRequestUpdate(data);
      }
      
      // Handle pong response
      if (data['type'] == 'pong') {
        if (kDebugMode) {
          print('🏓 Received pong');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error parsing message: $e');
      }
    }
  }
  
  /// Handle blood request update
  void _handleBloodRequestUpdate(Map<String, dynamic> data) {
    try {
      final requestData = data['data'] ?? data['blood_request'];
      if (requestData != null) {
        final bloodRequest = BloodRequestModel.fromJson(requestData as Map<String, dynamic>);
        _bloodRequestUpdateController.add(bloodRequest);
        
        if (kDebugMode) {
          print('🩸 Blood request update: ${bloodRequest.identifier} - ${bloodRequest.status}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error handling blood request update: $e');
      }
    }
  }
  
  /// Handle WebSocket errors
  void _onError(dynamic error) {
    if (kDebugMode) {
      print('❌ WebSocket error: $error');
    }
    
    _updateConnectionState(WebSocketConnectionState.error);
    _attemptReconnect();
  }
  
  /// Handle WebSocket connection closed
  void _onDone() {
    if (kDebugMode) {
      print('🔌 WebSocket connection closed');
    }
    
    _stopPingTimer();
    _updateConnectionState(WebSocketConnectionState.disconnected);
    _attemptReconnect();
  }
  
  /// Attempt to reconnect
  void _attemptReconnect() {
    if (_isDisposed || _userAccountSocketHash == null) {
      return;
    }
    
    if (_reconnectAttempts >= maxReconnectAttempts) {
      if (kDebugMode) {
        print('❌ Max reconnect attempts reached');
      }
      return;
    }
    
    _reconnectAttempts++;
    _updateConnectionState(WebSocketConnectionState.reconnecting);
    
    if (kDebugMode) {
      print('🔄 Reconnecting... (attempt $_reconnectAttempts/$maxReconnectAttempts)');
    }
    
    _stopReconnectTimer();
    _reconnectTimer = Timer(reconnectInterval, () {
      connect(_userAccountSocketHash!, authToken: _authToken);
    });
  }
  
  /// Start ping timer
  void _startPingTimer() {
    _stopPingTimer();
    _pingTimer = Timer.periodic(pingInterval, (_) {
      if (isConnected) {
        sendMessage({'type': 'ping', 'timestamp': DateTime.now().toIso8601String()});
      }
    });
  }
  
  /// Stop ping timer
  void _stopPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = null;
  }
  
  /// Stop reconnect timer
  void _stopReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
  }
  
  /// Update connection state
  void _updateConnectionState(WebSocketConnectionState state) {
    _connectionState = state;
    _connectionStateController.add(state);
  }
  
  /// Force reconnect
  Future<bool> forceReconnect() async {
    if (_userAccountSocketHash == null) {
      return false;
    }

    disconnect();
    _reconnectAttempts = 0;
    return await connect(_userAccountSocketHash!, authToken: _authToken);
  }
  
  /// Dispose resources
  void dispose() {
    _isDisposed = true;
    disconnect();
    _connectionStateController.close();
    _bloodRequestUpdateController.close();
    _messageController.close();
  }
}

