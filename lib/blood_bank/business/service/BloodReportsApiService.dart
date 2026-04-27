import 'dart:async';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:eblood_bank_mak_app/core/rbac/models/rbac_models.dart';
import 'package:eblood_bank_mak_app/core/rbac/services/rbac_url_helper.dart';
import '../../../apps/config/api/dio_client.dart';
import '../../../apps/models/api_response.dart';

class BloodReportsApiService {
  /// Reports menu — fetch_url/fetch_report_metrics_url, fetch_report_trends_url, etc.
  final List<RbacCollectionCrudItem> _reportsCrudInfo;
  /// Export menu — download_process_url/main
  final List<RbacCollectionCrudItem> _exportCrudInfo;
  final RbacUrlHelper _urlHelper = RbacUrlHelper();

  BloodReportsApiService({
    required List<RbacCollectionCrudItem> reportsCrudInfo,
    required List<RbacCollectionCrudItem> exportCrudInfo,
  })  : _reportsCrudInfo = reportsCrudInfo,
        _exportCrudInfo = exportCrudInfo;
  
  Future<IApiResponse> getBloodReportMetricKeys({
    String? startDate,
    String? endDate,
    String? bloodType,
    String? component,
    String? bloodBankId,
  }) async {
    try {
      // Build query parameters
      Map<String, dynamic> queryParams = {};
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;
      if (bloodType != null) queryParams['blood_type'] = bloodType;
      if (component != null) queryParams['component'] = component;
      if (bloodBankId != null) queryParams['blood_bank_id'] = bloodBankId;
      
      final response = await getWithDio(
        _urlHelper.getFetchUrl(_reportsCrudInfo, 'fetch_report_metrics_url'),
        queryParams: queryParams,
      );

      return response;
    } catch (e) {
      return IApiResponse(
        success: false,
        message: 'Network error: $e',
      );
    }
  }
  
  Future<IApiResponse> getBloodReportsTrends({
    required String period,
    String? bloodType,
    String? component,
    String? bloodBankId,
  }) async {
    try {
      // Build query parameters
      Map<String, dynamic> queryParams = {
        'period': period,
      };
      if (bloodType != null) queryParams['blood_type'] = bloodType;
      if (component != null) queryParams['component'] = component;
      if (bloodBankId != null) queryParams['blood_bank_id'] = bloodBankId;
      
      final response = await getWithDio(
        _urlHelper.getFetchUrl(_reportsCrudInfo, 'fetch_report_trends_url'),
        queryParams: queryParams,
      );

      return response;
    } catch (e) {
      return IApiResponse(
        success: false,
        message: 'Network error: $e',
      );
    }
  }
  
  Future<IApiResponse> getMonthlyComparison({
    int? compareMonth,
    int? compareYear,
    String? bloodBankId,
  }) async {
    try {
      // Build query parameters
      Map<String, dynamic> queryParams = {};
      if (compareMonth != null) queryParams['compare_month'] = compareMonth.toString();
      if (compareYear != null) queryParams['compare_year'] = compareYear.toString();
      if (bloodBankId != null) queryParams['blood_bank_id'] = bloodBankId;
      
      final response = await getWithDio(
        _urlHelper.getFetchUrl(_reportsCrudInfo, 'fetch_report_monthly_comparison_url'),
        queryParams: queryParams,
      );

      return response;
    } catch (e) {
      return IApiResponse(
        success: false,
        message: 'Network error: $e',
      );
    }
  }
  
  Future<IApiResponse> generateBloodReport({
    required String reportType,
    String? startDate,
    String? endDate,
    String format = 'pdf',
    String? bloodBankId,
  }) async {
    try {
      // Build query parameters
      Map<String, dynamic> queryParams = {
        'report_type': reportType,
        'format': format,
      };
      if (startDate != null) queryParams['start_date'] = startDate;
      if (endDate != null) queryParams['end_date'] = endDate;
      if (bloodBankId != null) queryParams['blood_bank_id'] = bloodBankId;
      
      final response = await getWithDio(
        _urlHelper.getDownloadProcessUrl(_exportCrudInfo),
        queryParams: queryParams,
      );

      return response;
    } catch (e) {
      return IApiResponse(
        success: false,
        message: 'Network error: $e',
      );
    }
  }
  
  Future<IApiResponse> downloadReportFile(String downloadUrl) async {
    try {
      // Get the application documents directory
      final Directory appDocDir = await getApplicationDocumentsDirectory();
      final String fileName = downloadUrl.split('/').last;
      final String filePath = '${appDocDir.path}/$fileName';
      
      print('📥 Downloading from: $downloadUrl');
      print('💾 Saving to: $filePath');
      
      // Use downloadWithDio helper (includes device info, auth, location headers)
      final response = await downloadWithDio(
        url: downloadUrl,
        savePath: filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            print('📥 Download progress: ${(received / total * 100).toStringAsFixed(0)}%');
          }
        },
      );
      
      if (response.success) {
        // File downloaded successfully
        print('✅ File downloaded to: $filePath');
        
        // Get file size
        final file = File(filePath);
        final fileSize = await file.length();
        
        // ✅ RETURN file info WITHOUT auto-opening (let UI show preview dialog)
        return IApiResponse(
          success: true,
          message: 'Rapport téléchargé avec succès',
          data: {
            'local_path': filePath,
            'file_name': fileName,
            'file_size': fileSize,
          },
        );
      } else {
        return IApiResponse(
          success: false,
          message: 'Échec du téléchargement: ${response.message}',
        );
      }
    } catch (e) {
      print('❌ Download error: $e');
      return IApiResponse(
        success: false,
        message: 'Erreur lors du téléchargement: $e',
      );
    }
  }
}