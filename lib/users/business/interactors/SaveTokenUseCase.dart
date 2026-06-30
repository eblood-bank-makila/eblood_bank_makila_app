import 'package:eblood_bank_mak_app/users/business/service/utilisateurLocalService.dart';

class SaveTokenUseCase {
  UtilisateurLocalService local;

  SaveTokenUseCase(this.local);

  Future<bool> run(String data) async {
    var res = await local.saveToken(data);
    return res;
  }
}
