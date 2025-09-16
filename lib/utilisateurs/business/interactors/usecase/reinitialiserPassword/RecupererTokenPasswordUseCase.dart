
import 'package:eblood_bank_mak_app/utilisateurs/business/service/utilisateurLocalService.dart';

class RecupererTokenPasswordUseCase{
  UtilisateurLocalService local;
  RecupererTokenPasswordUseCase(this.local);

  Future<String> run() async{
    var res=await local.recupererTokenPassword();
    return res;
  }
}