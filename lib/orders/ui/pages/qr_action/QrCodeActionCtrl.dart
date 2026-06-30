import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sembast/sembast_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import '../../../business/interactor/usecase/qr_action/QrCodeActionUseCase.dart';
import '../../../business/model/delivery/DeliveryValidationModel.dart';
import '../../framework/delivery/DeliveryValidationNetworkServiceImpl.dart';
import '../../../../users/ui/framework/UtilisateurLocalServiceImpl.dart';
import '../../../../apps/config/AppConfig.dart';
import 'package:get/get.dart';

part 'QrCodeActionCtrl.g.dart';

@riverpod
class QrCodeActionCtrl extends _$QrCodeActionCtrl {
  @override
  QrCodeActionState build() {
    return QrCodeActionState();
  }

  /// Executes a QR code action (delivery validation or password request)
  Future<QrCodeActionResponseModel?> executeQrCodeAction(String actionType, String qrCodeData) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // Create database instance
      final appDir = await getApplicationDocumentsDirectory();
      final dbPath = join(appDir.path, "sembast.db");
      DatabaseFactory dbFactory = databaseFactoryIo;
      Database db = await dbFactory.openDatabase(dbPath);

      // Create use case with dependencies using AppConfig
      final baseUrl = AppConfig.instance.fullApiUrl;
      print("🌐 QrCodeActionCtrl using baseUrl: $baseUrl");

      final networkService = QrCodeActionNetworkServiceImpl(baseUrl);
      final localService = UtilisateurLocalServiceImpl(db);
      final useCase = QrCodeActionUseCase(networkService, localService);

      // Execute action
      final result = await useCase.run(actionType, qrCodeData);

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
          error: result?.message ?? 'unknown_execution_error'.tr,
        );
      }

      return result;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        isSuccess: false,
        error: 'execution_error_details'.trParams({'error': e.toString()}),
      );
      return null;
    }
  }

  /// Resets the state
  void reset() {
    state = QrCodeActionState();
  }
}

class QrCodeActionState {
  final bool isLoading;
  final bool isSuccess;
  final String? error;
  final QrCodeActionResponseModel? result;

  QrCodeActionState({
    this.isLoading = false,
    this.isSuccess = false,
    this.error,
    this.result,
  });

  QrCodeActionState copyWith({
    bool? isLoading,
    bool? isSuccess,
    String? error,
    QrCodeActionResponseModel? result,
  }) {
    return QrCodeActionState(
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      error: error ?? this.error,
      result: result ?? this.result,
    );
  }

  @override
  String toString() {
    return 'QrCodeActionState(isLoading: $isLoading, isSuccess: $isSuccess, error: $error, result: $result)';
  }
}
