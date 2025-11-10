import 'package:eblood_bank_mak_app/utilisateurs/business/models/authentification/AuthentificationModele.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/models/code_otp/DatumCodeOtpModele.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/service/utilisateurLocalService.dart';
import 'package:sembast/sembast.dart';
import 'package:get_storage/get_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

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

    // Also clear any session flags/tokens stored via GetStorage
    try {
      final box = GetStorage();
      // Auth tokens and account context used by UI/routing
      await box.remove('auth_token');
      await box.remove('refresh_token');
      await box.remove('account_type');
      await box.remove('user_profiles');

      // Pending MFA flow flags that could incorrectly trigger OTP screens
      await box.remove('mfa_access_token');
      await box.remove('pending_mfa_type');
      await box.remove('pending_login_email');
      await box.remove('pending_login_phone');

      // Keep remember_me and first-launch/language settings intact
    } catch (e) {
      // Non-fatal: continue clearing secure storage
      print('⚠️ GetStorage clear on logout failed: $e');
    }

    // Clear secure storage tokens written by network/AuthApi layers
    try {
      const secure = FlutterSecureStorage();
      await secure.delete(key: 'auth_token');
      await secure.delete(key: 'refresh_token');
    } catch (e) {
      print('⚠️ SecureStorage clear on logout failed: $e');
    }

    // Sign out from Firebase Auth (Google Sign-In)
    try {
      final firebaseAuth = FirebaseAuth.instance;
      final googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();
      await firebaseAuth.signOut();
      print('🔐 Firebase sign-out successful');
    } catch (e) {
      print('⚠️ Firebase sign-out failed: $e');
      // Continue with logout even if Firebase sign-out fails
    }

    print("🔐 User disconnected - All tokens, session flags, and Firebase auth cleared");
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
