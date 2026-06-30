import 'package:eblood_bank_mak_app/users/business/models/authentification/Authentification.dart';
import 'package:eblood_bank_mak_app/users/business/models/authentification/AuthentificationModele.dart';
import 'package:eblood_bank_mak_app/users/business/models/OtpCodeModele.dart';
import 'package:eblood_bank_mak_app/users/business/models/OtpModele.dart';
import 'package:eblood_bank_mak_app/users/business/models/changerPassword/ChangerPasswordModel.dart';
import 'package:eblood_bank_mak_app/users/business/models/changerPassword/PasswordChangerModel.dart';
import 'package:eblood_bank_mak_app/users/business/models/code_otp/DatumCodeOtpModele.dart';
import 'package:eblood_bank_mak_app/users/business/models/notification/DatumNotificationModel.dart';
import 'package:eblood_bank_mak_app/users/business/models/notification/SuppressionResponseNotificationModel.dart';
import 'package:eblood_bank_mak_app/users/business/models/reinitialiserPassword/MotDePasseOublieModele.dart';
import 'package:eblood_bank_mak_app/users/business/models/reinitialiserPassword/OtpCodeReinitialiserModele.dart';
import 'package:eblood_bank_mak_app/users/business/models/reinitialiserPassword/OtpReinitialiserModele.dart';
import 'package:eblood_bank_mak_app/users/business/models/reinitialiserPassword/ReinitialiserModele.dart';
import 'package:eblood_bank_mak_app/users/business/models/reinitialiserPassword/ReinitialiserPasswordModele.dart';
import '../models/notification/SuppressionDatumNotificationModel.dart';
import '../models/reinitialiserPassword/MotDePasseModele.dart';

abstract class UtilisateurNetworkService {
  Future<AuthentificationModel?> recuperationUtilisateur(String token);

  Future<DatumCodeOtpModele?> recuperationUtilisateurOtp(String token);

  Future<AuthentificationModel?> login(AuthenticateRequestBody data);

  Future<List<String>> recuperationNomUtilisateur(String name);

  Future<DatumCodeOtpModele?> verifyOtp(OtpModele data, String token);

  Future<OtpCodeReinitialiserModele?> verifyOtpPassword(
      OtpReinitialiserModele data, String token);

  Future<PasswordChangerModel?> changerPassword(
      ChangerPasswordModel data, String token);

  Future<String> renvoiCode(String token);

  Future<String> renvoiCodePassword(String token);

  Future<bool> deconnexion(String? token);

  Future<MotDePasseModele?> reinitialiserPassword(MotDePasseOublieModele data);

  Future<ReinitialiserModele?> passwordReinitialiser(
      ReinitialiserPasswordModele datas, String data);

  Future<PasswordChangerModel?> passwordChanger(ChangerPasswordModel data);

  Future<List<DatumNotificationModel>?> recuperationNotification(
      String authBarear);

  Future<SuppressionDatumNotificationModel> suppressionNotification(
      String _id, String authBarear);
}
