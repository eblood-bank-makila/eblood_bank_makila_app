import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../business/service/BloodDonorApiService.dart';
import '../models/donor.dart';

// Define the donor list state
class DonorListState {
  final bool isLoading;
  final bool isError;
  final String errorMessage;
  final List<Donor> donors;
  final bool isSearchActive;
  final String? searchQuery;
  final String? searchType;
  final String? gender;
  final String? bloodType;
  final int currentPage; // Current page, starting from 0
  final int pageSize; // Number of items per page
  final int totalItems; // Total number of items available
  final bool hasMorePages; // Whether there are more pages to load
  final bool isStatisticsLoading;
  final bool isStatisticsError;
  final String statisticsErrorMessage;
  final Map<String, dynamic>? statistics;

  DonorListState({
    this.isLoading = false,
    this.isError = false,
    this.errorMessage = '',
    this.donors = const [],
    this.isSearchActive = false,
    this.searchQuery,
    this.searchType,
    this.gender,
    this.bloodType,
    this.currentPage = 0, // Start from page 0
    this.pageSize = 20,
    this.totalItems = 0,
    this.hasMorePages = true,
    this.isStatisticsLoading = false,
    this.isStatisticsError = false,
    this.statisticsErrorMessage = '',
    this.statistics,
  });

  // Copy with method to create a new state with some fields updated
  DonorListState copyWith({
    bool? isLoading,
    bool? isError,
    String? errorMessage,
    List<Donor>? donors,
    bool? isSearchActive,
    String? searchQuery,
    String? searchType,
    String? gender,
    String? bloodType,
    int? currentPage,
    int? pageSize,
    int? totalItems,
    bool? hasMorePages,
    bool? isStatisticsLoading,
    bool? isStatisticsError,
    String? statisticsErrorMessage,
    Map<String, dynamic>? statistics,
  }) {
    return DonorListState(
      isLoading: isLoading ?? this.isLoading,
      isError: isError ?? this.isError,
      errorMessage: errorMessage ?? this.errorMessage,
      donors: donors ?? this.donors,
      isSearchActive: isSearchActive ?? this.isSearchActive,
      searchQuery: searchQuery ?? this.searchQuery,
      searchType: searchType ?? this.searchType,
      gender: gender ?? this.gender,
      bloodType: bloodType ?? this.bloodType,
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
      totalItems: totalItems ?? this.totalItems,
      hasMorePages: hasMorePages ?? this.hasMorePages,
      isStatisticsLoading: isStatisticsLoading ?? this.isStatisticsLoading,
      isStatisticsError: isStatisticsError ?? this.isStatisticsError,
      statisticsErrorMessage:
          statisticsErrorMessage ?? this.statisticsErrorMessage,
      statistics: statistics ?? this.statistics,
    );
  }
}
// Donors provider class
class DonorsProvider extends StateNotifier<DonorListState> {
  final BloodDonorApiService _apiService;

  DonorsProvider(this._apiService) : super(DonorListState()) {
    // Load donors and statistics when the provider initializes
    fetchDonors();
    fetchDonorStatistics();
  }

