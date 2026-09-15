import 'package:flutter_test/flutter_test.dart';
import 'package:eblood_bank_mak_app/apps/models/api_response.dart';
import 'package:eblood_bank_mak_app/blood_bank/business/models/ewallet_models.dart';
import 'package:eblood_bank_mak_app/blood_bank/business/models/payout_number_model.dart';
import 'package:eblood_bank_mak_app/blood_bank/business/models/cash_out_model.dart';
import 'package:eblood_bank_mak_app/blood_bank/data/services/ewallet_service.dart';
import 'package:eblood_bank_mak_app/blood_bank/providers/ewallet_provider.dart';

/// In-memory double for [EwalletService] — no Dio, no network. Overrides only
/// the methods the provider tests below actually exercise; every override
/// also records what it was called with so the tests can assert on it.
class FakeEwalletService extends EwalletService {
  FakeEwalletService({
    this.wallets = const [],
    this.payoutNumbers = const [],
    this.cashOuts = const [],
    IApiResponse? createResponse,
    IApiResponse? updateResponse,
    IApiResponse? deleteResponse,
    IApiResponse? withdrawResponse,
    IApiResponse? updateSettingsResponse,
  })  : createResponse = createResponse ?? IApiResponse(success: true),
        updateResponse = updateResponse ?? IApiResponse(success: true),
        deleteResponse = deleteResponse ?? IApiResponse(success: true),
        withdrawResponse = withdrawResponse ?? IApiResponse(success: true),
        updateSettingsResponse = updateSettingsResponse ?? IApiResponse(success: true);

  List<EWalletModel> wallets;
  List<PayoutNumberModel> payoutNumbers;
  List<CashOutModel> cashOuts;
  final IApiResponse createResponse;
  final IApiResponse updateResponse;
  final IApiResponse deleteResponse;
  final IApiResponse withdrawResponse;
  final IApiResponse updateSettingsResponse;

  int getMyWalletsCallCount = 0;
  int getCashOutsCallCount = 0;
  Map<String, dynamic>? lastCreatePayload;
  String? lastUpdateId;
  Map<String, dynamic>? lastUpdatePayload;
  String? lastDeleteId;
  String? lastWithdrawOpsEwalletId;
  double? lastWithdrawAmount;
  String? lastWithdrawPayoutNumberId;

  // Reload targets used only so `loadWallets()` (an untouched old method,
  // reused by `withdraw()` for its wallet reload) doesn't hit real Dio.
  @override
  Future<List<EWalletModel>> getMyWallets() async {
    getMyWalletsCallCount++;
    return wallets;
  }

  @override
  Future<EWalletHistoryPage> getHistory({
    required String opsEwalletId,
    int page = 0,
    int limit = 20,
  }) async =>
      EWalletHistoryPage(items: const [], balance: 0);

  @override
  Future<List<PayoutNumberModel>> getPayoutNumbers() async => payoutNumbers;

  @override
  Future<IApiResponse> createPayoutNumber(Map<String, dynamic> payload) async {
    lastCreatePayload = payload;
    return createResponse;
  }

  @override
  Future<IApiResponse> updatePayoutNumber(String id, Map<String, dynamic> patch) async {
    lastUpdateId = id;
    lastUpdatePayload = patch;
    return updateResponse;
  }

  @override
  Future<IApiResponse> deletePayoutNumber(String id) async {
    lastDeleteId = id;
    return deleteResponse;
  }

  @override
  Future<List<CashOutModel>> getCashOuts({String? walletId, int page = 0, int limit = 20}) async {
    getCashOutsCallCount++;
    return cashOuts;
  }

  @override
  Future<IApiResponse> submitWithdrawal({
    required String opsEwalletId,
    required double amount,
    required String payoutNumberId,
  }) async {
    lastWithdrawOpsEwalletId = opsEwalletId;
    lastWithdrawAmount = amount;
    lastWithdrawPayoutNumberId = payoutNumberId;
    return withdrawResponse;
  }

