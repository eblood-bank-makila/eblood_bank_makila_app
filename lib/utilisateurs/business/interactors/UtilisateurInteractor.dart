import 'package:eblood_bank_mak_app/utilisateurs/business/interactors/DeconnexionUtilisateurUseCase.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/interactors/RecuperationNomUseCase.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/interactors/RecuperationTokenUseCase.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/interactors/RecuperationUtilisateurLocalUseCase.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/interactors/RecuperationUtilisateurNetworkUseCase.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/interactors/SaveTokenUseCase.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/interactors/SaveUserUseCase.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/interactors/UtilisateurUseCase.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/interactors/usecase/OtpUtilisateurUseCase.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/interactors/usecase/RecuperationTokenOtpUseCase.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/interactors/usecase/RecuperationUtilisateurLocalCodeUseCase.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/interactors/usecase/RecuperationUtilisateurNetworkCodeUseCase.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/interactors/usecase/RenvoyerCodeUseCase.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/interactors/usecase/SaveTokenOtpUseCase.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/interactors/usecase/SaveUserCodeUseCase.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/interactors/usecase/notification/RecuperationNotificationUseCase.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/interactors/usecase/notification/SuppresionNotificationUseCase.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/interactors/usecase/reinitialiserPassword/OtpCodePasswordUseCase.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/interactors/usecase/reinitialiserPassword/PasswordReinitialiserUseCase.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/interactors/usecase/reinitialiserPassword/ReinitialiserPasswordUseCase.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/interactors/usecase/reinitialiserPassword/RenvoyerCodePasswordUseCase.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/service/utilisateurLocalService.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/service/utilisateurNetworkService.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'usecase/changerPassword/ChangerPasswordUseCase.dart';
import 'usecase/reinitialiserPassword/RecupererTokenPasswordUseCase.dart';
import 'usecase/reinitialiserPassword/SaveTokenPasseword.dart';

part 'UtilisateurInteractor.g.dart';

class Utilisateurinteractor {
  UtilisateurUseCase authentificationusecase;
  OtpUtilisateurUseCase otpUtilisateurUsecase;
  RecuperationUtilisateurLocalUseCase getUserLocalUseCase;
  RecuperationUtilisateurLocalCodeUseCase getUserLocalCodeUseCase;
  DeconnexionUtilisateurUseCase deconnexionUtilisateurUseCase;
  RecuperationNomUseCase recuperationNomUseCase;
  RecuperationTokenOtpUseCase recuperationTokenOtpUseCase;
  RecuperationTokenUseCase recuperationTokenUseCase;
  RecuperationUtilisateurNetworkUseCase recuperationUtilisateurNetworkUseCase;
  RecuperationUtilisateurNetworkCodeUseCase
      recuperationUtilisateurNetworkCodeUseCase;
  SaveTokenUseCase saveTokenUseCase;
  SaveTokenOtpUseCase saveTokenOtpUseCase;
  SaveUserUseCase saveUserUseCase;
  SaveUserCodeUseCase saveUserCodeUseCase;
  RenvoyerCodeUseCase renvoyerCodeUseCase;
  RecupererTokenPasswordUseCase recupererTokenPasswordUseCase;
  SaveTokenPasswordUseCase saveTokenPasswordUseCase;
  ReinitialiserPasswordUseCase reinitialiserPasswordUseCase;
  OtpCodePasswordUseCase otpCodePasswordUseCase;
  RenvoyerCodePasswordUseCase renvoyerCodePasswordUseCase;
  PasswordReinitialiserUseCase passwordReinitialiserUseCase;
  ChangerPasswordUseCase changerPasswordUseCase;
  RecuperationNotifcationUseCase recuperationNotificationUseCase;
  SuppressionNotificationUseCase suppressionNotificationUseCase;

  Utilisateurinteractor._(
      this.authentificationusecase,
      this.otpUtilisateurUsecase,
      this.getUserLocalUseCase,
      this.getUserLocalCodeUseCase,
      this.deconnexionUtilisateurUseCase,
      this.recuperationNomUseCase,
      this.recuperationTokenUseCase,
      this.recuperationTokenOtpUseCase,
      this.recuperationUtilisateurNetworkUseCase,
      this.recuperationUtilisateurNetworkCodeUseCase,
      this.saveTokenUseCase,
      this.saveTokenOtpUseCase,
      this.saveUserCodeUseCase,
      this.saveUserUseCase,
      this.renvoyerCodeUseCase,
      this.recupererTokenPasswordUseCase,
      this.saveTokenPasswordUseCase,
      this.reinitialiserPasswordUseCase,
      this.otpCodePasswordUseCase,
      this.renvoyerCodePasswordUseCase,
      this.passwordReinitialiserUseCase,
      this.changerPasswordUseCase,
      this.recuperationNotificationUseCase,
      this.suppressionNotificationUseCase);

  static Utilisateurinteractor build(
      UtilisateurNetworkService network, UtilisateurLocalService local) {
    return Utilisateurinteractor._(
        UtilisateurUseCase(network, local),
        OtpUtilisateurUseCase(network, local),
        RecuperationUtilisateurLocalUseCase(local),
        RecuperationUtilisateurLocalCodeUseCase(local),
        DeconnexionUtilisateurUseCase(network, local),
        RecuperationNomUseCase(network),
        RecuperationTokenUseCase(local),
        RecuperationTokenOtpUseCase(local),
        RecuperationUtilisateurNetworkUseCase(network, local),
        RecuperationUtilisateurNetworkCodeUseCase(network, local),
        SaveTokenUseCase(local),
        SaveTokenOtpUseCase(local),
        SaveUserCodeUseCase(local),
        SaveUserUseCase(local),
        RenvoyerCodeUseCase(network),
        RecupererTokenPasswordUseCase(local),
        SaveTokenPasswordUseCase(local),
        ReinitialiserPasswordUseCase(network, local),
        OtpCodePasswordUseCase(network, local),
        RenvoyerCodePasswordUseCase(network),
        PasswordReinitialiserUseCase(network, local),
        ChangerPasswordUseCase(network, local),
        RecuperationNotifcationUseCase(network, local),
        SuppressionNotificationUseCase(network, local));
  }
}

@Riverpod(keepAlive: true)
Utilisateurinteractor utilisateurInteractor(Ref ref) {
  throw Exception("Non encore implementaté");
}
