import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:eblood_bank_mak_app/apps/translations/AppTranslations.dart';
import 'package:eblood_bank_mak_app/blood_bank/business/models/structure_validation_model.dart';
import 'package:eblood_bank_mak_app/blood_bank/providers/structure_validation_provider.dart';
import 'package:eblood_bank_mak_app/blood_bank/ui/widgets/structure_validation_banner.dart';
import 'package:eblood_bank_mak_app/core/rbac/rbac_screen_registry.dart';

const _pending = StructureValidationModel(id: 's', name: 'x', status: 'pending');
const _validated = StructureValidationModel(id: 's', name: 'x', status: 'validated');
const _rejected = StructureValidationModel(id: 's', name: 'x', status: 'rejected', note: 'Adresse introuvable');
const _notLinked = StructureValidationModel(id: '', name: '', status: 'not_linked');

Widget _host(StructureValidationModel? value, {Widget? child, RbacAccountType? accountType}) {
  final body = child ?? StructureValidationBanner(requireStructureAccount: accountType != null);
  return ProviderScope(
    overrides: [myStructureProvider.overrideWith((ref) async => value)],
    child: GetMaterialApp(
      translations: AppTranslations(),
      locale: const Locale('fr', 'FR'),
      fallbackLocale: const Locale('fr', 'FR'),
      home: Scaffold(
        body: accountType == null ? body : RbacAccountTypeScope(accountType: accountType, child: body),
      ),
    ),
  );
}

final _bannerKey = find.byKey(const Key('structure-validation-banner'));

void main() {
  testWidgets('renders nothing when validated or unknown', (t) async {
    await t.pumpWidget(_host(_validated));
    await t.pumpAndSettle();
    expect(_bannerKey, findsNothing);
    await t.pumpWidget(_host(null));
    await t.pumpAndSettle();
    expect(_bannerKey, findsNothing);
  });

  testWidgets('pending shows the banner with the French title and the "unverified" chip', (t) async {
    await t.pumpWidget(_host(_pending));
    await t.pumpAndSettle();
    expect(_bannerKey, findsOneWidget);
    expect(find.text('En attente de validation par eBlood'), findsOneWidget);
    expect(find.text('Non vérifiée'), findsOneWidget);
  });

  testWidgets('rejected shows the reason', (t) async {
    await t.pumpWidget(_host(_rejected));
    await t.pumpAndSettle();
    expect(find.text('Validation refusée par eBlood'), findsOneWidget);
    expect(find.textContaining('Adresse introuvable'), findsOneWidget);
  });

  testWidgets('not linked tells the user to contact support', (t) async {
    await t.pumpWidget(_host(_notLinked));
    await t.pumpAndSettle();
    expect(find.text('Aucune structure rattachée'), findsOneWidget);
    expect(find.textContaining('Contactez le support'), findsOneWidget);
  });

  testWidgets('inside the RBAC shell it is hidden for customer accounts and shown for structure accounts', (t) async {
    await t.pumpWidget(_host(_pending, accountType: RbacAccountType.customer));
    await t.pumpAndSettle();
    expect(_bannerKey, findsNothing);
    await t.pumpWidget(_host(_pending, accountType: RbacAccountType.bloodBank));
    await t.pumpAndSettle();
    expect(_bannerKey, findsOneWidget);
    await t.pumpWidget(_host(_pending, accountType: RbacAccountType.hospital));
    await t.pumpAndSettle();
    expect(_bannerKey, findsOneWidget);
  });

  // A gated page always renders the banner above its form, so the provider is
  // already resolved by the time the user taps Save — mirror that here. The
  // verdict is written into a Text (a second SnackBar would only be queued
  // behind the gate's own one).
  Widget gateButton() => Consumer(builder: (context, ref, _) {
        return StatefulBuilder(builder: (context, setState) {
          var verdict = '';
          return Column(children: [
            const StructureValidationBanner(),
            StatefulBuilder(builder: (context, setInner) => Column(children: [
              TextButton(
                key: const Key('go'),
                onPressed: () => setInner(() {
                  verdict = StructureValidationGate.blockIfUnverified(context, ref) ? 'blocked' : 'allowed';
                }),
                child: const Text('go'),
              ),
              Text(verdict, key: const Key('verdict')),
            ])),
          ]);
        });
      });

  testWidgets('blockIfUnverified refuses the action with the backend-like message when pending', (t) async {
    await t.pumpWidget(_host(_pending, child: gateButton()));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('go')));
    await t.pump();
    expect(find.text('blocked'), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.textContaining('validation par eBlood'), findsWidgets);
  });

  testWidgets('blockIfUnverified lets validated and unknown structures through', (t) async {
    await t.pumpWidget(_host(_validated, child: gateButton()));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('go')));
    await t.pump();
    expect(find.text('allowed'), findsOneWidget);
    await t.pumpWidget(_host(null, child: gateButton()));
    await t.pumpAndSettle();
    await t.tap(find.byKey(const Key('go')));
    await t.pump();
    expect(find.text('allowed'), findsOneWidget);
  });

  test('the keys exist in all five locales', () {
    final keys = AppTranslations().keys;
    for (final locale in ['fr_FR', 'en_US', 'es_ES', 'ln_CD', 'ru_RU']) {
      for (final k in [
        'structure_pending_validation_title', 'structure_pending_validation_body',
        'structure_rejected_title', 'structure_rejected_body',
        'structure_not_linked_title', 'structure_not_linked_body',
        'structure_validation_reason', 'structure_validation_contact', 'structure_unverified_badge',
      ]) {
        expect(keys[locale]!.containsKey(k), isTrue, reason: '$locale lacks $k');
      }
    }
  });
}
