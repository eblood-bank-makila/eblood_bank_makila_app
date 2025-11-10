import 'package:flutter/material.dart';


import '../../../apps/models/api_response.dart';
import '../../../apps/config/api/dio_client.dart';
import 'PatientNetworkService.dart';

class PatientNetworkServiceImpl implements PatientNetworkService {
  PatientNetworkServiceImpl();

  static const String _base = '/eblood/patients';




  @override
  Future<IApiResponse> createPatient(Map<String, dynamic> patientData) async {
    try {
      // Do not set hospital_id on the client; backend derives it from authenticated user
      debugPrint('Creating patient with data: $patientData', wrapWidth: 1024);
      final response = await postWithDio('$_base/create', body: patientData);
      return response;
    } catch (e) {
      return IApiResponse.error('Create patient error: $e');
    }
  }

  @override
  Future<IApiResponse> getPatients({
    String? hospitalId,
    int page = 0,
    int limit = 20,
    String? searchQuery,
    String? status,
    String? category,
  }) async {
    try {
      final params = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (searchQuery != null && searchQuery.isNotEmpty) params['search_query'] = searchQuery;
      if (status != null && status.isNotEmpty) params['status'] = status;
      if (category != null && category.isNotEmpty) params['category'] = category;

      final response = await getWithDio('$_base/list', queryParams: params);
      return response;
    } catch (e) {
      return IApiResponse.error('List patients error: $e');
    }
  }

  @override
  Future<IApiResponse> getPatientDetails(String patientId) async {
    try {
      final response = await getWithDio(_base, queryParams: {'patient_id': patientId});
      return response;
    } catch (e) {
      return IApiResponse.error('Get patient details error: $e');
    }
  }

  @override
  Future<IApiResponse> updatePatient(String patientId, Map<String, dynamic> updateData) async {
    try {
      final response = await putWithDio(_base, body: updateData, queryParams: {'patient_id': patientId});
      return response;
    } catch (e) {
      return IApiResponse.error('Update patient error: $e');
    }
  }

  @override
  Future<IApiResponse> searchPatients(String searchQuery, {String? hospitalId, int limit = 20}) async {
    try {
      final params = <String, dynamic>{
        'search_query': searchQuery,
        'limit': limit,
      };
      final response = await getWithDio('$_base/search', queryParams: params);
      return response;
    } catch (e) {
      return IApiResponse.error('Search patients error: $e');
    }
  }
}

