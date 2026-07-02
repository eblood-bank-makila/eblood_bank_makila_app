import 'package:flutter/foundation.dart';

import '../../../apps/config/api/dio_client.dart';
import '../../../apps/services/EbloodAuthHelper.dart';

/// Sprint 15 — thin client over the gateway-agnostic eblood payments
/// module. The endpoints live under /api/v1/payments/* and are framed
/// in terms of {purpose, entity_id, payer_user_id, amount_cents,
/// currency} — they don't know about onafriq or any specific gateway.
/// Pair the initiate response with LokotroPayCheckoutService.launchCheckout
/// to actually collect the funds; the backend's webhook handler
/// reconciles the payment intent with the gateway result.
class PaymentApi {
  PaymentApi._();

  /// POST /api/v1/payments/initiate/payment
  ///
  /// Creates a PaymentIntent in PENDING AND returns the FULL lokotro_pay
  /// configuration the checkout widget needs — app_key, is_production,
  /// notify_url, merchant block, prefilled user info. The Flutter app
  /// passes these straight through to LokotroPayConfigs/LokotroPaymentBody;
  /// it does NOT carry the app_key in its bundle.
  ///
  /// [purpose] must be one of the backend's PaymentPurpose enum values
  /// — at the time of writing: `address_access`, `delivery`. [entityId]
  /// is the bag id (for address_access) or order id (for delivery).
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

