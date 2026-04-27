import 'package:eblood_bank_mak_app/users/business/models/OtpCodeModele.dart';
import 'package:eblood_bank_mak_app/users/business/models/code_otp/DatumCodeOtpModele.dart';
import 'package:eblood_bank_mak_app/users/business/service/utilisateurLocalService.dart';

class RecuperationUtilisateurLocalCodeUseCase{
  UtilisateurLocalService local;

  RecuperationUtilisateurLocalCodeUseCase(this.local);

  Future<DatumCodeOtpModele?> run() async{
    var res = await local.getCodeUser();
    return res;
  }


}