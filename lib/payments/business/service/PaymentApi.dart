import 'package:flutter/foundation.dart';

import '../../../apps/config/api/dio_client.dart';
import '../../../apps/services/EbloodAuthHelper.dart';
import '../../../core/config/app_config.dart';

/// Sprint 15 — thin client over the gateway-agnostic eblood payments
/// module. The endpoints live under /api/v1/payments/* and are framed
/// in terms of {purpose, entity_id, payer_user_id, amount_cents,
/// currency} — they don't know about onafriq or any specific gateway.
/// Pair the initiate response with LokotroPayCheckoutService.launchCheckout
/// to actually collect the funds; the backend's webhook handler
/// reconciles the payment intent with the gateway result.
class PaymentApi {
  PaymentApi._();

  /// POST /api/v1/payments/initiate
  ///
  /// Creates a PaymentIntent in PENDING and returns the
  /// `customer_reference` lokotro_pay needs. [purpose] must be one of
  /// the backend's PaymentPurpose enum values — at the time of writing:
  /// `address_access`, `delivery`. [entityId] is the bag id (for
  /// address_access) or order id (for delivery).
  static Future<PaymentInitiateResult> initiate({
    required String purpose,
    String? entityId,
    required int amountCents,
    required String currency,
    String? description,
  }) async {
    try {
      final payerUserId = EbloodAuthHelper.currentUserId();
      if (payerUserId.isEmpty) {
        return PaymentInitiateResult.error(
          'Non connecté: impossible d\'initier le paiement.',
        );
      }
      final orgIds = EbloodAuthHelper.currentUserOrgIds();
      final body = <String, dynamic>{
        'purpose': purpose,
        if (entityId != null && entityId.isNotEmpty) 'entity_id': entityId,
        'payer_user_id': payerUserId,
        if (orgIds.isNotEmpty) 'payer_org_id': orgIds.first,
        'amount_cents': amountCents,
        'currency': currency.toUpperCase(),
        if (description != null && description.isNotEmpty)
          'description': description,
      };

      final res = await postWithDio('/payments/initiate', body: body);
      if (!res.success || res.data is! Map) {
        return PaymentInitiateResult.error(
          res.message ?? 'Échec de l\'initiation du paiement.',
        );
      }
      final data = Map<String, dynamic>.from(res.data as Map);
      final customerRef = data['customer_reference']?.toString();
      if (customerRef == null || customerRef.isEmpty) {
        return PaymentInitiateResult.error(
          'Réponse invalide du backend (customer_reference manquant).',
        );
      }

      final notifyPath = (data['notify_url_path']?.toString() ?? '').trim();
      final base = AppConfig.apiBaseUrl.replaceAll(RegExp(r'/$'), '');
      final notifyUrlAbsolute = notifyPath.isEmpty
          ? ''
          : (notifyPath.startsWith('http') ? notifyPath : '$base$notifyPath');

      return PaymentInitiateResult.success(
        customerReference: customerRef,
        amountCents: (data['amount_cents'] is num)
            ? (data['amount_cents'] as num).toInt()
            : amountCents,
        currency: (data['currency']?.toString() ?? currency).toUpperCase(),
        state: data['state']?.toString() ?? 'pending',
        notifyUrlAbsolute: notifyUrlAbsolute,
      );
    } catch (e) {
      debugPrint('💥 PaymentApi.initiate error: $e');
      return PaymentInitiateResult.error('Erreur: $e');
    }
  }

  /// GET /api/v1/payments/get-payment-status?customer_reference=...
  static Future<PaymentStatusResult> getStatus(String customerReference) async {
    try {
      final res = await getWithDio(
        '/payments/get-payment-status',
        queryParams: {'customer_reference': customerReference},
      );
      if (!res.success || res.data is! Map) {
        return PaymentStatusResult.error(
          res.message ?? 'Échec de la vérification du statut.',
        );
      }
      final data = Map<String, dynamic>.from(res.data as Map);
      return PaymentStatusResult.fromJson(data);
    } catch (e) {
      debugPrint('💥 PaymentApi.getStatus error: $e');
      return PaymentStatusResult.error('Erreur: $e');
    }
  }

  /// POST /api/v1/payments/cancel-payment
  /// Used when the user closes the lokotro_pay checkout without paying.
  static Future<bool> cancel({
    required String customerReference,
    String? note,
  }) async {
    try {
      final res = await postWithDio(
        '/payments/cancel-payment',
        body: {
          'customer_reference': customerReference,
          if (note != null && note.isNotEmpty) 'note': note,
        },
      );
      return res.success;
    } catch (e) {
      debugPrint('💥 PaymentApi.cancel error: $e');
      return false;
    }
  }

