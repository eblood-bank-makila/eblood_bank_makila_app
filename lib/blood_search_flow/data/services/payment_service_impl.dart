/// Payment Service Implementation

import '../../domain/services/service_interfaces.dart';
import '../../domain/entities/search_flow_state.dart';
import '../../../apps/config/api/dio_client.dart';

class PaymentServiceImpl implements IPaymentService {
  PaymentServiceImpl();

  @override
  Future<double> getAddressViewPrice() async {
    try {
      final response = await getWithDio('/eblood-connect/address-access-price');
      if (response.success && response.data != null) {
        final price = response.data['price'];
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
      final response = await getWithDio('/eblood-connect/delivery-price');
      if (response.success && response.data != null) {
        final price = response.data['price'];
        return price is num ? price.toDouble() : 0.0;
      }
      return 0.0;
    } catch (e) {
      print('PaymentService.getDeliveryPrice error: $e');
      return 0.0;
    }
  }

  @override
  Future<PaymentResult> payForAddressView({
    required String hospitalId,
    required String authToken,
    required Map<String, dynamic> paymentDetails,
  }) async {
    try {
      // Backend schema expects: blood_bank_id, blood_bags_id (array), hospital_id, phone_number, transactional_currency_id
      // Ensure blood_bags_id is always an array
      final bloodBagsId = paymentDetails['blood_bags_id'];
      final bloodBagsIdArray = bloodBagsId is List ? bloodBagsId : [bloodBagsId];
      
      final data = <String, dynamic>{
        'blood_bank_id': paymentDetails['blood_bank_id'],
        'blood_bags_id': bloodBagsIdArray,
        if (paymentDetails['phone_number'] != null) 'phone_number': paymentDetails['phone_number'],
        if (paymentDetails['transactional_currency_id'] != null) 'transactional_currency_id': paymentDetails['transactional_currency_id'],
      };
      
      // Only include hospital_id if it's not empty
      if (hospitalId.isNotEmpty) {
        data['hospital_id'] = hospitalId;
      }
      
      print('🏥 [PaymentService.payForAddressView] hospitalId param: $hospitalId');
      print('📤 [PaymentService.payForAddressView] Sending data: $data');
      
      final response = await postWithDio(
        '/eblood-connect/blood-bank-address-request/submit-payment',
        body: data,
      );

      if (response.success) {
        final resultData = response.data as Map<String, dynamic>?;
        return PaymentResult(
          success: true,
          transactionId: resultData?['onafriq_transaction_ref']?.toString(),
          requestIdentifier: resultData?['blood_bank_address_request_identifier']?.toString(),
          message: response.message,
          paymentStatus: resultData?['onafriq_state']?.toString(),
          option: PaymentOption.viewAddress,
        );
      }

      return PaymentResult(
        success: false,
        message: response.message ?? 'Payment failed',
        option: PaymentOption.viewAddress,
      );
    } catch (e) {
      print('PaymentService.payForAddressView error: $e');
      return PaymentResult(
        success: false,
        message: 'Payment error: $e',
        option: PaymentOption.viewAddress,
      );
    }
  }

  @override
  Future<PaymentResult> payForDelivery({
    required String hospitalId,
    required List<String> bloodBagIds,
    required String authToken,
    required Map<String, dynamic> paymentDetails,
  }) async {
    try {
      final response = await postWithDio(
        '/eblood-connect/cart/submit-payment',
        body: {
          'hospital_id': hospitalId,
          'blood_bag_ids': bloodBagIds,
          'payment_method': paymentDetails['payment_method'] ?? 'mobile_money',
          ...paymentDetails,
        },
      );

      if (response.success) {
        final resultData = response.data as Map<String, dynamic>?;
        return PaymentResult(
          success: true,
          transactionId: resultData?['onafriq_transaction_ref']?.toString() ??
                         resultData?['tracking_id']?.toString(),
          requestIdentifier: resultData?['blood_bank_address_request_identifier']?.toString() ??
                             resultData?['blood_request_identifier']?.toString(),
          message: response.message,
          paymentStatus: resultData?['onafriq_state']?.toString(),
          option: PaymentOption.delivery,
        );
      }

      return PaymentResult(
        success: false,
        message: response.message ?? 'Payment failed',
        option: PaymentOption.delivery,
      );
    } catch (e) {
      print('PaymentService.payForDelivery error: $e');
      return PaymentResult(
        success: false,
        message: 'Payment error: $e',
        option: PaymentOption.delivery,
      );
    }
  }

  @override
  Future<PaymentResult> checkPaymentStatus({
    required String requestIdentifier,
    required String authToken,
    double? progressPercent,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'identifier': requestIdentifier,
      };
      if (progressPercent != null) {
        queryParams['percent'] = progressPercent;
      }

      final response = await getWithDio(
        '/eblood-connect/blood-bank-address-request/check-payment-status',
        queryParams: queryParams,
      );

      if (response.success && response.data != null) {
        final resultData = response.data as Map<String, dynamic>;
        final status = resultData['status']?.toString() ?? 'unknown';

        return PaymentResult(
          success: status == 'success' || status == 'successful',
          transactionId: resultData['onafriq_transaction_ref']?.toString(),
          requestIdentifier: resultData['blood_request_identifier']?.toString(),
          message: resultData['failure_reason']?.toString() ?? response.message,
          paymentStatus: status,
          option: PaymentOption.viewAddress,
        );
      }

      return PaymentResult(
        success: false,
        message: response.message ?? 'Status check failed',
        option: PaymentOption.viewAddress,
      );
    } catch (e) {
      print('PaymentService.checkPaymentStatus error: $e');
      return PaymentResult(
        success: false,
        message: 'Status check error: $e',
        option: PaymentOption.viewAddress,
      );
    }
  }
}
