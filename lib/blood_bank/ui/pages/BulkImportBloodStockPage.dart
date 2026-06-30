import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iconsax/iconsax.dart';

import 'package:eblood_bank_mak_app/apps/config/theme/ColorPages.dart';
import 'package:eblood_bank_mak_app/blood_bank/controllers/bulk_import_provider.dart';

/// Bulk blood-bag import: download an Excel template, fill it, upload it.
/// The import is all-or-nothing — if any row is invalid the whole file is
/// rejected and the per-row errors are shown.
class BulkImportBloodStockPage extends ConsumerWidget {
  const BulkImportBloodStockPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(bulkImportProvider);
    final controller = ref.read(bulkImportProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(Iconsax.arrow_left, color: Colors.grey.shade800),
        ),
        title: Text(
          'bulk_import_title'.tr,
          style: GoogleFonts.ubuntu(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildIntro(),
            const SizedBox(height: 20),
            _buildStepCard(
              step: '1',
              icon: Iconsax.document_download,
              title: 'bulk_import_download_title'.tr,
              subtitle: 'bulk_import_download_desc'.tr,
              buttonLabel: 'bulk_import_download_btn'.tr,
              busy: state.isDownloading,
              onPressed: state.isDownloading || state.isUploading
                  ? null
                  : () => controller.downloadTemplate(),
            ),
            const SizedBox(height: 16),
            _buildStepCard(
              step: '2',
              icon: Iconsax.document_upload,
              title: 'bulk_import_upload_title'.tr,
              subtitle: 'bulk_import_upload_desc'.tr,
              buttonLabel: 'bulk_import_upload_btn'.tr,
              busy: state.isUploading,
              onPressed: state.isDownloading || state.isUploading
                  ? null
                  : () => controller.pickAndUpload(),
            ),
            const SizedBox(height: 20),
            _buildResult(context, state),
          ],
        ),
      ),
    );
  }

  Widget _buildIntro() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Iconsax.info_circle, color: ColorPages.COLOR_PRINCIPAL),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'bulk_import_intro'.tr,
              style: GoogleFonts.ubuntu(fontSize: 13, color: Colors.grey.shade700),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard({
    required String step,
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required bool busy,
    required VoidCallback? onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: ColorPages.COLOR_PRINCIPAL.withValues(alpha: 0.12),
                child: Text(
                  step,
                  style: GoogleFonts.ubuntu(
                    fontWeight: FontWeight.bold,
                    color: ColorPages.COLOR_PRINCIPAL,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Icon(icon, color: Colors.grey.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.ubuntu(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.ubuntu(fontSize: 13, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: ColorPages.COLOR_PRINCIPAL,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(icon, size: 18),
              label: Text(
                buttonLabel,
                style: GoogleFonts.ubuntu(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResult(BuildContext context, BulkImportState state) {
    if (state.isUploading) {
      return const SizedBox.shrink();
    }

    // Success
    if (state.isSuccess) {
      return _resultPanel(
        color: Colors.green,
        icon: Iconsax.tick_circle,
        title: 'bulk_import_success_title'.tr,
        body: Text(
          'bulk_import_success_body'.trParams({'count': '${state.createdCount}'}),
          style: GoogleFonts.ubuntu(color: Colors.grey.shade800),
        ),
      );
    }

    // Rejected (all-or-nothing) with per-row errors
    if (state.hasResult) {
      return _resultPanel(
        color: Colors.red,
        icon: Iconsax.close_circle,
        title: 'bulk_import_rejected_title'.tr,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'bulk_import_rejected_body'.tr,
              style: GoogleFonts.ubuntu(color: Colors.grey.shade800),
            ),
            const SizedBox(height: 12),
            if (state.rowErrors.isEmpty && state.hasError)
              Text(state.error!,
                  style: GoogleFonts.ubuntu(
                      fontSize: 13, color: Colors.red.shade700)),
            ...state.rowErrors.take(50).map((e) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    e.row != null
                        ? 'bulk_import_row_error'.trParams({
                            'row': '${e.row}',
                            'field': e.field,
                            'message': e.message,
                          })
                        : '${e.field}: ${e.message}',
                    style: GoogleFonts.ubuntu(
                        fontSize: 13, color: Colors.red.shade700),
                  ),
                )),
            if (state.rowErrors.length > 50)
              Text(
                'bulk_import_more_errors'.trParams(
                    {'count': '${state.rowErrors.length - 50}'}),
                style: GoogleFonts.ubuntu(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey.shade600),
              ),
          ],
        ),
      );
    }

    // Plain error (network/parse), no job result
    if (state.hasError) {
      return _resultPanel(
        color: Colors.red,
        icon: Iconsax.warning_2,
        title: 'something_went_wrong'.tr,
        body: Text(state.error!,
            style: GoogleFonts.ubuntu(color: Colors.red.shade700)),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _resultPanel({
    required Color color,
    required IconData icon,
    required String title,
    required Widget body,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.ubuntu(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          body,
        ],
      ),
    );
  }
}
