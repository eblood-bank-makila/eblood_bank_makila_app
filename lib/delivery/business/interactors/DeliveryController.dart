import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../apps/config/api/ApiConfig.dart';
import '../../../apps/services/EbloodAuthHelper.dart';
import '../../../orders/ui/framework/blood_request/BloodRequestNetworkServiceImpl.dart';
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

// ============================================================================
// PENDING DELIVERY REQUEST CONTROLLER (Yango-style)
// ============================================================================

// Pending Delivery Request State
class PendingDeliveryRequestState {
  final List<PendingDeliveryRequest> pendingRequests;
  final ActiveDelivery? activeDelivery;
  final bool isLoading;
  final String? error;
  final bool isAccepting;
  final bool isRejecting;

  PendingDeliveryRequestState({
    this.pendingRequests = const [],
    this.activeDelivery,
    this.isLoading = false,
    this.error,
    this.isAccepting = false,
    this.isRejecting = false,
  });

  PendingDeliveryRequestState copyWith({
    List<PendingDeliveryRequest>? pendingRequests,
    ActiveDelivery? activeDelivery,
    bool? isLoading,
    String? error,
    bool? isAccepting,
    bool? isRejecting,
    bool clearActiveDelivery = false,
  }) {
    return PendingDeliveryRequestState(
      pendingRequests: pendingRequests ?? this.pendingRequests,
      activeDelivery: clearActiveDelivery ? null : (activeDelivery ?? this.activeDelivery),
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isAccepting: isAccepting ?? this.isAccepting,
      isRejecting: isRejecting ?? this.isRejecting,
    );
  }

  bool get hasPendingRequests => pendingRequests.isNotEmpty;
  bool get hasActiveDelivery => activeDelivery != null;
  PendingDeliveryRequest? get firstPendingRequest =>
      pendingRequests.isNotEmpty ? pendingRequests.first : null;
}

// Pending Delivery Request Controller
class PendingDeliveryRequestController extends StateNotifier<PendingDeliveryRequestState> {
  final DeliveryApiService _apiService;
  final String deliveryPersonId;

  PendingDeliveryRequestController(this._apiService, this.deliveryPersonId)
      : super(PendingDeliveryRequestState());

  /// Load pending delivery requests
  Future<void> loadPendingRequests() async {
    state = state.copyWith(isLoading: true, error: null);

    final response = await _apiService.getPendingDeliveryRequests(deliveryPersonId);

    if (response.success && response.data != null) {
      // Filter out expired requests
      final validRequests = response.data!.where((r) => !r.isExpired).toList();
      state = state.copyWith(
        pendingRequests: validRequests,
        isLoading: false,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: response.error ?? 'Failed to load pending requests',
      );
    }
  }

  /// Load active delivery
  Future<void> loadActiveDelivery() async {
    final response = await _apiService.getActiveDelivery(deliveryPersonId);

    if (response.success) {
      state = state.copyWith(
        activeDelivery: response.data,
        clearActiveDelivery: response.data == null,
      );
    }
  }

  /// Accept a delivery request
  Future<bool> acceptDelivery(String deliveryId) async {
    state = state.copyWith(isAccepting: true, error: null);

    final response = await _apiService.acceptDeliveryRequest(deliveryId, deliveryPersonId);

    if (response.success) {
      // Remove from pending requests
      final updatedRequests = state.pendingRequests
          .where((r) => r.id != deliveryId)
          .toList();

      state = state.copyWith(
        pendingRequests: updatedRequests,
        isAccepting: false,
      );

      // Load the active delivery
      await loadActiveDelivery();
      return true;
    } else {
      state = state.copyWith(
        isAccepting: false,
        error: response.error ?? 'Failed to accept delivery',
      );
      return false;
    }
  }

  /// Reject a delivery request
  Future<bool> rejectDelivery(String deliveryId, {String? reason}) async {
    state = state.copyWith(isRejecting: true, error: null);

    final response = await _apiService.rejectDeliveryRequest(
      deliveryId,
      deliveryPersonId,
      reason: reason,
    );

    if (response.success) {
      // Remove from pending requests
      final updatedRequests = state.pendingRequests
          .where((r) => r.id != deliveryId)
          .toList();

      state = state.copyWith(
        pendingRequests: updatedRequests,
        isRejecting: false,
      );
      return true;
    } else {
      state = state.copyWith(
        isRejecting: false,
        error: response.error ?? 'Failed to reject delivery',
      );
      return false;
    }
  }

