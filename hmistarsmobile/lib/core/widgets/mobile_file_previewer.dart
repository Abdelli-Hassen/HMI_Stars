import 'dart:io' as io;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import 'top_notification_banner.dart';

class MobileFilePreviewer {
  static void show(BuildContext context, String url, String name) {
    final isPdf = name.toLowerCase().endsWith('.pdf') || url.toLowerCase().contains('.pdf');
    final isImage = name.toLowerCase().endsWith('.png') ||
        name.toLowerCase().endsWith('.jpg') ||
        name.toLowerCase().endsWith('.jpeg') ||
        name.toLowerCase().endsWith('.gif') ||
        name.toLowerCase().endsWith('.webp') ||
        url.toLowerCase().contains('.png') ||
        url.toLowerCase().contains('.jpg') ||
        url.toLowerCase().contains('.jpeg') ||
        url.toLowerCase().contains('.gif') ||
        url.toLowerCase().contains('.webp');
        
    final theme = Theme.of(context);

    if (isImage) {
      // Show full image dialog with download button
      showDialog(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.9),
        builder: (dialogContext) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(12),
            child: Stack(
              alignment: Alignment.center,
              children: [
                InteractiveViewer(
                  maxScale: 5.0,
                  child: Center(
                    child: url.startsWith('http')
                        ? Image.network(url, fit: BoxFit.contain)
                        : Image.file(io.File(url), fit: BoxFit.contain),
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Row(
                    children: [
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.5),
                        ),
                        icon: const Icon(Icons.download, color: Colors.white, size: 24),
                        tooltip: 'Télécharger',
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          _triggerDownload(context, url, name);
                        },
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.black.withValues(alpha: 0.5),
                        ),
                        icon: const Icon(Icons.close, color: Colors.white, size: 24),
                        tooltip: 'Fermer',
                        onPressed: () => Navigator.pop(dialogContext),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      );
    } else if (isPdf) {
      // Show PDF in app
      showDialog(
        context: context,
        builder: (dialogContext) {
          return Dialog.fullscreen(
            child: Scaffold(
              appBar: AppBar(
                title: Text(
                  name,
                  style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(dialogContext),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.download),
                    tooltip: 'Télécharger',
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      _triggerDownload(context, url, name);
                    },
                  ),
                ],
              ),
              body: PdfPreview(
                build: (format) async {
                  final httpClient = io.HttpClient();
                  final request = await httpClient.getUrl(Uri.parse(url));
                  final response = await request.close();
                  final bytes = await response.fold<List<int>>([], (list, element) => list..addAll(element));
                  return Uint8List.fromList(bytes);
                },
                canDebug: false,
                canChangePageFormat: false,
                canChangeOrientation: false,
              ),
            ),
          );
        },
      );
    } else {
      // Non-previewable file
      showDialog(
        context: context,
        builder: (dialogContext) {
          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.insert_drive_file, size: 64, color: theme.colorScheme.primary),
                  const SizedBox(height: 16),
                  Text(
                    name,
                    style: GoogleFonts.manrope(fontWeight: FontWeight.bold, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "Ce type de fichier ne peut pas être prévisualisé directement.",
                    style: GoogleFonts.inter(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(dialogContext),
                        child: const Text("Fermer"),
                      ),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(dialogContext);
                          _triggerDownload(context, url, name);
                        },
                        icon: const Icon(Icons.download),
                        label: const Text("Télécharger"),
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        },
      );
    }
  }

  static Future<void> _triggerDownload(BuildContext context, String url, String name) async {
    try {
      final downloadUrl = url.contains('?') ? '$url&download=' : '$url?download=';
      final uri = Uri.parse(downloadUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        TopNotificationBanner.show(
          context,
          'Impossible d\'ouvrir le téléchargeur externe de votre téléphone.',
          isError: true,
        );
      }
    } catch (e) {
      TopNotificationBanner.show(
        context,
        'Erreur lors du lancement du téléchargement : $e',
        isError: true,
      );
    }
  }
}
