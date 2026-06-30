import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eblood_bank_mak_app/blood_bank/business/service/BloodBagBatchNumberApiService.dart';

/// Lightweight model for a reusable blood-bag batch number ("numéro de lot").
class BatchNumber {
  final String id;
  final String batchNumber;

  const BatchNumber({required this.id, required this.batchNumber});

  factory BatchNumber.fromJson(Map<String, dynamic> json) => BatchNumber(
        id: (json['id'] ?? json['_id'] ?? '').toString(),
        batchNumber: (json['batch_number'] ?? '').toString(),
      );
}

/// Paginated + searchable list state for the organization's batch numbers.
class BatchNumberListState {
  final bool isLoading;
  final bool isError;
  final String errorMessage;
  final List<BatchNumber> items;
  final String? searchQuery;
  final bool isSearchActive;
  final int currentPage;
  final int pageSize;
  final int totalItems;
  final bool hasMorePages;
  final bool isCreating;

  const BatchNumberListState({
    this.isLoading = false,
    this.isError = false,
    this.errorMessage = '',
    this.items = const [],
    this.searchQuery,
    this.isSearchActive = false,
    this.currentPage = 0,
    this.pageSize = 20,
    this.totalItems = 0,
    this.hasMorePages = true,
    this.isCreating = false,
  });

  /// Items filtered by the local search query (the list endpoint has no query
  /// param, so filtering is client-side over the loaded, paginated set).
  List<BatchNumber> get filteredItems {
    final q = searchQuery?.trim().toLowerCase();
    if (q == null || q.isEmpty) return items;
    return items
        .where((b) => b.batchNumber.toLowerCase().contains(q))
        .toList();
  }

  BatchNumberListState copyWith({
    bool? isLoading,
    bool? isError,
    String? errorMessage,
    List<BatchNumber>? items,
    String? searchQuery,
    bool? isSearchActive,
    int? currentPage,
    int? pageSize,
    int? totalItems,
    bool? hasMorePages,
    bool? isCreating,
  }) {
    return BatchNumberListState(
      isLoading: isLoading ?? this.isLoading,
      isError: isError ?? this.isError,
      errorMessage: errorMessage ?? this.errorMessage,
      items: items ?? this.items,
      searchQuery: searchQuery ?? this.searchQuery,
      isSearchActive: isSearchActive ?? this.isSearchActive,
      currentPage: currentPage ?? this.currentPage,
      pageSize: pageSize ?? this.pageSize,
      totalItems: totalItems ?? this.totalItems,
      hasMorePages: hasMorePages ?? this.hasMorePages,
      isCreating: isCreating ?? this.isCreating,
    );
  }
}

class BatchNumbersProvider extends StateNotifier<BatchNumberListState> {
  final BloodBagBatchNumberApiService _api;

  BatchNumbersProvider(this._api) : super(const BatchNumberListState()) {
    // Fetch the first page (20) on init.
    fetchBatchNumbers();
  }

  /// Fetch the current page. Page 0 replaces the list, later pages append.
  Future<void> fetchBatchNumbers() async {
    state = state.copyWith(isLoading: true, isError: false, errorMessage: '');
    try {
      final res = await _api.getBatchNumbers(
        page: state.currentPage,
        limit: state.pageSize,
      );

      if (res.success && res.data is List) {
        final fetched = (res.data as List)
            .whereType<Map<String, dynamic>>()
            .map(BatchNumber.fromJson)
            .where((b) => b.batchNumber.isNotEmpty)
            .toList();

        final total = res.max ?? 0;
        final merged =
            state.currentPage == 0 ? fetched : [...state.items, ...fetched];

        // Prefer the server total; otherwise fall back to a page-fill heuristic.
        final hasMore = total > 0
            ? merged.length < total
            : fetched.length >= state.pageSize;

        state = state.copyWith(
          isLoading: false,
          items: merged,
          totalItems: total,
          hasMorePages: hasMore,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          isError: true,
          errorMessage: res.message ?? '',
        );
      }
    } catch (e) {
      debugPrint('Error in fetchBatchNumbers: $e');
      state = state.copyWith(
        isLoading: false,
        isError: true,
        errorMessage: e.toString(),
      );
    }
  }

