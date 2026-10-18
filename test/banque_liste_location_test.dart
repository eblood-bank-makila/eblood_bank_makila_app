import 'package:flutter_test/flutter_test.dart';

import 'package:eblood_bank_mak_app/core/services/location_access.dart';
import 'package:eblood_bank_mak_app/stock_management/ui/framework/banque/BanqueListeServiceNetworkImpl.dart';

/// With the phone's location off the app used to search around a hard-coded
/// point in Kigali, found no bank within 100 km and showed "Aucune banque
/// disponible" while Kinshasa banks had stock. No position must now surface
/// as its own error so the page can ask for the location instead.
void main() {
  test('no known position throws LocationUnavailableException instead of searching a default city', () async {
    final impl = BanqueListeNetworkServiceImpl('https://example.invalid', locate: () async => null);

    await expectLater(
      impl.recuperationListeBanque('token'),
      throwsA(isA<LocationUnavailableException>()),
    );
  });
}
