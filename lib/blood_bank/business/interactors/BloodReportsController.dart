import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eblood_bank_mak_app/core/rbac/models/rbac_models.dart';
import 'package:eblood_bank_mak_app/core/rbac/providers/rbac_provider.dart';
import '../service/BloodReportsApiService.dart';

// API Service Provider
final bloodReportsApiServiceProvider = Provider<BloodReportsApiService>((ref) {
  List<RbacCollectionCrudItem> _resolve(String bbFlag, String cntsFlag) {
    final rbac = ref.read(rbacProvider.notifier);
    var info = rbac.getCrudInfoByPath(bbFlag);
    if (info.isEmpty) info = rbac.getCrudInfoByPath(cntsFlag);
    return info;
  }

  return BloodReportsApiService(
    reportsCrudInfo: _resolve(
      'flutter_apps_eblood_bank_bb_inventory_reports',
      'flutter_apps_eblood_bank_cnts_inventory_reports',
    ),
    exportCrudInfo: _resolve(
      'flutter_apps_eblood_bank_bb_inventory_reports',
      'flutter_apps_eblood_bank_cnts_inventory_reports',
    ),
  );
});

// Reports Key Metrics State
class BloodReportsMetricsState {
  final Map<String, dynamic> metrics;
  final bool isLoading;
  final String? error;

  BloodReportsMetricsState({
    this.metrics = const {},
    this.isLoading = false,
    this.error,
  });

  BloodReportsMetricsState copyWith({
    Map<String, dynamic>? metrics,
    bool? isLoading,
    String? error,
  }) {
    return BloodReportsMetricsState(
      metrics: metrics ?? this.metrics,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Reports Trends State
class BloodReportsTrendsState {
  final Map<String, dynamic> trends;
  final bool isLoading;
  final String? error;

  BloodReportsTrendsState({
    this.trends = const {},
    this.isLoading = false,
    this.error,
  });

  BloodReportsTrendsState copyWith({
    Map<String, dynamic>? trends,
    bool? isLoading,
    String? error,
  }) {
    return BloodReportsTrendsState(
      trends: trends ?? this.trends,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Monthly Comparison State
class BloodReportsMonthlyComparisonState {
  final Map<String, dynamic> comparison;
  final bool isLoading;
  final String? error;

  BloodReportsMonthlyComparisonState({
    this.comparison = const {},
    this.isLoading = false,
    this.error,
  });

  BloodReportsMonthlyComparisonState copyWith({
    Map<String, dynamic>? comparison,
    bool? isLoading,
    String? error,
  }) {
    return BloodReportsMonthlyComparisonState(
      comparison: comparison ?? this.comparison,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Report Metrics Controller
class BloodReportsMetricsController extends StateNotifier<BloodReportsMetricsState> {
  final BloodReportsApiService _apiService;

  BloodReportsMetricsController(this._apiService) : super(BloodReportsMetricsState());

  Future<void> loadMetrics({
    String? startDate,
    String? endDate,
    String? bloodType,
    String? component,
    String? bloodBankId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    final response = await _apiService.getBloodReportMetricKeys(
      startDate: startDate,
      endDate: endDate,
      bloodType: bloodType,
      component: component,
      bloodBankId: bloodBankId,
    );
    
    if (response.success && response.data != null) {
      state = state.copyWith(
        metrics: response.data,
        isLoading: false,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: response.message ?? 'Failed to load metrics data',
      );
    }
  }
}

// Report Trends Controller
class BloodReportsTrendsController extends StateNotifier<BloodReportsTrendsState> {
  final BloodReportsApiService _apiService;

  BloodReportsTrendsController(this._apiService) : super(BloodReportsTrendsState());

  Future<void> loadTrends({
    required String period,
    String? bloodType,
    String? component,
    String? bloodBankId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    final response = await _apiService.getBloodReportsTrends(
      period: period,
      bloodType: bloodType,
      component: component,
      bloodBankId: bloodBankId,
    );
    
    if (response.success && response.data != null) {
      state = state.copyWith(
        trends: response.data,
        isLoading: false,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: response.message ?? 'Failed to load trend data',
      );
    }
  }
}

// Monthly Comparison Controller
class BloodReportsMonthlyComparisonController extends StateNotifier<BloodReportsMonthlyComparisonState> {
  final BloodReportsApiService _apiService;

  BloodReportsMonthlyComparisonController(this._apiService) : super(BloodReportsMonthlyComparisonState());

  Future<void> loadMonthlyComparison({
    int? compareMonth,
    int? compareYear,
    String? bloodBankId,
  }) async {
    print('🔄 BloodReportsMonthlyComparisonController: Loading comparison data...');
    print('📅 Parameters: month=$compareMonth, year=$compareYear, bloodBankId=$bloodBankId');
    
    state = state.copyWith(isLoading: true, error: null);
    
    final response = await _apiService.getMonthlyComparison(
      compareMonth: compareMonth,
      compareYear: compareYear,
      bloodBankId: bloodBankId,
    );
    
    if (response.success && response.data != null) {
      print('✅ BloodReportsMonthlyComparisonController: Data received successfully');
      print('📊 Response data: ${response.data}');
      
      state = state.copyWith(
        comparison: response.data,
        isLoading: false,
      );
    } else {
      print('❌ BloodReportsMonthlyComparisonController: Failed to load data');
      print('🚨 Error: ${response.message}');
      
      state = state.copyWith(
        isLoading: false,
        error: response.message ?? 'Failed to load comparison data',
      );
    }
  }
}

// Providers
final bloodReportsMetricsControllerProvider = StateNotifierProvider<BloodReportsMetricsController, BloodReportsMetricsState>((ref) {
  final apiService = ref.watch(bloodReportsApiServiceProvider);
  return BloodReportsMetricsController(apiService);
});

final bloodReportsTrendsControllerProvider = StateNotifierProvider<BloodReportsTrendsController, BloodReportsTrendsState>((ref) {
  final apiService = ref.watch(bloodReportsApiServiceProvider);
  return BloodReportsTrendsController(apiService);
});

final bloodReportsMonthlyComparisonControllerProvider = StateNotifierProvider<BloodReportsMonthlyComparisonController, BloodReportsMonthlyComparisonState>((ref) {
  final apiService = ref.watch(bloodReportsApiServiceProvider);
  return BloodReportsMonthlyComparisonController(apiService);
});