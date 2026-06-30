import 'package:eblood_bank_mak_app/users/business/models/authentification/AuthentificationModele.dart';
import 'package:eblood_bank_mak_app/users/business/models/code_otp/DatumCodeOtpModele.dart';

abstract class UtilisateurLocalService {
  Future<bool> saveToken(String data);

  Future<bool> saveUser(AuthentificationModel data);
  Future<bool> saveUserOtp(DatumCodeOtpModele data);
  Future<bool> saveUserCode(DatumCodeOtpModele data);

  Future<AuthentificationModel?> getUser();
  Future<DatumCodeOtpModele?> getCodeUser();

  Future<bool> deconnexion();

  Future<String> recupererToken();
  Future<String?> recupererTokenOtp();
  Future<bool> saveTokenCode(String data);
  Future<bool> saveTokenPassword(String data);
  Future<String> recupererTokenPassword();
  Future<bool> SaveTokenPasswordChanger(String data);
  Future<String> recupererTokenChanger();

}
