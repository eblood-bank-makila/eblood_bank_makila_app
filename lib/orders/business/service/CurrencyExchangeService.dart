import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../apps/config/api/dio_client.dart';
import '../model/CurrencyExchangeModel.dart';

/// Sprint 15 — currency conversion fetcher.
///
/// Backend contract changed:
///   * Old: POST /eblood-connect/amount-exchances {amount, ref_currency_id}
///          returning a batch of {currency_from, currency_to, rate, ...}.
///   * New: GET /api/v1/pricing/get-currency-exchange-rate
///          ?from_currency=USD&to_currency=CDF
///          returning ONE {from_currency, to_currency, rate}.
///
/// The UI layer still wants a "list of available conversions for the
/// cart's currency" so it can show two payment buttons. We adapt by
/// fanning out: ask the backend which currencies it supports, then
/// hit the rate endpoint once per (from, to) pair where to != from.
/// At demo scale (USD + CDF + a couple of others) the fan-out is 1-2
/// extra requests, easily worth the simpler backend contract.
abstract class CurrencyExchangeService {
  Future<CurrencyExchangeResponse> getCurrencyExchanges(
    double amount,
    String fromCurrencyCode,
  );
}

class CurrencyExchangeServiceImpl implements CurrencyExchangeService {
  CurrencyExchangeServiceImpl();

  @override
  Future<CurrencyExchangeResponse> getCurrencyExchanges(
    double amount,
    String fromCurrencyCode,
  ) async {
    final fromCode = _normalizeCode(fromCurrencyCode);
    if (fromCode.isEmpty) {
      debugPrint('⚠️ CurrencyExchangeService: empty fromCurrencyCode — skipping');
      return CurrencyExchangeResponse(
        success: false,
        data: const [],
        message: 'Missing from_currency code',
      );
    }

    try {
      final supported = await _fetchSupportedCurrencies();
      if (supported.isEmpty) {
        return CurrencyExchangeResponse(
          success: false,
          data: const [],
          message: 'No supported currencies returned by backend.',
        );
      }

      final targets = supported
          .map(_normalizeCode)
          .where((c) => c.isNotEmpty && c != fromCode)
          .toSet()
          .toList(growable: false);

      final results = <CurrencyExchangeModel>[];
      for (final toCode in targets) {
        final model = await _fetchSingleRate(
          amount: amount,
          fromCode: fromCode,
          toCode: toCode,
        );
        if (model != null) results.add(model);
      }

      return CurrencyExchangeResponse(
        success: results.isNotEmpty,
        data: results,
        message: results.isNotEmpty
            ? 'Currency conversions fetched successfully'
            : 'No conversion rates available for $fromCode',
      );
    } catch (e) {
      debugPrint('❌ CurrencyExchangeService.getCurrencyExchanges error: $e');
      return CurrencyExchangeResponse(
        success: false,
        data: const [],
        message: 'Error fetching currency conversions: $e',
      );
    }
  }

  Future<List<String>> _fetchSupportedCurrencies() async {
    final res = await getWithDio('/pricing/list-supported-currencies');
    if (!res.success) {
      debugPrint('⚠️ list-supported-currencies failed: ${res.message}');
      return const [];
    }
    final data = res.data;
    if (data is List) {
      return data.map((e) => e.toString()).toList(growable: false);
    }
    if (data is Map && data['data'] is List) {
      return (data['data'] as List).map((e) => e.toString()).toList(growable: false);
    }
    return const [];
  }

  Future<CurrencyExchangeModel?> _fetchSingleRate({
    required double amount,
    required String fromCode,
    required String toCode,
  }) async {
    final res = await getWithDio(
      '/pricing/get-currency-exchange-rate',
      queryParams: {
        'from_currency': fromCode,
        'to_currency': toCode,
      },
    );
    if (!res.success || res.data is! Map) {
      debugPrint('⚠️ get-currency-exchange-rate ($fromCode→$toCode) failed: ${res.message}');
      return null;
    }
    final body = Map<String, dynamic>.from(res.data as Map);
    final rate = (body['rate'] ?? 0.0) is num ? (body['rate'] as num).toDouble() : 0.0;
    if (rate <= 0) {
      debugPrint('⚠️ rate is 0 for $fromCode→$toCode — skipping');
      return null;
    }
    return CurrencyExchangeModel(
      id: '${fromCode}_$toCode',
      currencyFrom: '',
      currencyFromCode: fromCode.toLowerCase(),
      currencyTo: '',
      currencyToCode: toCode.toLowerCase(),
      exchangedValue: rate,
      amount: amount,
      convertedAmount: amount * rate,
    );
  }

  String _normalizeCode(String raw) {
    final trimmed = raw.trim().toUpperCase();
    // Mongo ObjectIds are 24 hex chars — Sprint 15 needs ISO codes
    // (3 letters). Reject anything that doesn't look like a code so
    // legacy callers passing the old ref_currency_id fail fast.
    if (trimmed.length != 3) return '';
    return trimmed;
  }
}

// Provider for the currency exchange service
final currencyExchangeServiceProvider = Provider<CurrencyExchangeService>((ref) {
  return CurrencyExchangeServiceImpl();
});

/// Strongly-typed params to avoid rebuild loops (Map identity).
///
/// Sprint 15 — `fromCurrencyCode` replaces the legacy `refCurrencyId`
/// (Mongo ObjectId). The old field name is kept as an alias on the
/// constructor for one release so call-sites can migrate without a
/// flag-day change.
class CurrencyExchangeParams {
  final double amount;
  final String fromCurrencyCode;

  const CurrencyExchangeParams({
    required this.amount,
    required this.fromCurrencyCode,
  });

  /// Back-compat for any caller still passing `refCurrencyId:` —
  /// treats the value as a code (so callers must pass codes now). To
  /// be removed once all call-sites use the new param.
  CurrencyExchangeParams.legacy({
    required this.amount,
    required String refCurrencyId,
  }) : fromCurrencyCode = refCurrencyId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CurrencyExchangeParams &&
          runtimeType == other.runtimeType &&
          amount == other.amount &&
          fromCurrencyCode == other.fromCurrencyCode;

  @override
  int get hashCode => Object.hash(amount, fromCurrencyCode);

  @override
  String toString() =>
      'CurrencyExchangeParams(amount: $amount, fromCurrencyCode: $fromCurrencyCode)';
}

// Provider for currency exchange data with parameters
final currencyExchangeProvider = FutureProvider.family<CurrencyExchangeResponse, CurrencyExchangeParams>((ref, params) async {
  final service = ref.read(currencyExchangeServiceProvider);
  if (params.fromCurrencyCode.trim().isEmpty) {
    debugPrint('currencyExchangeProvider: missing fromCurrencyCode; skipping API call.');
    return CurrencyExchangeResponse(
      success: false,
      data: const [],
      message: 'Missing from_currency code',
    );
  }

  return await service.getCurrencyExchanges(params.amount, params.fromCurrencyCode);
});