  /// GET /api/v1/payments/list-by-payer?payer_user_id=...
  /// Backs the floating payment-stream button.
  static Future<List<PaymentStatusResult>> listMine({
    String? stateFilter,
    int limit = 20,
    int skip = 0,
  }) async {
    try {
      final payerUserId = EbloodAuthHelper.currentUserId();
      if (payerUserId.isEmpty) return const [];
      final query = <String, dynamic>{
        'payer_user_id': payerUserId,
        'limit': limit,
        'skip': skip,
        if (stateFilter != null && stateFilter.isNotEmpty) 'state': stateFilter,
      };
      final res = await getWithDio(
        '/payments/list-by-payer',
        queryParams: query,
      );
      if (!res.success) return const [];
      final raw = res.data;
      List<dynamic> list;
      if (raw is List) {
        list = raw;
      } else if (raw is Map && raw['data'] is List) {
        list = raw['data'] as List;
      } else {
        return const [];
      }
      return list
          .whereType<Map>()
          .map((m) => Map<String, dynamic>.from(m))
          .map(PaymentStatusResult.fromJson)
          .toList(growable: false);
    } catch (e) {
      debugPrint('💥 PaymentApi.listMine error: $e');
      return const [];
    }
  }
}

class PaymentInitiateResult {
  final bool isSuccess;
  final String? customerReference;
  final int amountCents;
  final String? currency;
  final String? state;
  final String? notifyUrlAbsolute;
  final String? errorMessage;

  const PaymentInitiateResult._({
    required this.isSuccess,
    this.customerReference,
    this.amountCents = 0,
    this.currency,
    this.state,
    this.notifyUrlAbsolute,
    this.errorMessage,
  });

  factory PaymentInitiateResult.success({
    required String customerReference,
    required int amountCents,
    required String currency,
    required String state,
    required String notifyUrlAbsolute,
  }) =>
      PaymentInitiateResult._(
        isSuccess: true,
        customerReference: customerReference,
        amountCents: amountCents,
        currency: currency,
        state: state,
        notifyUrlAbsolute: notifyUrlAbsolute,
      );

  factory PaymentInitiateResult.error(String message) =>
      PaymentInitiateResult._(isSuccess: false, errorMessage: message);
}

class PaymentStatusResult {
  /// True when the call itself succeeded — does NOT mean the payment
  /// was approved. Inspect [state] / [isTerminal] for that.
  final bool ok;
  final String? errorMessage;

  final String customerReference;
  final String state;
  final String purpose;
  final String? entityId;
  final int amountCents;
  final String currency;
  final bool isTerminal;
  final String? gatewayTransactionId;

  const PaymentStatusResult._({
    required this.ok,
    this.errorMessage,
    this.customerReference = '',
    this.state = '',
    this.purpose = '',
    this.entityId,
    this.amountCents = 0,
    this.currency = '',
    this.isTerminal = false,
    this.gatewayTransactionId,
  });

  factory PaymentStatusResult.error(String message) =>
      PaymentStatusResult._(ok: false, errorMessage: message);

  factory PaymentStatusResult.fromJson(Map<String, dynamic> json) {
    return PaymentStatusResult._(
      ok: true,
      customerReference: json['customer_reference']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      purpose: json['purpose']?.toString() ?? '',
      entityId: json['entity_id']?.toString(),
      amountCents: (json['amount_cents'] is num)
          ? (json['amount_cents'] as num).toInt()
          : 0,
      currency: (json['currency']?.toString() ?? '').toUpperCase(),
      isTerminal: json['is_terminal'] == true,
      gatewayTransactionId: json['gateway_transaction_id']?.toString(),
    );
  }

  /// Maps the backend's PaymentState enum to a coarse outcome the UI
  /// can render without a switch-on-string at every call site.
  PaymentDisplayState get display {
    switch (state.toLowerCase()) {
      case 'paid':
      case 'approved':
      case 'success':
      case 'completed':
        return PaymentDisplayState.paid;
      case 'failed':
      case 'rejected':
      case 'error':
        return PaymentDisplayState.failed;
      case 'cancelled':
      case 'canceled':
        return PaymentDisplayState.cancelled;
      case 'expired':
      case 'timeout':
        return PaymentDisplayState.expired;
      case 'pending':
      case 'processing':
      default:
        return PaymentDisplayState.pending;
    }
  }
}

enum PaymentDisplayState { pending, paid, failed, cancelled, expired }