  // Method to fetch donors from API
  Future<void> fetchDonors() async {
    // Set loading state
    state = state.copyWith(isLoading: true, isError: false, errorMessage: '');

    try {
      // Get the response from the API
      final response = await _apiService.getDonorsList(
        searchQuery: state.searchQuery,
        searchType: state.searchType,
        gender: state.gender,
        bloodType: state.bloodType,
        page: state.currentPage, // Use the current page (starts from 0)
        size: state.pageSize,
      );

      if (response.success && response.data != null) {
        // Parse the donors from the response
        List<dynamic> donorDataList = [];
        int totalItems = 0;
        int pageSize = state.pageSize;
        bool hasMorePages = false;

        // Special handling for the nested structure in the response
        if (response.data is Map<String, dynamic>) {
          final responseMap = response.data as Map<String, dynamic>;

          // Based on the logs, donors are directly in data (not in data.data)
          if (responseMap.containsKey('donors') &&
              responseMap['donors'] is List) {
            // Use the donors array directly from response.data
            donorDataList = responseMap['donors'] as List;

            // Get pagination info directly from response.data
            totalItems = responseMap['total_donors'] ?? 0;
            pageSize = responseMap['page_size'] ?? state.pageSize;
            int currentPage = responseMap['page'] ?? 0;

            debugPrint(
              'Found ${donorDataList.length} donors, total: $totalItems, page: $currentPage',
            );

            // Calculate if we have more pages
            if (totalItems > 0) {
              int totalPages = (totalItems / pageSize).ceil();
              hasMorePages = currentPage < totalPages - 1;
            } else {
              hasMorePages = donorDataList.length >= pageSize;
            }
          }
          // Legacy format handling
          else if (responseMap.containsKey('data')) {
            // Check if data contains the donors nested structure
            if (responseMap['data'] is Map<String, dynamic>) {
              final dataObj = responseMap['data'] as Map<String, dynamic>;

              if (dataObj.containsKey('donors') && dataObj['donors'] is List) {
                // Use the donors array from nested data
                donorDataList = dataObj['donors'] as List;

                // Get pagination info from nested data
                totalItems = dataObj['total_donors'] ?? 0;
                pageSize = dataObj['page_size'] ?? state.pageSize;
                int currentPage = dataObj['page'] ?? 0;

                debugPrint(
                  'Found nested ${donorDataList.length} donors, total: $totalItems, page: $currentPage',
                );

                // Calculate if we have more pages
                if (totalItems > 0) {
                  int totalPages = (totalItems / pageSize).ceil();
                  hasMorePages = currentPage < totalPages - 1;
                } else {
                  hasMorePages = donorDataList.length >= pageSize;
                }
              } else if (dataObj is List) {
                // Direct list in data field
                donorDataList = dataObj as List;
              }
            } else if (responseMap['data'] is List) {
              // Direct list in data field
              donorDataList = responseMap['data'] as List;
            }
          } else if (responseMap.containsKey('totalElements')) {
            // For the legacy format with pagination metadata
            totalItems = responseMap['totalElements'] ?? 0;
            if (responseMap.containsKey('totalPages')) {
              int totalPages = responseMap['totalPages'] ?? 0;
              hasMorePages = (state.currentPage + 1) < totalPages;
            }
          }
        } else if (response.data is List) {
          // Direct list of donors
          donorDataList = response.data;
          hasMorePages = donorDataList.length >= state.pageSize;
        }

        debugPrint('Processing ${donorDataList.length} donors from API');

        // Convert raw data to Donor objects with error handling
        final List<Donor> donorsList = donorDataList
            .where((donorData) {
              final isMap = donorData is Map<String, dynamic>;
              if (!isMap) {
                debugPrint('Invalid donor data format (not a Map): $donorData');
              }
              return isMap;
            })
            .map((donorData) {
              try {
                final donor = Donor.fromJson(donorData as Map<String, dynamic>);
                debugPrint(
                  'Successfully parsed donor: ${donor.firstName} ${donor.lastName}',
                );
                return donor;
              } catch (e) {
                debugPrint('Error parsing donor: $e');
                debugPrint('Problem donor data: $donorData');
                return null;
              }
            })
            .where((donor) => donor != null)
            .cast<Donor>()
            .toList();

        // For first page, replace the list. For additional pages, append to existing list.
        final List<Donor> updatedDonors = state.currentPage == 0
            ? donorsList
            : [...state.donors, ...donorsList];

        debugPrint('Final donor list contains ${donorsList.length} items');
        if (donorsList.isEmpty) {
          debugPrint(
            'WARNING: No donors were successfully parsed from API data',
          );
        }

        // Update state with fetched donors and pagination info
        state = state.copyWith(
          isLoading: false,
          donors: updatedDonors,
          totalItems: totalItems,
          hasMorePages: hasMorePages,
          // Only consider search active if there's actual filtering taking place
          // When searchQuery, gender, or bloodType has a non-empty value
          isSearchActive:
              (state.searchQuery != null && state.searchQuery!.isNotEmpty) ||
              (state.gender != null && state.gender!.isNotEmpty) ||
              (state.bloodType != null && state.bloodType!.isNotEmpty),
        );

        // Additional check to verify state update was successful
        debugPrint(
          'State updated with ${state.donors.length} donors, isLoading: ${state.isLoading}',
        );
      } else {
        // Handle API error
        state = state.copyWith(
          isLoading: false,
          isError: true,
          errorMessage: response.message ?? 'Failed to fetch donors',
        );
      }
    } catch (e) {
      debugPrint('Error in fetchDonors: $e');
      // Update state with error
      state = state.copyWith(
        isLoading: false,
        isError: true,
        errorMessage: 'An error occurred while fetching donors: $e',
      );
    }
  }

