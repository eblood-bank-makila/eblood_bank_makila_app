import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lokotro_pay/lokotro_pay.dart';

import 'PaymentApi.dart';

/// Sprint 15 — wraps the lokotro_pay SDK so callers don't have to know
/// about LokotroPayConfigs / LokotroPaymentBody / Navigator-push
/// plumbing.
///
/// All gateway credentials (app_key, is_production, notify_url, the
/// merchant block, prefilled user info) come from the backend's
/// `/payments/initiate/payment` response, surfaced as [PaymentInitiateResult].
/// Flutter doesn't carry the app_key in its bundle.
///
/// The flow is one-way: launch the checkout, await the
/// onResponse / onError callback, return a normalised result. The
/// backend's `/payments/payment-gateway-callback` handler is the source
/// of truth for the final payment state — this service only reports
/// what the SDK observed in-app.
class LokotroPayCheckoutService {
  LokotroPayCheckoutService._();

  /// Launch the checkout with the config the backend just returned.
  /// The caller passes [initiate] (from `PaymentApi.initiate(...)`) plus
  /// the chosen [paymentMethod] string ('wallet', 'card', 'mobile_money',
  /// 'flash', 'bank_transfer'). Optional [phoneNumberOverride] takes
  /// precedence over the prefilled phone (e.g. when the user typed a
  /// different mobile-money number on the previous step).
  static Future<LokotroPayCheckoutResult> launchFromInitiate(
    BuildContext context, {
    required PaymentInitiateResult initiate,
    required String paymentMethod,
    String? phoneNumberOverride,
    String? mobileMoneyPhoneNumber,
    String? title,
    String? acceptLanguage,
  }) {
    assert(initiate.isSuccess && initiate.customerReference != null,
        'launchFromInitiate requires a successful PaymentInitiateResult');
    assert(initiate.appKey.isNotEmpty,
        'launchFromInitiate requires app_key from the backend response');

    final configs = LokotroPayConfigs(
      // Auth-v3: backend's `appKey` field now carries a session_token
      // minted via lokotro_gateway's /api/v1/internal/sessions/create.
      // SDK exposes it under the new `sessionToken` parameter.
      sessionToken: initiate.appKey,
      acceptLanguage:
          acceptLanguage ?? Localizations.localeOf(context).languageCode,
    );

    final paymentBody = LokotroPaymentBody(
      customerReference: initiate.customerReference!,
      amount: (initiate.amountCents / 100.0).toStringAsFixed(2),
      currency: (initiate.currency ?? 'usd').toLowerCase(),
      paymentMethod: paymentMethod,
      userInfo: initiate.userInfo,
      paymentMethodInfo: initiate.paymentMethodInfo,
      feeCoveredBy: initiate.feeCoveredBy,
      deliveryBehaviour: initiate.deliveryBehaviour,
      notifyUrl: initiate.notifyUrlAbsolute,
      firstName: initiate.firstName,
      lastName: initiate.lastName,
      phoneNumber: phoneNumberOverride ?? initiate.phoneNumber,
      email: initiate.email,
      mobileMoneyPhoneNumber: mobileMoneyPhoneNumber,
      merchant: LokotroMerchantInfo(
        name: initiate.merchantName,
        logo: initiate.merchantLogo,
        url: initiate.merchantUrl,
      ),
    );

    return _push(
      context,
      configs: configs,
      paymentBody: paymentBody,
      title: title,
      fallbackCustomerReference: initiate.customerReference!,
    );
  }

