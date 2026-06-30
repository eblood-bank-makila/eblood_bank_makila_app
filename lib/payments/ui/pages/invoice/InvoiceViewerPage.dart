import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:open_filex/open_filex.dart';
import 'package:share_plus/share_plus.dart';

class InvoiceViewerPage extends StatelessWidget {
  final String filePath;
  final String? title;

  const InvoiceViewerPage({super.key, required this.filePath, this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title ?? 'Reçu de paiement'),
        actions: [
          IconButton(
            tooltip: 'Ouvrir dans une autre application',
            icon: const Icon(Icons.open_in_new),
            onPressed: () => OpenFilex.open(filePath),
          ),
          IconButton(
            tooltip: 'Partager',
            icon: const Icon(Icons.share),
            onPressed: () async {
              if (!await File(filePath).exists()) return;
              await Share.shareXFiles([XFile(filePath)], text: 'Reçu de paiement');
            },
          ),
        ],
      ),
      body: PDFView(
        filePath: filePath,
        enableSwipe: true,
        swipeHorizontal: false,
        autoSpacing: true,
        pageFling: true,
        pageSnap: true,
        nightMode: false,
      ),
    );
  }
}

