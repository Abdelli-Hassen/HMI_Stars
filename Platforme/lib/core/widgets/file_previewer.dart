import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_text_styles.dart';
import 'web_image.dart';

class FilePreviewer {
  static void show(BuildContext context, String url, String fileName) {
    final isImage = fileName.toLowerCase().endsWith('.png') ||
        fileName.toLowerCase().endsWith('.jpg') ||
        fileName.toLowerCase().endsWith('.jpeg') ||
        fileName.toLowerCase().endsWith('.gif') ||
        fileName.toLowerCase().endsWith('.webp') ||
        fileName.toLowerCase().endsWith('.svg') ||
        url.toLowerCase().contains('.png') ||
        url.toLowerCase().contains('.jpg') ||
        url.toLowerCase().contains('.jpeg') ||
        url.toLowerCase().contains('.gif') ||
        url.toLowerCase().contains('.webp') ||
        url.toLowerCase().contains('.svg') ||
        url.toLowerCase().contains('/svg');

    final isPdf = fileName.toLowerCase().endsWith('.pdf') || url.toLowerCase().contains('.pdf');

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
                          onPressed: () => _downloadFile(url, fileName),
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
                                  child: WebImage(url: url),
                                ),
                              );
                            },
                          );
                        } else if (isPdf) {
                          return PdfPreview(
                            build: (format) async {
                              final response = await http.get(Uri.parse(url));
                              return response.bodyBytes;
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
                                onPressed: () => _downloadFile(url, fileName),
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