  static Future<LokotroPayCheckoutResult> _push(
    BuildContext context, {
    required LokotroPayConfigs configs,
    required LokotroPaymentBody paymentBody,
    required String fallbackCustomerReference,
    String? title,
  }) async {
    final completer = Completer<LokotroPayCheckoutResult>();

    void resolve(LokotroPayCheckoutResult result) {
      if (!completer.isCompleted) completer.complete(result);
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (innerContext) => LokotroPayCheckout(
          title: title,
          configs: configs,
          paymentBody: paymentBody,
          onResponse: (response) {
            // Full payload dump — /payments/confirm-collect needs the
            // gateway's transaction id, and at least one live payment came
            // back with transactionId == null (intent stuck PENDING, so it
            // never appears in my-recent-activity). Log everything so we can
            // see which field the gateway actually populates.
            debugPrint(
              '📦 LokotroPayCheckout onResponse: '
              'status=${response.paymentStatus.name} '
              'apiCode=${response.apiResponseCode.code} '
              'transactionId=${response.transactionId} '
              'systemRef=${response.systemRef} '
              'identifier=${response.identifier} '
              'customerReference=${response.customerReference} '
              'customRef=${response.customRef} '
              'amount=${response.amount} ${response.currency} '
              'message="${response.message}"',
            );
            // transaction_id/payment_id may be absent while system_ref is
            // set (the SDK model parses system_ref ?? payment_id into
            // systemRef, with '-' as its missing marker). The backend
            // re-verifies whatever id we send against the gateway before
            // touching the intent, so a wrong fallback only fails the
            // non-blocking confirm — same as sending nothing.
            String? sdkTransactionId = response.transactionId?.trim();
            if (sdkTransactionId == null || sdkTransactionId.isEmpty) {
              final systemRef = response.systemRef.trim();
              if (systemRef.isNotEmpty && systemRef != '-') {
                sdkTransactionId = systemRef;
              } else {
                final identifier = response.identifier?.trim() ?? '';
                sdkTransactionId = identifier.isNotEmpty ? identifier : null;
              }
            }
            resolve(
              LokotroPayCheckoutResult.success(
                customerReference: response.customerReference
                    ?? fallbackCustomerReference,
                transactionId: sdkTransactionId,
                status: response.paymentStatus.name,
                message: response.message,
              ),
            );
            // Deliberately do NOT pop here — the SDK closes the checkout
            // itself on every success path (success screen auto-redirect,
            // Continue, Close all call onResponse and then pop). Popping
            // here too made it a DOUBLE pop: ours removed the checkout,
            // the SDK's removed the payment page beneath it, and the user
            // saw the search screen flash before the reveal navigation.
            // (onResponse can also fire early from the SDK's message
            // stream while its success screen is still showing; popping on
            // that call cut the success screen off entirely.)
          },
          onError: (error) {
            debugPrint(
              '💥 LokotroPayCheckout onError: code=${error.errorCode?.code} '
              'title="${error.title}" message="${error.message}" '
              'customerRef=${error.customerReference} '
              'systemRef=${error.systemReference} '
              'amount=${error.amount} currency=${error.currency}',
            );
            resolve(
              LokotroPayCheckoutResult.error(
                customerReference: error.customerReference
                    ?? fallbackCustomerReference,
                errorCode: error.errorCode?.code,
                message: error.message,
                title: error.title,
              ),
            );
            // Deliberately do NOT pop here. The SDK routes to its own error
            // screen, which carries the detailed reason (e.g. "Failed to
            // initialize payment: <cause>"); the callback's `message` is
            // sometimes empty. Popping made a failing checkout look like it
            // opened and closed instantly with no explanation at all. The
            // user can dismiss the SDK screen with back when they're done
            // reading it.
          },
        ),
      ),
    );

    // System back-button popped the route without firing either
    // callback — surface a cancelled result so the caller can
    // distinguish from a real error.
    resolve(LokotroPayCheckoutResult.cancelled(
      customerReference: fallbackCustomerReference,
    ));
    return completer.future;
  }
}

class LokotroPayCheckoutResult {
  final LokotroPayCheckoutOutcome outcome;
  final String customerReference;
  final String? transactionId;
  final String? status;
  final String? message;
  final String? errorCode;
  final String? title;

  const LokotroPayCheckoutResult._({
    required this.outcome,
    required this.customerReference,
    this.transactionId,
    this.status,
    this.message,
    this.errorCode,
    this.title,
  });

  factory LokotroPayCheckoutResult.success({
    required String customerReference,
    String? transactionId,
    String? status,
    String? message,
  }) =>
      LokotroPayCheckoutResult._(
        outcome: LokotroPayCheckoutOutcome.success,
        customerReference: customerReference,
        transactionId: transactionId,
        status: status,
        message: message,
      );

  factory LokotroPayCheckoutResult.error({
    required String customerReference,
    String? errorCode,
    String? message,
    String? title,
  }) =>
      LokotroPayCheckoutResult._(
        outcome: LokotroPayCheckoutOutcome.error,
        customerReference: customerReference,
        errorCode: errorCode,
        message: message,
        title: title,
      );

  factory LokotroPayCheckoutResult.cancelled({
    required String customerReference,
  }) =>
      LokotroPayCheckoutResult._(
        outcome: LokotroPayCheckoutOutcome.cancelled,
        customerReference: customerReference,
        message: 'Paiement annulé.',
      );

  bool get isSuccess => outcome == LokotroPayCheckoutOutcome.success;
}

enum LokotroPayCheckoutOutcome { success, error, cancelled }
