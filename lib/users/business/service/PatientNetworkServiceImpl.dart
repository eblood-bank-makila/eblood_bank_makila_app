import 'package:flutter/foundation.dart';


import '../../../apps/models/api_response.dart';
import '../../../apps/config/api/dio_client.dart';
import '../../../core/rbac/models/rbac_models.dart';
import '../../../core/rbac/services/rbac_url_helper.dart';
import 'PatientNetworkService.dart';

class PatientNetworkServiceImpl implements PatientNetworkService {
  final List<RbacCollectionCrudItem> _crudInfo;
  final RbacUrlHelper _urlHelper = RbacUrlHelper();

  PatientNetworkServiceImpl(this._crudInfo);




  @override
  Future<IApiResponse> createPatient(Map<String, dynamic> patientData) async {
    try {
      final url = _urlHelper.getCreateProcessingUrl(_crudInfo, 'create_patient_url');
      if (kDebugMode) print('[PatientService] createPatient → $url');
      final response = await postWithDio(url, body: patientData);
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
      final url = _urlHelper.getFetchUrl(_crudInfo, 'fetch_patients_list_url');
      if (kDebugMode) print('[PatientService] getPatients → $url');
      final params = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      if (searchQuery != null && searchQuery.isNotEmpty) params['search_query'] = searchQuery;
      if (status != null && status.isNotEmpty) params['status'] = status;
      if (category != null && category.isNotEmpty) params['category'] = category;

      final response = await getWithDio(url, queryParams: params);
      return response;
    } catch (e) {
      return IApiResponse.error('List patients error: $e');
    }
  }

  @override
  Future<IApiResponse> getPatientDetails(String patientId) async {
    try {
      final url = _urlHelper.getFetchUrl(_crudInfo, 'fetch_patient_detail_url');
      if (kDebugMode) print('[PatientService] getPatientDetails → $url');
      final response = await getWithDio(url, queryParams: {'patient_id': patientId});
      return response;
    } catch (e) {
      return IApiResponse.error('Get patient details error: $e');
    }
  }

  @override
  Future<IApiResponse> updatePatient(String patientId, Map<String, dynamic> updateData) async {
    try {
      final url = _urlHelper.getUpdateProcessingUrl(_crudInfo, 'update_patient_url');
      if (kDebugMode) print('[PatientService] updatePatient → $url');
      final response = await putWithDio(url, body: updateData, queryParams: {'patient_id': patientId});
      return response;
    } catch (e) {
      return IApiResponse.error('Update patient error: $e');
    }
  }

  @override
  Future<IApiResponse> searchPatients(String searchQuery, {String? hospitalId, int limit = 20}) async {
    try {
      final url = _urlHelper.getFetchUrl(_crudInfo, 'search_patients_url');
      if (kDebugMode) print('[PatientService] searchPatients → $url');
      final params = <String, dynamic>{
        'search_query': searchQuery,
        'limit': limit,
      };
      final response = await getWithDio(url, queryParams: params);
      return response;
    } catch (e) {
      return IApiResponse.error('Search patients error: $e');
    }
  }
}

