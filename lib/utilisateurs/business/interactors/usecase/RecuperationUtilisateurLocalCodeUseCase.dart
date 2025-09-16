import 'package:eblood_bank_mak_app/utilisateurs/business/models/OtpCodeModele.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/models/code_otp/DatumCodeOtpModele.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/service/utilisateurLocalService.dart';

class RecuperationUtilisateurLocalCodeUseCase{
  UtilisateurLocalService local;

  RecuperationUtilisateurLocalCodeUseCase(this.local);

  Future<DatumCodeOtpModele?> run() async{
    var res = await local.getCodeUser();
    return res;
  }


}