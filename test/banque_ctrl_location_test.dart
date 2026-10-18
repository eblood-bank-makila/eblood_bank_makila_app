import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:eblood_bank_mak_app/core/services/location_access.dart';
import 'package:eblood_bank_mak_app/stock_management/business/interactor/GestionStockInteractor.dart';
import 'package:eblood_bank_mak_app/stock_management/business/model/banque/BanqueModele.dart';
import 'package:eblood_bank_mak_app/stock_management/business/service/banque/BanqueListeLocalService.dart';
import 'package:eblood_bank_mak_app/stock_management/business/service/banque/BanqueListeNetworkService.dart';
import 'package:eblood_bank_mak_app/stock_management/business/service/favoris/FavorisBanqueNetworkService.dart';
import 'package:eblood_bank_mak_app/stock_management/business/service/poche/PocheListeNetworkService.dart';
import 'package:eblood_bank_mak_app/stock_management/business/service/recherche/RechercheListeNetworkService.dart';
import 'package:eblood_bank_mak_app/stock_management/ui/pages/banque/BanqueCtrl.dart';
import 'package:eblood_bank_mak_app/users/business/service/utilisateurLocalService.dart';

/// First call: no position. Every later call: one bank.
class _Network implements BanqueListeNetworkService {
  var calls = 0;

  @override
  Future<List<BanqueModele>?> recuperationListeBanque(String token) async {
    if (calls++ == 0) throw const LocationUnavailableException();
    return [
      BanqueModele.fromJson({
        '_id': 'b1',
        'identifier': 'b1',
        'blood_bank_name': 'cs dannico',
        'blood_bank_logo': '',
        'latitude': '-4.36',
        'longitude': '15.33',
      }),
    ];
  }
}

class _User implements UtilisateurLocalService {
  @override
  Future<String?> recupererTokenOtp() async => 'token';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Unused implements BanqueListeLocalService, PocheListeNetworkService, FavorisBanqueNetworkService, RechercheListeNetworkService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  test('no position is reported as such, then cleared by the next successful load', () async {
    final unused = _Unused();
    final container = ProviderContainer(overrides: [
      gestionstockInteractorProvider.overrideWithValue(
        Gestionstockinteractor.build(_Network(), unused, _User(), unused, unused, unused),
      ),
    ]);
    addTearDown(container.dispose);
    final ctrl = container.read(banqueCtrlProvider.notifier);

    await ctrl.listebanque();
    expect(container.read(banqueCtrlProvider).locationUnavailable, isTrue);
    expect(container.read(banqueCtrlProvider).isLoading, isFalse);

    await ctrl.listebanque();
    expect(container.read(banqueCtrlProvider).locationUnavailable, isFalse);
    expect(container.read(banqueCtrlProvider).banques, hasLength(1));
  });
}
