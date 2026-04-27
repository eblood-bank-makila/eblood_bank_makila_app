import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/rbac/providers/rbac_provider.dart';
import '../data/models/blood_request_model.dart';
import '../data/services/blood_request_service.dart';

/// State for blood requests
class BloodRequestState {
  final List<BloodRequestModel> requests;
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final int currentPage;
  final int totalItems;
  final bool hasMore;
  final String? statusFilter;
  final String? urgencyFilter;
  final String? searchQuery;

  const BloodRequestState({
    this.requests = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.currentPage = 0,
    this.totalItems = 0,
    this.hasMore = true,
    this.statusFilter,
    this.urgencyFilter,
    this.searchQuery,
  });

  BloodRequestState copyWith({
    List<BloodRequestModel>? requests,
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    int? currentPage,
    int? totalItems,
    bool? hasMore,
    String? statusFilter,
    String? urgencyFilter,
    String? searchQuery,
  }) {
    return BloodRequestState(
      requests: requests ?? this.requests,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error,
      currentPage: currentPage ?? this.currentPage,
      totalItems: totalItems ?? this.totalItems,
      hasMore: hasMore ?? this.hasMore,
      statusFilter: statusFilter ?? this.statusFilter,
      urgencyFilter: urgencyFilter ?? this.urgencyFilter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

/// Controller for blood requests
class BloodRequestController extends StateNotifier<BloodRequestState> {
  final BloodRequestService _service;

  BloodRequestController(this._service) : super(const BloodRequestState());

  /// Fetch blood requests (initial load or refresh)
  Future<void> fetchBloodRequests({bool refresh = false}) async {
    if (refresh) {
      state = state.copyWith(
        isLoading: true,
        error: null,
        currentPage: 0,
        requests: [],
      );
    } else if (state.isLoading || state.isLoadingMore) {
      return; // Prevent duplicate requests
    } else {
      state = state.copyWith(isLoading: true, error: null);
    }

    try {
      final response = await _service.getBloodRequests(
        statusFilter: state.statusFilter,
        urgencyLevel: state.urgencyFilter,
        searchQuery: state.searchQuery,
        page: 0,
        limit: 20,
      );

      state = state.copyWith(
        requests: response.data,
        isLoading: false,
        currentPage: 0,
        totalItems: response.total,
        hasMore: response.data.length < response.total,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load more blood requests (pagination)
  Future<void> loadMore() async {
    if (!state.hasMore || state.isLoadingMore || state.isLoading) {
      return;
    }

    state = state.copyWith(isLoadingMore: true);

    try {
      final nextPage = state.currentPage + 1;
      final response = await _service.getBloodRequests(
        statusFilter: state.statusFilter,
        urgencyLevel: state.urgencyFilter,
        searchQuery: state.searchQuery,
        page: nextPage,
        limit: 20,
      );

      final updatedRequests = [...state.requests, ...response.data];

      state = state.copyWith(
        requests: updatedRequests,
        isLoadingMore: false,
        currentPage: nextPage,
        hasMore: updatedRequests.length < response.total,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  /// Set status filter
  void setStatusFilter(String? status) {
    if (state.statusFilter != status) {
      state = state.copyWith(statusFilter: status);
      fetchBloodRequests(refresh: true);
    }
  }

  /// Set urgency filter
  void setUrgencyFilter(String? urgency) {
    if (state.urgencyFilter != urgency) {
      state = state.copyWith(urgencyFilter: urgency);
      fetchBloodRequests(refresh: true);
    }
  }

  /// Set search query
  void setSearchQuery(String? query) {
    if (state.searchQuery != query) {
      state = state.copyWith(searchQuery: query);
      fetchBloodRequests(refresh: true);
    }
  }

  /// Clear all filters
  void clearFilters() {
    state = state.copyWith(
      statusFilter: null,
      urgencyFilter: null,
      searchQuery: null,
    );
    fetchBloodRequests(refresh: true);
  }

  /// Confirm pickup of blood request
  Future<BloodRequestModel> confirmPickup(String requestId) async {
    try {
      final updatedRequest = await _service.confirmPickup(requestId);

      // Update the request in the list
      final updatedRequests = state.requests.map((request) {
        if (request.id == requestId) {
          return updatedRequest;
        }
        return request;
      }).toList();

      state = state.copyWith(requests: updatedRequests);

      return updatedRequest;
    } catch (e) {
      rethrow;
    }
  }

  /// Update a blood request in the list (for WebSocket updates)
  void updateBloodRequest(BloodRequestModel updatedRequest) {
    final updatedRequests = state.requests.map((request) {
      if (request.id == updatedRequest.id) {
        return updatedRequest;
      }
      return request;
    }).toList();

    // If the request is not in the list, add it at the beginning
    if (!state.requests.any((r) => r.id == updatedRequest.id)) {
      updatedRequests.insert(0, updatedRequest);
    }

    state = state.copyWith(requests: updatedRequests);
  }
}

/// Provider for blood request service
final bloodRequestServiceProvider = Provider<BloodRequestService>((ref) {
  final appCrudInfo = ref.read(rbacProvider.notifier).getCrudInfoByPath(
    'flutter_apps_eblood_bank_blood_bank_requests_app',
  );
  final detailCrudInfo = ref.read(rbacProvider.notifier).getCrudInfoByPath(
    'flutter_apps_eblood_bank_bb_requests_detail',
  );
  return BloodRequestService(appCrudInfo, detailCrudInfo);
});

/// Provider for blood request controller
final bloodRequestProvider =
    StateNotifierProvider<BloodRequestController, BloodRequestState>((ref) {
  final service = ref.watch(bloodRequestServiceProvider);
  return BloodRequestController(service);
});

/// Provider for fetching a single blood request by ID
final bloodRequestByIdProvider = FutureProvider.family<BloodRequestModel, String>((ref, requestId) async {
  final service = ref.watch(bloodRequestServiceProvider);
  return service.getBloodRequestById(requestId);
});

