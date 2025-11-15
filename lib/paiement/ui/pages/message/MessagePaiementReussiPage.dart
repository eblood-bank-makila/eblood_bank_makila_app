import 'package:animate_do/animate_do.dart';
import '../../../../apps/config/theme/ColorPages.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:flutter_svg/flutter_svg.dart';
import 'dart:io';

import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import '../../../../apps/config/api/dio_client.dart';
import '../../../services/invoice_pdf_service.dart';
import '../invoice/InvoiceViewerPage.dart';
import 'package:get/get.dart';



class OpsSuccessScreen extends StatefulWidget {
  final message;
  final title;
  final VoidCallback onClosing;
  final bool hidde_all_btn;
  final String? ref;
  final String? amountText;
  final String? bloodRequestId;
  final String? systemIdentifier;


  const OpsSuccessScreen({
      super.key,
      required this.message,
      required this.onClosing,
      this.title,
      required this.hidde_all_btn,
      this.ref,
      this.amountText,
      this.bloodRequestId,
      this.systemIdentifier,
    });

  @override
  State<OpsSuccessScreen> createState() => _OpsSuccessScreenState();


}

class _OpsSuccessScreenState extends State<OpsSuccessScreen> {
  bool _isProcessing = false;
  bool _isGeneratingInvoice = false;

  Future<Map<String, dynamic>> _prepareInvoiceData() async {
    final now = DateTime.now();
    final dateText = DateFormat('dd/MM/yyyy HH:mm').format(now);

    final Map<String, dynamic> map = {
      'title': widget.title?.toString() ?? 'Reçu de paiement',
      'message': widget.message?.toString() ?? '',
      'ref': widget.ref ?? '-',
      'system_identifier': widget.systemIdentifier ?? (widget.bloodRequestId ?? '-'),
      'amount_text': widget.amountText ?? '-',
      'date_text': dateText,
      'provider': 'Mobile Money (Onafriq)',
      'items': <Map<String, dynamic>>[],
      'totals': <String, dynamic>{},
    };

    try {
      if (widget.bloodRequestId != null) {
        final resp = await getWithDio('/eblood-connect/blood-requests/${widget.bloodRequestId}');
        if (resp.success == true && resp.data is Map<String, dynamic>) {
          final data = resp.data as Map<String, dynamic>;
          if (data['identifier'] != null) {
            map['system_identifier'] = data['identifier'].toString();
          }
          final totals = <String, dynamic>{};
          if (data['total_amount'] != null) {
            totals['Sous-total'] = data['total_amount'].toString();
          }
          if (data['eblood_fee'] != null) {
            totals['Frais plateforme'] = data['eblood_fee'].toString();
          }
          if (data['total_amount_merged'] != null) {
            totals['Total'] = data['total_amount_merged'].toString();
          }
          if (totals.isNotEmpty) {
            map['totals'] = totals;
          }

          // Items (requested blood bags)
          final items = <Map<String, dynamic>>[];
          if (data['requested_items'] is List) {
            for (final it in (data['requested_items'] as List)) {
              if (it is Map<String, dynamic>) {
                final qtyRaw = it['quantity'] ?? 1;
                final unitRaw = it['price'];
                final binfo = (it['blood_bag_info'] ?? {}) as Map<String, dynamic>;
                final bt = ((binfo['blood_type_info'] ?? {}) as Map<String, dynamic>)['blood_type_name']?.toString() ?? '';
                final rh = ((binfo['blood_rhesus_info'] ?? {}) as Map<String, dynamic>)['blood_rheusus_name']?.toString() ?? '';
                final volInfo = ((binfo['blood_volume_info'] ?? {}) as Map<String, dynamic>);
                final volName = volInfo['blood_volume_name']?.toString();
                final volUnit = ((volInfo['blood_volume_unity_info'] ?? {}) as Map<String, dynamic>)['blood_volume_unity_name']?.toString();
                final volStr = [
                  if (volName != null && volName.isNotEmpty) volName,
                  if (volUnit != null && volUnit.isNotEmpty) volUnit,
                ].join(' ');
                final name = [
                  'Sachet',
                  [bt, rh].where((s) => s.isNotEmpty).join(' '),
                  if (volStr.isNotEmpty) '($volStr)',
                ].join(' ').trim();

                final qtyNum = qtyRaw is num ? qtyRaw : int.tryParse(qtyRaw.toString()) ?? 1;
                final unitNum = unitRaw is num ? unitRaw : num.tryParse(unitRaw?.toString() ?? '');
                final total = (unitNum != null) ? (unitNum * qtyNum) : null;

                items.add({
                  'name': name,
                  'qty': qtyNum,
                  'unit_price': unitNum != null ? unitNum.toStringAsFixed(2) : '-',
                  'total': total != null ? total.toStringAsFixed(2) : '-',
                });
              }
            }
          }
          if (items.isNotEmpty) {
            map['items'] = items;
          }
        }
      }
    } catch (_) {}

    return map;
  }

  Future<void> _downloadInvoice() async {
    if (_isGeneratingInvoice) return;
    setState(() => _isGeneratingInvoice = true);
    try {
      final invoice = await _prepareInvoiceData();
      final bytes = await InvoicePdfService.generateReceipt(invoice: invoice);
      final dir = await getApplicationDocumentsDirectory();
      final safeRef = (invoice['system_identifier'] ?? invoice['ref'] ?? 'paiement')
          .toString()
          .replaceAll(RegExp('[^a-zA-Z0-9_-]'), '_');
      final file = File('${dir.path}/recu_$safeRef.pdf');
      await file.writeAsBytes(bytes, flush: true);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reçu téléchargé: ${file.path}'),
          backgroundColor: Colors.green,
          action: SnackBarAction(
            label: 'Ouvrir',
            textColor: Colors.white,
            onPressed: () => OpenFile.open(file.path),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de la génération: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isGeneratingInvoice = false);
    }
  }

