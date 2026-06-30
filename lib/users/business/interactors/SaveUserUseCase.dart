import 'package:eblood_bank_mak_app/users/business/models/authentification/AuthentificationModele.dart';
import 'package:eblood_bank_mak_app/users/business/service/utilisateurLocalService.dart';

class SaveUserUseCase{
  UtilisateurLocalService local;
  SaveUserUseCase(this.local);
  Future<bool> run(AuthentificationModel data) async{
    var res=await local.saveUser(data);
    return res;
  }
}