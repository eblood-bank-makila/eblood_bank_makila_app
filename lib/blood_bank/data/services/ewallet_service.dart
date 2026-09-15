import 'package:flutter/foundation.dart';
import 'package:eblood_bank_mak_app/apps/config/api/dio_client.dart';
import 'package:eblood_bank_mak_app/apps/config/api/ApiConfig.dart';
import 'package:eblood_bank_mak_app/apps/models/api_response.dart';
import 'package:eblood_bank_mak_app/blood_bank/business/models/ewallet_models.dart';
import 'package:eblood_bank_mak_app/blood_bank/business/models/payout_number_model.dart';
import 'package:eblood_bank_mak_app/blood_bank/business/models/cash_out_model.dart';

/// One page of wallet history plus the wallet's current balance.
class EWalletHistoryPage {
  final List<EWalletHistoryModel> items;
  final double balance;
  final int page;
  final int limit;

  EWalletHistoryPage({
    required this.items,
    required this.balance,
    this.page = 0,
    this.limit = 20,
  });
}

/// Per-profile e-wallet network service.
///
/// All endpoints are scoped server-side to the authenticated user's organization
/// (blood bank or CNTS), so the same calls return the right wallet per profile.
class EwalletService {
  /// GET /eblood-connect/ewallet/my-wallets -> the caller's org wallets (one per currency).
  Future<List<EWalletModel>> getMyWallets() async {
    try {
      final res = await getWithDio(ApiConfig.ewalletMyWallets);
      if (res.success && res.data is Map) {
        final data = Map<String, dynamic>.from(res.data as Map);
        final list = (data['data'] as List?) ?? const [];
        return list
            .whereType<Map>()
            .map((m) => EWalletModel.fromBackendJson(Map<String, dynamic>.from(m)))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('EwalletService.getMyWallets error: $e');
      rethrow;
    }
  }

  /// GET /eblood-connect/ewallet/history?ops_ewallet_id=&page=&limit=
  Future<EWalletHistoryPage> getHistory({
    required String opsEwalletId,
    int page = 0,
    int limit = 20,
  }) async {
    try {
      final res = await getWithDio(
        ApiConfig.ewalletHistory,
        queryParams: {'ops_ewallet_id': opsEwalletId, 'page': page, 'limit': limit},
      );
      if (res.success && res.data is Map) {
        final data = Map<String, dynamic>.from(res.data as Map);
        final list = (data['data'] as List?) ?? const [];
        final items = list
            .whereType<Map>()
            .map((m) => EWalletHistoryModel.fromBackendJson(Map<String, dynamic>.from(m)))
            .toList();
        final balance = (data['balance'] as num?)?.toDouble() ?? 0.0;
        return EWalletHistoryPage(items: items, balance: balance, page: page, limit: limit);
      }
      return EWalletHistoryPage(items: const [], balance: 0.0, page: page, limit: limit);
    } catch (e) {
      debugPrint('EwalletService.getHistory error: $e');
      rethrow;
    }
  }

  /// POST /eblood-connect/ewallet/withdraw -> creates a PENDING withdrawal request
  /// against a validated payout number.
  Future<IApiResponse> submitWithdrawal({
    required String opsEwalletId,
    required double amount,
    required String payoutNumberId,
  }) async {
    final res = await postWithDio(
      ApiConfig.ewalletWithdraw,
      body: {
        'ops_ewallet_id': opsEwalletId,
        'amount': amount,
        'cfg_payout_phone_number_id': payoutNumberId,
      },
    );
    return res;
  }

  /// PUT /eblood-connect/ewallet/settings -> updates the caller's wallet settings.
  /// Only the provided (non-null) fields are sent, so each settings section
  /// (email, phone, auto-reception) can be saved independently.
  Future<IApiResponse> updateSettings({
    required String opsEwalletId,
    String? authEmail,
    String? authPhoneNumber,
    bool? autoCashOut,
  }) async {
    final res = await putWithDio(
      ApiConfig.ewalletUpdateSettings,
      body: {
        'ops_ewallet_id': opsEwalletId,
        if (authEmail != null) 'auth_email': authEmail,
        if (authPhoneNumber != null) 'auth_phone_number': authPhoneNumber,
        if (autoCashOut != null) 'auto_cash_out': autoCashOut,
      },
    );
    return res;
  }

  // ──────────────────────────────────────────────────
  // Payout numbers (settlement escrow cash-out targets)
  // ──────────────────────────────────────────────────

  /// Pure parsing helper (no Dio) — accepts a bare `List`, `{data: [...]}`
  /// or `{data: {data: [...]}}` envelope, per the shapes `res.data` can take
  /// across the different generic-list endpoints.
  static List<dynamic> _listOf(dynamic body) {
    if (body is List) return body;
    if (body is! Map) return const [];
    final data = body['data'];
    if (data is List) return data;
    if (data is Map && data['data'] is List) return data['data'] as List;
    return const [];
  }

  static List<PayoutNumberModel> parsePayoutNumbers(dynamic body) =>
      _listOf(body).whereType<Map>().map((e) => PayoutNumberModel.fromJson(Map<String, dynamic>.from(e))).toList();

  static List<CashOutModel> parseCashOuts(dynamic body) =>
      _listOf(body).whereType<Map>().map((e) => CashOutModel.fromJson(Map<String, dynamic>.from(e))).toList();

  /// GET /eblood-connect/ewallet/payout-numbers -> the caller's org payout numbers.
  Future<List<PayoutNumberModel>> getPayoutNumbers() async {
    try {
      final res = await getWithDio(ApiConfig.ewalletPayoutNumbers);
      if (!res.success) return const [];
      return parsePayoutNumbers(res.data);
    } catch (e) {
      debugPrint('EwalletService.getPayoutNumbers error: $e');
      rethrow;
    }
  }

  /// POST /eblood-connect/ewallet/payout-numbers -> registers a new payout number
  /// (pending validation by the MAIN profile).
  Future<IApiResponse> createPayoutNumber(Map<String, dynamic> payload) async =>
      postWithDio(ApiConfig.ewalletPayoutNumbers, body: payload);

  /// PUT /eblood-connect/ewallet/payout-numbers/{id} -> patches a payout number.
  Future<IApiResponse> updatePayoutNumber(String id, Map<String, dynamic> patch) async =>
      putWithDio(ApiConfig.ewalletPayoutNumber(id), body: patch);

  /// DELETE /eblood-connect/ewallet/payout-numbers/{id}.
  Future<IApiResponse> deletePayoutNumber(String id) async =>
      deleteWithDio(ApiConfig.ewalletPayoutNumber(id));

  // ──────────────────────────────────────────────────
  // Cash-outs (withdrawal / auto-checkout history)
  // ──────────────────────────────────────────────────

  /// GET /eblood-connect/ewallet/cash-outs?ops_ewallet_id=&page=&limit=
  Future<List<CashOutModel>> getCashOuts({String? walletId, int page = 0, int limit = 20}) async {
    try {
      final res = await getWithDio(
        ApiConfig.ewalletCashOuts,
        queryParams: {
          'page': page,
          'limit': limit,
          if (walletId != null) 'ops_ewallet_id': walletId,
        },
      );
      if (!res.success) return const [];
      return parseCashOuts(res.data);
    } catch (e) {
      debugPrint('EwalletService.getCashOuts error: $e');
      rethrow;
    }
  }
}
