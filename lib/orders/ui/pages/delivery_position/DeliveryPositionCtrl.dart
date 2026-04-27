import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';
import 'package:get/get.dart';

import '../../../business/interactor/usecase/delivery_position/DeliveryPositionUseCase.dart';
import '../../../business/model/delivery/DeliveryPositionModel.dart';
import '../../../business/model/blood_request/BloodRequestModel.dart';
import '../../framework/delivery/DeliveryValidationNetworkServiceImpl.dart';
import '../../../../users/ui/framework/UtilisateurLocalServiceImpl.dart';
import '../../../../apps/config/AppConfig.dart';

final deliveryPositionCtrlProvider = StateNotifierProvider<DeliveryPositionCtrl, DeliveryPositionState>((ref) {
  return DeliveryPositionCtrl();
});

class DeliveryPositionCtrl extends StateNotifier<DeliveryPositionState> {
  DeliveryPositionCtrl() : super(DeliveryPositionState());

  /// Fetches delivery position using action_data
  Future<DeliveryPositionResponseModel?> fetchDeliveryPosition(String actionData) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // Create database instance
      final appDir = await getApplicationDocumentsDirectory();
      final dbPath = join(appDir.path, "sembast.db");
      DatabaseFactory dbFactory = databaseFactoryIo;
      Database db = await dbFactory.openDatabase(dbPath);

      // Create use case with dependencies using AppConfig
      final baseUrl = AppConfig.instance.fullApiUrl;
      print("🌐 DeliveryPositionCtrl using baseUrl: $baseUrl");

      final networkService = QrCodeActionNetworkServiceImpl(baseUrl);
      final localService = UtilisateurLocalServiceImpl(db);
      final useCase = DeliveryPositionUseCase(networkService, localService);

      // Fetch position
      final result = await useCase.fetchDeliveryPosition(actionData);

      if (result != null && result.success && result.info != null) {
        state = state.copyWith(
          isLoading: false,
          isSuccess: true,
          positionInfo: result.info,
          message: result.message,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          isSuccess: false,
          error: result?.message ?? 'error_fetching_position'.tr,
        );
      }

      return result;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isSuccess: false,
        error: 'error_fetching_position_details'.trParams({'error': e.toString()}),
      );
      return null;
    }
  }

  /// Fetches delivery position from BloodRequestModel
  Future<DeliveryPositionResponseModel?> fetchPositionFromRequest(BloodRequestModel request) async {
    if (request.actionData == null || request.actionData!.isEmpty) {
      state = state.copyWith(
        isLoading: false,
        isSuccess: false,
        error: 'no_action_data_available'.tr,
      );
      return null;
    }

    return await fetchDeliveryPosition(request.actionData!);
  }

  /// Refreshes the current position data
  Future<void> refreshPosition() async {
    if (state.lastActionData != null) {
      await fetchDeliveryPosition(state.lastActionData!);
    }
  }

  /// Resets the state
  void reset() {
    state = DeliveryPositionState();
  }

  /// Sets loading state
  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  /// Sets error state
  void setError(String error) {
    state = state.copyWith(
      isLoading: false,
      isSuccess: false,
      error: error,
    );
  }
}

class DeliveryPositionState {
  final bool isLoading;
  final bool isSuccess;
  final String? error;
  final String? message;
  final DeliveryPositionInfo? positionInfo;
  final String? lastActionData;

  DeliveryPositionState({
    this.isLoading = false,
    this.isSuccess = false,
    this.error,
    this.message,
    this.positionInfo,
    this.lastActionData,
  });

  DeliveryPositionState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? error,
    String? message,
    DeliveryPositionInfo? positionInfo,
    String? lastActionData,
  }) {
    return DeliveryPositionState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      error: error ?? this.error,
      message: message ?? this.message,
      positionInfo: positionInfo ?? this.positionInfo,
      lastActionData: lastActionData ?? this.lastActionData,
    );
  }

  /// Check if position data is available and valid
  bool get hasValidPosition {
    return positionInfo != null && 
           DeliveryPositionUseCase.isValidPositionData(positionInfo!);
  }

  /// Get formatted distance string
  String get formattedDistance {
    return positionInfo?.formattedDistance ?? 'not_available_short'.tr;
  }

  /// Get distance status message
  String get distanceStatus {
    if (positionInfo == null) return 'position_unavailable'.tr;
    return DeliveryPositionUseCase.getDistanceStatus(positionInfo!.distance);
  }

  /// Get distance color for UI
  int get distanceColor {
    if (positionInfo == null) return 0xFF9E9E9E; // Grey
    return DeliveryPositionUseCase.getDistanceColor(positionInfo!.distance);
  }

  @override
  String toString() {
    return 'DeliveryPositionState(isLoading: $isLoading, isSuccess: $isSuccess, error: $error, message: $message, positionInfo: $positionInfo, lastActionData: $lastActionData)';
  }
}
