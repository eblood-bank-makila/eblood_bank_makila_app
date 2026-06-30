import 'package:eblood_bank_mak_app/users/business/service/utilisateurLocalService.dart';

class SaveTokenPasswordUseCase{
  UtilisateurLocalService local;


  SaveTokenPasswordUseCase(this.local);

  Future<bool> run(String data) async{
    var res = await local.saveTokenPassword(data);
    return res;
  }


}