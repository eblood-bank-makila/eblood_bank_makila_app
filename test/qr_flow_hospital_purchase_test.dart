/// Regression tests for "Blood bag not found" in the QR / blood-search flow
/// (prod, 2026-10-18, logged in as a hospital).
///
/// The prod request was:
///
///   POST /eblood-connect/visitor/blood-bag/purchase-quote
///   {"blood_bag_id": "6aca438e9a0943579876bd7d", "hospital_id": "6a3f609fc93f467fd971f162"}  → 404
///
/// Both ids were wrong:
///  * `blood_bag_id` was the BLOOD BANK's id: search-simple rows carry the bag
///    id only in `blood_bag_info._id`, and `BloodSearchResult.fromJson` fell
///    back to `blood_bank_info._id`. This broke visitors too.
///  * `hospital_id` was the login's `user_entity` (the organisation's location
///    entity, "kinshasa"), not the hospital's sys_health_structure.
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:get_storage/get_storage.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:eblood_bank_mak_app/blood_search_flow/domain/entities/search_flow_state.dart';
import 'package:eblood_bank_mak_app/blood_search_flow/domain/services/service_interfaces.dart';
import 'package:eblood_bank_mak_app/blood_search_flow/providers/search_flow_provider.dart';
import 'package:eblood_bank_mak_app/payments/business/service/PaymentApi.dart'
    show PaymentInitiateResult;

const _bankId = '6aca438e9a0943579876bd7d';
const _bagId = '6acd2fdd0a803dd7afd5c0a8';
const _cityEntityId = '6a3f609fc93f467fd971f162';
const _structureId = '6acd31c0fcf168ff7d67c9e8';

/// A search-simple row as prod returned it on 2026-10-18 (trimmed): no
/// top-level `id` / `_id`, the bag id only inside `blood_bag_info`.
Map<String, dynamic> _prodRow() => <String, dynamic>{
      'blood_bag_info': <String, dynamic>{
        '_id': _bagId,
        'identifier': 'BAG-c0a8',
        'blood_type_info': <String, dynamic>{'blood_type_name': 'O'},
        'blood_rhesus_info': <String, dynamic>{'blood_rheusus_name': '+'},
      },
      'blood_stock_count': 1,
      'currency': 'usd',
      'price': 1,
      'blood_bank_info': <String, dynamic>{
        '_id': _bankId,
        'blood_bank_name': 'banque de sang lobiko',
        'latitude': '-4.33',
        'longitude': '15.31',
      },
      'status': 'available',
      'days_until_expiry': 36,
    };

/// GET /eblood/hospital-structure/my-health-structure, as
/// HealthStructureService.getMyHealthStructure() returns it.
Map<String, dynamic> _myStructure() => <String, dynamic>{
      'id': _structureId,
      'name': 'cs bolingo',
      'identifier': '12345678',
      'latitude': '-4.3609',
      'longitude': 15.3385,
    };

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

class _UnusedSearch implements IBloodSearchService {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName}');
}

class _UnusedHospitals implements IHospitalIdentificationService {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName}');
}

class _UnusedVisitors implements IVisitorRegistrationService {
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName}');
}

class _Auth implements IAuthService {
  @override
  Future<String?> getAuthToken() async => 'jwt.hospital';

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName}');
}

/// Records what the provider asks the payments layer to charge.
class _RecordingPayments implements IPaymentService {
  String? hospitalId;
  Map<String, dynamic>? paymentDetails;

