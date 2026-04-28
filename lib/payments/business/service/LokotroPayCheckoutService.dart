import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lokotro_pay/lokotro_pay.dart';

import '../../../core/config/app_config.dart';

/// Sprint 15 — wraps the lokotro_pay SDK so callers don't have to know
/// about LokotroPayConfigs / LokotroPaymentBody / Navigator-push
/// plumbing. Pair with the backend's POST /payments/initiate endpoint
/// which returns the customer_reference this widget needs.
///
/// The flow is intentionally one-way: launch the checkout, await the
/// onResponse / onError callback, return a normalised result. The
/// backend's /payments/lokotro-webhook handler is the source of truth
/// for the final payment state — this service only reports what the
/// SDK observed in-app.
class LokotroPayCheckoutService {
  LokotroPayCheckoutService._();

  /// Read at each launch so env hot-reloads take effect without
  /// requiring an app restart in dev. Centralised in AppConfig so the
  /// env-key names (LOKOTRO_PAY_TOKEN etc.) live in one file.
  static LokotroPayConfigs _configs() {
    return LokotroPayConfigs(
      token: AppConfig.lokotroPayToken,
      isProduction: AppConfig.lokotroPayIsProduction,
      acceptLanguage: AppConfig.lokotroPayLanguage,
    );
  }

  /// Push the checkout widget and resolve when the SDK fires
  /// onResponse or onError. The caller does NOT need to wrap in a
  /// MaterialPageRoute — that's done here.
  ///
  /// [amount] is sent as a string per the SDK contract (the gateway
  /// API parses it as a decimal). [currency] is an ISO code (USD,
  /// CDF, ...) and is lowercased internally by the SDK.
  ///
  /// [notifyUrlAbsolute] must be the FULL URL the gateway POSTs the
  /// webhook to — typically `<API_BASE_URL>/payments/lokotro-webhook`.
  /// The backend returns the path-only suffix in its initiate response;
  /// the caller is responsible for prefixing the API base URL.
  static Future<LokotroPayCheckoutResult> launchCheckout(
    BuildContext context, {
    required String customerReference,
    required double amount,
    required String currency,
    required String notifyUrlAbsolute,
    String? phoneNumber,
    String? email,
    String? firstName,
    String? lastName,
    String? title,
    String paymentMethod = 'wallet',
  }) async {
    final completer = Completer<LokotroPayCheckoutResult>();

    void resolve(LokotroPayCheckoutResult result) {
      if (!completer.isCompleted) completer.complete(result);
    }

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (innerContext) => LokotroPayCheckout(
          title: title,
          configs: _configs(),
          paymentBody: LokotroPaymentBody(
            customerReference: customerReference,
            amount: amount.toStringAsFixed(2),
            currency: currency,
            paymentMethod: paymentMethod,
            notifyUrl: notifyUrlAbsolute,
            phoneNumber: phoneNumber,
            email: email,
            firstName: firstName,
            lastName: lastName,
            merchant: const LokotroMerchantInfo(name: 'eblood'),
          ),
          onResponse: (response) {
            resolve(
              LokotroPayCheckoutResult.success(
                customerReference:
                    response.customerReference ?? customerReference,
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
                customerReference:
                    error.customerReference ?? customerReference,
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

    // If the user popped the route without picking either callback
    // (e.g., system back button), surface a cancelled result so the
    // caller can distinguish from a real error.
    resolve(LokotroPayCheckoutResult.cancelled(
      customerReference: customerReference,
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
