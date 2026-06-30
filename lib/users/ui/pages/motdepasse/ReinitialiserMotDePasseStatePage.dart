import 'package:eblood_bank_mak_app/users/business/models/reinitialiserPassword/MotDePasseModele.dart';

import '../../../business/models/reinitialiserPassword/ReinitialiserModele.dart';

class ReinitialiserMotDePasseStatePage {
  bool isLoading;
  MotDePasseModele? reinitialiser;
  ReinitialiserModele? confirmer_reinitialiser;

  ReinitialiserMotDePasseStatePage(
      {this.isLoading = false,
      this.reinitialiser = null,
      this.confirmer_reinitialiser = null
      //chargement
      });

  ReinitialiserMotDePasseStatePage copyWith(
          {bool? isLoading,
          MotDePasseModele? reinitialiser,
          ReinitialiserModele? confirmer_reinitialiser}) =>
      ReinitialiserMotDePasseStatePage(
          isLoading: isLoading ?? this.isLoading,
          reinitialiser: reinitialiser ?? this.reinitialiser,
          confirmer_reinitialiser:
              confirmer_reinitialiser ?? this.confirmer_reinitialiser);
}
