import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../../apps/config/api/dio_client.dart';
import '../../../apps/config/api/ApiConfig.dart';
import '../../../apps/models/api_response.dart';

// Define endpoints for reports
class BloodReportsEndpoints {
  static const String metricKeys = '/eblood/reports/blood-inventory/metric-keys';
  static const String trends = '/eblood/reports/blood-inventory/trends';
  static const String monthlyComparison = '/eblood/reports/blood-inventory/monthly-comparison';
  static const String generateReport = '/eblood/reports/blood-inventory/generate';
}

class BloodReportsApiService {
  BloodReportsApiService();
  
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
        BloodReportsEndpoints.metricKeys,
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
        BloodReportsEndpoints.trends,
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
        BloodReportsEndpoints.monthlyComparison,
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
        BloodReportsEndpoints.generateReport,
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
      
      // Create a Dio instance for download
      final dio = Dio();
      dio.options.connectTimeout = const Duration(minutes: 5);
      dio.options.receiveTimeout = const Duration(minutes: 5);
      
      // Build full URL if downloadUrl is relative
      final fullUrl = downloadUrl.startsWith('http') 
          ? downloadUrl 
          : '${dotenv.env['BASE_API_URL']}$downloadUrl';
      
      print('📥 Downloading from: $fullUrl');
      print('💾 Saving to: $filePath');
      
      // Download the file from the server
      final response = await dio.download(
        fullUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            print('📥 Download progress: ${(received / total * 100).toStringAsFixed(0)}%');
          }
        },
      );
      
      if (response.statusCode == 200) {
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
          message: 'Échec du téléchargement: Code ${response.statusCode}',
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