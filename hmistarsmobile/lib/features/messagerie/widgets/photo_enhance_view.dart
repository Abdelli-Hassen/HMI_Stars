import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import '../../../core/widgets/top_notification_banner.dart';
import '../../../core/utils/translation_extension.dart';

class PhotoEnhanceView extends StatefulWidget {
  final String imagePath;
  final Function(String finalPath) onPhotoConfirmed;

  const PhotoEnhanceView({
    super.key,
    required this.imagePath,
    required this.onPhotoConfirmed,
  });

  @override
  State<PhotoEnhanceView> createState() => _PhotoEnhanceViewState();
}

class _PhotoEnhanceViewState extends State<PhotoEnhanceView> {
  Uint8List? _originalBytes;
  Uint8List? _displayBytes;
  bool _isProcessing = false;
  String _activeFilter = 'original';
  final Map<String, Uint8List> _filterCache = {};

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  Future<void> _loadImage() async {
    setState(() => _isProcessing = true);
    try {
      final file = File(widget.imagePath);
      final bytes = await file.readAsBytes();
      setState(() {
        _originalBytes = bytes;
        _displayBytes = bytes;
        _filterCache['original'] = bytes;
      });
    } catch (e) {
      if (mounted) {
        TopNotificationBanner.show(
          context,
          "${context.trStatic('Erreur lors du chargement de l\'image', 'Error loading image')}: $e",
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // Runs in background isolate
  static Uint8List _applyFilter(Map<String, dynamic> params) {
    final Uint8List bytes = params['bytes'];
    final String filter = params['filter'];

    img.Image? image = img.decodeImage(bytes);
    if (image == null) return bytes;

    if (filter == 'bw') {
      img.grayscale(image);
      for (final frame in image.frames) {
        final w = frame.width;
        final h = frame.height;
        for (int y = 0; y < h; y++) {
          for (int x = 0; x < w; x++) {
            final pixel = frame.getPixel(x, y);
            final l = pixel.r;
            if (l > 140) {
              pixel.r = 255;
              pixel.g = 255;
              pixel.b = 255;
            } else if (l < 80) {
              pixel.r = 0;
              pixel.g = 0;
              pixel.b = 0;
            }
          }
        }
      }
    } else if (filter == 'enhanced') {
      img.adjustColor(image, contrast: 1.3, brightness: 1.08, saturation: 0.9);
    }

    return Uint8List.fromList(img.encodeJpg(image, quality: 92));
  }

  Future<void> _setFilter(String filter) async {
    if (_activeFilter == filter || _originalBytes == null) return;

    // Serve from cache if available
    if (_filterCache.containsKey(filter)) {
      setState(() {
        _activeFilter = filter;
        _displayBytes = _filterCache[filter];
      });
      return;
    }

    setState(() {
      _activeFilter = filter;
      _isProcessing = true;
    });

    try {
      final result = await compute(_applyFilter, {
        'bytes': _originalBytes!,
        'filter': filter,
      });

      _filterCache[filter] = result;

      if (mounted) {
        setState(() => _displayBytes = result);
      }
    } catch (e) {
      if (mounted) {
        TopNotificationBanner.show(
          context,
          "${context.trStatic('Erreur de traitement', 'Processing error')}: $e",
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _confirmAndSend() async {
    if (_displayBytes == null) return;

    setState(() => _isProcessing = true);
    try {
      // Save filtered image to a temp file
      final originalFile = File(widget.imagePath);
      final dir = originalFile.parent;
      final ext = widget.imagePath.split('.').last;
      final newPath =
          '${dir.path}/enhanced_${DateTime.now().millisecondsSinceEpoch}.$ext';
      final newFile = File(newPath);
      await newFile.writeAsBytes(_displayBytes!);
      if (mounted) {
        widget.onPhotoConfirmed(newPath);
      }
    } catch (e) {
      if (mounted) {
        TopNotificationBanner.show(
          context,
          "${context.trStatic('Erreur lors de la sauvegarde', 'Error saving image')}: $e",
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
        title: Text(context.tr('Améliorer la photo', 'Enhance Photo')),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        actions: [
          if (_displayBytes != null)
            TextButton.icon(
              onPressed: _isProcessing ? null : _confirmAndSend,
              icon: const Icon(Icons.send_rounded, color: Colors.greenAccent),
              label: Text(
                context.tr('Envoyer', 'Send'),
                style: const TextStyle(
                    color: Colors.greenAccent, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: _originalBytes == null
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : Stack(
              children: [
                Column(
                  children: [
                    // Image Preview
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Center(
                          child: _displayBytes != null
                              ? Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.5),
                                        blurRadius: 15,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.memory(
                                      _displayBytes!,
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                )
                              : const CircularProgressIndicator(
                                  color: Colors.white),
                        ),
                      ),
                    ),

                    // Filter toolbar
                    Container(
                      color: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            context.tr('Choisir un filtre', 'Choose a filter'),
                            style: const TextStyle(
                                color: Colors.white54, fontSize: 12),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildFilterButton(
                                'original',
                                context.tr('Original', 'Original'),
                                Icons.image_outlined,
                              ),
                              _buildFilterButton(
                                'bw',
                                context.tr('Noir & Blanc', 'B&W'),
                                Icons.filter_b_and_w_outlined,
                              ),
                              _buildFilterButton(
                                'enhanced',
                                context.tr('Amélioré', 'Enhanced'),
                                Icons.auto_fix_high_outlined,
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
                    color: Colors.black54,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(color: Colors.white),
                          const SizedBox(height: 16),
                          Text(
                            context.tr(
                                'Traitement de l\'image...', 'Processing...'),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 16),
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
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
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
                color: isActive ? Colors.white : Colors.white54, size: 22),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.white54,
                fontSize: 12,
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
