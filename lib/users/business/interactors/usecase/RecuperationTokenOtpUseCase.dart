import 'package:eblood_bank_mak_app/users/business/service/utilisateurLocalService.dart';

class RecuperationTokenOtpUseCase{
  UtilisateurLocalService local;
  RecuperationTokenOtpUseCase(this.local);

  Future<String?> run() async{
    var res=await local.recupererTokenOtp();
    return res;
  }
}