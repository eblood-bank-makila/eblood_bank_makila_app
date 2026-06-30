/// Hospital Identification Service Implementation

import '../../domain/services/service_interfaces.dart';
import '../../domain/entities/search_flow_state.dart';
import '../../../services/HealthStructureService.dart';

class HospitalIdentificationServiceImpl implements IHospitalIdentificationService {
  final HealthStructureService _healthStructureService;

  HospitalIdentificationServiceImpl(this._healthStructureService);

  @override
  Future<IdentifiedHospital?> identifyByCode(String code) async {
    try {
      // Use new backend endpoint to get health structure by identifier
      final data = await _healthStructureService.getHealthStructureByIdentifier(code);
      
      if (data != null) {
        final hospitalId = data['id']?.toString();
        print('🏥 [identifyByCode] Hospital ID from service: $hospitalId');
        
        // Validate hospital ID is not null, empty, or invalid string
        if (hospitalId == null || 
            hospitalId.isEmpty || 
            hospitalId.toLowerCase() == 'none' || 
            hospitalId.toLowerCase() == 'null') {
          print('❌ [identifyByCode] Invalid hospital ID: $hospitalId');
          return null;
        }
        
        final hospital = IdentifiedHospital(
          id: hospitalId,
          code: data['identifier']?.toString() ?? code,
          name: data['name']?.toString() ?? 'Unknown',
          address: data['address']?.toString(),
          latitude: data['latitude'] is num ? (data['latitude'] as num).toDouble() : null,
          longitude: data['longitude'] is num ? (data['longitude'] as num).toDouble() : null,
          method: HospitalIdentificationMethod.manualCode,
        );
        print('✅ [identifyByCode] Created IdentifiedHospital with ID: ${hospital.id}');
        return hospital;
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
      // QR content is the identifier string
      // Parse QR content - could be JSON, URL, or plain code
      String? hospitalCode;

      // Try parsing as JSON
      if (qrContent.startsWith('{')) {
        try {
          final Map<String, dynamic> jsonData = _parseJson(qrContent);
          hospitalCode = jsonData['identifier']?.toString() ?? 
                        jsonData['code']?.toString() ?? 
                        jsonData['hospital_code']?.toString();
        } catch (_) {}
      }
      
      // Try parsing as deep link URL
      if (hospitalCode == null) {
        final uri = Uri.tryParse(qrContent);
        if (uri != null && uri.pathSegments.isNotEmpty) {
          // Format: myapp://hospital/<identifier>
          // Or: https://eblood.app/hospital/<identifier>
          final lastSegment = uri.pathSegments.last;
          if (lastSegment.length >= 6 && RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(lastSegment)) {
            hospitalCode = lastSegment;
          }
        }
      }

      // If just a plain identifier string
      if (hospitalCode == null) {
        if (qrContent.length >= 6 && RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(qrContent)) {
          hospitalCode = qrContent;
        }
      }

      // Fetch hospital details using identifier
      if (hospitalCode != null) {
        final hospital = await identifyByCode(hospitalCode);
        if (hospital != null) {
          return IdentifiedHospital(
            id: hospital.id,
            code: hospital.code,
            name: hospital.name,
            address: hospital.address,
            latitude: hospital.latitude,
            longitude: hospital.longitude,
            method: HospitalIdentificationMethod.qrScan,
          );
        }
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
      // eblood://hospital/<identifier>
      // https://eblood.app/hospital/<identifier>
      
      if (uri.pathSegments.isEmpty) return null;

      String identifier = '';
      
      // Find hospital segment
      final hospitalIndex = uri.pathSegments.indexOf('hospital');
      if (hospitalIndex >= 0 && hospitalIndex < uri.pathSegments.length - 1) {
        identifier = uri.pathSegments[hospitalIndex + 1];
      } else {
        // Assume last segment is the identifier
        identifier = uri.pathSegments.last;
      }

      if (identifier.isEmpty) return null;

      // Use new backend endpoint to get health structure by identifier
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
