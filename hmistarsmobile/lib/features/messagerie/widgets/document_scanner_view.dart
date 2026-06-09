import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';
import 'package:printing/printing.dart';
import 'package:flutter/services.dart';
import 'package:flutter_document_scanner/flutter_document_scanner.dart';
import '../../../core/widgets/top_notification_banner.dart';
import '../../../core/utils/translation_extension.dart';

class DocumentScannerView extends StatefulWidget {
  final Function(String pdfPath) onScanCompleted;

  const DocumentScannerView({super.key, required this.onScanCompleted});

  @override
  State<DocumentScannerView> createState() => _DocumentScannerViewState();
}

class _DocumentScannerViewState extends State<DocumentScannerView> {
  final _scannerController = DocumentScannerController();
  bool _imageSelected = false;
  bool _isProcessing = false;
  String _processingMessage = '';

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _scannerController.currentPage.listen((AppPages page) {
      if (mounted) {
        setState(() {
          _imageSelected = page != AppPages.takePhoto;
          if (page == AppPages.cropPhoto || page == AppPages.editDocument) {
            _isProcessing = false;
          }
        });
      }
    });

    // Show loading overlay during take-photo processing (contour detection)
    _scannerController.statusTakePhotoPage.listen((AppStatus status) {
      if (mounted) {
        if (status == AppStatus.loading) {
          setState(() {
            _isProcessing = true;
            _processingMessage = context.trStatic('Détection des contours...', 'Detecting contours...');
          });
        } else if (status == AppStatus.success || status == AppStatus.failure) {
          setState(() => _isProcessing = false);
        }
      }
    });

    // Show loading overlay during crop processing
    _scannerController.statusCropPhoto.listen((AppStatus status) {
      if (mounted) {
        if (status == AppStatus.loading) {
          setState(() {
            _isProcessing = true;
            _processingMessage = context.trStatic('Recadrage en cours...', 'Cropping document...');
          });
        } else if (status == AppStatus.success || status == AppStatus.failure) {
          setState(() => _isProcessing = false);
        }
      }
    });

    // Show loading during filter application
    _scannerController.statusEditPhoto.listen((AppStatus status) {
      if (mounted) {
        if (status == AppStatus.loading) {
          setState(() {
            _isProcessing = true;
            _processingMessage = context.trStatic('Application du filtre...', 'Applying filter...');
          });
        } else if (status == AppStatus.success || status == AppStatus.failure) {
          setState(() => _isProcessing = false);
        }
      }
    });

