import 'package:eblood_bank_mak_app/utilisateurs/business/models/authentification/AuthentificationModele.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/models/OtpCodeModele.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/models/code_otp/DatumCodeOtpModele.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/service/utilisateurLocalService.dart';
import 'package:sembast/sembast.dart';

class UtilisateurLocalServiceImpl implements UtilisateurLocalService {
  Database db;
  String userKey = 'UserKey';
  String tokenKey = 'TOKENKey';           // Temporary token after login (before OTP)
  String otpTokenKey = 'OTP_TOKENKey';    // Final token after OTP verification

  var stockage = StoreRef.main();

  UtilisateurLocalServiceImpl(this.db);

  @override
  @override
  Future<bool> saveToken(String data) async {
    await stockage.record(tokenKey).put(db, data);
    return true;
  }

  @override
  Future<bool> saveUser(AuthentificationModel data) async {
    print("User ${data.toJson()}");
    await stockage.record(userKey).put(db, data.toJson());

    return true;
  }

  @override
  // Future<AuthentificationModel?> getUser() async {
  //   var data = await stockage.record(userKey).get(db) as Map?;
  //   print("data local uer $data");
  //   return Future.value(AuthentificationModel.fromJson(data ?? {"id": 0}));
  // }
  Future<AuthentificationModel?> getUser() async {
    var data = await stockage.record(userKey).get(db) as Map<dynamic, dynamic>?;
    print("data local user $data");

    // Cast to Map<String, dynamic> before passing to fromJson
    return Future.value(AuthentificationModel.fromJson(
        data?.cast<String, dynamic>() ?? {"id": 0}));
  }

  @override
  Future<bool> deconnexion() async {
    // Clear all user data and tokens
    await stockage.record(userKey).delete(db);
    await stockage.record(tokenKey).delete(db);      // Temporary token
    await stockage.record(otpTokenKey).delete(db);   // Final OTP token
    print("🔐 User disconnected - All tokens cleared");
    return true;
  }

  @override
  Future<String> recupererToken() async {
    var data = await stockage.record(tokenKey).get(db) as String?;
    print("data tokenddddd: $data");
    return Future.value(data);
  }

  @override
  Future<String?> recupererTokenOtp() async {
    // Only return token if user has completed OTP verification
    var data = await stockage.record(otpTokenKey).get(db) as String?;
    print("🔐 OTP Token check: $data");
    return Future.value(data);
  }

  @override
  Future<bool> saveTokenCode(String data) async {
    // Save final authenticated token after OTP verification
    await stockage.record(otpTokenKey).put(db, data);
    print("🔐 Final OTP token saved: User is now fully authenticated");
    return true;
  }

  @override
  Future<bool> saveUserCode(DatumCodeOtpModele data) async {
    print("User ${data.toJson()}");
    await stockage.record(userKey).put(db, data.toJson());

    return true;
  }

  @override
  Future<DatumCodeOtpModele?> getCodeUser() async {
    var data = await stockage.record(userKey).get(db) as Map?;
    print("data local uer $data");
    return Future.value(
        DatumCodeOtpModele.fromJson(data?.cast<String, dynamic>() ?? {"id": 0}));
  }

  @override
  Future<bool> saveUserOtp(DatumCodeOtpModele data) async {
    print("User ${data.toJson()}");
    await stockage.record(userKey).put(db, data.toJson());

    return true;
  }

  @override
  Future<String> recupererTokenChanger() async {
    var data = await stockage.record(tokenKey).get(db) as String?;
    print("data token: $data");
    return Future.value(data);
  }

  @override
  Future<bool> SaveTokenPasswordChanger(String data) async {
    await stockage.record(tokenKey).put(db, data);
    return true;
  }

  @override
  Future<String> recupererTokenPassword() async {
    var data = await stockage.record(tokenKey).get(db) as String?;
    print("data token: $data");
    return Future.value(data);
  }

  @override
  Future<bool> saveTokenPassword(String data) async {
    await stockage.record(tokenKey).put(db, data);
    return true;
  }
}
