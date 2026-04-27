import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../data/models/blood_request_model.dart';

/// Service for exporting blood requests to PDF and CSV formats
class BloodRequestExportService {
  /// Export blood requests to PDF
  static Future<File> exportToPdf({
    required List<BloodRequestModel> requests,
    String? title,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    final now = DateTime.now();
    
    final exportTitle = title ?? 'Blood Requests Export';
    
    // Create PDF pages
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return [
            // Header with gradient banner
            pw.Container(
              height: 60,
              decoration: const pw.BoxDecoration(
                gradient: pw.LinearGradient(
                  colors: [PdfColors.red, PdfColors.blue, PdfColors.amber],
                  begin: pw.Alignment.topLeft,
                  end: pw.Alignment.bottomRight,
                ),
                borderRadius: pw.BorderRadius.all(pw.Radius.circular(8)),
              ),
            ),
            pw.SizedBox(height: 16),
            
            // Title
            pw.Text(
              exportTitle,
              style: pw.TextStyle(
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.red,
              ),
            ),
            pw.SizedBox(height: 8),
            
            // Export info
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Total: ${requests.length} requests',
                  style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                ),
                pw.Text(
                  'Exported: ${dateFormat.format(now)}',
                  style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
                ),
              ],
            ),
            pw.SizedBox(height: 16),
            
            // Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              columnWidths: {
                0: const pw.FlexColumnWidth(1.5), // ID
                1: const pw.FlexColumnWidth(1.5), // Status
                2: const pw.FlexColumnWidth(1.5), // Urgency
                3: const pw.FlexColumnWidth(2), // Patient Blood Type
                4: const pw.FlexColumnWidth(1.5), // Units
                5: const pw.FlexColumnWidth(2), // Amount
                6: const pw.FlexColumnWidth(2), // Created
              },
              children: [
                // Header row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  children: [
                    _buildTableCell('ID', isHeader: true),
                    _buildTableCell('Status', isHeader: true),
                    _buildTableCell('Urgency', isHeader: true),
                    _buildTableCell('Blood Type', isHeader: true),
                    _buildTableCell('Units', isHeader: true),
                    _buildTableCell('Amount', isHeader: true),
                    _buildTableCell('Created', isHeader: true),
                  ],
                ),
                // Data rows
                ...requests.map((request) {
                  return pw.TableRow(
                    children: [
                      _buildTableCell(request.identifier),
                      _buildTableCell(_formatStatus(request.status)),
                      _buildTableCell(_formatUrgency(request.urgencyLevel)),
                      _buildTableCell(request.patientBloodTypeDisplay),
                      _buildTableCell(request.totalUnitsRequested.toString()),
                      _buildTableCell(_formatAmount(request.ebloodFee, request.refCurrencyId)),
                      _buildTableCell(
                        request.createdDateTime != null
                          ? dateFormat.format(request.createdDateTime!)
                          : '-'
                      ),
                    ],
                  );
                }),
              ],
            ),
            
            pw.SizedBox(height: 24),
            
            // Footer
            pw.Divider(color: PdfColors.grey300),
            pw.SizedBox(height: 8),
            pw.Text(
              'E-Blood Bank Management System',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              textAlign: pw.TextAlign.center,
            ),
          ];
        },
      ),
    );
    
    // Save to file
    final bytes = await pdf.save();
    final tempDir = await getTemporaryDirectory();
    final timestamp = now.millisecondsSinceEpoch;
    final file = File('${tempDir.path}/blood_requests_$timestamp.pdf');
    await file.writeAsBytes(bytes);
    
    return file;
  }
  
  /// Export blood requests to CSV
  static Future<File> exportToCsv({
    required List<BloodRequestModel> requests,
  }) async {
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    // Prepare CSV data
    List<List<dynamic>> rows = [
      // Header row
      [
        'ID',
        'Status',
        'Urgency Level',
        'Request Type',
        'Patient Blood Type',
        'Total Units',
        'Amount',
        'Currency',
        'Clinical Indication',
        'Notes',
        'Created At',
        'Requested Delivery Time',
      ],
    ];

    // Data rows
    for (var request in requests) {
      rows.add([
        request.identifier,
        _formatStatus(request.status),
        _formatUrgency(request.urgencyLevel),
        _formatRequestType(request.requestType),
        request.patientBloodTypeDisplay,
        request.totalUnitsRequested,
        request.ebloodFee ?? 0,
        request.refCurrencyId ?? '-',
        request.clinicalIndication,
        request.notes ?? '-',
        request.createdDateTime != null ? dateFormat.format(request.createdDateTime!) : '-',
        request.deliveryDateTime != null
          ? dateFormat.format(request.deliveryDateTime!)
          : '-',
      ]);
    }
    
    // Convert to CSV string
    String csv = const ListToCsvConverter().convert(rows);
    
    // Save to file
    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${tempDir.path}/blood_requests_$timestamp.csv');
    await file.writeAsString(csv);
    
    return file;
  }
  
  /// Build a table cell for PDF
  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: isHeader ? 10 : 9,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: isHeader ? PdfColors.black : PdfColors.grey800,
        ),
        textAlign: isHeader ? pw.TextAlign.center : pw.TextAlign.left,
      ),
    );
  }
  
  /// Format status for display
  static String _formatStatus(String? status) {
    if (status == null) return '-';
    return status.replaceAll('_', ' ').toUpperCase();
  }
  
  /// Format urgency level for display
  static String _formatUrgency(String? urgency) {
    if (urgency == null) return '-';
    return urgency.replaceAll('_', ' ').toUpperCase();
  }
  
  /// Format request type for display
  static String _formatRequestType(String? type) {
    if (type == null) return '-';
    return type.replaceAll('_', ' ').toUpperCase();
  }
  
  /// Format amount with currency
  static String _formatAmount(double? amount, String? currency) {
    if (amount == null) return '-';
    final formatted = NumberFormat('#,##0.00').format(amount);
    return currency != null ? '$formatted $currency' : formatted;
  }
}

