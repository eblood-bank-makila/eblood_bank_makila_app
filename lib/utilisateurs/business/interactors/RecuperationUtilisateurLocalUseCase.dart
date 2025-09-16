import 'package:eblood_bank_mak_app/utilisateurs/business/models/authentification/AuthentificationModele.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/service/utilisateurLocalService.dart';

class RecuperationUtilisateurLocalUseCase{
  UtilisateurLocalService local;

  RecuperationUtilisateurLocalUseCase(this.local);

  Future<AuthentificationModel?> run() async{
    var res = await local.getUser();
    return res;
  }


}