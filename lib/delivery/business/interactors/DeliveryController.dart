import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../service/DeliveryApiService.dart';
import '../model/DeliveryModels.dart';

// API Service Provider
final deliveryApiServiceProvider = Provider<DeliveryApiService>((ref) {
  return DeliveryApiService();
});

// Delivery State
class DeliveryState {
  final List<Delivery> deliveries;
  final bool isLoading;
  final String? error;

  DeliveryState({
    this.deliveries = const [],
    this.isLoading = false,
    this.error,
  });

  DeliveryState copyWith({
    List<Delivery>? deliveries,
    bool? isLoading,
    String? error,
  }) {
    return DeliveryState(
      deliveries: deliveries ?? this.deliveries,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Delivery Controller
class DeliveryController extends StateNotifier<DeliveryState> {
  final DeliveryApiService _apiService;

  DeliveryController(this._apiService) : super(DeliveryState());

  Future<void> loadDeliveries() async {
    state = state.copyWith(isLoading: true, error: null);
    
    final response = await _apiService.getDeliveries();
    
    if (response.success && response.data != null) {
      state = state.copyWith(
        deliveries: response.data!,
        isLoading: false,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: response.error ?? 'Failed to load deliveries',
      );
    }
  }

  Future<void> loadInProgressDeliveries() async {
    state = state.copyWith(isLoading: true, error: null);
    
    final response = await _apiService.getInProgressDeliveries();
    
    if (response.success && response.data != null) {
      state = state.copyWith(
        deliveries: response.data!,
        isLoading: false,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: response.error ?? 'Failed to load in-progress deliveries',
      );
    }
  }

  Future<void> loadDeliveredDeliveries() async {
    state = state.copyWith(isLoading: true, error: null);
    
    final response = await _apiService.getDeliveredDeliveries();
    
    if (response.success && response.data != null) {
      state = state.copyWith(
        deliveries: response.data!,
        isLoading: false,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: response.error ?? 'Failed to load delivered deliveries',
      );
    }
  }

  Future<bool> startDelivery(String deliveryId) async {
    final response = await _apiService.startDelivery(deliveryId);
    
    if (response.success && response.data != null) {
      final updatedDeliveries = state.deliveries.map((d) {
        return d.id == deliveryId ? response.data! : d;
      }).toList();
      state = state.copyWith(deliveries: updatedDeliveries);
      return true;
    } else {
      state = state.copyWith(error: response.error ?? 'Failed to start delivery');
      return false;
    }
  }

  Future<bool> completeDelivery(String deliveryId, {String? notes}) async {
    final response = await _apiService.completeDelivery(deliveryId, notes: notes);
    
    if (response.success && response.data != null) {
      final updatedDeliveries = state.deliveries.map((d) {
        return d.id == deliveryId ? response.data! : d;
      }).toList();
      state = state.copyWith(deliveries: updatedDeliveries);
      return true;
    } else {
      state = state.copyWith(error: response.error ?? 'Failed to complete delivery');
      return false;
    }
  }

  Future<bool> updateDeliveryStatus(String deliveryId, DeliveryStatus status, {String? notes}) async {
    final response = await _apiService.updateDeliveryStatus(deliveryId, status, notes: notes);
    
    if (response.success && response.data != null) {
      final updatedDeliveries = state.deliveries.map((d) {
        return d.id == deliveryId ? response.data! : d;
      }).toList();
      state = state.copyWith(deliveries: updatedDeliveries);
      return true;
    } else {
      state = state.copyWith(error: response.error ?? 'Failed to update delivery status');
      return false;
    }
  }

  List<Delivery> getInProgressDeliveries() {
    return state.deliveries.where((d) => d.status == DeliveryStatus.inProgress).toList();
  }

  List<Delivery> getDeliveredDeliveries() {
    return state.deliveries.where((d) => d.status == DeliveryStatus.delivered).toList();
  }

  List<Delivery> getUrgentDeliveries() {
    return state.deliveries.where((d) => d.priority == DeliveryPriority.urgent || d.priority == DeliveryPriority.emergency).toList();
  }

  List<Delivery> getDeliveriesByStatus(DeliveryStatus status) {
    return state.deliveries.where((d) => d.status == status).toList();
  }

  int getDeliveryCountByStatus(DeliveryStatus status) {
    return state.deliveries.where((d) => d.status == status).length;
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Delivery Provider
final deliveryControllerProvider = StateNotifierProvider<DeliveryController, DeliveryState>((ref) {
  final apiService = ref.watch(deliveryApiServiceProvider);
  return DeliveryController(apiService);
});

// Delivery Stats State
class DeliveryStatsState {
  final DeliveryStats? stats;
  final bool isLoading;
  final String? error;

  DeliveryStatsState({
    this.stats,
    this.isLoading = false,
    this.error,
  });

  DeliveryStatsState copyWith({
    DeliveryStats? stats,
    bool? isLoading,
    String? error,
  }) {
    return DeliveryStatsState(
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Delivery Stats Controller
class DeliveryStatsController extends StateNotifier<DeliveryStatsState> {
  final DeliveryApiService _apiService;

  DeliveryStatsController(this._apiService) : super(DeliveryStatsState());

  Future<void> loadStats() async {
    state = state.copyWith(isLoading: true, error: null);
    
    final response = await _apiService.getDeliveryStats();
    
    if (response.success && response.data != null) {
      state = state.copyWith(
        stats: response.data!,
        isLoading: false,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: response.error ?? 'Failed to load delivery statistics',
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Delivery Stats Provider
final deliveryStatsControllerProvider = StateNotifierProvider<DeliveryStatsController, DeliveryStatsState>((ref) {
  final apiService = ref.watch(deliveryApiServiceProvider);
  return DeliveryStatsController(apiService);
});

// Recent Activity Provider
final deliveryRecentActivityProvider = FutureProvider<List<DeliveryActivity>>((ref) async {
  final apiService = ref.watch(deliveryApiServiceProvider);
  final response = await apiService.getRecentActivity();
  
  if (response.success && response.data != null) {
    return response.data!;
  } else {
    throw Exception(response.error ?? 'Failed to load recent activity');
  }
});

// Computed Providers
final inProgressDeliveriesCountProvider = Provider<int>((ref) {
  final deliveryState = ref.watch(deliveryControllerProvider);
  return deliveryState.deliveries
      .where((delivery) => delivery.status == DeliveryStatus.inProgress)
      .length;
});

final deliveredDeliveriesCountProvider = Provider<int>((ref) {
  final deliveryState = ref.watch(deliveryControllerProvider);
  return deliveryState.deliveries
      .where((delivery) => delivery.status == DeliveryStatus.delivered)
      .length;
});

final urgentDeliveriesCountProvider = Provider<int>((ref) {
  final deliveryState = ref.watch(deliveryControllerProvider);
  return deliveryState.deliveries
      .where((delivery) => delivery.priority == DeliveryPriority.urgent || delivery.priority == DeliveryPriority.emergency)
      .length;
});

final totalDeliveriesCountProvider = Provider<int>((ref) {
  final deliveryState = ref.watch(deliveryControllerProvider);
  return deliveryState.deliveries.length;
});

// Filtered Providers for specific delivery types
final inProgressDeliveriesProvider = Provider<List<Delivery>>((ref) {
  final deliveryState = ref.watch(deliveryControllerProvider);
  return deliveryState.deliveries
      .where((delivery) => delivery.status == DeliveryStatus.inProgress)
      .toList();
});

final deliveredDeliveriesProvider = Provider<List<Delivery>>((ref) {
  final deliveryState = ref.watch(deliveryControllerProvider);
  return deliveryState.deliveries
      .where((delivery) => delivery.status == DeliveryStatus.delivered)
      .toList();
});
