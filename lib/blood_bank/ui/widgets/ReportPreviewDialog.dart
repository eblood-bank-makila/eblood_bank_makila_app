import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:share_plus/share_plus.dart';
import 'package:csv/csv.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:open_filex/open_filex.dart';
import '../../../apps/config/theme/ColorPages.dart';

class ReportPreviewDialog extends StatefulWidget {
  final String fileName;
  final String filePath;
  final int fileSizeBytes;
  final String reportType;
  final DateTime generatedAt;
  final VoidCallback? onClose;

  const ReportPreviewDialog({
    Key? key,
    required this.fileName,
    required this.filePath,
    required this.fileSizeBytes,
    required this.reportType,
    required this.generatedAt,
    this.onClose,
  }) : super(key: key);

  @override
  State<ReportPreviewDialog> createState() => _ReportPreviewDialogState();
}

class _ReportPreviewDialogState extends State<ReportPreviewDialog> {
  bool _isLoadingContent = false;
  String? _errorMessage;
  List<List<dynamic>>? _csvData;
  String? _textContent;
  int _selectedTab = 0; // 0 = Preview, 1 = Details

  @override
  void initState() {
    super.initState();
    _loadFileContent();
  }

  Future<void> _loadFileContent() async {
    setState(() {
      _isLoadingContent = true;
      _errorMessage = null;
    });

    try {
      final file = File(widget.filePath);
      final fileFormat = _getFileFormat();

      if (fileFormat == 'csv') {
        // Read CSV content as text
        final content = await file.readAsString();
        const csvConverter = CsvToListConverter();
        _csvData = csvConverter.convert(content);
      } else if (fileFormat == 'pdf') {
        // Don't read PDF files - they're binary and will be rendered by PDFView
        // Just validate the file exists
        if (!file.existsSync()) {
          throw Exception('PDF file not found');
        }
        // PDFView will handle the binary PDF rendering
      } else {
        // For text-based formats (txt, json, etc.), read as text
        final content = await file.readAsString();
        _textContent = content.length > 5000
            ? content.substring(0, 5000) + '\n...(truncated)'
            : content;
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erreur de lecture: $e';
      });
    } finally {
      setState(() {
        _isLoadingContent = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: 900,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: ColorPages.COLOR_PRINCIPAL.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getFileFormatIcon(_getFileFormat()),
                      color: _getFileFormatColor(_getFileFormat()),
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rapport Généré',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.fileName,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Prêt',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  IconButton(
                    icon: Icon(Icons.close, color: Colors.grey.shade600),
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onClose?.call();
                    },
                  ),
                ],
              ),
            ),

            // Tab bar
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                children: [
                  _buildTabButton('Aperçu', 0, Icons.visibility),
                  _buildTabButton('Détails', 1, Icons.info_outline),
                ],
              ),
            ),

            // Content area
            Expanded(
              child: Container(
                color: Colors.grey.shade50,
                child: _selectedTab == 0
                    ? _buildPreviewTab()
                    : _buildDetailsTab(),
              ),
            ),

            // Action buttons
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                border: Border(
                  top: BorderSide(color: Colors.grey.shade200),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: Icon(Icons.folder_open, size: 18),
                      label: Text('Dossier'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      onPressed: () => _openFileLocation(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: Icon(Icons.share, size: 18),
                      label: Text('Partager'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                      onPressed: () => _shareFile(context),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.open_in_new, size: 18),
                      label: Text('Ouvrir'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ColorPages.COLOR_PRINCIPAL,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        _openFile(context);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton(String label, int index, IconData icon) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? ColorPages.COLOR_PRINCIPAL : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isSelected
                    ? ColorPages.COLOR_PRINCIPAL
                    : Colors.grey.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected
                      ? ColorPages.COLOR_PRINCIPAL
                      : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewTab() {
    if (_isLoadingContent) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Chargement du contenu...',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(color: Colors.red.shade700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: Icon(Icons.refresh),
              label: Text('Réessayer'),
              onPressed: _loadFileContent,
            ),
          ],
        ),
      );
    }

    final fileFormat = _getFileFormat();

    if (fileFormat == 'csv' && _csvData != null) {
      return _buildCsvPreview();
    } else if (fileFormat == 'pdf') {
      return _buildPdfNotice();
    } else if (_textContent != null) {
      return _buildTextPreview();
    }

    return Center(
      child: Text(
        'Aperçu non disponible pour ce format',
        style: TextStyle(color: Colors.grey.shade600),
      ),
    );
  }

  Widget _buildCsvPreview() {
    if (_csvData == null || _csvData!.isEmpty) {
      return Center(child: Text('Aucune donnée CSV'));
    }

    // Limit rows for preview
    final maxRows = 50;
    final displayData = _csvData!.take(maxRows).toList();
    final hasMore = _csvData!.length > maxRows;

    return Column(
      children: [
        if (hasMore)
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.amber.shade100,
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Colors.amber.shade900),
                const SizedBox(width: 8),
                Text(
                  'Affichage des $maxRows premières lignes sur ${_csvData!.length}',
                  style: TextStyle(fontSize: 12, color: Colors.amber.shade900),
                ),
              ],
            ),
          ),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(
                  ColorPages.COLOR_PRINCIPAL.withOpacity(0.1),
                ),
                columns: displayData.first
                    .asMap()
                    .entries
                    .map(
                      (entry) => DataColumn(
                        label: Text(
                          '${displayData.first[entry.key]}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    )
                    .toList(),
                rows: displayData
                    .skip(1)
                    .map(
                      (row) => DataRow(
                        cells: row
                            .map(
                              (cell) => DataCell(
                                Text(
                                  '$cell',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPdfNotice() {
    // Validate file exists and is a PDF before attempting to render
    final file = File(widget.filePath);

    if (!file.existsSync()) {
      return _buildErrorMessage('Le fichier PDF n\'existe pas à l\'emplacement spécifié.\n\nChemin: ${widget.filePath}');
    }

    // Check if file is actually a PDF by reading first few bytes
    try {
      final bytes = file.readAsBytesSync();
      if (bytes.length < 4 || String.fromCharCodes(bytes.take(4)) != '%PDF') {
        return _buildErrorMessage('Le fichier n\'est pas au format PDF valide.\n\nFormat détecté: ${String.fromCharCodes(bytes.take(10))}');
      }
    } catch (e) {
      return _buildErrorMessage('Impossible de lire le fichier: $e');
    }

    // Show actual PDF preview using flutter_pdfview
    return Container(
      color: Colors.grey.shade100,
      child: PDFView(
        filePath: widget.filePath,
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: true,
        pageFling: true,
        pageSnap: true,
        defaultPage: 0,
        fitPolicy: FitPolicy.WIDTH,
        preventLinkNavigation: false,
        onRender: (pages) {
          print('✅ PDF rendered successfully with $pages pages');
        },
        onError: (error) {
          print('❌ PDF error: $error');
          setState(() {
            _errorMessage = 'Erreur PDF: $error';
          });
        },
        onPageError: (page, error) {
          print('❌ PDF page $page error: $error');
        },
        onViewCreated: (PDFViewController pdfViewController) {
          print('✅ PDF view created successfully');
        },
        onPageChanged: (int? page, int? total) {
          print('📄 PDF page changed to ${(page ?? 0) + 1} of $total');
        },
      ),
    );
  }

  Widget _buildErrorMessage(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.shade300,
            ),
            const SizedBox(height: 16),
            Text(
              'Erreur de prévisualisation',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _openFile(context),
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Ouvrir avec...'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    side: BorderSide(color: ColorPages.COLOR_PRINCIPAL),
                    foregroundColor: ColorPages.COLOR_PRINCIPAL,
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: () => _loadFileContent(),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: ColorPages.COLOR_PRINCIPAL,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextPreview() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: SelectableText(
          _textContent ?? 'no_content'.tr,
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
            color: Colors.grey.shade800,
          ),
        ),
      ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            _buildInfoRow(
              'Nom du fichier',
              widget.fileName,
              Icons.description_outlined,
            ),
            const Divider(height: 32),
            _buildInfoRow(
              'Taille',
              _formatFileSize(widget.fileSizeBytes),
              Icons.storage_outlined,
            ),
            const Divider(height: 32),
            _buildInfoRow(
              'Type de rapport',
              _formatReportType(widget.reportType),
              Icons.assessment_outlined,
            ),
            const Divider(height: 32),
            _buildInfoRow(
              'Format',
              _getFileFormat().toUpperCase(),
              Icons.insert_drive_file_outlined,
            ),
            const Divider(height: 32),
            _buildInfoRow(
              'Généré le',
              _formatDateTime(widget.generatedAt),
              Icons.access_time_outlined,
            ),
            const Divider(height: 32),
            _buildInfoRow(
              'Emplacement',
              _truncatePath(widget.filePath),
              Icons.folder_outlined,
              isPath: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    String label,
    String value,
    IconData icon, {
    bool isPath = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade800,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: isPath ? 2 : 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getFileFormat() {
    final extension = widget.fileName.split('.').last.toLowerCase();
    return extension;
  }

  IconData _getFileFormatIcon(String format) {
    switch (format) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'csv':
        return Icons.table_chart;
      case 'xlsx':
      case 'excel':
        return Icons.grid_on;
      default:
        return Icons.description;
    }
  }

  Color _getFileFormatColor(String format) {
    switch (format) {
      case 'pdf':
        return Colors.red;
      case 'csv':
        return Colors.green;
      case 'xlsx':
      case 'excel':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(2)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  String _formatReportType(String type) {
    return type
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word.isEmpty
            ? ''
            : '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  String _formatDateTime(DateTime dt) {
    final months = [
      'Jan',
      'Fév',
      'Mar',
      'Avr',
      'Mai',
      'Juin',
      'Juil',
      'Aoû',
      'Sep',
      'Oct',
      'Nov',
      'Déc'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year} à ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  String _truncatePath(String path) {
    if (path.length <= 50) return path;
    return '...${path.substring(path.length - 47)}';
  }

  void _openFile(BuildContext context) async {
    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 16),
              Text('Ouverture du fichier...'),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      // Open file with system default application
      final result = await OpenFilex.open(widget.filePath);

      print('📂 Open file result: ${result.type} - ${result.message}');

      // Check result and show appropriate message
      if (result.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Impossible d\'ouvrir le fichier',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(result.message),
                SizedBox(height: 4),
                Text('Chemin: ${widget.filePath}', style: TextStyle(fontSize: 11)),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Partager',
              textColor: Colors.white,
              onPressed: () => _shareFile(context),
            ),
          ),
        );
      }
    } catch (e) {
      print('❌ Error opening file: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Erreur lors de l\'ouverture du fichier',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text('$e'),
            ],
          ),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Partager',
            textColor: Colors.white,
            onPressed: () => _shareFile(context),
          ),
        ),
      );
    }
  }

  void _shareFile(BuildContext context) async {
    try {
      await Share.shareXFiles(
        [XFile(widget.filePath)],
        text: 'Rapport: ${widget.fileName}',
        subject: 'Rapport E-Blood - ${widget.fileName}',
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors du partage: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _openFileLocation(BuildContext context) {
    // Get the directory path
    final file = File(widget.filePath);
    final directory = file.parent.path;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Emplacement: $directory'),
        duration: Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Copier',
          textColor: Colors.white,
          onPressed: () {
            // Copy to clipboard would go here if we had clipboard package
          },
        ),
      ),
    );
  }
}
