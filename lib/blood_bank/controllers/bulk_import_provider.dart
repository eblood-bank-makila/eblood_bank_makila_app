import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import 'package:eblood_bank_mak_app/blood_bank/business/service/BloodBagBulkImportApiService.dart';

/// A single per-row validation error returned by the all-or-nothing import.
class BulkRowError {
  final int? row;
  final String field;
  final String message;
  const BulkRowError({this.row, required this.field, required this.message});
}

class BulkImportState {
  final bool isDownloading;
  final bool isUploading;

  /// Non-empty when something went wrong (network/parse). Empty string clears it.
  final String? error;

  /// 'completed' | 'validation_failed' | 'failed' | null (no import run yet).
  final String? jobStatus;
  final int createdCount;
  final int rejectedCount;
  final List<BulkRowError> rowErrors;
  final String? lastFileName;

  const BulkImportState({
    this.isDownloading = false,
    this.isUploading = false,
    this.error,
    this.jobStatus,
    this.createdCount = 0,
    this.rejectedCount = 0,
    this.rowErrors = const [],
    this.lastFileName,
  });

  bool get hasError => error != null && error!.isNotEmpty;
  bool get hasResult => jobStatus != null;
  bool get isSuccess => jobStatus == 'completed';

  BulkImportState copyWith({
    bool? isDownloading,
    bool? isUploading,
    String? error,
    String? jobStatus,
    int? createdCount,
    int? rejectedCount,
    List<BulkRowError>? rowErrors,
    String? lastFileName,
  }) {
    return BulkImportState(
      isDownloading: isDownloading ?? this.isDownloading,
      isUploading: isUploading ?? this.isUploading,
      error: error ?? this.error,
      jobStatus: jobStatus ?? this.jobStatus,
      createdCount: createdCount ?? this.createdCount,
      rejectedCount: rejectedCount ?? this.rejectedCount,
      rowErrors: rowErrors ?? this.rowErrors,
      lastFileName: lastFileName ?? this.lastFileName,
    );
  }
}

class BulkImportController extends StateNotifier<BulkImportState> {
  final BloodBagBulkImportApiService _api;

  BulkImportController(this._api) : super(const BulkImportState());

  void reset() => state = const BulkImportState();

  /// Download the template to a temp file and open it with the OS viewer.
  /// Returns the local path on success, null otherwise.
  Future<String?> downloadTemplate() async {
    state = state.copyWith(isDownloading: true, error: '');
    try {
      final dir = await getTemporaryDirectory();
      final savePath = '${dir.path}/blood_bag_import_template.xlsx';

      // Remove any stale file from a previous (possibly failed) attempt so we
      // never open a leftover/error file.
      final file = File(savePath);
      if (await file.exists()) {
        try {
          await file.delete();
        } catch (_) {}
      }

      final res = await _api.downloadTemplate(savePath);

      // Guard against a "successful" download that actually wrote an error body
      // (e.g. a small JSON 403/500) instead of a real .xlsx. A valid template is
      // several KB and starts with the ZIP magic bytes "PK".
      final exists = await file.exists();
      final len = exists ? await file.length() : 0;
      bool looksLikeXlsx = false;
      if (len > 0) {
        try {
          final head = await file.openRead(0, 2).first;
          looksLikeXlsx = head.length >= 2 && head[0] == 0x50 && head[1] == 0x4B; // "PK"
        } catch (_) {}
      }

      if (res.success && exists && len > 200 && looksLikeXlsx) {
        state = state.copyWith(isDownloading: false);
        await OpenFilex.open(savePath);
        return savePath;
      }

      // Clean up the bad file and surface a clear error.
      if (exists) {
        try {
          await file.delete();
        } catch (_) {}
      }
      state = state.copyWith(
        isDownloading: false,
        error: res.message != null && res.message!.isNotEmpty
            ? res.message
            : 'bulk_import_download_failed'.tr,
      );
      return null;
    } catch (e) {
      debugPrint('Error downloading template: $e');
      state = state.copyWith(isDownloading: false, error: e.toString());
      return null;
    }
  }

  /// Pick an .xlsx/.csv and upload it. No-op if the user cancels.
  Future<void> pickAndUpload() async {
    try {
      final picked = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['xlsx', 'xls', 'csv'],
        withData: false,
      );
      if (picked == null || picked.files.isEmpty) return; // cancelled
      final pf = picked.files.single;
      final path = pf.path;
      if (path == null || path.isEmpty) {
        state = state.copyWith(error: 'bulk_import_file_read_failed'.tr);
        return;
      }
      await _upload(path, pf.name);
    } catch (e) {
      debugPrint('Error picking/uploading file: $e');
      state = state.copyWith(isUploading: false, error: e.toString());
    }
  }

  Future<void> _upload(String path, String filename) async {
    // Fresh state for a new run (clears any previous result/error).
    state = BulkImportState(isUploading: true, lastFileName: filename);
    final res = await _api.uploadExcel(path, filename);

    if (!res.success || res.data == null) {
      state = state.copyWith(
        isUploading: false,
        error: res.message ?? 'bulk_import_failed'.tr,
      );
      return;
    }

    final job = (res.data is Map)
        ? Map<String, dynamic>.from(res.data as Map)
        : <String, dynamic>{};
    final status = (job['status'] ?? '').toString();

    if (status == 'completed') {
      final created = _toInt(job['successful_records']) ?? _summaryCreated(job);
      state = state.copyWith(
        isUploading: false,
        jobStatus: 'completed',
        createdCount: created,
        rowErrors: const [],
      );
      return;
    }

    // validation_failed / failed → surface per-row errors.
    final errors = <BulkRowError>[];
    final raw = job['validation_errors'];
    if (raw is List) {
      for (final e in raw) {
        if (e is Map) {
          errors.add(BulkRowError(
            row: _toInt(e['row']),
            field: (e['field'] ?? '').toString(),
            message: (e['message'] ?? '').toString(),
          ));
        }
      }
    }
    state = state.copyWith(
      isUploading: false,
      jobStatus: status.isEmpty ? 'failed' : status,
      rejectedCount: _toInt(job['failed_records']) ?? errors.length,
      rowErrors: errors,
      error: errors.isEmpty ? (job['error_log']?.toString() ?? '') : '',
    );
  }

  int? _toInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  int _summaryCreated(Map job) {
    final s = job['import_summary'];
    if (s is Map && s['created'] != null) return _toInt(s['created']) ?? 0;
    return 0;
  }
}

final bulkImportProvider =
    StateNotifierProvider<BulkImportController, BulkImportState>((ref) {
  return BulkImportController(ref.watch(bloodBagBulkImportApiServiceProvider));
});