  Future<void> _shareInvoice() async {
    if (_isGeneratingInvoice) return;
    setState(() => _isGeneratingInvoice = true);
    try {
      final invoice = await _prepareInvoiceData();
      final bytes = await InvoicePdfService.generateReceipt(invoice: invoice);
      final temp = await getTemporaryDirectory();
      final safeRef = (invoice['system_identifier'] ?? invoice['ref'] ?? 'paiement')
          .toString()
          .replaceAll(RegExp('[^a-zA-Z0-9_-]'), '_');
      final file = File('${temp.path}/recu_$safeRef.pdf');
      await file.writeAsBytes(bytes, flush: true);
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Reçu de paiement E-Blood',
        subject: 'Reçu - ${invoice['ref']}',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors du partage: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isGeneratingInvoice = false);
    }
  }

  Future<void> _viewInvoice() async {
    if (_isGeneratingInvoice) return;
    setState(() => _isGeneratingInvoice = true);
    try {
      final invoice = await _prepareInvoiceData();
      final bytes = await InvoicePdfService.generateReceipt(invoice: invoice);
      final temp = await getTemporaryDirectory();
      final safeRef = (invoice['system_identifier'] ?? invoice['ref'] ?? 'paiement')
          .toString()
          .replaceAll(RegExp('[^a-zA-Z0-9_-]'), '_');
      final file = File('${temp.path}/recu_$safeRef.pdf');
      await file.writeAsBytes(bytes, flush: true);
      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => InvoiceViewerPage(
            filePath: file.path,
            title: 'Reçu - ${invoice['ref'] ?? safeRef}',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur lors de l\'ouverture du reçu: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isGeneratingInvoice = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Set status bar style to dark (black icons/text) for light background
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark, // Dark icons for light background
        statusBarBrightness: Brightness.light, // For iOS
      ),
    );

    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.green.shade100,
            Colors.green.shade50,
            Colors.white,
          ],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 60.0),

          // Icon Badge
          FadeInDown(
            from: 60,
            duration: const Duration(milliseconds: 900),
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Center(
                child: Icon(
                  Icons.check_circle_outline_rounded,
                  size: 60,
                  color: Colors.green,
                ),
              ),
            ),
          ),

          const SizedBox(height: 30.0),

          // Title
          FadeInUp(
            from: 70,
            duration: const Duration(milliseconds: 1000),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Text(
                widget.title ?? 'operation_successful'.tr,
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          const SizedBox(height: 16.0),

          // Message
          FadeInUp(
            from: 85,
            duration: const Duration(milliseconds: 1000),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Text(
                widget.message,
                style: TextStyle(
                  fontWeight: FontWeight.normal,
                  fontSize: 15,
                  color: Colors.grey.shade700,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),

          // Info Card
          if (widget.ref != null || widget.amountText != null) ...[
            const SizedBox(height: 24),
            FadeInUp(
              from: 90,
              duration: const Duration(milliseconds: 1000),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 24.0),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (widget.ref != null) ...[
                      Row(
                        children: [
                          Icon(Icons.receipt_long, size: 20, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          Text(
                            'reference'.tr,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.ref!,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: 'copy'.tr,
                            icon: const Icon(Icons.copy, size: 18),
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: widget.ref!));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('reference_copied'.tr)),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                    if (widget.amountText != null) ...[
                      if (widget.ref != null) const SizedBox(height: 16),
                      Row(
                        children: [
                          Icon(Icons.payments_outlined, size: 20, color: Colors.grey.shade600),
                          const SizedBox(width: 8),
                          const Text(
                            'Montant',
                            style: TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        widget.amountText!,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],

          const Spacer(),

          // Invoice Actions
          if (widget.hidde_all_btn == false && (widget.ref != null || widget.bloodRequestId != null)) ...[
            FadeInUp(
              from: 60,
              duration: const Duration(milliseconds: 700),
              child: Center(
                child: TextButton.icon(
                  onPressed: _isGeneratingInvoice ? null : _viewInvoice,
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Voir le reçu'),
                ),
              ),
            ),
            const SizedBox(height: 8),
            FadeInUp(
              from: 90,
              duration: const Duration(milliseconds: 900),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isGeneratingInvoice ? null : _downloadInvoice,
                        icon: const Icon(Icons.download, color: Colors.white),
                        label: const Text('Télécharger reçu'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(48),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _isGeneratingInvoice ? null : _shareInvoice,
                        icon: const Icon(Icons.share),
                        label: const Text('Partager'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Close Button
          if (widget.hidde_all_btn == false)
            FadeInUp(
              from: 90,
              duration: const Duration(milliseconds: 1000),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Material(
                  elevation: 0,
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.green,
                  child: MaterialButton(
                    onPressed: _isProcessing ? null : () {
                      if (_isProcessing) return;
                      setState(() {
                        _isProcessing = true;
                      });
                      try {
                        debugPrint('🔘 Close button pressed (Success screen)');
                        widget.onClosing();
                      } catch (e) {
                        debugPrint('❌ Error in onClosing: $e');
                        setState(() {
                          _isProcessing = false;
                        });
                      }
                    },
                    minWidth: double.infinity,
                    height: 54,
                    child: Text(
                      'close'.tr,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ),

          const SizedBox(height: 30.0),
        ],
      ),
    );
  }
}
