import 'package:eblood_bank_mak_app/users/business/models/reinitialiserPassword/OtpCodeReinitialiserModele.dart';

class OtpCodePasswordStatePage {
  bool isLoading;
  OtpCodeReinitialiserModele? otp;

  OtpCodePasswordStatePage({
    this.isLoading = false,
    this.otp = null,
    //chargement
  });

  OtpCodePasswordStatePage copyWith({bool? isLoading, OtpCodeReinitialiserModele? otp}) =>
      OtpCodePasswordStatePage(
          isLoading: isLoading ?? this.isLoading, otp: otp ?? this.otp);
}
