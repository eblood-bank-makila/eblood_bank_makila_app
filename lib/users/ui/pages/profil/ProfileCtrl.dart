import 'package:eblood_bank_mak_app/users/business/interactors/UtilisateurInteractor.dart';
import 'package:eblood_bank_mak_app/users/ui/pages/profil/ProfilePageState.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:eblood_bank_mak_app/users/business/models/code_otp/DatumCodeOtpModele.dart';

part "ProfileCtrl.g.dart";

@riverpod
class ProfileCtrl extends _$ProfileCtrl {
  @override
  ProfilePageState build() {
    return ProfilePageState();
  }

  void getUserCode() async {
    // Start loading
    state = state.copyWith(isLoading: true);

    final interactor = ref.watch(utilisateurInteractorProvider);

    // 1) Try local cached user (saved at OTP verification)
    var localUsecase = interactor.getUserLocalCodeUseCase;
    var res = await localUsecase.run();

    bool isUserInfoMissing(DatumCodeOtpModele? u) {
      if (u == null) return true;
      final hasName = (u.uPrenom.isNotEmpty || u.uNom.isNotEmpty);
      final hasUsername = u.uUserName.isNotEmpty;
      final hasEmail = u.uCourriels.isNotEmpty && u.uCourriels.first.email.isNotEmpty;
      final hasPhone = u.uTelephones.isNotEmpty && u.uTelephones.first.phoneNumber.isNotEmpty;
      return !(hasName || hasUsername || hasEmail || hasPhone);
    }

    // 2) If missing or empty, refresh from network using final OTP token
    if (isUserInfoMissing(res)) {
      try {
        var networkUsecase = interactor.recuperationUtilisateurNetworkCodeUseCase;
        var fetched = await networkUsecase.run();
        if (!isUserInfoMissing(fetched)) {
          res = fetched;
        }
      } catch (_) {
        // Silently ignore; we'll fall back to whatever we have
      }
    }

    // End loading, publish state
    state = state.copyWith(user: res, isLoading: false);
  }

  Future<bool> disconnect() async {
    var usecase =
        ref.watch(utilisateurInteractorProvider).deconnexionUtilisateurUseCase;
    await usecase.run();

    return true;
  }
}