  @override
  Future<IApiResponse> updateSettings({
    required String opsEwalletId,
    String? authEmail,
    String? authPhoneNumber,
    bool? autoCashOut,
  }) async =>
      updateSettingsResponse;
}

EWalletModel _wallet({String id = 'w1'}) => EWalletModel(
      id: id,
      identifier: 'W-001',
      ewalletNumber: '1234567890',
      ewalletPlaceholderName: 'Test Wallet',
      ewalletAmount: 100.0,
      currencySymbol: '\$',
      currencyCode: 'USD',
      currencyName: 'US Dollar',
      authEmail: 'a@b.com',
      authPhoneNumber: '+243900000000',
      lockedUseStatus: 'active',
      walletType: 'basic',
      walletFlag: 'customer',
      isDefault: true,
      isActivated: true,
    );

PayoutNumberModel _payoutNumber({String id = 'p1', PayoutNumberStatus status = PayoutNumberStatus.validated}) =>
    PayoutNumberModel(
      id: id,
      sysOrganizationId: 'org1',
      phoneNumber: '+243900000001',
      holderName: 'Holder',
      maxAmountPerDay: 500,
      priority: 1,
      validationStatus: status,
    );

CashOutModel _cashOut({String id = 'c1'}) => CashOutModel(
      id: id,
      status: 'withdrawn',
      phoneNumber: '+243900000001',
      amount: 10,
      isAutoCheckout: false,
    );

