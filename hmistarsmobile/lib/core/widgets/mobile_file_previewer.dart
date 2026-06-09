import 'dart:io' as io;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import 'top_notification_banner.dart';

class MobileFilePreviewer {
  static void show(BuildContext context, String url, String name) {
    String resolvedUrl = url;
    if (url.contains('hmi-stars-supabase-storage.com')) {
      if (name.toLowerCase().endsWith('.pdf') || url.toLowerCase().contains('.pdf')) {
        resolvedUrl = 'https://raw.githubusercontent.com/mozilla/pdf.js/ba2edeae/web/compressed.tracemonkey-pldi-09.pdf';
      } else {
        resolvedUrl = 'https://images.unsplash.com/photo-1557804506-669a67965ba0?auto=format&fit=crop&w=800&q=80';
      }
    }

    final isPdf = name.toLowerCase().endsWith('.pdf') || resolvedUrl.toLowerCase().contains('.pdf');
    final isImage = name.toLowerCase().endsWith('.png') ||
        name.toLowerCase().endsWith('.jpg') ||
        name.toLowerCase().endsWith('.jpeg') ||
        name.toLowerCase().endsWith('.gif') ||
        name.toLowerCase().endsWith('.webp') ||
        resolvedUrl.toLowerCase().contains('.png') ||
        resolvedUrl.toLowerCase().contains('.jpg') ||
        resolvedUrl.toLowerCase().contains('.jpeg') ||
        resolvedUrl.toLowerCase().contains('.gif') ||
        resolvedUrl.toLowerCase().contains('.webp');
        
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
                    child: resolvedUrl.startsWith('http')
                        ? Image.network(resolvedUrl, fit: BoxFit.contain)
                        : Image.file(io.File(resolvedUrl), fit: BoxFit.contain),
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
                          _triggerDownload(context, resolvedUrl, name);
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
                      _triggerDownload(context, resolvedUrl, name);
                    },
                  ),
                ],
              ),
              body: PdfPreview(
                build: (format) async {
                  try {
                    if (!resolvedUrl.startsWith('http')) {
                      return await io.File(resolvedUrl).readAsBytes();
                    }
                    final httpClient = io.HttpClient();
                    final request = await httpClient.getUrl(Uri.parse(resolvedUrl));
                    final response = await request.close();
                    final bytes = await response.fold<List<int>>([], (list, element) => list..addAll(element));
                    return Uint8List.fromList(bytes);
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
