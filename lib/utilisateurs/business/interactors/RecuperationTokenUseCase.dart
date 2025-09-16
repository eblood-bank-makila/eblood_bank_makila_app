import 'package:eblood_bank_mak_app/utilisateurs/business/service/utilisateurLocalService.dart';

class RecuperationTokenUseCase {
  UtilisateurLocalService local;

  RecuperationTokenUseCase(this.local);

  Future<String> run() async {
    var res = await local.recupererToken();
    return res;
  }
}
