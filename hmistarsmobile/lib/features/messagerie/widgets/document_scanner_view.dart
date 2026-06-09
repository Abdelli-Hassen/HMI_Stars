import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:flutter/foundation.dart';
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
  int _visualRotationTurns = 0; // 0 = 0°, 1 = 90° CW, 2 = 180°, 3 = 270° CW (90° CCW)
  String _activeFilter = 'original'; // 'original', 'bw', 'enhanced'
  
  // Cache processed results by filter type
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
        imageQuality: 90, // Keep high quality
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
          _processedCache.clear(); // Clear cache when a new image is picked
          // Seed the cache with the original image
          _processedCache["original"] = bytes;
        });
      }
    } catch (e) {
      if (mounted) {
        TopNotificationBanner.show(
          context,
          "${context.trStatic('Erreur lors de la capture de l\'image', 'Error capturing image')}: $e",
          isError: true,
        );
      }
    }
  }

  // Pure Dart image processing offloaded to a background isolate using compute
  static Uint8List _applyFilter(Map<String, dynamic> params) {
    final Uint8List bytes = params['bytes'];
    final String filter = params['filter'];

    img.Image? image = img.decodeImage(bytes);
    if (image == null) return bytes;

    // Apply filter
    if (filter == 'bw') {
      img.grayscale(image);
      // CamScanner-style background removal and thresholding
      for (final frame in image.frames) {
        final w = frame.width;
        final h = frame.height;
        for (int y = 0; y < h; y++) {
          for (int x = 0; x < w; x++) {
            final pixel = frame.getPixel(x, y);
            final l = pixel.r; // grayscale value
            if (l > 140) {
              pixel.r = 255;
              pixel.g = 255;
              pixel.b = 255;
            } else if (l < 80) {
              pixel.r = 0;
              pixel.g = 0;
              pixel.b = 0;
            } else {
              // Smooth contrast stretch for clean text scanning
              final val = ((l - 80) / 60.0 * 255.0).round().clamp(0, 255);
              pixel.r = val;
              pixel.g = val;
              pixel.b = val;
            }
          }
        }
      }
    } else if (filter == 'enhanced') {
      // Color Scan / Magic Color
      img.contrast(image, contrast: 125);
      img.adjustColor(image, saturation: 1.25);
    }

    return Uint8List.fromList(img.encodeJpg(image, quality: 85));
  }

  // Heavy final rotation logic applied only right before saving/compiling to PDF
  static Uint8List _applyFinalRotation(Map<String, dynamic> params) {
    final Uint8List bytes = params['bytes'];
    final int turns = params['turns'];

    img.Image? image = img.decodeImage(bytes);
    if (image == null) return bytes;

    // Apply rotation
    if (turns == 1) {
      image = img.copyRotate(image, angle: 90);
    } else if (turns == 2) {
      image = img.copyRotate(image, angle: 180);
    } else if (turns == 3) {
      image = img.copyRotate(image, angle: 270);
    }

    return Uint8List.fromList(img.encodeJpg(image, quality: 85));
  }

  Future<void> _processImage() async {
    if (_originalImageBytes == null) return;
    
    final cacheKey = _activeFilter;
    if (_processedCache.containsKey(cacheKey)) {
      setState(() {
        _processedImageBytes = _processedCache[cacheKey];
      });
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final processed = await compute(_applyFilter, {
        'bytes': _originalImageBytes!,
        'filter': _activeFilter,
      });

      _processedCache[cacheKey] = processed;
      setState(() {
        _processedImageBytes = processed;
      });
    } catch (e) {
      debugPrint('Error processing image: $e');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  // Visual rotations: instantaneous, no recalculations/processing
  void _rotateLeft() {
    setState(() {
      _visualRotationTurns = (_visualRotationTurns - 1) % 4;
    });
  }

  void _rotateRight() {
    setState(() {
      _visualRotationTurns = (_visualRotationTurns + 1) % 4;
    });
  }

  void _setFilter(String filter) {
    setState(() {
      _activeFilter = filter;
    });
    _processImage();
  }

  Future<void> _handleSave() async {
    if (_processedImageBytes == null) return;

    setState(() => _isProcessing = true);
    try {
      // Process final rotation on compute isolate right before saving to PDF
      Uint8List finalBytes = _processedImageBytes!;
      if (_visualRotationTurns != 0) {
        finalBytes = await compute(_applyFinalRotation, {
          'bytes': _processedImageBytes!,
          'turns': _visualRotationTurns,
        });
      }

      final pdf = pw.Document();
      final image = pw.MemoryImage(finalBytes);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.zero, // full page scan
          build: (pw.Context context) {
            return pw.Center(
              child: pw.Image(image, fit: pw.BoxFit.contain),
            );
          },
        ),
      );

      final outputDir = await getTemporaryDirectory();
      final fileName = 'scan_${DateTime.now().millisecondsSinceEpoch}.pdf';
      final file = File('${outputDir.path}/$fileName');
      await file.writeAsBytes(await pdf.save());

      if (mounted) {
        // Pop the scanner route first before triggering prompt to avoid navigation race
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
      if (mounted) {
        setState(() => _isProcessing = false);
      }
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
                style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: _originalImage == null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.document_scanner_outlined, size: 72, color: Colors.white54),
                  const SizedBox(height: 20),
                  Text(
                    context.tr('Aucun document capturé', 'No document captured'),
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: Text(context.tr('Prendre une photo', 'Take a photo')),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: Text(context.tr('Choisir de la galerie', 'Choose from gallery')),
                    style: TextButton.styleFrom(foregroundColor: Colors.white70),
                  ),
                ],
              ),
            )
          : Stack(
              children: [
                Column(
                  children: [
                    // Document Preview Area
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Center(
                          child: _processedImageBytes != null
                              ? Container(
                                  decoration: BoxDecoration(
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.5),
                                        blurRadius: 15,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: RotatedBox(
                                    quarterTurns: _visualRotationTurns,
                                    child: Image.memory(
                                      _processedImageBytes!,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                )
                              : const CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                    ),
                    
                    // Toolbar for Rotation & Filters
                    Container(
                      color: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Filter Selectors
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildFilterButton('original', context.tr('Original', 'Original')),
                              _buildFilterButton('bw', context.tr('Noir & Blanc', 'B&W Scan')),
                              _buildFilterButton('enhanced', context.tr('Amélioré', 'Enhanced')),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(color: Colors.white24, height: 1),
                          const SizedBox(height: 12),
                          // Action Buttons
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              IconButton(
                                onPressed: _rotateLeft,
                                icon: const Icon(Icons.rotate_left_rounded, color: Colors.white, size: 28),
                                tooltip: context.tr('Pivoter à gauche', 'Rotate left'),
                              ),
                              IconButton(
                                onPressed: _rotateRight,
                                icon: const Icon(Icons.rotate_right_rounded, color: Colors.white, size: 28),
                                tooltip: context.tr('Pivoter à droite', 'Rotate right'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_isProcessing)
                  Container(
                    color: Colors.black54,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(color: Colors.white),
                          const SizedBox(height: 16),
                          Text(
                            context.tr('Traitement de l\'image...', 'Processing image...'),
                            style: const TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildFilterButton(String filter, String label) {
    final isActive = _activeFilter == filter;
    return ChoiceChip(
      label: Text(label),
      selected: isActive,
      onSelected: (_) => _setFilter(filter),
      backgroundColor: Colors.grey[900],
      selectedColor: Theme.of(context).colorScheme.primary,
      labelStyle: TextStyle(
        color: isActive ? Colors.white : Colors.white70,
        fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}
