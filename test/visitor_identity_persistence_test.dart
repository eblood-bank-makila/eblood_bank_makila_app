/// Regression test for the QR/blood-search visitor payment bug.
///
/// The visitor bootstrap in the blood-search flow used to persist ONLY the
/// auth token, never the `user` object the backend returns alongside it. So
/// a visitor held a perfectly valid token while
/// `EbloodAuthHelper.currentUserId()` (which reads `user_data.id`) stayed
/// empty — and `PaymentApi` refused every payment with
/// "Non connecté: impossible d'initier le paiement.".
///
/// These tests pin the identity persistence for both bootstrap paths
/// (create-visitor and check-existing), which return the same
/// {user, user_profils, access_token} payload shape.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:eblood_bank_mak_app/apps/services/EbloodAuthHelper.dart';
import 'package:eblood_bank_mak_app/blood_search_flow/data/services/visitor_registration_service_impl.dart';

/// GetStorage resolves its file location through path_provider, which has no
/// implementation in the test host — point it at a real temp directory.
class _TempPathProvider extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  _TempPathProvider(this.path);
  final String path;

  @override
  Future<String?> getApplicationDocumentsPath() async => path;
  @override
  Future<String?> getApplicationSupportPath() async => path;
  @override
  Future<String?> getTemporaryPath() async => path;
}

/// A representative `data` block from POST /auth/visitor/check-existing and
/// /auth/visitor/create-visitor — both are built by the backend's
/// `_complete_visitor_login` (auth_controller.py).
Map<String, dynamic> _visitorLoginPayload() => <String, dynamic>{
      'user': <String, dynamic>{
        'id': '6a5a277c58542a070352d8a1',
        'first_name': 'Visiteur',
        'phone_number': '243831642022',
        'user_account_socket_hash': 'sock_hash_abc',
      },
      'user_profils': <dynamic>[
        <String, dynamic>{
          'profil': 'VISITOR',
          'sys_organization_id': '6a5a277c58542a070352d999',
        },
      ],
      'access_token': 'jwt.access.token',
      'refresh_token': 'jwt.refresh.token',
    };

void main() {
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    tempDir = await Directory.systemTemp.createTemp('eblood_getstorage_test');
    PathProviderPlatform.instance = _TempPathProvider(tempDir.path);
    await GetStorage.init();
  });

  setUp(() async {
    await GetStorage().erase();
  });

  tearDownAll(() async {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('visitor identity persistence', () {
    test(
        'persistVisitorIdentity stores user_data so currentUserId() resolves '
        '(payment guard passes)', () async {
      // Before: nothing stored — this is the broken state that made
      // PaymentApi answer "Non connecté".
      expect(EbloodAuthHelper.currentUserId(), isEmpty);

      final service = VisitorRegistrationServiceImpl();
      await service.persistVisitorIdentity(_visitorLoginPayload());

      expect(EbloodAuthHelper.currentUserId(), '6a5a277c58542a070352d8a1');
    });

    test('persistVisitorIdentity stores profiles so org ids resolve', () async {
      final service = VisitorRegistrationServiceImpl();
      await service.persistVisitorIdentity(_visitorLoginPayload());

      expect(
        EbloodAuthHelper.currentUserOrgIds(),
        contains('6a5a277c58542a070352d999'),
      );
    });

    test('tolerates a payload with no user block (nothing stored, no throw)',
        () async {
      final service = VisitorRegistrationServiceImpl();
      await service.persistVisitorIdentity(<String, dynamic>{
        'access_token': 'jwt.access.token',
      });

      expect(EbloodAuthHelper.currentUserId(), isEmpty);
      expect(EbloodAuthHelper.currentUserOrgIds(), isEmpty);
    });

    // A visitor belongs to no organisation, and the backend used to render
    // that missing id with f"{None}" — the literal string "None". Sending it
    // back as payer_org_id made the payments API answer 422, so it must never
    // survive as an org id on the client either.
    test('never yields the literal "None" as an org id', () async {
      final service = VisitorRegistrationServiceImpl();
      await service.persistVisitorIdentity(<String, dynamic>{
        'user': <String, dynamic>{
          'id': '6a5b813c3347d5b71593bffb',
          'sys_organization_id': 'None',
        },
        'user_profils': <dynamic>[],
      });

      expect(EbloodAuthHelper.currentUserId(), '6a5b813c3347d5b71593bffb');
      expect(EbloodAuthHelper.currentUserOrgIds(), isEmpty);
    });

    test('rejects other non-ObjectId junk as org ids', () async {
      final service = VisitorRegistrationServiceImpl();
      await service.persistVisitorIdentity(<String, dynamic>{
        'user': <String, dynamic>{'id': '6a5b813c3347d5b71593bffb'},
        'user_profils': <dynamic>[
          <String, dynamic>{'profil': 'A', 'sys_organization_id': 'null'},
          <String, dynamic>{'profil': 'B', 'sys_organization_id': 'not-an-id'},
          <String, dynamic>{
            'profil': 'C',
            'sys_organization_id': '6a5a277c58542a070352d999',
          },
        ],
      });

      // Only the well-formed ObjectId survives.
      expect(
        EbloodAuthHelper.currentUserOrgIds(),
        <String>['6a5a277c58542a070352d999'],
      );
    });

    test('accepts an _id-keyed user document', () async {
      final service = VisitorRegistrationServiceImpl();
      await service.persistVisitorIdentity(<String, dynamic>{
        'user': <String, dynamic>{'_id': '6a5a277c58542a070352dfff'},
      });

      expect(EbloodAuthHelper.currentUserId(), '6a5a277c58542a070352dfff');
    });
  });
}
