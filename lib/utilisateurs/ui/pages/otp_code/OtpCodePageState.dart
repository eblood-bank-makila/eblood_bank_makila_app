import 'package:eblood_bank_mak_app/utilisateurs/business/models/OtpCodeModele.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/models/code_otp/DatumCodeOtpModele.dart';

class OtpCodePageState {
  bool isLoading;
  DatumCodeOtpModele? otp;

  OtpCodePageState({
    this.isLoading = false,
    this.otp = null,
    //chargement
  });

  OtpCodePageState copyWith({bool? isLoading, DatumCodeOtpModele? otp}) =>
      OtpCodePageState(
          isLoading: isLoading ?? this.isLoading, otp: otp ?? this.otp);
}
