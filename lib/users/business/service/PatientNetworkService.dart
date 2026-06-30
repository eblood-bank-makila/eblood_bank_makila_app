import '../../../apps/models/api_response.dart';

abstract class PatientNetworkService {
  Future<IApiResponse> createPatient(Map<String, dynamic> patientData);

  Future<IApiResponse> getPatients({
    String? hospitalId,
    int page = 0,
    int limit = 20,
    String? searchQuery,
    String? status,
    String? category,
  });

  Future<IApiResponse> getPatientDetails(String patientId);

  Future<IApiResponse> updatePatient(String patientId, Map<String, dynamic> updateData);

  Future<IApiResponse> searchPatients(String searchQuery, {String? hospitalId, int limit = 20});
}

