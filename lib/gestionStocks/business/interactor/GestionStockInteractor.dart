import 'package:eblood_bank_mak_app/gestionStocks/business/interactor/usecase/banque/BanqueListeUseCase.dart';
import 'package:eblood_bank_mak_app/gestionStocks/business/interactor/usecase/banque/RecupererListeBanqueLocalUseCase.dart';
import 'package:eblood_bank_mak_app/gestionStocks/business/interactor/usecase/banque/SaveListeBanqueUseCase.dart';
import 'package:eblood_bank_mak_app/gestionStocks/business/interactor/usecase/favoris/FavorisUseCase.dart';
import 'package:eblood_bank_mak_app/gestionStocks/business/interactor/usecase/favoris/RecupererFavorisBanqueUseCase.dart';
import 'package:eblood_bank_mak_app/gestionStocks/business/interactor/usecase/favoris/SupprimerFavorisUseCase.dart';
import 'package:eblood_bank_mak_app/gestionStocks/business/interactor/usecase/recherche/RechercheListeUseCase.dart';
import 'package:eblood_bank_mak_app/gestionStocks/business/service/banque/BanqueListeLocalService.dart';
import 'package:eblood_bank_mak_app/gestionStocks/business/service/favoris/FavorisBanqueNetworkService.dart';
import 'package:eblood_bank_mak_app/gestionStocks/business/service/poche/PocheListeNetworkService.dart';
import 'package:eblood_bank_mak_app/gestionStocks/business/service/recherche/RechercheListeNetworkService.dart';
import 'package:eblood_bank_mak_app/utilisateurs/business/service/utilisateurLocalService.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../service/banque/BanqueListeNetworkService.dart';
import 'usecase/poche/PocheListeUseCase.dart';

part 'GestionStockInteractor.g.dart';

class Gestionstockinteractor {
  BanqueListeUseCase banquelisteusecase;
  PocheListeUseCase pochelisteusecase;
  FavorisUseCase favorisUseCase;
  RecupererFavorisBanqueUseCase recupererFavorisBanqueUseCase;
  RechercheListeUseCase rechercheListeUseCase;
  SaveListeBanqueCodeUseCase saveListeBanqueCodeUseCase;
  RecupererListeBanqueLocalUseCase recupererListeBanqueLocalUseCase;
  SupprimerFavorisUseCase supprimerFavorisUseCase;

  Gestionstockinteractor._(
      this.banquelisteusecase,
      this.pochelisteusecase,
      this.favorisUseCase,
      this.recupererFavorisBanqueUseCase,
      this.rechercheListeUseCase,
      this.saveListeBanqueCodeUseCase,
      this.recupererListeBanqueLocalUseCase,
      this.supprimerFavorisUseCase

      );

  static Gestionstockinteractor build(
      BanqueListeNetworkService network,
      BanqueListeLocalService local,
      UtilisateurLocalService userLocale,
      PocheListeNetworkService poche,
      FavorisBanqueNetworkService favoris,
      RechercheListeNetworkService networks,


      ) {
    return Gestionstockinteractor._(
        BanqueListeUseCase(network, userLocale),
        PocheListeUseCase(poche, userLocale),
        FavorisUseCase(favoris, userLocale),
        RecupererFavorisBanqueUseCase(favoris, userLocale),
        RechercheListeUseCase(networks, userLocale),
        SaveListeBanqueCodeUseCase(local),
        RecupererListeBanqueLocalUseCase(local),
      SupprimerFavorisUseCase(favoris, userLocale)


    );
  }
}

@Riverpod(keepAlive: true)
Gestionstockinteractor gestionstockInteractor(Ref ref) {
  throw Exception("Non encore implementaté");
}