  @override
  Future<PaymentInitiateResult> initiateDeliveryPayment({
    required String hospitalId,
    required List<String> bloodBagIds,
    required String authToken,
    required Map<String, dynamic> paymentDetails,
  }) async {
    this.hospitalId = hospitalId;
    this.paymentDetails = paymentDetails;
    return PaymentInitiateResult.error('recorded');
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError('${invocation.memberName}');
}

SearchFlowNotifier _notifier(
  _RecordingPayments payments, {
  Future<Map<String, dynamic>?> Function()? loadOwnHealthStructure,
}) {
  return SearchFlowNotifier(
    bloodSearchService: _UnusedSearch(),
    hospitalService: _UnusedHospitals(),
    visitorService: _UnusedVisitors(),
    paymentService: payments,
    authService: _Auth(),
    loadOwnHealthStructure: loadOwnHealthStructure,
  );
}

/// What a hospital login leaves in GetStorage (AuthApi._extractAndSaveIdentifier).
Future<void> _loginAsHospital() async {
  final storage = GetStorage();
  await storage.write('account_type', 'hospital');
  await storage.write('auth_token', 'jwt.hospital');
  await storage.write('user_entity_id', _cityEntityId);
  await storage.write('user_entity_name', 'kinshasa');
  await storage.write('user_identifier', '12345678');
}

void main() {
  group('BloodSearchResult.fromJson', () {
    test('takes the bag id from blood_bag_info, never the blood bank id', () {
      final result = BloodSearchResult.fromJson(_prodRow());
      expect(result.id, _bagId);
      expect(result.bloodBankId, _bankId);
    });

    test('a top-level id (apps_api search rows) is the bag id too', () {
      final result = BloodSearchResult.fromJson({..._prodRow(), 'id': _bagId});
      expect(result.id, _bagId);
    });

    test('a row without any bag id yields an empty id, not the bank id', () {
      final row = _prodRow()..remove('blood_bag_info');
      expect(BloodSearchResult.fromJson(row).id, isEmpty);
    });
  });

  group('IdentifiedHospital.ownHospital', () {
    test('maps my-health-structure to the delivery destination', () {
      final hospital = IdentifiedHospital.ownHospital(_myStructure())!;
      expect(hospital.id, _structureId);
      expect(hospital.name, 'cs bolingo');
      expect(hospital.code, '12345678');
      expect(hospital.latitude, closeTo(-4.3609, 1e-9));
      expect(hospital.longitude, closeTo(15.3385, 1e-9));
      expect(hospital.method, HospitalIdentificationMethod.loggedInAccount);
    });

    test('no structure (or no id) means no hospital', () {
      expect(IdentifiedHospital.ownHospital(null), isNull);
      expect(IdentifiedHospital.ownHospital({'name': 'x'}), isNull);
    });
  });

  group('hospital account in the QR flow', () {
    late Directory tempDir;

    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      tempDir = await Directory.systemTemp.createTemp('eblood_qr_hospital_test');
      PathProviderPlatform.instance = _TempPathProvider(tempDir.path);
      await GetStorage.init();
    });

    setUp(() async {
      await GetStorage().erase();
      await _loginAsHospital();
    });

    tearDownAll(() async {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    });

    test('buys the selected BAG for its OWN structure, not the bank / the city', () async {
      final payments = _RecordingPayments();
      final notifier = _notifier(payments, loadOwnHealthStructure: () async => _myStructure());

      await notifier.startHospitalSearch();
      expect(notifier.state.identifiedHospital?.id, _structureId);
      // The city stays the location entity — that part was right.
      expect(notifier.state.selectedCity?.id, _cityEntityId);

      final result = BloodSearchResult.fromJson(_prodRow());
      notifier.selectResult(result);
      notifier.selectPaymentOption(PaymentOption.delivery);
      expect(notifier.state.currentStep, SearchFlowStep.payment);

      await notifier.beginPayment(PaymentOption.delivery, {
        'blood_bank_id': result.bloodBankId,
        'blood_bag_id': result.id,
      });
      expect(payments.hospitalId, _structureId);
      expect(payments.paymentDetails?['blood_bag_id'], _bagId);
    });

    test('never takes the destination from user_entity_id or the device cache', () async {
      // A cache another account may have left behind (not every logout clears it).
      await GetStorage().write('cached_health_structure', {'id': '6acd0000000000000000beef', 'name': 'autre hôpital'});
      final payments = _RecordingPayments();
      final notifier = _notifier(payments, loadOwnHealthStructure: () async => null);

      await notifier.startHospitalSearch();
      notifier.selectResult(BloodSearchResult.fromJson(_prodRow()));
      notifier.selectPaymentOption(PaymentOption.delivery);
      expect(notifier.state.identifiedHospital, isNull);
    });

    test('an unresolvable structure leaves the hospital unidentified', () async {
      final payments = _RecordingPayments();
      final notifier = _notifier(payments, loadOwnHealthStructure: () async => throw Exception('offline'));

      await notifier.startHospitalSearch();
      notifier.selectResult(BloodSearchResult.fromJson(_prodRow()));
      notifier.selectPaymentOption(PaymentOption.delivery);
      expect(notifier.state.identifiedHospital, isNull);

      await notifier.beginPayment(PaymentOption.delivery, {'blood_bag_id': _bagId});
      expect(payments.hospitalId, isNull, reason: 'nothing may be charged to a guessed hospital');
    });
  });
}
