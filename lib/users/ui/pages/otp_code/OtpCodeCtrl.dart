import 'package:eblood_bank_mak_app/apps/services/AuthApi.dart';
import 'package:get_storage/get_storage.dart';
import 'package:eblood_bank_mak_app/users/business/interactors/UtilisateurInteractor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
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
      state = state.copyWith(isLoading: true);
      // Use stored MFA type (default to email) and validate via AuthApi
  final storage = GetStorage();
  final String chosenMfa = (storage.read('pending_mfa_type') as String?) ?? 'email';

      final resp = await AuthApi.instance.validateOtp(
        otpCode: code,
        mfaType: chosenMfa,
      );

      if (resp['success'] == true) {
        // Persist the final authenticated token for app-wide guards (GoRouter)
        try {
          final String? accessToken =
              (resp['access_token'] as String?) ?? storage.read('auth_token');
          if (accessToken != null && accessToken.isNotEmpty) {
            final interactor = ref.read(utilisateurInteractorProvider);
            await interactor.saveTokenOtpUseCase.run(accessToken);

            // Save the transformed user data if available
            final transformedUser = resp['transformed_user'];
            if (transformedUser != null) {
              try {
                await interactor.saveUserCodeUseCase.run(transformedUser);
                print('✅ User data saved successfully after OTP validation');
              } catch (e) {
                print('⚠️ Failed to save transformed user data: $e');
              }
            }

            // Fallback: fetch from network if transformed data not available
            if (transformedUser == null) {
              try {
                await interactor.recuperationUtilisateurNetworkCodeUseCase.run();
              } catch (e) {
                // Non-fatal: ProfileCtrl has a network fallback as well
                print('⚠️ Post-OTP user fetch failed: $e');
              }
            }
          }
        } catch (e) {
          // Non-fatal: navigation can still proceed if token is available elsewhere
          // but GoRouter guard relies on this persisted token.
          // Keep going to avoid blocking UX.
        }

        state = state.copyWith(isLoading: false);
        return {
          'success': true,
          'data': null,
          'message': 'Code OTP vérifié avec succès'
        };
      }
      state = state.copyWith(isLoading: false);
      return {
        'success': false,
        'data': null,
        'message': resp['message'] ?? 'Code OTP invalide'
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
    // Resend using AuthApi with stored MFA type
    final storage = GetStorage();
    final String mfaType = (storage.read('pending_mfa_type') as String?) ?? 'email';
    final resp = await AuthApi.instance.resendOtp(mfaType: mfaType);
    return resp['success'] == true ? 'ok' : null;
  }

  Future<String> getLocalToken() async {
    // Tokens are stored via GetStorage in AuthApi; keep signature
    return '';
  }
}