void main() {
  group('EWalletController payout numbers + cash-outs', () {
    test('loadPayoutNumbers fills state.payoutNumbers and clears loading', () async {
      final fake = FakeEwalletService(payoutNumbers: [_payoutNumber()]);
      final controller = EWalletController(fake);

      final future = controller.loadPayoutNumbers();
      expect(controller.state.isLoadingNumbers, true);
      await future;

      expect(controller.state.isLoadingNumbers, false);
      expect(controller.state.payoutNumbers.length, 1);
      expect(controller.state.payoutNumbers.single.id, 'p1');
      expect(controller.state.validatedNumbers.length, 1);
      expect(controller.state.error, isNull);
    });

    test('savePayoutNumber without id calls create and reloads the list', () async {
      final fake = FakeEwalletService(payoutNumbers: [_payoutNumber(id: 'p2')]);
      final controller = EWalletController(fake);

      final ok = await controller.savePayoutNumber(payload: {'phone_number': '+243900000001'});

      expect(ok, true);
      expect(fake.lastCreatePayload, {'phone_number': '+243900000001'});
      expect(fake.lastUpdateId, isNull);
      // Reloaded from the (post-create) fake list.
      expect(controller.state.payoutNumbers.length, 1);
      expect(controller.state.payoutNumbers.single.id, 'p2');
      expect(controller.state.isSubmitting, false);
      expect(controller.state.error, isNull);
    });

    test('withdraw passes payoutNumberId through and reloads wallets + cash-outs', () async {
      final wallet = _wallet(id: 'w1');
      final fake = FakeEwalletService(wallets: [wallet], cashOuts: [_cashOut()]);
      final controller = EWalletController(fake);
      await controller.loadWallets();
      expect(controller.state.selected?.id, 'w1');
      final walletsCallsBefore = fake.getMyWalletsCallCount;

      final ok = await controller.withdraw(amount: 10, payoutNumberId: 'p1');

      expect(ok, true);
      expect(fake.lastWithdrawOpsEwalletId, 'w1');
      expect(fake.lastWithdrawAmount, 10);
      expect(fake.lastWithdrawPayoutNumberId, 'p1');
      // Reloaded wallets (loadWallets -> getMyWallets called again)...
      expect(fake.getMyWalletsCallCount, greaterThan(walletsCallsBefore));
      // ...and cash-outs.
      expect(fake.getCashOutsCallCount, 1);
      expect(controller.state.cashOuts.length, 1);
      expect(controller.state.cashOuts.single.id, 'c1');
      expect(controller.state.isSubmitting, false);
      expect(controller.state.error, isNull);
    });

    test('a failed create sets state.error to the response message', () async {
      final fake = FakeEwalletService(
        createResponse: IApiResponse(success: false, message: 'boom'),
      );
      final controller = EWalletController(fake);

      final ok = await controller.savePayoutNumber(payload: {'phone_number': '+1'});

      expect(ok, false);
      expect(controller.state.error, 'boom');
      expect(controller.state.isSubmitting, false);
    });

    test('savePayoutNumber with id calls update with that id and the payload', () async {
      final fake = FakeEwalletService(payoutNumbers: [_payoutNumber(id: 'n1')]);
      final controller = EWalletController(fake);
      final payload = {'phone_number': '+243900000001', 'priority': 2};

      final ok = await controller.savePayoutNumber(id: 'n1', payload: payload);

      expect(ok, true);
      expect(fake.lastUpdateId, 'n1');
      expect(fake.lastUpdatePayload, payload);
      expect(fake.lastCreatePayload, isNull);
      expect(controller.state.isSubmitting, false);
      expect(controller.state.error, isNull);
    });

    test('disablePayoutNumber sends exactly {validation_status: disabled}', () async {
      final fake = FakeEwalletService(payoutNumbers: [_payoutNumber(id: 'n1')]);
      final controller = EWalletController(fake);

      final ok = await controller.disablePayoutNumber('n1');

      expect(ok, true);
      expect(fake.lastUpdateId, 'n1');
      expect(fake.lastUpdatePayload, {'validation_status': 'disabled'});
      expect(controller.state.isSubmitting, false);
      expect(controller.state.error, isNull);
    });

    test('deletePayoutNumber records the id and reloads the list', () async {
      final fake = FakeEwalletService(payoutNumbers: [_payoutNumber(id: 'n2')]);
      final controller = EWalletController(fake);

      final ok = await controller.deletePayoutNumber('n1');

      expect(ok, true);
      expect(fake.lastDeleteId, 'n1');
      // Reloaded from the (post-delete) fake list.
      expect(controller.state.payoutNumbers.length, 1);
      expect(controller.state.payoutNumbers.single.id, 'n2');
      expect(controller.state.isSubmitting, false);
      expect(controller.state.error, isNull);
    });
  });

  group('EWalletController preserves payoutNumbers/cashOuts across routine reloads', () {
    test('loadWallets keeps payoutNumbers already loaded', () async {
      final wallet = _wallet(id: 'w1');
      final fake = FakeEwalletService(wallets: [wallet], payoutNumbers: [_payoutNumber()]);
      final controller = EWalletController(fake);

      await controller.loadPayoutNumbers();
      expect(controller.state.payoutNumbers.length, 1);

      await controller.loadWallets();

      expect(controller.state.selected?.id, 'w1');
      expect(controller.state.payoutNumbers.length, 1);
      expect(controller.state.payoutNumbers.single.id, 'p1');
    });

    test('loadHistory keeps cashOuts already loaded', () async {
      final wallet = _wallet(id: 'w1');
      final fake = FakeEwalletService(wallets: [wallet], cashOuts: [_cashOut()]);
      final controller = EWalletController(fake);

      await controller.loadWallets();
      await controller.loadCashOuts();
      expect(controller.state.cashOuts.length, 1);

      await controller.loadHistory('w1');

      expect(controller.state.cashOuts.length, 1);
      expect(controller.state.cashOuts.single.id, 'c1');
    });

    test('a successful updateSettings keeps payoutNumbers', () async {
      final wallet = _wallet(id: 'w1');
      final fake = FakeEwalletService(wallets: [wallet], payoutNumbers: [_payoutNumber()]);
      final controller = EWalletController(fake);

      await controller.loadWallets();
      await controller.loadPayoutNumbers();
      expect(controller.state.payoutNumbers.length, 1);

      final ok = await controller.updateSettings(authEmail: 'a@b.com');

      expect(ok, true);
      // updateSettings reloads wallets internally (loadWallets) — this is
      // the exact reload the stale-state fix targets.
      expect(controller.state.payoutNumbers.length, 1);
      expect(controller.state.payoutNumbers.single.id, 'p1');
    });
  });
}
