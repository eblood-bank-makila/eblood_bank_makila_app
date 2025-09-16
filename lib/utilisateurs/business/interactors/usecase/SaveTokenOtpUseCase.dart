import 'package:eblood_bank_mak_app/utilisateurs/business/service/utilisateurLocalService.dart';

class SaveTokenOtpUseCase {
  UtilisateurLocalService local;

  SaveTokenOtpUseCase(this.local);

  Future<bool> run(String data) async {
    var res = await local.saveTokenCode(data);
    return res;
  }
}
