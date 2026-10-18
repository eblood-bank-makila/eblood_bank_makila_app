
import '../config/api/dio_client.dart';
import '../config/api/ApiConfig.dart';
import '../models/api_response.dart';
import 'package:eblood_bank_mak_app/blood_bank/data/services/structure_validation_service.dart';

class BloodDeliveryService {
  static final BloodDeliveryService _instance = BloodDeliveryService._internal();
  factory BloodDeliveryService() => _instance;
  BloodDeliveryService._internal();

  Future<Map<String, dynamic>?> findDeliveredByCode(String code) async {
    final hid = await StructureValidationService().getMyStructureId();
    if (hid == null || hid.isEmpty) return null;
    final res = await getWithDio(ApiConfig.deliveriesForHospitalDelivered(hid));
    if (!res.success) return null;
    final data = res.data;
    List<dynamic> list = [];
    if (data is Map && data['data'] is List) {
      list = List<dynamic>.from(data['data'] as List);
    } else if (data is List) {
      list = List<dynamic>.from(data);
    }
    for (final item in list) {
      if (item is Map) {
        final m = Map<String, dynamic>.from(item);
        final deliveryCode = (m['delivery_code'] ?? m['code'] ?? '').toString();
        if (deliveryCode == code) return m;
      }
    }
    return null;
  }

  Future<IApiResponse> receiveDelivery({required String deliveryId, required String code}) async {
    return await postWithDio(ApiConfig.receiveDelivery(deliveryId), body: {
      'delivery_code': code,
    });
  }
}