  Future<void> fetchDonorStatistics() async {
    state = state.copyWith(
      isStatisticsLoading: true,
      isStatisticsError: false,
      statisticsErrorMessage: '',
    );

    try {
      final response = await _apiService.getDonorStatistics();

      if (response.success && response.data is Map<String, dynamic>) {
        state = state.copyWith(
          isStatisticsLoading: false,
          isStatisticsError: false,
          statisticsErrorMessage: '',
          statistics: response.data as Map<String, dynamic>,
        );
      } else {
        state = state.copyWith(
          isStatisticsLoading: false,
          isStatisticsError: true,
          statisticsErrorMessage:
              response.message ?? 'Impossible de récupérer les statistiques',
        );
      }
    } catch (e) {
      debugPrint('Error in fetchDonorStatistics: $e');
      state = state.copyWith(
        isStatisticsLoading: false,
        isStatisticsError: true,
        statisticsErrorMessage:
            'Une erreur est survenue lors de la récupération des statistiques: $e',
      );
    }
  }

  // Method to search for donors
  Future<void> searchDonors({
    String? searchQuery,
    String? searchType,
    String? gender,
    String? bloodType,
  }) async {
    // Update search parameters and reset pagination
    state = state.copyWith(
      searchQuery: searchQuery,
      searchType: searchType,
      gender: gender,
      bloodType: bloodType,
      currentPage: 0, // Reset to first page when searching
      // Only consider search active if there's actual filtering taking place
      // When searchQuery, gender, or bloodType has a non-empty value
      isSearchActive:
          (searchQuery != null && searchQuery.isNotEmpty) ||
          (gender != null && gender.isNotEmpty) ||
          (bloodType != null && bloodType.isNotEmpty),
    );

    // Fetch donors with new search parameters
    await fetchDonors();
  }

  // Method to clear search
  Future<void> clearSearch({String? preserveSearchType}) async {
    state = state.copyWith(
      searchQuery: null,
      // If preserveSearchType is provided, keep that search type, otherwise reset to default
      searchType: preserveSearchType ?? 'donor_code',
      gender: null,
      bloodType: null,
      currentPage: 0, // Reset to first page
      isSearchActive: false,
    );

    // Fetch donors with cleared search parameters
    await fetchDonors();
  }

  // Method to force a complete search reset without relying on state transitions
  // This is specifically designed to fix issues with search resetting
  Future<void> forceResetSearch() async {
    // First, explicitly set all search parameters to null in the state
    state = DonorListState(
      donors: [], // Clear donors to force a complete refresh
      searchQuery: null, // Explicitly null search query
      searchType: 'donor_code',
      gender: null,
      bloodType: null,
      currentPage: 0,
      pageSize: state.pageSize, // Keep the same page size
      hasMorePages: false,
      isLoading: true, // Set loading to true for UI feedback
      isError: false,
      errorMessage: '',
      isSearchActive: false,
      isStatisticsLoading: state.isStatisticsLoading,
      isStatisticsError: state.isStatisticsError,
      statisticsErrorMessage: state.statisticsErrorMessage,
      statistics: state.statistics,
    );

    // Debug log to track the reset operation
    debugPrint(
      'Force reset search: state completely reset with explicit nulls',
    );

    // Create a delay to ensure state update completes
    await Future.delayed(Duration.zero);

    // Make a fresh API call with explicitly cleared parameters
    try {
      // Call fetchDonors which will use the cleared state
      await fetchDonors();
      debugPrint(
        'Force reset search complete: ${state.donors.length} donors loaded with no filters',
      );
    } catch (e) {
      debugPrint('Error in forceResetSearch: $e');
      state = state.copyWith(
        isLoading: false,
        isError: true,
        errorMessage:
            'Une erreur est survenue lors de la réinitialisation de la recherche',
      );
    }
  }

