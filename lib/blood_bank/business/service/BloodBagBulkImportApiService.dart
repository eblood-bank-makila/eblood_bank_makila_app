import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:eblood_bank_mak_app/apps/config/api/dio_client.dart';
import 'package:eblood_bank_mak_app/apps/models/api_response.dart';

/// Client for the blood-bag bulk Excel import endpoints. The backend derives the
/// organization + health structure from the auth token, so nothing org-related
/// is sent from the client.
class BloodBagBulkImportApiService {
  static const String _templateUrl = '/eblood/import/blood-bags/template';
  static const String _uploadUrl = '/eblood/import/blood-bags/upload';

  /// Download the .xlsx template to [savePath]. Returns the IApiResponse
  /// (data.local_path on success).
  Future<IApiResponse> downloadTemplate(String savePath) async {
    return await downloadWithDio(url: _templateUrl, savePath: savePath);
  }

  /// Upload a filled .xlsx/.csv. The response `data` is the import job
  /// (status, counters, validation_errors, records).
  Future<IApiResponse> uploadExcel(String filePath, String filename) async {
    return await uploadFile(
      path: filePath,
      filename: filename,
      endpoint: _uploadUrl,
      fileFieldName: 'file',
    );
  }
}

final bloodBagBulkImportApiServiceProvider =
    Provider<BloodBagBulkImportApiService>(
  (ref) => BloodBagBulkImportApiService(),
);
