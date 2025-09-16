import 'package:eblood_bank_mak_app/utilisateurs/business/interactors/UtilisateurInteractor.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/models/OtpCodeModele.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/models/OtpModele.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../business/models/code_otp/DatumCodeOtpModele.dart';
import 'OtpCodePageState.dart';

part 'OtpCodeCtrl.g.dart';

@riverpod
class OtpCodeCtrl extends _$OtpCodeCtrl {
  @override
  OtpCodePageState build() {
    return OtpCodePageState();
  }

  //envoi des données vers framework
  Future<Map<String, dynamic>> otp(String code) async {
    try {
      var data = OtpModele(
        code: code,
      );
      var usecase =
          ref.read(utilisateurInteractorProvider).otpUtilisateurUsecase;
      state = state.copyWith(isLoading: true);
      var res = await usecase.run(data);
      state = state.copyWith(isLoading: false);
      return {
        'success': true,
        'data': res,
        'message': 'Code OTP vérifié avec succès'
      };
    } catch (e) {
      // Ensure loading state is reset even if there's an error
      state = state.copyWith(isLoading: false);
      print('❌ OTP verification error: $e');

      // Extract error message from exception
      String errorMessage = 'Code OTP invalide';
      if (e.toString().contains('Exception: ')) {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      }

      return {
        'success': false,
        'data': null,
        'message': errorMessage
      };
    }
  }

  void readLocalCodeToken() async {
    var usecase = ref.watch(utilisateurInteractorProvider).getUserLocalUseCase;
    var res = await usecase.run();
    print("token local ${res?.toJson()}");
  }

  Future<String?> renvoicode(String token) async {
    var usecase = ref.watch(utilisateurInteractorProvider).renvoyerCodeUseCase;
    var res = await usecase.run(token);
    return res;
  }

  Future<String> getLocalToken() async {
    var usecase =
        ref.watch(utilisateurInteractorProvider).recuperationTokenUseCase;
    var res = await usecase.run();
    print("token $res");
    return res;
  }
}