      final res = await postWithDio('/payments/initiate/payment', body: body);
      if (!res.success || res.data is! Map) {
        return PaymentInitiateResult.error(
          res.message ?? 'Échec de l\'initiation du paiement.',
        );
      }
      return _parseInitiateData(
        Map<String, dynamic>.from(res.data as Map),
        fallbackAmountCents: amountCents,
        fallbackCurrency: currency,
      );
    } catch (e) {
      debugPrint('💥 PaymentApi.initiate error: $e');
      return PaymentInitiateResult.error('Erreur: $e');
    }
  }

  /// POST /api/v1/eblood-connect/cart/initiate-lokotro-payment
  ///
  /// Lokotro checkout for the blood-bag PURCHASE itself. Unlike
  /// [initiate], the client does NOT declare the amount — the backend
  /// materializes the cart into an OpsBloodRequest, computes
  /// total + eblood_fee + transaction fee server-side and returns the
  /// same lokotro_pay widget config (plus blood_request identifiers).
  /// On the gateway's SUCCEEDED webhook the backend approves the
  /// request and starts the delivery chain.
  static Future<PaymentInitiateResult> initiateCartPurchase({
    required String cartId,
    String? phoneNumber,
    String? transactionalCurrencyId,
    String? requestFor,
    String? patientId,
    String? requestType,
    String? urgencyLevel,
    String? requestReason,
  }) async {
    try {
      final body = <String, dynamic>{
        'cart_id': cartId,
        if (phoneNumber != null && phoneNumber.isNotEmpty)
          'phone_number': phoneNumber,
        if (transactionalCurrencyId != null && transactionalCurrencyId.isNotEmpty)
          'transactional_currency_id': transactionalCurrencyId,
        if (requestFor != null && requestFor.isNotEmpty) 'request_for': requestFor,
        if (patientId != null && patientId.isNotEmpty) 'patient_id': patientId,
        if (requestType != null && requestType.isNotEmpty)
          'request_type': requestType,
        if (urgencyLevel != null && urgencyLevel.isNotEmpty)
          'urgency_level': urgencyLevel,
        if (requestReason != null && requestReason.isNotEmpty)
          'request_reason': requestReason,
      };

      final res = await postWithDio(
        '/eblood-connect/cart/initiate-lokotro-payment',
        body: body,
      );
      if (!res.success || res.data is! Map) {
        return PaymentInitiateResult.error(
          res.message ?? 'Échec de l\'initiation du paiement.',
        );
      }
      return _parseInitiateData(
        Map<String, dynamic>.from(res.data as Map),
        fallbackAmountCents: 0,
        fallbackCurrency: 'USD',
      );
    } catch (e) {
      debugPrint('💥 PaymentApi.initiateCartPurchase error: $e');
      return PaymentInitiateResult.error('Erreur: $e');
    }
  }

  /// Shared parser for the initiate-response shape (used by both the
  /// generic /payments/initiate/payment and the cart purchase endpoint).
  static PaymentInitiateResult _parseInitiateData(
    Map<String, dynamic> data, {
    required int fallbackAmountCents,
    required String fallbackCurrency,
  }) {
    final customerRef = data['customer_reference']?.toString();
    if (customerRef == null || customerRef.isEmpty) {
      return PaymentInitiateResult.error(
        'Réponse invalide du backend (customer_reference manquant).',
      );
    }

    // Pull out the lokotro_pay config block. The backend has already
    // built notify_url as an absolute URL — no client-side prefixing
    // needed.
    final merchantRaw = data['merchant'];
    final merchant = merchantRaw is Map
        ? Map<String, dynamic>.from(merchantRaw)
        : <String, dynamic>{};

    return PaymentInitiateResult.success(
      customerReference: customerRef,
      amountCents: (data['amount_cents'] is num)
          ? (data['amount_cents'] as num).toInt()
          : fallbackAmountCents,
      currency: (data['currency']?.toString() ?? fallbackCurrency).toUpperCase(),
      state: data['state']?.toString() ?? 'pending',
      appKey: data['app_key']?.toString() ?? '',
      isProduction: data['is_production'] == true,
      notifyUrlAbsolute: data['notify_url']?.toString() ?? '',
      userInfo: data['user_info']?.toString() ?? 'full',
      paymentMethodInfo: data['payment_method_info']?.toString() ?? 'full',
      feeCoveredBy: data['fee_covered_by']?.toString() ?? 'buyer',
      deliveryBehaviour:
          data['delivery_behaviour']?.toString() ?? 'direct_delivery',
      firstName: data['first_name']?.toString(),
      lastName: data['last_name']?.toString(),
      phoneNumber: data['phone_number']?.toString(),
      email: data['email']?.toString(),
      merchantName: merchant['name']?.toString() ?? 'eblood',
      merchantLogo: merchant['logo']?.toString(),
      merchantUrl: merchant['url']?.toString(),
    );
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

/// Sprint 15 — full lokotro_pay configuration returned by
/// `/payments/initiate/payment`. Mirrors the backend's
/// `PaymentInitiateResponse` schema field-for-field. Pass straight
/// through to `LokotroPayCheckoutService.launchCheckout`; nothing
/// here needs reading from `.env` on the client.
class PaymentInitiateResult {
  final bool isSuccess;
  final String? errorMessage;

  // Core intent
  final String? customerReference;
  final int amountCents;
  final String? currency;
  final String? state;

  // Lokotro gateway config (server-owned)
  final String appKey;
  final bool isProduction;
  final String notifyUrlAbsolute;

  // LokotroPaymentBody flags
  final String userInfo;
  final String paymentMethodInfo;
  final String feeCoveredBy;
  final String deliveryBehaviour;

  // Prefilled buyer info
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String? email;

  // Merchant block
  final String merchantName;
  final String? merchantLogo;
  final String? merchantUrl;

  const PaymentInitiateResult._({
    required this.isSuccess,
    this.errorMessage,
    this.customerReference,
    this.amountCents = 0,
    this.currency,
    this.state,
    this.appKey = '',
    this.isProduction = false,
    this.notifyUrlAbsolute = '',
    this.userInfo = 'full',
    this.paymentMethodInfo = 'full',
    this.feeCoveredBy = 'buyer',
    this.deliveryBehaviour = 'direct_delivery',
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.email,
    this.merchantName = 'eblood',
    this.merchantLogo,
    this.merchantUrl,
  });

  factory PaymentInitiateResult.success({
    required String customerReference,
    required int amountCents,
    required String currency,
    required String state,
    required String appKey,
    required bool isProduction,
    required String notifyUrlAbsolute,
    String userInfo = 'full',
    String paymentMethodInfo = 'full',
    String feeCoveredBy = 'buyer',
    String deliveryBehaviour = 'direct_delivery',
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? email,
    required String merchantName,
    String? merchantLogo,
    String? merchantUrl,
  }) =>
      PaymentInitiateResult._(
        isSuccess: true,
        customerReference: customerReference,
        amountCents: amountCents,
        currency: currency,
        state: state,
        appKey: appKey,
        isProduction: isProduction,
        notifyUrlAbsolute: notifyUrlAbsolute,
        userInfo: userInfo,
        paymentMethodInfo: paymentMethodInfo,
        feeCoveredBy: feeCoveredBy,
        deliveryBehaviour: deliveryBehaviour,
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        email: email,
        merchantName: merchantName,
        merchantLogo: merchantLogo,
        merchantUrl: merchantUrl,
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
