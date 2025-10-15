import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import '../service/BloodReportsApiService.dart';
import '../service/ReportHistoryService.dart';
import 'BloodReportsController.dart';
import '../../../apps/config/api/ApiConfig.dart';

// Report Export State
class BloodReportExportState {
  final bool isExporting;
  final bool isDownloading;
  final String? filePath;
  final String? fileName;
  final int? fileSizeBytes;
  final String? error;
  final String? currentReportType;
  final String? fileUuid;

  BloodReportExportState({
    this.isExporting = false,
    this.isDownloading = false,
    this.filePath,
    this.fileName,
    this.fileSizeBytes,
    this.error,
    this.currentReportType,
    this.fileUuid,
  });

  BloodReportExportState copyWith({
    bool? isExporting,
    bool? isDownloading,
    Object? filePath = _undefined,
    String? fileName,
    int? fileSizeBytes,
    Object? error = _undefined,
    String? currentReportType,
    String? fileUuid,
  }) {
    return BloodReportExportState(
      isExporting: isExporting ?? this.isExporting,
      isDownloading: isDownloading ?? this.isDownloading,
      filePath: filePath == _undefined ? this.filePath : filePath as String?,
      fileName: fileName ?? this.fileName,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      error: error == _undefined ? this.error : error as String?,
      currentReportType: currentReportType ?? this.currentReportType,
      fileUuid: fileUuid ?? this.fileUuid,
    );
  }
}

// Sentinel value for copyWith to distinguish between null and not provided
const _undefined = Object();

// Report Export Controller
class BloodReportExportController extends StateNotifier<BloodReportExportState> {
  final BloodReportsApiService _apiService;
  final ReportHistoryService _historyService = ReportHistoryService();

  BloodReportExportController(this._apiService) : super(BloodReportExportState());

  Future<void> exportReport({
    required String reportType, 
    String? startDate,
    String? endDate,
    String format = 'pdf',
    String? bloodBankId,
  }) async {
    // Convert Excel format to match backend expectation
    // Convert Excel format to match backend expectation
    final backendFormat = format == 'excel' ? 'excel' : 'pdf';
    
    // Update state to show exporting in progress
    state = state.copyWith(
      isExporting: true, 
      isDownloading: true, 
      error: null,
      currentReportType: reportType,
    );

    try {
      final response = await _apiService.generateBloodReport(
        reportType: reportType,
        startDate: startDate,
        endDate: endDate,
        format: backendFormat,
        bloodBankId: bloodBankId,
      );

      // Debug output to see the response data
      print('📊 Export API Response: ${response.data}');
      
      if (response.success && response.data != null) {
        // Extract response data matching backend structure
        final downloadUrl = response.data['download_url'] as String?;
        final fileName = response.data['file_name'] as String?;
        final fileGenerated = response.data['file_generated'] as bool? ?? false;
        final fileSizeBytes = response.data['file_size_bytes'] as int? ?? 0;
        final fileUuid = response.data['file_uuid'] as String?;
        
        print('📄 File generated: $fileGenerated');
        print('📁 File name: $fileName');
        print('🆔 File UUID: $fileUuid');
        print('📊 File size: ${(fileSizeBytes / 1024).toStringAsFixed(2)} KB');
        
        if (downloadUrl != null && fileGenerated) {
          // File was generated on backend, now download it
          print('🔽 Starting automatic download...');
          
          // Automatically trigger download
          final downloadResult = await _apiService.downloadReportFile(downloadUrl);
          
          if (downloadResult.success) {
            final localPath = downloadResult.data?['local_path'] as String?;
            final actualFileSize = downloadResult.data?['file_size'] as int? ?? fileSizeBytes;
            
            // ✅ Add to history
            if (localPath != null && fileName != null && fileUuid != null) {
              await _historyService.addToHistory(
                ReportHistory(
                  id: fileUuid,
                  fileName: fileName,
                  filePath: localPath,
                  reportType: reportType,
                  format: format,
                  fileSizeBytes: actualFileSize,
                  generatedAt: DateTime.now(),
                  downloadUrl: downloadUrl,
                ),
              );
              print('✅ Report added to history');
            }
            
            state = state.copyWith(
              isExporting: false,
              isDownloading: false,
              filePath: localPath,
              fileName: fileName,
              fileSizeBytes: actualFileSize,
              currentReportType: reportType,
              fileUuid: fileUuid,
              error: null,
            );
            print('✅ Report downloaded successfully (ready for preview)');
          } else {
            state = state.copyWith(
              isExporting: false,
              isDownloading: false,
              error: downloadResult.message ?? 'Failed to download generated report',
            );
            print('❌ Download failed: ${downloadResult.message}');
          }
        } else {
          state = state.copyWith(
            isExporting: false,
            isDownloading: false,
            error: fileGenerated 
                ? 'No download URL returned' 
                : 'Backend did not generate file',
          );
          print('❌ File generation issue: fileGenerated=$fileGenerated, downloadUrl=$downloadUrl');
        }
      } else {
        state = state.copyWith(
          isExporting: false,
          isDownloading: false,
          error: response.message ?? 'Failed to generate report',
        );
        print('❌ API Error: ${response.message}');
      }
    } catch (e) {
      state = state.copyWith(
        isExporting: false,
        isDownloading: false,
        error: 'Error exporting report: $e',
      );
    }
  }
  
  Future<String?> downloadReport() async {
    if (state.filePath == null) {
      state = state.copyWith(
        error: 'No file available to download',
      );
      return null;
    }
    
    state = state.copyWith(
      isDownloading: true,
      error: null,
    );
    
    try {
      // Call the API service to download the report
      final downloadUrl = state.filePath!;
      final response = await _apiService.downloadReportFile(downloadUrl);
      
      if (response.success) {
        // Return success message
        state = state.copyWith(
          isDownloading: false,
        );
        
        return response.message ?? "Report downloaded successfully";
      } else {
        // Handle download failure
        state = state.copyWith(
          isDownloading: false,
          error: response.message ?? 'Failed to download the report',
        );
        return null;
      }
    } catch (e) {
      state = state.copyWith(
        isDownloading: false,
        error: 'Error downloading report: $e',
      );
      return null;
    }
  }
}

// Provider for the export controller
final bloodReportExportControllerProvider = StateNotifierProvider<BloodReportExportController, BloodReportExportState>((ref) {
  final apiService = ref.watch(bloodReportsApiServiceProvider);
  return BloodReportExportController(apiService);
});