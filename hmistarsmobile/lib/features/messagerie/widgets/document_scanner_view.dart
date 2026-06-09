import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:printing/printing.dart';
import '../../../core/widgets/top_notification_banner.dart';
import '../../../core/utils/translation_extension.dart';

class DocumentScannerView extends StatefulWidget {
  final Function(String pdfPath) onScanCompleted;

  const DocumentScannerView({super.key, required this.onScanCompleted});

  @override
  State<DocumentScannerView> createState() => _DocumentScannerViewState();
}

class _DocumentScannerViewState extends State<DocumentScannerView> {
  File? _originalImage;
  Uint8List? _originalImageBytes;
  Uint8List? _processedImageBytes;
  bool _isProcessing = false;
  int _visualRotationTurns = 0;
  String _activeFilter = 'original';
  final Map<String, Uint8List> _processedCache = {};

  @override
  void initState() {
    super.initState();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        imageQuality: 95,
      );

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        final bytes = await file.readAsBytes();
        setState(() {
          _originalImage = file;
          _originalImageBytes = bytes;
          _processedImageBytes = bytes;
          _visualRotationTurns = 0;
          _activeFilter = 'original';
          _processedCache.clear();
          _processedCache['original'] = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        TopNotificationBanner.show(
          context,
          "${context.trStatic('Erreur lors de la capture', 'Error capturing image')}: $e",
          isError: true,
        );
      }
    }
  }

  // ─── TASK 2: Adaptive Thresholding via Sauvola method ──────────────────────
  // Uses integral image (summed area table) for O(n) per-pixel performance.
  // Window = 31px, k = 0.15. Result: white background, crisp dark text & lines.
  static Uint8List _applyAdaptiveThreshold(Uint8List bytes) {
    img.Image? image = img.decodeImage(bytes);
    if (image == null) return bytes;

    // Resize to a manageable size if very large (keeps processing fast)
    if (image.width > 2000 || image.height > 2000) {
      image = img.copyResize(image, width: 1600);
    }

    // Grayscale
    final gray = img.grayscale(image);
    final w = gray.width;
    final h = gray.height;

    // Build integral image (summed area table) for O(1) window sums
    final List<List<int>> integral = List.generate(
      h + 1,
      (_) => List.filled(w + 1, 0),
    );
    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final lum = gray.getPixel(x, y).r.toInt();
        integral[y + 1][x + 1] =
            lum + integral[y][x + 1] + integral[y + 1][x] - integral[y][x];
      }
    }

    const halfWin = 15; // window = 31px
    const k = 0.15;

    // Build output image (white background)
    final output = img.Image(width: w, height: h);
    img.fill(output, color: img.ColorRgb8(255, 255, 255));

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final x1 = (x - halfWin).clamp(0, w - 1);
        final y1 = (y - halfWin).clamp(0, h - 1);
        final x2 = (x + halfWin).clamp(0, w - 1);
        final y2 = (y + halfWin).clamp(0, h - 1);

        final count = (x2 - x1 + 1) * (y2 - y1 + 1);
        final sum = integral[y2 + 1][x2 + 1]
            - integral[y1][x2 + 1]
            - integral[y2 + 1][x1]
            + integral[y1][x1];

        final mean = sum / count;
        final threshold = mean * (1.0 - k);

        final lum = gray.getPixel(x, y).r.toDouble();
        if (lum < threshold) {
          output.setPixel(x, y, img.ColorRgb8(0, 0, 0));
        }
        // else stays white
      }
    }

    return Uint8List.fromList(img.encodePng(output));
  }

  // ─── Enhanced filter: contrast + sharpening ────────────────────────────────
  static Uint8List _applyEnhanced(Uint8List bytes) {
    img.Image? image = img.decodeImage(bytes);
    if (image == null) return bytes;
    img.adjustColor(image, contrast: 1.35, brightness: 1.05, saturation: 0.85);
    return Uint8List.fromList(img.encodeJpg(image, quality: 92));
  }

  // ─── Final rotation applied only at save time ───────────────────────────────
  static Uint8List _applyFinalRotation(Map<String, dynamic> params) {
    final Uint8List bytes = params['bytes'];
    final int turns = params['turns'];
    img.Image? image = img.decodeImage(bytes);
    if (image == null) return bytes;
    if (turns == 1) image = img.copyRotate(image, angle: 90);
    else if (turns == 2) image = img.copyRotate(image, angle: 180);
    else if (turns == 3) image = img.copyRotate(image, angle: 270);
    return Uint8List.fromList(img.encodeJpg(image, quality: 90));
  }

  Future<void> _processImage() async {
    if (_originalImageBytes == null) return;

    if (_processedCache.containsKey(_activeFilter)) {
      setState(() => _processedImageBytes = _processedCache[_activeFilter]);
      return;
    }

    setState(() => _isProcessing = true);
    try {
      Uint8List result;
      if (_activeFilter == 'bw') {
        // Task 2: use adaptive threshold (run in isolate — it's heavy)
        result = await compute(
          (Uint8List b) => _applyAdaptiveThreshold(b),
          _originalImageBytes!,
        );
      } else if (_activeFilter == 'enhanced') {
        result = await compute(
          (Uint8List b) => _applyEnhanced(b),
          _originalImageBytes!,
        );
      } else {
        result = _originalImageBytes!;
      }
      _processedCache[_activeFilter] = result;
      if (mounted) setState(() => _processedImageBytes = result);
    } catch (e) {
      debugPrint('Error processing: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _rotateLeft() =>
      setState(() => _visualRotationTurns = (_visualRotationTurns - 1) % 4);

  void _rotateRight() =>
      setState(() => _visualRotationTurns = (_visualRotationTurns + 1) % 4);

  void _setFilter(String filter) {
    setState(() => _activeFilter = filter);
    _processImage();
  }

  // ─── TASK 1 + 3 + 4: Clean white PDF with invisible OCR text layer ─────────
  Future<void> _handleSave() async {
    if (_processedImageBytes == null || _originalImage == null) return;

    setState(() => _isProcessing = true);
    try {
      // Step A: Apply final rotation to image bytes
      Uint8List finalBytes = _processedImageBytes!;
      if (_visualRotationTurns != 0) {
        finalBytes = await compute(_applyFinalRotation, {
          'bytes': _processedImageBytes!,
          'turns': _visualRotationTurns,
        });
      }

      // Step B: If filter is 'original', always apply adaptive threshold for PDF
      // (user expects a clean doc scan, not a raw photo in PDF)
      Uint8List pdfImageBytes = finalBytes;
      if (_activeFilter == 'original') {
        pdfImageBytes = await compute(
          (Uint8List b) => _applyAdaptiveThreshold(b),
          finalBytes,
        );
      }

      // Step C: Save processed image to temp file for OCR input
      final tempDir = await getTemporaryDirectory();
      final tempImgPath =
          '${tempDir.path}/ocr_${DateTime.now().millisecondsSinceEpoch}.jpg';
      // OCR works better on the original (not thresholded) image
      final ocrBytes = _activeFilter == 'bw'
          ? finalBytes // already rotated original
          : finalBytes;
      await File(tempImgPath).writeAsBytes(ocrBytes);

      // Step D: Run OCR
      final inputImage = InputImage.fromFilePath(tempImgPath);
      final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
      RecognizedText? recognizedText;
      try {
        recognizedText = await recognizer.processImage(inputImage);
      } catch (_) {
        // OCR failure is non-fatal — PDF will be image-only
      } finally {
        await recognizer.close();
      }

      // Step E: Get image dimensions
      final decoded = img.decodeImage(pdfImageBytes);
      final imgW = decoded?.width.toDouble() ?? 1080;
      final imgH = decoded?.height.toDouble() ?? 1440;

      final pageFormat = PdfPageFormat.a4;
      final scaleX = pageFormat.width / imgW;
      final scaleY = pageFormat.height / imgH;

      // Step F: Build PDF
      // TASK 1: White A4 page — NO background image bleed
      // TASK 3: Full-bleed clean processed image
      // TASK 4: Invisible OCR text overlay for searchability
      final pdf = pw.Document();
      final pdfImage = pw.MemoryImage(pdfImageBytes);

      pdf.addPage(
        pw.Page(
          pageFormat: pageFormat,
          // Pure white background, no margin
          margin: pw.EdgeInsets.zero,
          build: (pw.Context ctx) {
            return pw.Stack(
              children: [
                // TASK 3: Clean document image fills the page (white bg baked in)
                pw.Image(
                  pdfImage,
                  width: pageFormat.width,
                  height: pageFormat.height,
                  fit: pw.BoxFit.fill,
                ),

                // TASK 4: Invisible OCR text layer for PDF searchability
                if (recognizedText != null)
                  ...recognizedText.blocks.map((block) {
                    final bb = block.boundingBox;
                    final left = bb.left * scaleX;
                    final top = bb.top * scaleY;
                    final width = bb.width * scaleX;
                    final height = bb.height * scaleY;

                    final lineCount = block.lines.length;
                    final rawFontSize = lineCount > 0
                        ? (height / lineCount).clamp(5.0, 30.0)
                        : 8.0;
                    final fontSize = (rawFontSize * 0.72).clamp(5.0, 26.0);

                    final blockText =
                        block.lines.map((l) => l.text).join('\n');

                    return pw.Positioned(
                      left: left,
                      top: top,
                      child: pw.SizedBox(
                        width: width,
                        child: pw.Text(
                          blockText,
                          style: pw.TextStyle(
                            fontSize: fontSize,
                            // Invisible: white text blends into white bg
                            // but is still indexed by PDF readers
                            color: PdfColors.white,
                          ),
                          softWrap: true,
                          overflow: pw.TextOverflow.clip,
                        ),
                      ),
                    );
                  }).toList(),
              ],
            );
          },
        ),
      );

      // Step G: Generate PDF bytes & preview before saving
      final pdfBytes = await pdf.save();

      if (!mounted) return;
      final bool? confirmSend = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => ScanPdfPreviewScreen(pdfBytes: pdfBytes),
        ),
      );

      if (confirmSend == true && mounted) {
        final outputDir = await getTemporaryDirectory();
        final fileName =
            'scan_${DateTime.now().millisecondsSinceEpoch}.pdf';
        final file = File('${outputDir.path}/$fileName');
        await file.writeAsBytes(pdfBytes);

        if (mounted) {
          Navigator.pop(context);
          widget.onScanCompleted(file.path);
        }
      }
    } catch (e) {
      if (mounted) {
        TopNotificationBanner.show(
          context,
          "${context.trStatic('Erreur lors de la création du PDF', 'Error creating PDF')}: $e",
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(context.tr('Scanner un document', 'Scan a document')),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          if (_processedImageBytes != null)
            TextButton.icon(
              onPressed: _isProcessing ? null : _handleSave,
              icon: const Icon(Icons.check, color: Colors.greenAccent),
              label: Text(
                context.tr('Envoyer', 'Send'),
                style: const TextStyle(
                    color: Colors.greenAccent, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: _originalImage == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.document_scanner_outlined,
                      size: 72, color: Colors.white54),
                  const SizedBox(height: 20),
                  Text(
                    context.tr(
                        'Aucun document capturé', 'No document captured'),
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: Text(
                        context.tr('Prendre une photo', 'Take a photo')),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: Text(context.tr(
                        'Choisir de la galerie', 'Choose from gallery')),
                    style: TextButton.styleFrom(
                        foregroundColor: Colors.white70),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                Column(
                  children: [
                    // Document Preview
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Center(
                          child: _processedImageBytes != null
                              ? Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(4),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.5),
                                        blurRadius: 15,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: RotatedBox(
                                      quarterTurns: _visualRotationTurns,
                                      child: Image.memory(
                                        _processedImageBytes!,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ),
                                )
                              : const CircularProgressIndicator(
                                  color: Colors.white),
                        ),
                      ),
                    ),

                    // Info badge
                    Container(
                      color: const Color(0xFF1A1A2E),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.auto_awesome,
                              color: Colors.amber, size: 13),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              context.tr(
                                'PDF blanc avec texte OCR invisible',
                                'Clean white PDF with invisible OCR text layer',
                              ),
                              style: const TextStyle(
                                  color: Colors.white38, fontSize: 11),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Toolbar
                    Container(
                      color: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Filter selectors
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildFilterButton(
                                'original',
                                context.tr('Original', 'Original'),
                                Icons.image_outlined,
                              ),
                              _buildFilterButton(
                                'bw',
                                context.tr('Doc (N&B)', 'Doc (B&W)'),
                                Icons.filter_b_and_w_outlined,
                              ),
                              _buildFilterButton(
                                'enhanced',
                                context.tr('Amélioré', 'Enhanced'),
                                Icons.auto_fix_high_outlined,
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          const Divider(color: Colors.white12, height: 1),
                          const SizedBox(height: 10),
                          // Rotation
                          Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceAround,
                            children: [
                              IconButton(
                                onPressed: _rotateLeft,
                                icon: const Icon(Icons.rotate_left_rounded,
                                    color: Colors.white, size: 28),
                                tooltip: context.tr(
                                    'Pivoter à gauche', 'Rotate left'),
                              ),
                              IconButton(
                                onPressed: _rotateRight,
                                icon: const Icon(
                                    Icons.rotate_right_rounded,
                                    color: Colors.white,
                                    size: 28),
                                tooltip: context.tr(
                                    'Pivoter à droite', 'Rotate right'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Processing overlay
                if (_isProcessing)
                  Container(
                    color: Colors.black87,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(
                              color: Colors.white),
                          const SizedBox(height: 16),
                          Text(
                            context.tr(
                              'Traitement du document...',
                              'Processing document...',
                            ),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 15),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            context.tr(
                              'Suppression de l\'arrière-plan...',
                              'Removing background...',
                            ),
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildFilterButton(String filter, String label, IconData icon) {
    final isActive = _activeFilter == filter;
    return GestureDetector(
      onTap: () => _setFilter(filter),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isActive
              ? Theme.of(context).colorScheme.primary
              : Colors.grey[900],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? Theme.of(context).colorScheme.primary
                : Colors.white24,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: isActive ? Colors.white : Colors.white54,
                size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white54,
                fontSize: 11,
                fontWeight:
                    isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ScanPdfPreviewScreen extends StatelessWidget {
  final Uint8List pdfBytes;

  const ScanPdfPreviewScreen({super.key, required this.pdfBytes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: Text(
          context.tr('Aperçu du PDF', 'PDF Preview'),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context, false),
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.check, color: Colors.greenAccent),
            label: Text(
              context.tr('Confirmer', 'Confirm'),
              style: const TextStyle(
                color: Colors.greenAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) async => pdfBytes,
        canDebug: false,
        canChangePageFormat: false,
        canChangeOrientation: false,
        actions: const [],
        loadingWidget: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      ),
    );
  }
}