  Future<void> searchDonorsByPhoto(
    File photo, {
    Map<String, dynamic>? hints,
  }) async {
    final normalizedHints = <String, dynamic>{};
    if (hints != null) {
      final genderHint = hints['gender'];
      if (genderHint is String && genderHint.isNotEmpty) {
        normalizedHints['gender'] = genderHint.toLowerCase();
      }
      final bloodTypeHint = hints['blood_type'];
      if (bloodTypeHint is String && bloodTypeHint.isNotEmpty) {
        normalizedHints['blood_type'] = bloodTypeHint;
      }
    }

    final String? genderFilter = normalizedHints['gender'] as String?;
    final String? bloodTypeFilter = normalizedHints['blood_type'] as String?;

    state = state.copyWith(
      isLoading: true,
      isError: false,
      errorMessage: '',
      searchType: 'photo',
      searchQuery: null,
      gender: genderFilter,
      bloodType: bloodTypeFilter,
      currentPage: 0,
      isSearchActive: true,
    );

    try {
      final metadata = <String, dynamic>{'search_type': 'photo'};
      if (normalizedHints.isNotEmpty) {
        metadata['hints'] = normalizedHints;
      }

      final response = await _apiService.searchDonorsByPhoto(
        photo: photo,
        metadata: metadata,
      );

      if (response.success && response.data != null) {
        final donorDataList = _extractDonorList(response.data);
        final donorsList = donorDataList
            .whereType<Map<String, dynamic>>()
            .map((donorMap) => Donor.fromJson(donorMap))
            .toList();

        final totalItems = _extractTotalItems(response.data, donorsList.length);

        state = state.copyWith(
          isLoading: false,
          donors: donorsList,
          totalItems: totalItems,
          hasMorePages: false,
          isError: false,
          errorMessage: '',
          isSearchActive: true,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          isError: true,
          errorMessage: response.message ?? 'Échec de la recherche par photo',
        );
      }
    } catch (e) {
      debugPrint('Error in searchDonorsByPhoto: $e');
      state = state.copyWith(
        isLoading: false,
        isError: true,
        errorMessage:
            'Une erreur est survenue lors de la recherche par photo: $e',
      );
    }
  }

  List<dynamic> _extractDonorList(dynamic data) {
    if (data == null) {
      return <dynamic>[];
    }

    if (data is List) {
      return data;
    }

    if (data is Map<String, dynamic>) {
      if (data['donors'] is List) {
        return data['donors'] as List<dynamic>;
      }
      if (data['matches'] is List) {
        return data['matches'] as List<dynamic>;
      }
      if (data['results'] is List) {
        return data['results'] as List<dynamic>;
      }
      if (data.containsKey('data')) {
        return _extractDonorList(data['data']);
      }
    }

    return <dynamic>[];
  }

  int _extractTotalItems(dynamic data, int fallback) {
    if (data is Map<String, dynamic>) {
      if (data['total_donors'] is int) {
        return data['total_donors'] as int;
      }
      if (data['total'] is int) {
        return data['total'] as int;
      }
      if (data['metadata'] is Map<String, dynamic>) {
        final metadata = data['metadata'] as Map<String, dynamic>;
        if (metadata['total'] is int) {
          return metadata['total'] as int;
        }
      }
      if (data.containsKey('data')) {
        return _extractTotalItems(data['data'], fallback);
      }
    }

    return fallback;
  }

  // Method to refresh donors
  Future<void> refreshDonors() async {
    // Reset to page 0 on refresh and set loading state
    state = state.copyWith(
      currentPage: 0,
      isLoading: true,
      isError: false,
      errorMessage: '',
    );

    // Return the future so that RefreshIndicator can track completion
    return fetchDonors();
  }

  // Method to load next page
  Future<void> loadNextPage() async {
    // Only load more if we're not already loading and there are more pages
    if (!state.isLoading && state.hasMorePages) {
      state = state.copyWith(currentPage: state.currentPage + 1);
      await fetchDonors();
    }
  }
}

// Provider for the donors
final donorsProvider = StateNotifierProvider<DonorsProvider, DonorListState>((
  ref,
) {
  final apiService = ref.watch(bloodDonorApiServiceProvider);
  return DonorsProvider(apiService);
});
