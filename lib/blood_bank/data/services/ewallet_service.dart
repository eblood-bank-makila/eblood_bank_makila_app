import 'package:flutter/foundation.dart';
import 'package:eblood_bank_mak_app/apps/config/api/dio_client.dart';
import 'package:eblood_bank_mak_app/apps/config/api/ApiConfig.dart';
import 'package:eblood_bank_mak_app/apps/models/api_response.dart';
import 'package:eblood_bank_mak_app/blood_bank/business/models/ewallet_models.dart';

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

  /// POST /eblood-connect/ewallet/withdraw -> creates a PENDING withdrawal request.
  Future<IApiResponse> submitWithdrawal({
    required String opsEwalletId,
    required double amount,
    String? phoneNumber,
    String? refWithdrawalMethodId,
  }) async {
    final res = await postWithDio(
      ApiConfig.ewalletWithdraw,
      body: {
        'ops_ewallet_id': opsEwalletId,
        'amount': amount,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (refWithdrawalMethodId != null) 'ref_withdrawal_method_id': refWithdrawalMethodId,
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
    String? withdrawalPhoneNumber,
  }) async {
    final res = await putWithDio(
      ApiConfig.ewalletUpdateSettings,
      body: {
        'ops_ewallet_id': opsEwalletId,
        if (authEmail != null) 'auth_email': authEmail,
        if (authPhoneNumber != null) 'auth_phone_number': authPhoneNumber,
        if (autoCashOut != null) 'auto_cash_out': autoCashOut,
        if (withdrawalPhoneNumber != null) 'withdrawal_phone_number': withdrawalPhoneNumber,
      },
    );
    return res;
  }
}
