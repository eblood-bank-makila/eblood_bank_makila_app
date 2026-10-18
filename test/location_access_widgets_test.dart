import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

import 'package:eblood_bank_mak_app/apps/translations/AppTranslations.dart';
import 'package:eblood_bank_mak_app/apps/widgets/location/location_access_tile.dart';
import 'package:eblood_bank_mak_app/apps/widgets/location/location_needed_card.dart';
import 'package:eblood_bank_mak_app/core/services/location_access.dart';

class _Fake {
  bool serviceEnabled = true;
  LocationPermission permission = LocationPermission.denied;
  final calls = <String>[];

  LocationAccess build() => LocationAccess(
        isServiceEnabled: () async => serviceEnabled,
        checkPermission: () async => permission,
        requestPermission: () async {
          calls.add('requestPermission');
          return permission = LocationPermission.whileInUse;
        },
        openLocationSettings: () async {
          calls.add('openLocationSettings');
          return true;
        },
        openAppSettings: () async {
          calls.add('openAppSettings');
          return true;
        },
      );
}

Widget _host(Widget child) => GetMaterialApp(
      translations: AppTranslations(),
      locale: const Locale('fr', 'FR'),
      fallbackLocale: const Locale('fr', 'FR'),
      home: Scaffold(body: SingleChildScrollView(child: child)),
    );

Future<void> _resume(WidgetTester t) async {
  t.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
  t.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
  await t.pumpAndSettle();
}

void main() {
  group('LocationAccessTile (profile)', () {
    testWidgets('phone location off: says so and opens the Android location screen', (t) async {
      final fake = _Fake()..serviceEnabled = false;
      await t.pumpWidget(_host(LocationAccessTile(access: fake.build())));
      await t.pumpAndSettle();

      expect(find.text('Localisation'), findsOneWidget);
      expect(find.text('Localisation du téléphone désactivée'), findsOneWidget);

      await t.tap(find.byType(LocationAccessTile));
      await t.pumpAndSettle();
      expect(fake.calls, ['openLocationSettings']);
    });

    testWidgets('re-reads the state when the user comes back from settings', (t) async {
      final fake = _Fake()..serviceEnabled = false;
      await t.pumpWidget(_host(LocationAccessTile(access: fake.build())));
      await t.pumpAndSettle();

      fake
        ..serviceEnabled = true
        ..permission = LocationPermission.whileInUse;
      await _resume(t);

      expect(find.text('Activée'), findsOneWidget);
    });
  });

  group('LocationNeededCard (Poches de sang)', () {
    testWidgets('granting the permission from the card reloads the list', (t) async {
      final fake = _Fake();
      var retries = 0;
      await t.pumpWidget(_host(LocationNeededCard(access: fake.build(), onRetry: () async => retries++)));
      await t.pumpAndSettle();

      expect(find.text('Localisation requise'), findsOneWidget);
      await t.tap(find.text('Activer la localisation'));
      await t.pumpAndSettle();

      expect(fake.calls, ['requestPermission']);
      expect(retries, 1);
    });

    testWidgets('location switched on in settings reloads the list on return', (t) async {
      final fake = _Fake()..serviceEnabled = false;
      var retries = 0;
      await t.pumpWidget(_host(LocationNeededCard(access: fake.build(), onRetry: () async => retries++)));
      await t.pumpAndSettle();

      await t.tap(find.text('Activer la localisation'));
      await t.pumpAndSettle();
      expect(fake.calls, ['openLocationSettings']);
      expect(retries, 0);

      fake
        ..serviceEnabled = true
        ..permission = LocationPermission.whileInUse;
      await _resume(t);

      expect(retries, 1);
    });
  });
}
