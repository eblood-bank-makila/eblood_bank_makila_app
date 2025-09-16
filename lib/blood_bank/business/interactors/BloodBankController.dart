import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../service/BloodBankApiService.dart';
import '../model/BloodStock.dart';

// API Service Provider
final bloodBankApiServiceProvider = Provider<BloodBankApiService>((ref) {
  return BloodBankApiService();
});

// Blood Stock State
class BloodStockState {
  final List<BloodStock> stocks;
  final bool isLoading;
  final String? error;

  BloodStockState({
    this.stocks = const [],
    this.isLoading = false,
    this.error,
  });

  BloodStockState copyWith({
    List<BloodStock>? stocks,
    bool? isLoading,
    String? error,
  }) {
    return BloodStockState(
      stocks: stocks ?? this.stocks,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Blood Stock Controller
class BloodStockController extends StateNotifier<BloodStockState> {
  final BloodBankApiService _apiService;

  BloodStockController(this._apiService) : super(BloodStockState());

  Future<void> loadBloodStock() async {
    state = state.copyWith(isLoading: true, error: null);
    
    final response = await _apiService.getBloodStock();
    
    if (response.success && response.data != null) {
      state = state.copyWith(
        stocks: response.data!,
        isLoading: false,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: response.error ?? 'Failed to load blood stock',
      );
    }
  }

  Future<bool> addBloodStock(BloodStock stock) async {
    final response = await _apiService.addBloodStock(stock);
    
    if (response.success && response.data != null) {
      final updatedStocks = [...state.stocks, response.data!];
      state = state.copyWith(stocks: updatedStocks);
      return true;
    } else {
      state = state.copyWith(error: response.error ?? 'Failed to add blood stock');
      return false;
    }
  }

  Future<bool> updateBloodStock(String id, BloodStock stock) async {
    final response = await _apiService.updateBloodStock(id, stock);
    
    if (response.success && response.data != null) {
      final updatedStocks = state.stocks.map((s) {
        return s.id == id ? response.data! : s;
      }).toList();
      state = state.copyWith(stocks: updatedStocks);
      return true;
    } else {
      state = state.copyWith(error: response.error ?? 'Failed to update blood stock');
      return false;
    }
  }

  Future<bool> deleteBloodStock(String id) async {
    final response = await _apiService.deleteBloodStock(id);
    
    if (response.success) {
      final updatedStocks = state.stocks.where((s) => s.id != id).toList();
      state = state.copyWith(stocks: updatedStocks);
      return true;
    } else {
      state = state.copyWith(error: response.error ?? 'Failed to delete blood stock');
      return false;
    }
  }

  List<BloodStock> getStockByType(String bloodType) {
    return state.stocks.where((stock) => stock.bloodType == bloodType).toList();
  }

  List<BloodStock> getExpiringStock({int days = 7}) {
    final cutoffDate = DateTime.now().add(Duration(days: days));
    return state.stocks.where((stock) => 
      stock.expirationDate.isBefore(cutoffDate) && 
      stock.status == BloodStockStatus.available
    ).toList();
  }

  List<BloodStock> getLowStock({int threshold = 5}) {
    final stockByType = <String, int>{};
    
    for (final stock in state.stocks) {
      if (stock.status == BloodStockStatus.available) {
        stockByType[stock.bloodType] = (stockByType[stock.bloodType] ?? 0) + stock.quantity;
      }
    }
    
    return state.stocks.where((stock) => 
      (stockByType[stock.bloodType] ?? 0) <= threshold
    ).toList();
  }

  Map<String, int> getStockByTypeMap() {
    final stockByType = <String, int>{};
    
    for (final stock in state.stocks) {
      if (stock.status == BloodStockStatus.available) {
        stockByType[stock.bloodType] = (stockByType[stock.bloodType] ?? 0) + stock.quantity;
      }
    }
    
    return stockByType;
  }

  int getTotalStock() {
    return state.stocks
        .where((stock) => stock.status == BloodStockStatus.available)
        .fold(0, (sum, stock) => sum + stock.quantity);
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Blood Stock Provider
final bloodStockControllerProvider = StateNotifierProvider<BloodStockController, BloodStockState>((ref) {
  final apiService = ref.watch(bloodBankApiServiceProvider);
  return BloodStockController(apiService);
});

// Blood Requests State
class BloodRequestsState {
  final List<BloodRequest> requests;
  final bool isLoading;
  final String? error;

  BloodRequestsState({
    this.requests = const [],
    this.isLoading = false,
    this.error,
  });

  BloodRequestsState copyWith({
    List<BloodRequest>? requests,
    bool? isLoading,
    String? error,
  }) {
    return BloodRequestsState(
      requests: requests ?? this.requests,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Blood Requests Controller
class BloodRequestsController extends StateNotifier<BloodRequestsState> {
  final BloodBankApiService _apiService;

  BloodRequestsController(this._apiService) : super(BloodRequestsState());

  Future<void> loadBloodRequests() async {
    state = state.copyWith(isLoading: true, error: null);
    
    final response = await _apiService.getBloodRequests();
    
    if (response.success && response.data != null) {
      state = state.copyWith(
        requests: response.data!,
        isLoading: false,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: response.error ?? 'Failed to load blood requests',
      );
    }
  }

  Future<bool> approveRequest(String requestId, String notes) async {
    final response = await _apiService.approveBloodRequest(requestId, notes);
    
    if (response.success && response.data != null) {
      final updatedRequests = state.requests.map((r) {
        return r.id == requestId ? response.data! : r;
      }).toList();
      state = state.copyWith(requests: updatedRequests);
      return true;
    } else {
      state = state.copyWith(error: response.error ?? 'Failed to approve request');
      return false;
    }
  }

  Future<bool> rejectRequest(String requestId, String reason) async {
    final response = await _apiService.rejectBloodRequest(requestId, reason);
    
    if (response.success && response.data != null) {
      final updatedRequests = state.requests.map((r) {
        return r.id == requestId ? response.data! : r;
      }).toList();
      state = state.copyWith(requests: updatedRequests);
      return true;
    } else {
      state = state.copyWith(error: response.error ?? 'Failed to reject request');
      return false;
    }
  }

  List<BloodRequest> getPendingRequests() {
    return state.requests.where((r) => r.status == BloodRequestStatus.pending).toList();
  }

  List<BloodRequest> getUrgentRequests() {
    return state.requests.where((r) => r.priority == BloodRequestPriority.urgent).toList();
  }

  List<BloodRequest> getRequestsByStatus(BloodRequestStatus status) {
    return state.requests.where((r) => r.status == status).toList();
  }

  int getRequestCountByStatus(BloodRequestStatus status) {
    return state.requests.where((r) => r.status == status).length;
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Blood Requests Provider
final bloodRequestsControllerProvider = StateNotifierProvider<BloodRequestsController, BloodRequestsState>((ref) {
  final apiService = ref.watch(bloodBankApiServiceProvider);
  return BloodRequestsController(apiService);
});

// Blood Bank Stats State
class BloodBankStatsState {
  final BloodBankStats? stats;
  final bool isLoading;
  final String? error;

  BloodBankStatsState({
    this.stats,
    this.isLoading = false,
    this.error,
  });

  BloodBankStatsState copyWith({
    BloodBankStats? stats,
    bool? isLoading,
    String? error,
  }) {
    return BloodBankStatsState(
      stats: stats ?? this.stats,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Blood Bank Stats Controller
class BloodBankStatsController extends StateNotifier<BloodBankStatsState> {
  final BloodBankApiService _apiService;

  BloodBankStatsController(this._apiService) : super(BloodBankStatsState());

  Future<void> loadStats() async {
    state = state.copyWith(isLoading: true, error: null);
    
    final response = await _apiService.getBloodBankStats();
    
    if (response.success && response.data != null) {
      state = state.copyWith(
        stats: response.data!,
        isLoading: false,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: response.error ?? 'Failed to load statistics',
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Blood Bank Stats Provider
final bloodBankStatsControllerProvider = StateNotifierProvider<BloodBankStatsController, BloodBankStatsState>((ref) {
  final apiService = ref.watch(bloodBankApiServiceProvider);
  return BloodBankStatsController(apiService);
});

// Recent Activity Provider
final recentActivityProvider = FutureProvider<List<BloodBankActivity>>((ref) async {
  final apiService = ref.watch(bloodBankApiServiceProvider);
  final response = await apiService.getRecentActivity();
  
  if (response.success && response.data != null) {
    return response.data!;
  } else {
    throw Exception(response.error ?? 'Failed to load recent activity');
  }
});

// Blood Type Availability Provider
final bloodTypeAvailabilityProvider = FutureProvider<Map<String, int>>((ref) async {
  final apiService = ref.watch(bloodBankApiServiceProvider);
  final response = await apiService.getBloodTypeAvailability();
  
  if (response.success && response.data != null) {
    return response.data!;
  } else {
    throw Exception(response.error ?? 'Failed to load blood type availability');
  }
});

// Computed Providers
final totalStockProvider = Provider<int>((ref) {
  final stockState = ref.watch(bloodStockControllerProvider);
  return stockState.stocks
      .where((stock) => stock.status == BloodStockStatus.available)
      .fold(0, (sum, stock) => sum + stock.quantity);
});

final pendingRequestsCountProvider = Provider<int>((ref) {
  final requestsState = ref.watch(bloodRequestsControllerProvider);
  return requestsState.requests
      .where((request) => request.status == BloodRequestStatus.pending)
      .length;
});

final urgentRequestsCountProvider = Provider<int>((ref) {
  final requestsState = ref.watch(bloodRequestsControllerProvider);
  return requestsState.requests
      .where((request) => request.priority == BloodRequestPriority.urgent)
      .length;
});

final expiringStockCountProvider = Provider<int>((ref) {
  final stockState = ref.watch(bloodStockControllerProvider);
  final cutoffDate = DateTime.now().add(const Duration(days: 7));
  return stockState.stocks
      .where((stock) => 
        stock.expirationDate.isBefore(cutoffDate) && 
        stock.status == BloodStockStatus.available)
      .length;
});

final criticalStockCountProvider = Provider<int>((ref) {
  final stockState = ref.watch(bloodStockControllerProvider);
  final stockByType = <String, int>{};
  
  for (final stock in stockState.stocks) {
    if (stock.status == BloodStockStatus.available) {
      stockByType[stock.bloodType] = (stockByType[stock.bloodType] ?? 0) + stock.quantity;
    }
  }
  
  return stockByType.values.where((quantity) => quantity <= 5).length;
});