    // Show loading during save/PDF generation
    _scannerController.statusSavePhotoDocument.listen((AppStatus status) {
      if (mounted) {
        if (status == AppStatus.loading) {
          setState(() {
            _isProcessing = true;
            _processingMessage = context.trStatic('Création du PDF...', 'Creating PDF...');
          });
        } else if (status == AppStatus.success || status == AppStatus.failure) {
          setState(() => _isProcessing = false);
        }
      }
    });
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1600,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _isProcessing = true;
          _processingMessage = context.trStatic('Détection des contours...', 'Detecting contours...');
        });

        // This fires the bloc event and returns immediately
        // The loading overlay stays until statusTakePhotoPage changes to success
        await _scannerController.findContoursFromExternalImage(
          image: File(pickedFile.path),
        );
        // DO NOT set _isProcessing = false here.
        // The statusTakePhotoPage listener will handle that.
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isProcessing = false);
        TopNotificationBanner.show(
          context,
          "${context.trStatic('Erreur lors de la capture', 'Error capturing image')}: $e",
          isError: true,
        );
      }
    }
  }

  Future<void> _processCroppedImage(Uint8List croppedBytes) async {
    setState(() {
      _isProcessing = true;
      _processingMessage = context.trStatic('Amélioration du document...', 'Enhancing document...');
    });

    try {
      // Run heavy image processing in an isolate to prevent ANR
      final enhancedBytes = await compute(_enhanceImageIsolate, croppedBytes);

      if (!mounted) return;
      setState(() => _processingMessage = context.trStatic('Génération du PDF...', 'Generating PDF...'));

      // Build PDF on main thread (pdf.save() is async)
      final pdfBytes = await _buildPdfFromEnhanced(enhancedBytes);

      if (!mounted) return;
      setState(() => _isProcessing = false);

      // Preview before confirming/sending
      final bool? confirmSend = await Navigator.push<bool>(
        context,
        MaterialPageRoute(
          builder: (context) => ScanPdfPreviewScreen(pdfBytes: pdfBytes),
        ),
      );

      if (confirmSend == true && mounted) {
        final tempDir = await getTemporaryDirectory();
        final file = File(
          '${tempDir.path}/scan_${DateTime.now().millisecondsSinceEpoch}.pdf',
        );
        await file.writeAsBytes(pdfBytes);
        Navigator.pop(context);
        widget.onScanCompleted(file.path);
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

  /// Top-level function for compute() isolate - enhances image only
  static Uint8List _enhanceImageIsolate(Uint8List rawBytes) {
    final decoded = img.decodeImage(rawBytes);
    if (decoded == null) throw Exception('Failed to decode image');

    final enhanced = _enhanceDocument(decoded);
    return Uint8List.fromList(img.encodeJpg(enhanced, quality: 95));
  }

  /// Build PDF from enhanced image bytes (runs on main thread, is async)
  static Future<Uint8List> _buildPdfFromEnhanced(Uint8List enhancedBytes) async {
    final decoded = img.decodeImage(enhancedBytes);
    final imgW = decoded?.width ?? 1080;
    final imgH = decoded?.height ?? 1440;

    final pdf = pw.Document();
    final pdfImage = pw.MemoryImage(enhancedBytes);

    const pageFormat = PdfPageFormat.a4;
    const margin = 24.0;

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(margin),
        build: (pw.Context ctx) {
          final availableW = pageFormat.width - margin * 2;
          final availableH = pageFormat.height - margin * 2;
          final imgAspect = imgW / imgH;
          final areaAspect = availableW / availableH;

          double fitW, fitH;
          if (imgAspect > areaAspect) {
            fitW = availableW;
            fitH = availableW / imgAspect;
          } else {
            fitH = availableH;
            fitW = availableH * imgAspect;
          }

          return pw.Center(
            child: pw.Image(
              pdfImage,
              width: fitW,
              height: fitH,
              fit: pw.BoxFit.contain,
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  /// Enhance a document image to look like a real digital scan
  static img.Image _enhanceDocument(img.Image src) {
    final w = src.width;
    final h = src.height;

    // Step 1: Convert to grayscale for analysis
    final gray = img.grayscale(img.copyResize(src, width: w, height: h));

    // Step 2: Calculate histogram for adaptive thresholding
    final histogram = List<int>.filled(256, 0);
    for (int y = 0; y < gray.height; y++) {
      for (int x = 0; x < gray.width; x++) {
        final pixel = gray.getPixel(x, y);
        final lum = img.getLuminance(pixel).toInt().clamp(0, 255);
        histogram[lum]++;
      }
    }

    // Find the background brightness (mode of upper 30% of histogram)
    final totalPixels = w * h;
    int bgBrightness = 200;
    int cumulative = 0;
    for (int i = 255; i >= 0; i--) {
      cumulative += histogram[i];
      if (cumulative > totalPixels * 0.3) {
        bgBrightness = i;
        break;
      }
    }

    // Step 3: Apply adaptive enhancement to original color image
    final result = img.Image(width: w, height: h);

    final bgTarget = 255.0;
    final scaleFactor = bgBrightness > 10 ? bgTarget / bgBrightness : 1.0;

    for (int y = 0; y < h; y++) {
      for (int x = 0; x < w; x++) {
        final pixel = src.getPixel(x, y);
        final r = pixel.r.toDouble();
        final g = pixel.g.toDouble();
        final b = pixel.b.toDouble();
        final lum = (0.299 * r + 0.587 * g + 0.114 * b);

        double newR, newG, newB;

        if (lum > bgBrightness * 0.85) {
          // Background pixel - push toward white
          newR = math.min(255, r * scaleFactor * 1.05);
          newG = math.min(255, g * scaleFactor * 1.05);
          newB = math.min(255, b * scaleFactor * 1.05);
        } else if (lum < bgBrightness * 0.4) {
          // Dark text/ink - darken for contrast
          final darkFactor = 0.7;
          newR = (r * darkFactor).clamp(0, 255);
          newG = (g * darkFactor).clamp(0, 255);
          newB = (b * darkFactor).clamp(0, 255);
        } else {
          // Mid-tone - moderate enhancement
          final midFactor = scaleFactor * 0.95;
          newR = (r * midFactor).clamp(0, 255);
          newG = (g * midFactor).clamp(0, 255);
          newB = (b * midFactor).clamp(0, 255);
        }

        result.setPixelRgba(
          x, y,
          newR.round(),
          newG.round(),
          newB.round(),
          255,
        );
      }
    }

    // Step 4: Slight sharpening for crisper text
    return img.convolution(
      result,
      filter: [
        0, -0.5, 0,
        -0.5, 3, -0.5,
        0, -0.5, 0,
      ],
      div: 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: !_imageSelected
          ? AppBar(
              title: Text(context.tr('Scanner un document', 'Scan a document')),
              backgroundColor: Colors.black.withOpacity(0.6),
              foregroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 24),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            )
          : null,
      body: Stack(
        children: [
          DocumentScanner(
            controller: _scannerController,
            generalStyles: GeneralStyles(
              baseColor: const Color(0xFF121212),
              showCameraPreview: false,
              hideDefaultDialogs: true,
              messageTakingPicture: context.trStatic('Traitement...', 'Processing...'),
              messageCroppingPicture: context.trStatic('Recadrage...', 'Cropping...'),
              messageEditingPicture: context.trStatic('Application des filtres...', 'Applying filters...'),
              messageSavingPicture: context.trStatic('Génération...', 'Generating...'),
              widgetInsteadOfCameraPreview: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.document_scanner_outlined,
                        size: 80, color: Colors.white54),
                    const SizedBox(height: 24),
                    Text(
                      context.tr(
                          'Aucun document capturé', 'No document captured'),
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 16),
                    ),
                    const SizedBox(height: 32),
                    ElevatedButton.icon(
                      onPressed: () => _pickImage(ImageSource.camera),
                      icon: const Icon(Icons.camera_alt, color: Colors.white),
                      label: Text(
                        context.tr('Prendre une photo', 'Take a photo'),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () => _pickImage(ImageSource.gallery),
                      icon: const Icon(Icons.photo_library, color: Colors.white70),
                      label: Text(
                        context.tr('Choisir de la galerie', 'Choose from gallery'),
                        style: const TextStyle(color: Colors.white70),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            cropPhotoDocumentStyle: CropPhotoDocumentStyle(
              textButtonSave: context.tr('Étape suivante', 'Next step'),
              colorBorderArea: Colors.greenAccent,
              widthBorderArea: 3.5,
              dotSize: 28,
            ),
            editPhotoDocumentStyle: EditPhotoDocumentStyle(
              textButtonSave: context.tr('Créer le PDF', 'Create PDF'),
            ),
            onSave: (Uint8List imageBytes) {
              _processCroppedImage(imageBytes);
            },
          ),
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.85),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 48,
                      height: 48,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      _processingMessage.isNotEmpty
                          ? _processingMessage
                          : context.tr('Traitement en cours...', 'Processing...'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr('Veuillez patienter', 'Please wait'),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 13,
                      ),
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

class ScanPdfPreviewScreen extends StatelessWidget {
  final Uint8List pdfBytes;

  const ScanPdfPreviewScreen({super.key, required this.pdfBytes});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(
          context.tr('Aperçu du document', 'Document Preview'),
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        elevation: 2,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          ),
          onPressed: () => Navigator.pop(context, false),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(context, true),
              icon: const Icon(Icons.check_circle_outline, size: 20),
              label: Text(
                context.tr('Confirmer', 'Confirm'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4CAF50),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                elevation: 0,
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
        allowPrinting: false,
        allowSharing: false,
        pdfPreviewPageDecoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        actions: const [],
        loadingWidget: const Center(
          child: CircularProgressIndicator(color: Color(0xFF1A1A2E)),
        ),
      ),
    );
  }
}