  Future<void> loadNextPage() async {
    if (!state.isLoading && state.hasMorePages) {
      state = state.copyWith(currentPage: state.currentPage + 1);
      await fetchBatchNumbers();
    }
  }

  Future<void> refresh() async {
    state = state.copyWith(currentPage: 0, isLoading: true, isError: false);
    await fetchBatchNumbers();
  }

  /// Client-side search (no server query param on the list endpoint).
  void searchLocal(String query) {
    final q = query.trim();
    state = state.copyWith(searchQuery: q, isSearchActive: q.isNotEmpty);
  }

  void clearSearch() {
    state = state.copyWith(searchQuery: '', isSearchActive: false);
  }

  /// Create a new batch number, or return an existing one (case-insensitive)
  /// without hitting the API. Returns the resolved batch string, or null on
  /// empty input / API failure (caller reads [state.errorMessage]).
  Future<String?> createOrFind(String raw) async {
    final batch = raw.trim();
    if (batch.isEmpty) return null;

    final existing = state.items.where(
      (b) => b.batchNumber.toLowerCase() == batch.toLowerCase(),
    );
    if (existing.isNotEmpty) {
      return existing.first.batchNumber; // dedupe → select, no POST
    }

    state = state.copyWith(isCreating: true, isError: false, errorMessage: '');
    try {
      final res = await _api.createBatchNumber(batch);
      if (res.success) {
        final rawResp = res.raw;
        final id = (rawResp is Map && rawResp['item_id'] != null)
            ? rawResp['item_id'].toString()
            : '';
        // Optimistically prepend so it appears immediately.
        state = state.copyWith(
          isCreating: false,
          items: [BatchNumber(id: id, batchNumber: batch), ...state.items],
          totalItems: state.totalItems + 1,
        );
        return batch;
      }
      state = state.copyWith(
        isCreating: false,
        isError: true,
        errorMessage: res.message ?? '',
      );
      return null;
    } catch (e) {
      debugPrint('Error in createOrFind: $e');
      state = state.copyWith(
        isCreating: false,
        isError: true,
        errorMessage: e.toString(),
      );
      return null;
    }
  }

  /// Rename a batch number. Returns the new value on success, null on failure.
  Future<String?> updateBatchNumber(String id, String raw) async {
    final batch = raw.trim();
    if (id.isEmpty || batch.isEmpty) return null;
    try {
      final res = await _api.updateBatchNumber(id, batch);
      if (res.success) {
        state = state.copyWith(
          items: [
            for (final b in state.items)
              if (b.id == id) BatchNumber(id: id, batchNumber: batch) else b,
          ],
        );
        return batch;
      }
      state = state.copyWith(isError: true, errorMessage: res.message ?? '');
      return null;
    } catch (e) {
      debugPrint('Error in updateBatchNumber: $e');
      state = state.copyWith(isError: true, errorMessage: e.toString());
      return null;
    }
  }

  /// Delete a batch number. Returns true on success.
  Future<bool> deleteBatchNumber(String id) async {
    if (id.isEmpty) return false;
    try {
      final res = await _api.deleteBatchNumber(id);
      if (res.success) {
        state = state.copyWith(
          items: state.items.where((b) => b.id != id).toList(),
          totalItems: state.totalItems > 0 ? state.totalItems - 1 : 0,
        );
        return true;
      }
      state = state.copyWith(isError: true, errorMessage: res.message ?? '');
      return false;
    } catch (e) {
      debugPrint('Error in deleteBatchNumber: $e');
      state = state.copyWith(isError: true, errorMessage: e.toString());
      return false;
    }
  }
}

final batchNumbersProvider =
    StateNotifierProvider<BatchNumbersProvider, BatchNumberListState>((ref) {
  return BatchNumbersProvider(ref.watch(bloodBagBatchNumberApiServiceProvider));
});
