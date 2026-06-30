import 'package:eblood_bank_mak_app/users/business/service/utilisateurLocalService.dart';

class RecuperationTokenUseCase {
  UtilisateurLocalService local;

  RecuperationTokenUseCase(this.local);

  Future<String> run() async {
    var res = await local.recupererToken();
    return res;
  }
}
