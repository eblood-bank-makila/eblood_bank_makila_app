/// Payment Service Implementation
///
/// Sprint 15 — migrated off the legacy onafriq-shaped endpoints
/// (/eblood-connect/blood-bank-address-request/submit-payment,
/// /eblood-connect/cart/submit-payment, etc.) onto the gateway-agnostic
/// payments module. The actual gateway interaction (lokotro_pay) is
/// launched separately by the UI layer, which has the BuildContext
/// the lokotro_pay widget needs; this service is the server-side
/// initiate-and-poll half of the flow.

import '../../domain/services/service_interfaces.dart';
import '../../domain/entities/search_flow_state.dart';
import '../../../apps/config/api/dio_client.dart';
import '../../../payments/business/service/PaymentApi.dart';

class PaymentServiceImpl implements IPaymentService {
  PaymentServiceImpl();

  @override
  Future<double> getAddressViewPrice() async {
    try {
      final response = await getWithDio('/pricing/get-address-access-price');
      if (response.success && response.data is Map) {
        final data = Map<String, dynamic>.from(response.data as Map);
        // Sprint 15: pricing module returns {amount_cents, currency,
        // description}. UI wants a plain double for display, so divide.
        final cents = data['amount_cents'];
        if (cents is num) return cents.toDouble() / 100.0;
        // Fallback for any caller that still returns the legacy
        // {price: <double>} shape.
        final price = data['price'];
        return price is num ? price.toDouble() : 0.0;
      }
      return 0.0;
    } catch (e) {
      print('PaymentService.getAddressViewPrice error: $e');
      return 0.0;
    }
  }

  @override
  Future<double> getDeliveryPrice() async {
    try {
      final response = await getWithDio('/pricing/get-delivery-price');
      if (response.success && response.data is Map) {
        final data = Map<String, dynamic>.from(response.data as Map);
        final cents = data['amount_cents'];
        if (cents is num) return cents.toDouble() / 100.0;
        final price = data['price'];
        return price is num ? price.toDouble() : 0.0;
      }
      return 0.0;
    } catch (e) {
      print('PaymentService.getDeliveryPrice error: $e');
      return 0.0;
    }
  }

  @override
  Future<PaymentInitiateResult> initiateAddressViewPayment({
    required String hospitalId,
    required String authToken,
    required Map<String, dynamic> paymentDetails,
  }) async {
    final entityId = _firstNonEmpty([
      paymentDetails['blood_bag_id'],
      _firstFromList(paymentDetails['blood_bags_id']),
    ]);
    // Returns the FULL config (incl. the gateway session_token in appKey).
    // The UI launches LokotroPayCheckout with it; money is collected there.
    return PaymentApi.initiate(
      purpose: 'address_access',
      entityId: entityId,
      amountCents: _readAmountCents(paymentDetails),
      currency: _readCurrency(paymentDetails),
    );
  }

  @override
  Future<PaymentInitiateResult> initiateDeliveryPayment({
    required String hospitalId,
    required List<String> bloodBagIds,
    required String authToken,
    required Map<String, dynamic> paymentDetails,
  }) async {
    // Visitor delivery = a full purchase of the selected bag, delivered to
    // the hospital the visitor scanned. The backend resolves the price from
    // the stock bag and mints a BLOOD_BAG_PURCHASE session so the gateway's
    // success webhook dispatches a courier (blood bank → hospital).
    final bagId = _firstNonEmpty([
      paymentDetails['blood_bag_id'],
      _firstFromList(paymentDetails['blood_bags_id']),
      bloodBagIds.isNotEmpty ? bloodBagIds.first : null,
    ]);
    return PaymentApi.initiateVisitorDeliveryPurchase(
      bloodBagId: bagId ?? '',
      hospitalId: hospitalId,
      phoneNumber: paymentDetails['phone_number']?.toString(),
      transactionalCurrencyId:
          paymentDetails['transactional_currency_id']?.toString(),
    );
  }

  @override
  Future<PaymentResult> checkPaymentStatus({
    required String requestIdentifier,
    required String authToken,
    double? progressPercent,
  }) async {
    // Sprint 15 — `requestIdentifier` is the customer_reference now.
    final status = await PaymentApi.getStatus(requestIdentifier);
    if (!status.ok) {
      return PaymentResult(
        success: false,
        message: status.errorMessage ?? 'Status check failed',
        option: PaymentOption.viewAddress,
      );
    }
    final isPaid = status.display == PaymentDisplayState.paid;
    return PaymentResult(
      success: isPaid,
      transactionId: status.gatewayTransactionId,
      requestIdentifier: status.customerReference,
      message: 'state=${status.state}',
      paymentStatus: status.state,
      option: PaymentOption.viewAddress,
    );
  }

  String? _firstNonEmpty(List<dynamic> candidates) {
    for (final c in candidates) {
      if (c == null) continue;
      final s = c.toString();
      if (s.isNotEmpty) return s;
    }
    return null;
  }

  String? _firstFromList(dynamic v) {
    if (v is List && v.isNotEmpty) return v.first.toString();
    if (v is String && v.isNotEmpty) return v;
    return null;
  }

  int _readAmountCents(Map<String, dynamic> details) {
    final cents = details['amount_cents'];
    if (cents is num) return cents.toInt();
    final amount = details['amount'];
    if (amount is num) return (amount * 100).round();
    return 0;
  }

  String _readCurrency(Map<String, dynamic> details) {
    final c = (details['currency']
            ?? details['currency_code']
            ?? details['transactional_currency_code'])
        ?.toString();
    if (c != null && c.trim().isNotEmpty) return c.trim().toUpperCase();
    return 'USD';
  }
}
