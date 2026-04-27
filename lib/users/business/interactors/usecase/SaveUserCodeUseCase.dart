import 'package:eblood_bank_mak_app/users/business/models/OtpCodeModele.dart';
import 'package:eblood_bank_mak_app/users/business/models/code_otp/DatumCodeOtpModele.dart';
import 'package:eblood_bank_mak_app/users/business/service/utilisateurLocalService.dart';

class SaveUserCodeUseCase{
  UtilisateurLocalService local;
  SaveUserCodeUseCase(this.local);
  Future<bool> run(DatumCodeOtpModele data) async{
    var res=await local.saveUserCode(data);
    return res;
  }
}