  /// Update delivery phase
  Future<bool> updatePhase(String phase, {LocationInfo? location}) async {
    if (state.activeDelivery == null) return false;

    final response = await _apiService.updateDeliveryPhase(
      state.activeDelivery!.id,
      deliveryPersonId,
      phase,
      location: location,
    );

    if (response.success) {
      await loadActiveDelivery();
      return true;
    } else {
      state = state.copyWith(error: response.error ?? 'Failed to update phase');
      return false;
    }
  }

  /// Update location
  Future<bool> updateLocation(double lat, double lng, {double? accuracy}) async {
    final response = await _apiService.updateDeliveryPersonLocation(
      deliveryPersonId,
      lat,
      lng,
      accuracy: accuracy,
    );

    return response.success;
  }

  /// Add a new pending request (from push notification)
  void addPendingRequest(PendingDeliveryRequest request) {
    if (!request.isExpired) {
      final updatedRequests = [...state.pendingRequests, request];
      state = state.copyWith(pendingRequests: updatedRequests);
    }
  }

  /// Remove expired requests
  void removeExpiredRequests() {
    final validRequests = state.pendingRequests.where((r) => !r.isExpired).toList();
    if (validRequests.length != state.pendingRequests.length) {
      state = state.copyWith(pendingRequests: validRequests);
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Clear active delivery (when completed)
  void clearActiveDelivery() {
    state = state.copyWith(clearActiveDelivery: true);
  }
}

// Provider for delivery person ID (should be set from auth)
final deliveryPersonIdProvider = StateProvider<String?>((ref) => null);

// Pending Delivery Request Provider
final pendingDeliveryRequestProvider = StateNotifierProvider<PendingDeliveryRequestController, PendingDeliveryRequestState>((ref) {
  final apiService = ref.watch(deliveryApiServiceProvider);
  final deliveryPersonId = ref.watch(deliveryPersonIdProvider) ?? '';
  return PendingDeliveryRequestController(apiService, deliveryPersonId);
});

// Computed providers for pending requests
final hasPendingRequestsProvider = Provider<bool>((ref) {
  final state = ref.watch(pendingDeliveryRequestProvider);
  return state.hasPendingRequests;
});

final hasActiveDeliveryProvider = Provider<bool>((ref) {
  final state = ref.watch(pendingDeliveryRequestProvider);
  return state.hasActiveDelivery;
});

final firstPendingRequestProvider = Provider<PendingDeliveryRequest?>((ref) {
  final state = ref.watch(pendingDeliveryRequestProvider);
  return state.firstPendingRequest;
});

final activeDeliveryProvider = Provider<ActiveDelivery?>((ref) {
  final state = ref.watch(pendingDeliveryRequestProvider);
  return state.activeDelivery;
});

// ============================================================================
// HOSPITAL SIDE - Incoming Deliveries Controller
// ============================================================================

/// State for incoming deliveries (hospital view)
class IncomingDeliveriesState {
  final List<IncomingDelivery> deliveries;
  final bool isLoading;
  final String? error;

  IncomingDeliveriesState({
    this.deliveries = const [],
    this.isLoading = false,
    this.error,
  });

  IncomingDeliveriesState copyWith({
    List<IncomingDelivery>? deliveries,
    bool? isLoading,
    String? error,
  }) {
    return IncomingDeliveriesState(
      deliveries: deliveries ?? this.deliveries,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  bool get hasIncomingDeliveries => deliveries.isNotEmpty;
  IncomingDelivery? get firstDelivery => deliveries.isNotEmpty ? deliveries.first : null;
}

/// Controller for outgoing deliveries (SELLER view — blood bank selling to
/// a hospital, or CNTS selling to a blood bank). The backend derives the
/// seller structure from the authenticated caller.
class OutgoingDeliveriesController extends StateNotifier<List<OutgoingDelivery>> {
  final DeliveryApiService _apiService;

  OutgoingDeliveriesController(this._apiService) : super([]);

  Future<void> loadOutgoingDeliveries() async {
    try {
      final response = await _apiService.getOutgoingDeliveries();
      if (response.success && response.data != null) {
        state = response.data!;
      }
    } catch (e) {
      // Keep current state on error
    }
  }

  /// Seller attests the bags were handed to the courier. Returns the error
  /// message on failure, null on success.
  Future<String?> confirmPickup(String deliveryId) async {
    try {
      final response = await _apiService.confirmPickupBySeller(deliveryId);
      if (response.success) {
        await loadOutgoingDeliveries();
        return null;
      }
      return response.error ?? 'Échec de la confirmation de remise';
    } catch (e) {
      return 'Erreur: $e';
    }
  }

  Future<void> refresh() async {
    await loadOutgoingDeliveries();
  }
}

final outgoingDeliveriesProvider =
    StateNotifierProvider<OutgoingDeliveriesController, List<OutgoingDelivery>>((ref) {
  final apiService = ref.watch(deliveryApiServiceProvider);
  return OutgoingDeliveriesController(apiService);
});

/// Controller for incoming deliveries (hospital view)
class IncomingDeliveriesController extends StateNotifier<List<IncomingDelivery>> {
  final DeliveryApiService _apiService;
  final String hospitalId;
  final String hospitalUserId;

  IncomingDeliveriesController(this._apiService, this.hospitalId, this.hospitalUserId) : super([]);

  /// Load incoming deliveries for hospital
  Future<void> loadIncomingDeliveries() async {
    try {
      final response = await _apiService.getIncomingDeliveriesForHospital(hospitalId);
      if (response.success && response.data != null) {
        state = response.data!;
      }
    } catch (e) {
      // Keep current state on error
    }
  }

  /// Confirm delivery receipt.
  ///
  /// When [verificationCode] is provided (the code the courier presents at
  /// the door), the settlement-triggering confirm
  /// (/eblood-connect/blood-requests/confirm-delivery) runs FIRST — it is
  /// the operation that credits the seller wallets — then the assignment is
  /// closed. Without a code (legacy path) only the assignment is closed.
  Future<bool> confirmDelivery(
    String deliveryId, {
    String? bloodRequestId,
    String? verificationCode,
  }) async {
    try {
      if (verificationCode != null &&
          verificationCode.isNotEmpty &&
          bloodRequestId != null &&
          bloodRequestId.isNotEmpty) {
        final service = BloodRequestNetworkServiceImpl(ApiConfig.BASE_URL);
        final settlementRes = await service.confirmDelivery(
          bloodRequestId,
          verificationCode,
          'code',
        );
        if (!settlementRes.success) {
          return false;
        }
      }

      // Real authenticated user id — the legacy hospitalUserId provider was
      // never populated.
      final userId = hospitalUserId.isNotEmpty
          ? hospitalUserId
          : EbloodAuthHelper.currentUserId();
      final response = await _apiService.confirmDeliveryReceipt(deliveryId, userId);
      if (response.success) {
        // Remove from list
        state = state.where((d) => d.id != deliveryId).toList();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Refresh deliveries
  Future<void> refresh() async {
    await loadIncomingDeliveries();
  }
}

// Provider for hospital ID (should be set from auth)
final hospitalIdProvider = StateProvider<String?>((ref) => null);

// Provider for hospital user ID (should be set from auth)
final hospitalUserIdProvider = StateProvider<String?>((ref) => null);

// Provider for incoming deliveries (hospital view)
final incomingDeliveriesProvider = StateNotifierProvider<IncomingDeliveriesController, List<IncomingDelivery>>((ref) {
  final apiService = ref.watch(deliveryApiServiceProvider);
  final hospitalId = ref.watch(hospitalIdProvider) ?? '';
  final hospitalUserId = ref.watch(hospitalUserIdProvider) ?? '';
  return IncomingDeliveriesController(apiService, hospitalId, hospitalUserId);
});

// Computed providers for incoming deliveries
final hasIncomingDeliveriesProvider = Provider<bool>((ref) {
  final deliveries = ref.watch(incomingDeliveriesProvider);
  return deliveries.isNotEmpty;
});

final firstIncomingDeliveryProvider = Provider<IncomingDelivery?>((ref) {
  final deliveries = ref.watch(incomingDeliveriesProvider);
  return deliveries.isNotEmpty ? deliveries.first : null;
});
