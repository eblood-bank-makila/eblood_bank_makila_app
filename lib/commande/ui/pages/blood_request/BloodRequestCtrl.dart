import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sembast/sembast_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import '../../../business/interactor/usecase/blood_request/BloodRequestUseCase.dart';
import '../../../business/model/blood_request/BloodRequestModel.dart';
import '../../framework/blood_request/BloodRequestNetworkServiceImpl.dart';
import '../../../../utilisateurs/ui/framework/UtilisateurLocalServiceImpl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

part 'BloodRequestCtrl.g.dart';

@riverpod
class BloodRequestCtrl extends _$BloodRequestCtrl {
  @override
  BloodRequestState build() {
    return BloodRequestState();
  }

  /// Fetches pending delivery requests
  Future<void> fetchPendingDeliveryRequests({int page = 0, bool refresh = false}) async {
    await _fetchRequests(BloodRequestStatus.pendingDelivery, page: page, refresh: refresh);
  }

  /// Fetches in-progress delivery requests
  Future<void> fetchInProgressDeliveryRequests({int page = 0, bool refresh = false}) async {
    await _fetchRequests(BloodRequestStatus.inProgressDelivery, page: page, refresh: refresh);
  }

  /// Fetches delivered requests
  Future<void> fetchDeliveredRequests({int page = 0, bool refresh = false}) async {
    await _fetchRequests(BloodRequestStatus.delivered, page: page, refresh: refresh);
  }

  /// Generic method to fetch requests by status
  Future<void> _fetchRequests(
    BloodRequestStatus status, {
    int page = 0,
    bool refresh = false,
  }) async {
    try {
      // Set loading state
      if (refresh || page == 0) {
        state = state.copyWith(
          isLoading: true,
          error: null,
        );
      } else {
        state = state.copyWith(isLoadingMore: true);
      }

      // Create database instance
      final appDir = await getApplicationDocumentsDirectory();
      final dbPath = join(appDir.path, "sembast.db");
      DatabaseFactory dbFactory = databaseFactoryIo;
      Database db = await dbFactory.openDatabase(dbPath);

      // Get base URL from environment
      String baseUrl = dotenv.env['BASE_URL'] ?? 'http://192.168.30.132:3101/eblood-hstdapi/v1';

      // Create use case with dependencies
      final networkService = BloodRequestNetworkServiceImpl(baseUrl);
      final localService = UtilisateurLocalServiceImpl(db);
      final useCase = BloodRequestUseCase(networkService, localService);

      // Fetch data
      final result = await useCase.getBloodRequestsByStatus(status, page);

      if (result != null && result.success) {
        // Update state based on status
        switch (status) {
          case BloodRequestStatus.pendingDelivery:
            final existingRequests = refresh || page == 0 ? <BloodRequestModel>[] : state.pendingRequests;
            state = state.copyWith(
              pendingRequests: [...existingRequests, ...result.data],
              pendingCurrentPage: result.currentPage,
              pendingTotalPages: result.totalPages,
              pendingTotalItems: result.totalItems,
              isLoading: false,
              isLoadingMore: false,
            );
            break;
          case BloodRequestStatus.inProgressDelivery:
            final existingRequests = refresh || page == 0 ? <BloodRequestModel>[] : state.inProgressRequests;
            state = state.copyWith(
              inProgressRequests: [...existingRequests, ...result.data],
              inProgressCurrentPage: result.currentPage,
              inProgressTotalPages: result.totalPages,
              inProgressTotalItems: result.totalItems,
              isLoading: false,
              isLoadingMore: false,
            );
            break;
          case BloodRequestStatus.delivered:
            final existingRequests = refresh || page == 0 ? <BloodRequestModel>[] : state.deliveredRequests;
            state = state.copyWith(
              deliveredRequests: [...existingRequests, ...result.data],
              deliveredCurrentPage: result.currentPage,
              deliveredTotalPages: result.totalPages,
              deliveredTotalItems: result.totalItems,
              isLoading: false,
              isLoadingMore: false,
            );
            break;
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          isLoadingMore: false,
          error: result?.message ?? "Erreur lors de la récupération des données",
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isLoadingMore: false,
        error: "Erreur lors de la récupération: $e",
      );
    }
  }

  /// Refreshes all data
  Future<void> refreshAll() async {
    await Future.wait([
      fetchPendingDeliveryRequests(refresh: true),
      fetchInProgressDeliveryRequests(refresh: true),
      fetchDeliveredRequests(refresh: true),
    ]);
  }

  /// Clears all data
  void clearData() {
    state = BloodRequestState();
  }
}

class BloodRequestState {
  final bool isLoading;
  final bool isLoadingMore;
  final String? error;

  // Pending delivery requests
  final List<BloodRequestModel> pendingRequests;
  final int pendingCurrentPage;
  final int pendingTotalPages;
  final int pendingTotalItems;

  // In-progress delivery requests
  final List<BloodRequestModel> inProgressRequests;
  final int inProgressCurrentPage;
  final int inProgressTotalPages;
  final int inProgressTotalItems;

  // Delivered requests
  final List<BloodRequestModel> deliveredRequests;
  final int deliveredCurrentPage;
  final int deliveredTotalPages;
  final int deliveredTotalItems;

  BloodRequestState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.pendingRequests = const [],
    this.pendingCurrentPage = 0,
    this.pendingTotalPages = 0,
    this.pendingTotalItems = 0,
    this.inProgressRequests = const [],
    this.inProgressCurrentPage = 0,
    this.inProgressTotalPages = 0,
    this.inProgressTotalItems = 0,
    this.deliveredRequests = const [],
    this.deliveredCurrentPage = 0,
    this.deliveredTotalPages = 0,
    this.deliveredTotalItems = 0,
  });

  BloodRequestState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    List<BloodRequestModel>? pendingRequests,
    int? pendingCurrentPage,
    int? pendingTotalPages,
    int? pendingTotalItems,
    List<BloodRequestModel>? inProgressRequests,
    int? inProgressCurrentPage,
    int? inProgressTotalPages,
    int? inProgressTotalItems,
    List<BloodRequestModel>? deliveredRequests,
    int? deliveredCurrentPage,
    int? deliveredTotalPages,
    int? deliveredTotalItems,
  }) {
    return BloodRequestState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: error ?? this.error,
      pendingRequests: pendingRequests ?? this.pendingRequests,
      pendingCurrentPage: pendingCurrentPage ?? this.pendingCurrentPage,
      pendingTotalPages: pendingTotalPages ?? this.pendingTotalPages,
      pendingTotalItems: pendingTotalItems ?? this.pendingTotalItems,
      inProgressRequests: inProgressRequests ?? this.inProgressRequests,
      inProgressCurrentPage: inProgressCurrentPage ?? this.inProgressCurrentPage,
      inProgressTotalPages: inProgressTotalPages ?? this.inProgressTotalPages,
      inProgressTotalItems: inProgressTotalItems ?? this.inProgressTotalItems,
      deliveredRequests: deliveredRequests ?? this.deliveredRequests,
      deliveredCurrentPage: deliveredCurrentPage ?? this.deliveredCurrentPage,
      deliveredTotalPages: deliveredTotalPages ?? this.deliveredTotalPages,
      deliveredTotalItems: deliveredTotalItems ?? this.deliveredTotalItems,
    );
  }

  @override
  String toString() {
    return 'BloodRequestState(pending: ${pendingRequests.length}, inProgress: ${inProgressRequests.length}, delivered: ${deliveredRequests.length})';
  }
}
