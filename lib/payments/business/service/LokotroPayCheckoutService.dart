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
      token: initiate.appKey,
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
            resolve(
              LokotroPayCheckoutResult.success(
                customerReference: response.customerReference
                    ?? fallbackCustomerReference,
                transactionId: response.transactionId,
                status: response.paymentStatus.name,
                message: response.message,
              ),
            );
            if (Navigator.of(innerContext).canPop()) {
              Navigator.of(innerContext).pop();
            }
          },
          onError: (error) {
            resolve(
              LokotroPayCheckoutResult.error(
                customerReference: error.customerReference
                    ?? fallbackCustomerReference,
                errorCode: error.errorCode?.code,
                message: error.message,
                title: error.title,
              ),
            );
            if (Navigator.of(innerContext).canPop()) {
              Navigator.of(innerContext).pop();
            }
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
