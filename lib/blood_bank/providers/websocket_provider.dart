import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../apps/config/AppConfig.dart';
import '../services/websocket_service.dart';
import '../data/models/blood_request_model.dart';

/// Provider for WebSocket service instance
final bloodRequestWebSocketServiceProvider = Provider<BloodRequestWebSocketService>((ref) {
  final config = AppConfig.instance;
  final service = BloodRequestWebSocketService(
    baseUrl: config.baseApiUrl,
    apiConsumerHashKey: config.apiConsumerHashKey,
    pingInterval: const Duration(seconds: 30),
    reconnectInterval: const Duration(seconds: 5),
    maxReconnectAttempts: 5,
  );
  
  // Dispose when provider is disposed
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});

/// Provider for WebSocket connection state
final webSocketConnectionStateProvider = StreamProvider<WebSocketConnectionState>((ref) {
  final service = ref.watch(bloodRequestWebSocketServiceProvider);
  return service.onConnectionStateChange;
});

/// Provider for blood request updates stream
final bloodRequestUpdatesProvider = StreamProvider<BloodRequestModel>((ref) {
  final service = ref.watch(bloodRequestWebSocketServiceProvider);
  return service.onBloodRequestUpdate;
});

/// Provider to check if WebSocket is connected
final isWebSocketConnectedProvider = Provider<bool>((ref) {
  final connectionState = ref.watch(webSocketConnectionStateProvider);
  return connectionState.when(
    data: (state) => state == WebSocketConnectionState.connected,
    loading: () => false,
    error: (_, __) => false,
  );
});

