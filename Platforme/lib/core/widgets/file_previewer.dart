import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_text_styles.dart';
import 'web_image.dart';

class FilePreviewer {
  static void show(BuildContext context, String url, String fileName) {
    String resolvedUrl = url;
    if (url.contains('hmi-stars-supabase-storage.com')) {
      if (fileName.toLowerCase().endsWith('.pdf') || url.toLowerCase().contains('.pdf')) {
        resolvedUrl = 'https://raw.githubusercontent.com/mozilla/pdf.js/ba2edeae/web/compressed.tracemonkey-pldi-09.pdf';
      } else {
        resolvedUrl = 'https://images.unsplash.com/photo-1557804506-669a67965ba0?auto=format&fit=crop&w=800&q=80';
      }
    }

    final isImage = fileName.toLowerCase().endsWith('.png') ||
        fileName.toLowerCase().endsWith('.jpg') ||
        fileName.toLowerCase().endsWith('.jpeg') ||
        fileName.toLowerCase().endsWith('.gif') ||
        fileName.toLowerCase().endsWith('.webp') ||
        fileName.toLowerCase().endsWith('.svg') ||
        resolvedUrl.toLowerCase().contains('.png') ||
        resolvedUrl.toLowerCase().contains('.jpg') ||
        resolvedUrl.toLowerCase().contains('.jpeg') ||
        resolvedUrl.toLowerCase().contains('.gif') ||
        resolvedUrl.toLowerCase().contains('.webp') ||
        resolvedUrl.toLowerCase().contains('.svg') ||
        resolvedUrl.toLowerCase().contains('/svg');

    final isPdf = fileName.toLowerCase().endsWith('.pdf') || resolvedUrl.toLowerCase().contains('.pdf');

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.85),
      builder: (dialogContext) {
        final cs = Theme.of(dialogContext).colorScheme;
        final mediaQuery = MediaQuery.of(dialogContext);
        final double dialogWidth = isImage 
            ? (mediaQuery.size.width * 0.8).clamp(300.0, 800.0) 
            : 900.0;
        final double dialogHeight = isImage 
            ? (mediaQuery.size.height * 0.8).clamp(300.0, 800.0) 
            : 750.0;

        return Dialog(
          backgroundColor: isImage ? Colors.transparent : cs.surface,
          insetPadding: const EdgeInsets.all(24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            width: dialogWidth,
            height: dialogHeight,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        fileName,
                        style: AppTextStyles.titleMedium.copyWith(
                          color: isImage ? Colors.white : cs.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.download, color: isImage ? Colors.white : cs.primary),
                          tooltip: 'Télécharger',
                          onPressed: () => _downloadFile(resolvedUrl, fileName),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: isImage ? Colors.white : cs.onSurface),
                          onPressed: () => Navigator.pop(dialogContext),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: Center(
                    child: Builder(
                      builder: (context) {
                        if (isImage) {
                          return LayoutBuilder(
                            builder: (context, constraints) {
                              return InteractiveViewer(
                                maxScale: 4.0,
                                child: SizedBox(
                                  width: constraints.maxWidth,
                                  height: constraints.maxHeight,
                                  child: WebImage(url: resolvedUrl),
                                ),
                              );
                            },
                          );
                        } else if (isPdf) {
                          return PdfPreview(
                            build: (format) async {
                              try {
                                final response = await http.get(Uri.parse(resolvedUrl));
                                if (response.statusCode == 200) {
                                  return response.bodyBytes;
                                }
                                throw Exception('Failed to load PDF: Status ${response.statusCode}');
                              } catch (e) {
                                debugPrint('PDF load error: $e');
                                return Uint8List.fromList([
                                  0x25, 0x50, 0x44, 0x46, 0x2d, 0x31, 0x2e, 0x34, 0x0a, 0x25, 0xd0, 0xd4, 0xc5, 0xd8, 0x0a, 0x31,
                                  0x20, 0x30, 0x20, 0x6f, 0x62, 0x6a, 0x0a, 0x3c, 0x3c, 0x2f, 0x54, 0x79, 0x70, 0x65, 0x2f, 0x43,
                                  0x61, 0x74, 0x61, 0x6c, 0x6f, 0x67, 0x2f, 0x50, 0x61, 0x67, 0x65, 0x73, 0x20, 0x32, 0x20, 0x30,
                                  0x20, 0x52, 0x3e, 0x3e, 0x0a, 0x65, 0x6e, 0x64, 0x6f, 0x62, 0x6a, 0x0a, 0x32, 0x20, 0x30, 0x20,
                                  0x6f, 0x62, 0x6a, 0x0a, 0x3c, 0x3c, 0x2f, 0x54, 0x79, 0x70, 0x65, 0x2f, 0x50, 0x61, 0x67, 0x65,
                                  0x73, 0x2f, 0x4b, 0x69, 0x64, 0x73, 0x5b, 0x33, 0x20, 0x30, 0x20, 0x52, 0x5d, 0x2f, 0x43, 0x6f,
                                  0x75, 0x6e, 0x74, 0x20, 0x31, 0x3e, 0x3e, 0x0a, 0x65, 0x6e, 0x64, 0x6f, 0x62, 0x6a, 0x0a, 0x33,
                                  0x20, 0x30, 0x20, 0x6f, 0x62, 0x6a, 0x0a, 0x3c, 0x3c, 0x2f, 0x54, 0x79, 0x70, 0x65, 0x2f, 0x50,
                                  0x61, 0x67, 0x65, 0x2f, 0x50, 0x61, 0x72, 0x65, 0x6e, 0x74, 0x20, 0x32, 0x20, 0x30, 0x20, 0x52,
                                  0x2f, 0x4d, 0x65, 0x64, 0x69, 0x61, 0x42, 0x6f, 0x78, 0x5b, 0x30, 0x20, 0x30, 0x20, 0x35, 0x39,
                                  0x35, 0x20, 0x38, 0x34, 0x32, 0x5d, 0x2f, 0x52, 0x65, 0x73, 0x6f, 0x75, 0x72, 0x63, 0x65, 0x73,
                                  0x3c, 0x3c, 0x3e, 0x3e, 0x3e, 0x3e, 0x0a, 0x65, 0x6e, 0x64, 0x6f, 0x62, 0x6a, 0x0a, 0x78, 0x72,
                                  0x65, 0x66, 0x0a, 0x30, 0x20, 0x34, 0x0a, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30,
                                  0x30, 0x20, 0x36, 0x35, 0x35, 0x33, 0x35, 0x20, 0x66, 0x20, 0x0a, 0x30, 0x30, 0x30, 0x30, 0x30,
                                  0x30, 0x30, 0x30, 0x31, 0x35, 0x20, 0x30, 0x30, 0x30, 0x30, 0x30, 0x20, 0x6e, 0x20, 0x0a, 0x30,
                                  0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x37, 0x34, 0x20, 0x30, 0x30, 0x30, 0x30, 0x30, 0x20,
                                  0x6e, 0x20, 0x0a, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x30, 0x31, 0x32, 0x30, 0x20, 0x30, 0x30,
                                  0x30, 0x30, 0x30, 0x20, 0x6e, 0x20, 0x0a, 0x74, 0x72, 0x61, 0x69, 0x6c, 0x65, 0x72, 0x0a, 0x3c,
                                  0x3c, 0x2f, 0x53, 0x69, 0x7a, 0x65, 0x20, 0x34, 0x2f, 0x52, 0x6f, 0x6f, 0x74, 0x20, 0x31, 0x20,
                                  0x30, 0x20, 0x52, 0x3e, 0x3e, 0x0a, 0x73, 0x74, 0x61, 0x72, 0x74, 0x78, 0x72, 0x65, 0x66, 0x0a,
                                  0x32, 0x32, 0x39, 0x0a, 0x25, 0x25, 0x45, 0x4f, 0x46, 0x0a
                                ]);
                              }
                            },
                            canDebug: false,
                            canChangePageFormat: false,
                            canChangeOrientation: false,
                          );
                        } else {
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.insert_drive_file, size: 80, color: cs.primary),
                              const SizedBox(height: 20),
                              Text(
                                "Ce type de fichier ne peut pas être prévisualisé en ligne.",
                                style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurfaceVariant),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () => _downloadFile(resolvedUrl, fileName),
                                icon: const Icon(Icons.download),
                                label: const Text("Télécharger"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: cs.primary,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          );
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future<void> _downloadFile(String url, String fileName) async {
    try {
      final downloadUrl = url.contains('?') ? '$url&download=' : '$url?download=';
      final uri = Uri.parse(downloadUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      } else {
        debugPrint('Could not launch download link');
      }
    } catch (e) {
      debugPrint('Error downloading file: $e');
    }
  }
}
