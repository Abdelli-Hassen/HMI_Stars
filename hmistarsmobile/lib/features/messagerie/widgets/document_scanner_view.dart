import 'package:flutter/material.dart';
import 'package:flutter_document_scanner/flutter_document_scanner.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';
import '../../../core/widgets/top_notification_banner.dart';
import '../../../core/utils/translation_extension.dart';

class DocumentScannerView extends StatefulWidget {
  final Function(String pdfPath) onScanCompleted;

  const DocumentScannerView({super.key, required this.onScanCompleted});

  @override
  State<DocumentScannerView> createState() => _DocumentScannerViewState();
}

class _DocumentScannerViewState extends State<DocumentScannerView> {
  final DocumentScannerController _controller = DocumentScannerController();
  bool _isProcessing = false;

  Future<void> _handleSave(Uint8List imageBytes) async {
    setState(() => _isProcessing = true);
    try {
      // Create PDF document
      final pdf = pw.Document();
      final image = pw.MemoryImage(imageBytes);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Image(image, fit: pw.BoxFit.contain),
            );
          },
        ),
      );

      // Save PDF to temp directory
      final outputDir = await getTemporaryDirectory();
      final fileName = 'scan_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${outputDir.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      if (mounted) {
        widget.onScanCompleted(file.path);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        TopNotificationBanner.show(
          context,
          '${context.trStatic('Erreur lors de la création du PDF', 'Error creating PDF')}: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.tr('Scanner un document', 'Scan a document')),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          DocumentScanner(
            controller: _controller,
            onSave: _handleSave,
            resolutionCamera: ResolutionPreset.high,
            generalStyles: const GeneralStyles(
              baseColor: Colors.white,
            ),
          ),
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 16),
                    Text(
                      context.tr('Création du PDF...', 'Creating PDF...'),
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
