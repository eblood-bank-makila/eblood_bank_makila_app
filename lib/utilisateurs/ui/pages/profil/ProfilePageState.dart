import 'package:eblood_bank_mak_app/utilisateurs/business/models/OtpCodeModele.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/models/code_otp/DatumCodeOtpModele.dart';

class ProfilePageState {
  bool isLoading;
  DatumCodeOtpModele? user;

  ProfilePageState({
    this.isLoading = false,
    this.user = null,
  });

  ProfilePageState copyWith({
    bool? isLoading,
    DatumCodeOtpModele? user,
  }) =>
      ProfilePageState(
        isLoading: isLoading ?? this.isLoading,
        user: user ?? this.user,
      );
}
