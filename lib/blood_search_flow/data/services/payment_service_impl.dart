/// Payment Service Implementation

import 'package:dio/dio.dart';
import '../../domain/services/service_interfaces.dart';
import '../../domain/entities/search_flow_state.dart';
import '../../../core/network/dio_client.dart';

class PaymentServiceImpl implements IPaymentService {
  late final Dio _dio;

  PaymentServiceImpl() {
    _dio = DioClient().dio;
  }

  @override
  Future<double> getAddressViewPrice() async {
    try {
      final response = await _dio.get('/eblood-connect/address-access-price');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final price = response.data['data']['price'];
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
      final response = await _dio.get('/eblood-connect/delivery-price');
      if (response.statusCode == 200 && response.data['success'] == true) {
        final price = response.data['data']['price'];
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
      final response = await _dio.post(
        '/eblood-connect/blood-bank-address-request/submit-payment',
        data: {
          'hospital_id': hospitalId,
          'payment_method': paymentDetails['payment_method'] ?? 'mobile_money',
          ...paymentDetails,
        },
        options: Options(headers: {'Authorization': 'Bearer $authToken'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        return PaymentResult(
          success: data['success'] == true,
          transactionId: data['data']?['transaction_id']?.toString(),
          message: data['message']?.toString(),
          option: PaymentOption.viewAddress,
        );
      }

      return PaymentResult(
        success: false,
        message: 'Payment failed with status ${response.statusCode}',
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
      final response = await _dio.post(
        '/eblood-connect/cart/submit-payment',
        data: {
          'hospital_id': hospitalId,
          'blood_bag_ids': bloodBagIds,
          'payment_method': paymentDetails['payment_method'] ?? 'mobile_money',
          ...paymentDetails,
        },
        options: Options(headers: {'Authorization': 'Bearer $authToken'}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        return PaymentResult(
          success: data['success'] == true,
          transactionId: data['data']?['transaction_id']?.toString() ??
                         data['data']?['tracking_id']?.toString(),
          message: data['message']?.toString(),
          option: PaymentOption.delivery,
        );
      }

      return PaymentResult(
        success: false,
        message: 'Payment failed with status ${response.statusCode}',
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
}
