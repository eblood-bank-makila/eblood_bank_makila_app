import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';

class ReportHistory {
  final String id;
  final String fileName;
  final String filePath;
  final String reportType;
  final String format;
  final int fileSizeBytes;
  final DateTime generatedAt;
  final String downloadUrl;

  ReportHistory({
    required this.id,
    required this.fileName,
    required this.filePath,
    required this.reportType,
    required this.format,
    required this.fileSizeBytes,
    required this.generatedAt,
    required this.downloadUrl,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'fileName': fileName,
        'filePath': filePath,
        'reportType': reportType,
        'format': format,
        'fileSizeBytes': fileSizeBytes,
        'generatedAt': generatedAt.toIso8601String(),
        'downloadUrl': downloadUrl,
      };

  factory ReportHistory.fromJson(Map<String, dynamic> json) {
    return ReportHistory(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      filePath: json['filePath'] as String,
      reportType: json['reportType'] as String,
      format: json['format'] as String,
      fileSizeBytes: json['fileSizeBytes'] as int,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      downloadUrl: json['downloadUrl'] as String,
    );
  }

  // Check if the file still exists on disk
  Future<bool> fileExists() async {
    try {
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  // Get actual file size (in case it changed)
  Future<int> getActualFileSize() async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        return await file.length();
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }
}

class ReportHistoryService {
  static const String _storageKey = 'blood_report_history';
  static const int _maxHistoryItems = 50;

  /// Get all report history
  Future<List<ReportHistory>> getHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey) ?? '[]';
      final List<dynamic> jsonList = json.decode(jsonStr);
      
      final history = jsonList
          .map((j) => ReportHistory.fromJson(j as Map<String, dynamic>))
          .toList();
      
      // Sort by generated date, most recent first
      history.sort((a, b) => b.generatedAt.compareTo(a.generatedAt));
      
      return history;
    } catch (e) {
      print('Error loading report history: $e');
      return [];
    }
  }

  /// Add a new report to history
  Future<void> addToHistory(ReportHistory report) async {
    try {
      final history = await getHistory();
      
      // Remove duplicate if exists (same id)
      history.removeWhere((r) => r.id == report.id);
      
      // Add to beginning
      history.insert(0, report);
      
      // Keep only last N reports
      if (history.length > _maxHistoryItems) {
        // Delete old files before removing from history
        final itemsToRemove = history.sublist(_maxHistoryItems);
        for (final item in itemsToRemove) {
          await _deleteFileIfExists(item.filePath);
        }
        history.removeRange(_maxHistoryItems, history.length);
      }
      
      await _saveHistory(history);
    } catch (e) {
      print('Error adding to report history: $e');
    }
  }

  /// Delete a specific report
  Future<bool> deleteReport(String id) async {
    try {
      final history = await getHistory();
      final reportToDelete = history.firstWhere(
        (r) => r.id == id,
        orElse: () => throw Exception('Report not found'),
      );
      
      // Delete file from disk
      await _deleteFileIfExists(reportToDelete.filePath);
      
      // Remove from history
      history.removeWhere((r) => r.id == id);
      await _saveHistory(history);
      
      return true;
    } catch (e) {
      print('Error deleting report: $e');
      return false;
    }
  }

  /// Clear all history
  Future<bool> clearHistory() async {
    try {
      final history = await getHistory();
      
      // Delete all files
      for (final report in history) {
        await _deleteFileIfExists(report.filePath);
      }
      
      // Clear history
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
      
      return true;
    } catch (e) {
      print('Error clearing report history: $e');
      return false;
    }
  }

  /// Clear old reports (older than specified days)
  Future<int> clearOldReports({int daysOld = 30}) async {
    try {
      final history = await getHistory();
      final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));
      
      final oldReports = history.where((r) => r.generatedAt.isBefore(cutoffDate)).toList();
      
      int deletedCount = 0;
      for (final report in oldReports) {
        final success = await deleteReport(report.id);
        if (success) deletedCount++;
      }
      
      return deletedCount;
    } catch (e) {
      print('Error clearing old reports: $e');
      return 0;
    }
  }

  /// Get total storage used by reports
  Future<int> getTotalStorageUsed() async {
    try {
      final history = await getHistory();
      int totalBytes = 0;
      
      for (final report in history) {
        final actualSize = await report.getActualFileSize();
        totalBytes += actualSize;
      }
      
      return totalBytes;
    } catch (e) {
      print('Error calculating storage: $e');
      return 0;
    }
  }

  /// Clean up reports with missing files
  Future<int> cleanupMissingFiles() async {
    try {
      final history = await getHistory();
      final missingReports = <ReportHistory>[];
      
      for (final report in history) {
        if (!await report.fileExists()) {
          missingReports.add(report);
        }
      }
      
      // Remove missing reports from history
      history.removeWhere((r) => missingReports.any((m) => m.id == r.id));
      await _saveHistory(history);
      
      return missingReports.length;
    } catch (e) {
      print('Error cleaning up missing files: $e');
      return 0;
    }
  }

  /// Get history statistics
  Future<Map<String, dynamic>> getStatistics() async {
    try {
      final history = await getHistory();
      final totalStorage = await getTotalStorageUsed();
      
      // Count by report type
      final Map<String, int> byType = {};
      for (final report in history) {
        byType[report.reportType] = (byType[report.reportType] ?? 0) + 1;
      }
      
      // Count by format
      final Map<String, int> byFormat = {};
      for (final report in history) {
        byFormat[report.format] = (byFormat[report.format] ?? 0) + 1;
      }
      
      return {
        'total_reports': history.length,
        'total_storage_bytes': totalStorage,
        'by_type': byType,
        'by_format': byFormat,
        'oldest_report': history.isEmpty ? null : history.last.generatedAt,
        'newest_report': history.isEmpty ? null : history.first.generatedAt,
      };
    } catch (e) {
      print('Error getting statistics: $e');
      return {};
    }
  }

  // Private helper methods
  
  Future<void> _saveHistory(List<ReportHistory> history) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = json.encode(history.map((r) => r.toJson()).toList());
      await prefs.setString(_storageKey, jsonStr);
    } catch (e) {
      print('Error saving history: $e');
    }
  }

  Future<void> _deleteFileIfExists(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        print('🗑️ Deleted file: $filePath');
      }
    } catch (e) {
      print('Error deleting file $filePath: $e');
    }
  }
}
