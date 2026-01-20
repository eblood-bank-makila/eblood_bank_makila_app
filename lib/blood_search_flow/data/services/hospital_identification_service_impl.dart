/// Hospital Identification Service Implementation

import 'package:dio/dio.dart';
import '../../domain/services/service_interfaces.dart';
import '../../domain/entities/search_flow_state.dart';
import '../../../core/network/dio_client.dart';

class HospitalIdentificationServiceImpl implements IHospitalIdentificationService {
  late final Dio _dio;

  HospitalIdentificationServiceImpl() {
    _dio = DioClient().dio;
  }

  @override
  Future<IdentifiedHospital?> identifyByCode(String code) async {
    try {
      final response = await _dio.get(
        '/eblood/hospitals/identify',
        queryParameters: {'code': code},
      );

      if (response.statusCode == 200 && response.data['success'] == true) {
        final data = response.data['data'];
        if (data != null) {
          return IdentifiedHospital.fromJson(data, HospitalIdentificationMethod.manualCode);
        }
      }
      return null;
    } catch (e) {
      print('HospitalIdentificationService.identifyByCode error: $e');
      return null;
    }
  }

  @override
  Future<IdentifiedHospital?> identifyFromQrContent(String qrContent) async {
    try {
      // Parse QR content - could be JSON, URL, or plain code
      String? hospitalId;
      String? hospitalCode;

      // Try parsing as JSON
      if (qrContent.startsWith('{')) {
        try {
          final Map<String, dynamic> jsonData = _parseJson(qrContent);
          hospitalId = jsonData['hospital_id']?.toString() ?? jsonData['id']?.toString();
          hospitalCode = jsonData['code']?.toString() ?? jsonData['hospital_code']?.toString();
        } catch (_) {}
      }
      
      // Try parsing as deep link URL
      if (hospitalId == null && hospitalCode == null) {
        final uri = Uri.tryParse(qrContent);
        if (uri != null && uri.pathSegments.isNotEmpty) {
          // Format: myapp://hospital/<id_or_code>
          // Or: https://eblood.app/hospital/<id_or_code>
          final lastSegment = uri.pathSegments.last;
          if (lastSegment.length == 8 && RegExp(r'^[A-Z0-9]+$').hasMatch(lastSegment)) {
            hospitalCode = lastSegment;
          } else {
            hospitalId = lastSegment;
          }
        }
      }

      // If just an 8-character code
      if (hospitalId == null && hospitalCode == null) {
        if (qrContent.length == 8 && RegExp(r'^[A-Z0-9]+$').hasMatch(qrContent)) {
          hospitalCode = qrContent;
        }
      }

      // Fetch hospital details
      if (hospitalId != null) {
        final response = await _dio.get('/eblood/hospitals/$hospitalId');
        if (response.statusCode == 200 && response.data['success'] == true) {
          return IdentifiedHospital.fromJson(
            response.data['data'], 
            HospitalIdentificationMethod.qrScan,
          );
        }
      } else if (hospitalCode != null) {
        return await identifyByCode(hospitalCode);
      }

      return null;
    } catch (e) {
      print('HospitalIdentificationService.identifyFromQrContent error: $e');
      return null;
    }
  }

  @override
  Future<IdentifiedHospital?> identifyFromDeepLink(String deepLinkUri) async {
    try {
      final uri = Uri.parse(deepLinkUri);
      
      // Expected formats:
      // eblood://hospital/<id_or_code>
      // https://eblood.app/hospital/<id_or_code>
      
      if (uri.pathSegments.isEmpty) return null;

      String? identifier;
      
      // Find hospital segment
      final hospitalIndex = uri.pathSegments.indexOf('hospital');
      if (hospitalIndex >= 0 && hospitalIndex < uri.pathSegments.length - 1) {
        identifier = uri.pathSegments[hospitalIndex + 1];
      } else {
        // Assume last segment is the identifier
        identifier = uri.pathSegments.last;
      }

      if (identifier == null || identifier.isEmpty) return null;

      // Check if it's a code (8 alphanumeric) or an ID
      if (identifier.length == 8 && RegExp(r'^[A-Z0-9]+$').hasMatch(identifier)) {
        final hospital = await identifyByCode(identifier);
        if (hospital != null) {
          return IdentifiedHospital(
            id: hospital.id,
            code: hospital.code,
            name: hospital.name,
            address: hospital.address,
            latitude: hospital.latitude,
            longitude: hospital.longitude,
            method: HospitalIdentificationMethod.deepLink,
          );
        }
      } else {
        // Treat as hospital ID
        final response = await _dio.get('/eblood/hospitals/$identifier');
        if (response.statusCode == 200 && response.data['success'] == true) {
          return IdentifiedHospital.fromJson(
            response.data['data'],
            HospitalIdentificationMethod.deepLink,
          );
        }
      }

      return null;
    } catch (e) {
      print('HospitalIdentificationService.identifyFromDeepLink error: $e');
      return null;
    }
  }

  Map<String, dynamic> _parseJson(String jsonString) {
    // Simple JSON parsing - in production use dart:convert
    try {
      return Map<String, dynamic>.from(
        (jsonString as dynamic) as Map,
      );
    } catch (_) {
      return {};
    }
  }
}
