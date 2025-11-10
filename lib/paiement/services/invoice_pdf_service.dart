import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Lightweight PDF generator for payment receipt/invoice
/// Uses only data provided; callers can enrich the map with extra fields as needed.
class InvoicePdfService {
  /// Generates a simple, brand-styled payment receipt PDF.
  ///
  /// Expected keys in [invoice]:
  /// - title (String)
  /// - message (String)
  /// - ref (String)                // Onafriq transaction ref
  /// - system_identifier (String)  // Internal identifier
  /// - amount_text (String)        // Formatted amount with currency
  /// - date_text (String)          // Localized date/time string
  /// - provider (String)           // e.g., "Mobile Money (Onafriq)"
  /// - items (List<Map>)           // Optional itemized lines
  /// - totals (Map)                // Optional totals breakdown
  static Future<Uint8List> generateReceipt({
    required Map<String, dynamic> invoice,
  }) async {
    final pdf = pw.Document();

    final title = (invoice['title'] ?? 'Reçu de paiement').toString();
    final message = (invoice['message'] ?? '').toString();
    final ref = (invoice['ref'] ?? '-').toString();
    final identifier = (invoice['system_identifier'] ?? '-').toString();
    final amountText = (invoice['amount_text'] ?? '-').toString();
    final dateText = (invoice['date_text'] ?? '').toString();
    final provider = (invoice['provider'] ?? 'Mobile Money').toString();

    final baseText = pw.TextStyle(fontSize: 11);
    final labelStyle = pw.TextStyle(fontSize: 10, color: PdfColors.grey700);
    final valueStyle = pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold);
    final titleStyle = pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.red);

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // Top banner
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
              pw.SizedBox(height: 12),

              // Card-like body
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  borderRadius: pw.BorderRadius.circular(8),
                  boxShadow: [
                    pw.BoxShadow(color: PdfColors.grey300, blurRadius: 6, offset: const PdfPoint(0, 2)),
                  ],
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    // Title
                    pw.Text(title, style: titleStyle),
                    if (message.isNotEmpty) ...[
                      pw.SizedBox(height: 8),
                      pw.Text(message, style: baseText),
                    ],

                    pw.SizedBox(height: 16),

                    // Key details
                    _kvRow('Date', dateText, labelStyle, valueStyle),
                    _kvRow('Référence paiement', ref, labelStyle, valueStyle),
                    _kvRow('Référence système', identifier, labelStyle, valueStyle),
                    _kvRow('Montant', amountText, labelStyle, valueStyle),
                    _kvRow('Méthode', provider, labelStyle, valueStyle),

                    // Optional items table
                    if (invoice['items'] is List && (invoice['items'] as List).isNotEmpty) ...[
                      pw.SizedBox(height: 16),
                      pw.Text('Détails', style: baseText.copyWith(fontWeight: pw.FontWeight.bold)),
                      pw.SizedBox(height: 8),
                      _itemsTable(invoice['items'] as List),
                    ],

                    // Optional totals
                    if (invoice['totals'] is Map && (invoice['totals'] as Map).isNotEmpty) ...[
                      pw.SizedBox(height: 12),
                      _totalsBlock(invoice['totals'] as Map),
                    ],

                    pw.SizedBox(height: 20),
                    pw.Divider(color: PdfColors.grey300),
                    pw.SizedBox(height: 6),
                    pw.Text(
                      'Merci pour votre confiance. Conservez ce reçu pour vos dossiers.',
                      style: baseText.copyWith(color: PdfColors.grey700),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _kvRow(String label, String value, pw.TextStyle labelStyle, pw.TextStyle valueStyle) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(flex: 2, child: pw.Text(label, style: labelStyle)),
          pw.SizedBox(width: 6),
          pw.Expanded(flex: 4, child: pw.Text(value, style: valueStyle, textAlign: pw.TextAlign.right)),
        ],
      ),
    );
  }

  static pw.Widget _itemsTable(List items) {
    final headers = <String>['Article', 'Qté', 'PU', 'Total'];
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: [
        for (final it in items)
          [
            (it['name'] ?? '-').toString(),
            (it['qty'] ?? '').toString(),
            (it['unit_price'] ?? '').toString(),
            (it['total'] ?? '').toString(),
          ]
      ],
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey800),
      cellStyle: const pw.TextStyle(fontSize: 10),
      cellAlignment: pw.Alignment.centerLeft,
      headerAlignment: pw.Alignment.centerLeft,
      border: null,
      rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
      headerHeight: 22,
      cellHeight: 20,
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(2),
      },
    );
  }

  static pw.Widget _totalsBlock(Map totals) {
    final labelStyle = const pw.TextStyle(fontSize: 10, color: PdfColors.grey700);
    final valueStyle = pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold);

    List<pw.Widget> rows = [];
    totals.forEach((key, value) {
      rows.add(_kvRow(key.toString(), value.toString(), labelStyle, valueStyle));
    });

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: rows,
    );
  }
}

