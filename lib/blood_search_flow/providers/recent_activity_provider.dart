/// Global Recent Activity Provider
/// Fetches and caches pending delivery requests + today's succeeded address requests

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../apps/config/api/dio_client.dart';

// ============================================
// Models
// ============================================

class PendingDeliveryItem {
  final String id;
  final String identifier;
  final String status;
  final double totalAmount;
  final double totalAmountMerged;
  final String? createdAt;

  const PendingDeliveryItem({
    required this.id,
    required this.identifier,
    required this.status,
    required this.totalAmount,
    required this.totalAmountMerged,
    this.createdAt,
  });

  factory PendingDeliveryItem.fromJson(Map<String, dynamic> json) {
    return PendingDeliveryItem(
      id: json['id']?.toString() ?? '',
      identifier: json['identifier']?.toString() ?? '',
      status: json['status']?.toString() ?? 'unknown',
      totalAmount: (json['total_amount'] is num) ? (json['total_amount'] as num).toDouble() : 0.0,
      totalAmountMerged: (json['total_amount_merged'] is num) ? (json['total_amount_merged'] as num).toDouble() : 0.0,
      createdAt: json['created_at']?.toString(),
    );
  }

  String get statusDisplay => status.replaceAll('_', ' ').split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
}

class TodayAddressRequestItem {
  final String id;
  final String identifier;
  final String status;
  final double totalAmount;
  final double totalAmountMerged;
  final String? bloodBankId;
  final String? bloodBankName;
  final String? phoneNumber;
  final String? createdAt;

  const TodayAddressRequestItem({
    required this.id,
    required this.identifier,
    required this.status,
    required this.totalAmount,
    required this.totalAmountMerged,
    this.bloodBankId,
    this.bloodBankName,
    this.phoneNumber,
    this.createdAt,
  });

  factory TodayAddressRequestItem.fromJson(Map<String, dynamic> json) {
    return TodayAddressRequestItem(
      id: json['id']?.toString() ?? '',
      identifier: json['identifier']?.toString() ?? '',
      status: json['status']?.toString() ?? 'unknown',
      totalAmount: (json['total_amount'] is num) ? (json['total_amount'] as num).toDouble() : 0.0,
      totalAmountMerged: (json['total_amount_merged'] is num) ? (json['total_amount_merged'] as num).toDouble() : 0.0,
      bloodBankId: json['blood_bank_id']?.toString(),
      bloodBankName: json['blood_bank_name']?.toString(),
      phoneNumber: json['phone_number']?.toString(),
      createdAt: json['created_at']?.toString(),
    );
  }

  String get statusDisplay => status.replaceAll('_', ' ').split(' ').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ');
}

class RecentActivityState {
  final List<PendingDeliveryItem> pendingDeliveries;
  final List<TodayAddressRequestItem> todayAddressRequests;
  final bool isLoading;
  final String? error;
  /// Which tab to auto-open: 0 = deliveries, 1 = address requests, null = don't auto-open
  final int? autoOpenTab;

  const RecentActivityState({
    this.pendingDeliveries = const [],
    this.todayAddressRequests = const [],
    this.isLoading = false,
    this.error,
    this.autoOpenTab,
  });

  bool get hasActivity => pendingDeliveries.isNotEmpty || todayAddressRequests.isNotEmpty;

  int get totalCount => pendingDeliveries.length + todayAddressRequests.length;

  RecentActivityState copyWith({
    List<PendingDeliveryItem>? pendingDeliveries,
    List<TodayAddressRequestItem>? todayAddressRequests,
    bool? isLoading,
    String? error,
    bool clearError = false,
    int? autoOpenTab,
    bool clearAutoOpenTab = false,
  }) {
    return RecentActivityState(
      pendingDeliveries: pendingDeliveries ?? this.pendingDeliveries,
      todayAddressRequests: todayAddressRequests ?? this.todayAddressRequests,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      autoOpenTab: clearAutoOpenTab ? null : (autoOpenTab ?? this.autoOpenTab),
    );
  }
}

// ============================================
// Notifier
// ============================================

class RecentActivityNotifier extends StateNotifier<RecentActivityState> {
  RecentActivityNotifier() : super(const RecentActivityState());

  /// Fetch recent activity from backend
  Future<void> fetchRecentActivity({int? autoOpenTab}) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // Sprint 13b — migrated from /eblood-connect/my-recent-activity to the
      // dedicated activity-log module (kebab-case verb-noun convention).
      final response = await getWithDio('/activity-log/list-recent');

      if (response.success && response.data != null) {
        final data = response.data as Map<String, dynamic>;

        final pendingList = (data['pending_deliveries'] as List<dynamic>?)
            ?.map((e) => PendingDeliveryItem.fromJson(e as Map<String, dynamic>))
            .toList() ?? [];

        final addressList = (data['today_address_requests'] as List<dynamic>?)
            ?.map((e) => TodayAddressRequestItem.fromJson(e as Map<String, dynamic>))
            .toList() ?? [];

        state = state.copyWith(
          pendingDeliveries: pendingList,
          todayAddressRequests: addressList,
          isLoading: false,
          autoOpenTab: autoOpenTab,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      print('RecentActivityProvider.fetchRecentActivity error: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Clear the auto-open tab flag (after showing the bottom sheet)
  void clearAutoOpenTab() {
    state = state.copyWith(clearAutoOpenTab: true);
  }

  /// Trigger showing delivery tab
  void triggerDeliveryTab() {
    state = state.copyWith(autoOpenTab: 0);
  }

  /// Trigger showing address tab
  void triggerAddressTab() {
    state = state.copyWith(autoOpenTab: 1);
  }
}

// ============================================
// Provider
// ============================================

final recentActivityProvider = StateNotifierProvider<RecentActivityNotifier, RecentActivityState>(
  (ref) => RecentActivityNotifier(),
);
