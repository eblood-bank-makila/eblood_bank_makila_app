import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sembast/sembast_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import '../../../business/interactor/usecase/delivery/DeliveryValidationUseCase.dart';
import '../../../business/model/delivery/DeliveryValidationModel.dart';
import '../../framework/delivery/DeliveryValidationNetworkServiceImpl.dart';
import '../../../../users/ui/framework/UtilisateurLocalServiceImpl.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

part 'DeliveryValidationCtrl.g.dart';

@riverpod
class DeliveryValidationCtrl extends _$DeliveryValidationCtrl {
  @override
  DeliveryValidationState build() {
    return DeliveryValidationState();
  }

  /// Validates delivery using QR code data
  Future<DeliveryValidationResponseModel?> validateDelivery(String qrCodeData) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // Create database instance
      final appDir = await getApplicationDocumentsDirectory();
      final dbPath = join(appDir.path, "sembast.db");
      DatabaseFactory dbFactory = databaseFactoryIo;
      Database db = await dbFactory.openDatabase(dbPath);

      // Navigate to payment status page
      String baseUrl = dotenv.env['BASE_URL'] ?? '';

      // Create use case with dependencies
      final networkService = QrCodeActionNetworkServiceImpl(
        baseUrl
      );
      final localService = UtilisateurLocalServiceImpl(db);
      final useCase = DeliveryValidationUseCase(networkService, localService);

      // Execute validation
      final result = await useCase.run(qrCodeData);

      if (result != null && result.success) {
        state = state.copyWith(
          isLoading: false,
          isSuccess: true,
          result: result,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          isSuccess: false,
          error: result?.message ?? "Erreur inconnue lors de la validation",
        );
      }

      return result;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isSuccess: false,
        error: "Erreur lors de la validation: $e",
      );
      return null;
    }
  }

  /// Resets the state
  void reset() {
    state = DeliveryValidationState();
  }
}

class DeliveryValidationState {
  final bool isLoading;
  final bool isSuccess;
  final String? error;
  final DeliveryValidationResponseModel? result;

  DeliveryValidationState({
    this.isLoading = false,
    this.isSuccess = false,
    this.error,
    this.result,
  });

  DeliveryValidationState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? error,
    DeliveryValidationResponseModel? result,
  }) {
    return DeliveryValidationState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      error: error ?? this.error,
      result: result ?? this.result,
    );
  }

  @override
  String toString() {
    return 'DeliveryValidationState(isLoading: $isLoading, isSuccess: $isSuccess, error: $error, result: $result)';
  }
}
