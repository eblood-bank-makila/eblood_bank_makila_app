import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../business/service/HealthStructureApiService.dart';
import '../../data/models/HealthStructureModel.dart';

// Service provider
final healthStructureApiServiceProvider = Provider<HealthStructureApiService>((ref) {
  return HealthStructureApiService();
});

// State class for health structures
class HealthStructureState {
  final List<HealthStructureModel> healthStructures;
  final bool isLoading;
  final String? errorMessage;
  final int totalCount;
  final int currentPage;
  final int totalPages;
  final EHealthStructureType? currentTypeFilter;

  HealthStructureState({
    this.healthStructures = const [],
    this.isLoading = false,
    this.errorMessage,
    this.totalCount = 0,
    this.currentPage = 0,
    this.totalPages = 0,
    this.currentTypeFilter,
  });

  HealthStructureState copyWith({
    List<HealthStructureModel>? healthStructures,
    bool? isLoading,
    String? errorMessage,
    int? totalCount,
    int? currentPage,
    int? totalPages,
    EHealthStructureType? currentTypeFilter,
  }) {
    return HealthStructureState(
      healthStructures: healthStructures ?? this.healthStructures,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      totalCount: totalCount ?? this.totalCount,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      currentTypeFilter: currentTypeFilter ?? this.currentTypeFilter,
    );
  }
}

// State notifier for managing health structures
class HealthStructureNotifier extends StateNotifier<HealthStructureState> {
  final HealthStructureApiService _apiService;

  HealthStructureNotifier(this._apiService) : super(HealthStructureState());

  /// Fetch health structures by type
  Future<void> fetchHealthStructuresByType({
    EHealthStructureType? typeFilter,
    int page = 0,
    int limit = 20,
    String? searchQuery,
    bool? hasEmergencyServices,
    String? city,
    String? stateLocation,
  }) async {
    // Set loading state
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      currentTypeFilter: typeFilter,
    );

    try {
      final response = await _apiService.getHealthStructuresByType(
        healthStructureTypeFlag: typeFilter?.value,
        page: page,
        limit: limit,
        searchQuery: searchQuery,
        hasEmergencyServices: hasEmergencyServices,
        city: city,
        state: stateLocation,
      );

      if (response.success && response.data != null) {
        final data = response.data;

        // Parse health structures - data can be a list or a map
        List<dynamic> structuresList = [];
        int totalCount = response.total ?? 0;
        int currentPage = response.page ?? 0;
        int totalPages = 0;

        if (data is List) {
          // If data is a list, structures are directly in data
          structuresList = data;
        } else if (data is Map) {
          // If data is a map, check for health_structures or hospitals keys
          structuresList = data['health_structures'] ?? data['hospitals'] ?? [];
          // Override with data-level pagination if available
          totalCount = data['total'] ?? totalCount;
          currentPage = data['page'] ?? currentPage;
        }

        // Calculate total pages
        if (limit > 0) {
          totalPages = (totalCount + limit - 1) ~/ limit;
        }

        final healthStructuresList = structuresList
            .map((json) => HealthStructureModel.fromJson(json))
            .toList();

        // Update state with fetched data
        state = state.copyWith(
          healthStructures: healthStructuresList,
          isLoading: false,
          totalCount: totalCount,
          currentPage: currentPage,
          totalPages: totalPages,
        );
      } else {
        // Handle error
        state = state.copyWith(
          isLoading: false,
          errorMessage: response.message ?? 'Failed to fetch health structures',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error: $e',
      );
    }
  }

  /// Fetch all health structures (no type filter)
  Future<void> fetchAllHealthStructures({
    int page = 0,
    int limit = 20,
    String? searchQuery,
  }) async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      currentTypeFilter: null,
    );

    try {
      final response = await _apiService.getAllHealthStructures(
        page: page,
        limit: limit,
        searchQuery: searchQuery,
      );

      if (response.success && response.data != null) {
        final data = response.data!;

        // Parse health structures - data can be a list or a map
        List<dynamic> structuresList = [];
        int totalCount = response.total ?? 0;
        int currentPage = response.page ?? 0;
        int totalPages = 0;

        if (data is List) {
          // If data is a list, structures are directly in data
          structuresList = data;
        } else if (data is Map) {
          // If data is a map, check for health_structures or hospitals keys
          structuresList = data['health_structures'] ?? data['hospitals'] ?? [];
          // Override with data-level pagination if available
          totalCount = data['total'] ?? totalCount;
          currentPage = data['page'] ?? currentPage;
        }

        // Calculate total pages
        if (limit > 0) {
          totalPages = (totalCount + limit - 1) ~/ limit;
        }

        final healthStructuresList = structuresList
            .map((json) => HealthStructureModel.fromJson(json))
            .toList();

        state = state.copyWith(
          healthStructures: healthStructuresList,
          isLoading: false,
          totalCount: totalCount,
          currentPage: currentPage,
          totalPages: totalPages,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          errorMessage: response.message ?? 'Failed to fetch health structures',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Error: $e',
      );
    }
  }

  /// Refresh current filter
  Future<void> refresh() async {
    if (state.currentTypeFilter != null) {
      await fetchHealthStructuresByType(
        typeFilter: state.currentTypeFilter,
        page: state.currentPage,
      );
    } else {
      await fetchAllHealthStructures(page: state.currentPage);
    }
  }

  /// Clear state
  void clear() {
    state = HealthStructureState();
  }
}

// Provider for health structure notifier
final healthStructureProvider = StateNotifierProvider<HealthStructureNotifier, HealthStructureState>((ref) {
  final apiService = ref.watch(healthStructureApiServiceProvider);
  return HealthStructureNotifier(apiService);
});
