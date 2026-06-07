import 'package:flutter/material.dart';
import 'dart:ui' show ImageFilter;
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:io' as io;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../../../core/models/models.dart';
import '../../../core/providers/app_state.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  const MessageBubble({super.key, required this.message});

  bool get isImage {
    if (message.typeDocument == TypeDocument.media) return true;
    final url = message.fichierUrl?.toLowerCase() ?? '';
    final name = message.fichierNom?.toLowerCase() ?? message.contenu.toLowerCase();
    return url.endsWith('.png') ||
        url.endsWith('.jpg') ||
        url.endsWith('.jpeg') ||
        url.endsWith('.gif') ||
        url.endsWith('.webp') ||
        name.endsWith('.png') ||
        name.endsWith('.jpg') ||
        name.endsWith('.jpeg') ||
        name.endsWith('.gif') ||
        name.endsWith('.webp');
  }

  void afficherGrandApercuImage(BuildContext context, String url, String nom) {
    final isLocal = !url.startsWith('http');
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.9),
      builder: (dialogContext) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.all(12),
            child: Stack(
              alignment: Alignment.center,
              children: [
                InteractiveViewer(
                  maxScale: 5.0,
                  child: isLocal
                      ? Image.file(
                          io.File(url),
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) => Container(
                            padding: const EdgeInsets.all(24),
                            color: Colors.transparent,
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.broken_image, size: 48, color: Colors.white70),
                                SizedBox(height: 12),
                                Text(
                                  "Impossible de charger l'image locale",
                                  style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Image.network(
                          url,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) => Container(
                            padding: const EdgeInsets.all(24),
                            color: Colors.transparent,
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.broken_image, size: 48, color: Colors.white70),
                                SizedBox(height: 12),
                                Text(
                                  "Impossible de charger l'image",
                                  style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
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
                        icon: const Icon(Icons.close, color: Colors.white, size: 24),
                        tooltip: 'Fermer',
                        onPressed: () => Navigator.pop(dialogContext),
                      ),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 20,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      nom,
                      style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
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

  void _onSingleFileTap(BuildContext context, String url, String name, bool currentIsImage) async {
    if (url.isEmpty) return;

    if (!url.startsWith('http')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Envoi du fichier en cours...')),
      );
      return;
    }

    final theme = Theme.of(context);
    final messenger = ScaffoldMessenger.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                name,
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: theme.colorScheme.primary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: Icon(Icons.open_in_new, color: theme.colorScheme.primary),
              title: Text('Ouvrir le fichier', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              onTap: () async {
                Navigator.pop(ctx);
                if (currentIsImage) {
                  afficherGrandApercuImage(context, url, name);
                } else {
                  try {
                    final uri = Uri.parse(url);
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } catch (e) {
                    messenger.showSnackBar(
                      SnackBar(content: Text('Impossible d\'ouvrir le fichier : $e')),
                    );
                  }
                }
              },
            ),
            ListTile(
              leading: Icon(Icons.download, color: theme.colorScheme.primary),
              title: Text('Télécharger sur l\'appareil', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
              onTap: () async {
                Navigator.pop(ctx);
                messenger.showSnackBar(
                  const SnackBar(content: Text('Téléchargement en cours...')),
                );
                try {
                  final directory = await getApplicationDocumentsDirectory();
                  final downloadDir = io.Directory('${directory.path}/Downloads');
                  if (!await downloadDir.exists()) {
                    await downloadDir.create(recursive: true);
                  }

                  final extDotIdx = name.lastIndexOf('.');
                  final String baseName;
                  final String extension;
                  if (extDotIdx != -1) {
                    baseName = name.substring(0, extDotIdx);
                    extension = name.substring(extDotIdx);
                  } else {
                    baseName = name;
                    extension = '';
                  }

                  io.File targetFile = io.File('${downloadDir.path}/$name');
                  int counter = 0;
                  while (await targetFile.exists()) {
                    counter++;
                    final suffix = getNumberWord(counter);
                    final newName = '$baseName $suffix$extension';
                    targetFile = io.File('${downloadDir.path}/$newName');
                  }

                  final httpClient = io.HttpClient();
                  final request = await httpClient.getUrl(Uri.parse(url));
                  final response = await request.close();
                  final bytes = await response.fold<List<int>>([], (list, element) => list..addAll(element));
                  await targetFile.writeAsBytes(bytes);

                  messenger.showSnackBar(
                    SnackBar(
                      content: Text('Téléchargé avec succès :\n${targetFile.path.split("/").last}'),
                      backgroundColor: Colors.green,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                } catch (e) {
                  messenger.showSnackBar(
                    SnackBar(content: Text('Erreur de téléchargement : $e')),
                  );
                }
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String getNumberWord(int index) {
    const numberWords = [
      'zero',
      'one',
      'two',
      'three',
      'four',
      'five',
      'six',
      'seven',
      'eight',
      'nine',
      'ten',
    ];
    if (index < numberWords.length) {
      return numberWords[index];
    }
    return index.toString();
  }

  Widget _buildAvatar(BuildContext context, bool isForSelf) {
    final appState = Provider.of<AppState>(context, listen: false);
    
    // 1. Try to get avatar using message.userId if available
    if (message.userId != null && message.userId!.isNotEmpty) {
      final salarie = appState.salaries.firstWhere(
        (s) => s.id == message.userId,
        orElse: () => appState.salariesArchives.firstWhere(
          (s) => s.id == message.userId,
          orElse: () => const Salarie(
            id: '',
            entrepriseId: '',
            nom: '',
            prenom: '',
            nomDeNaissance: '',
            typeContrat: '',
          ),
        ),
      );

      if (salarie.id.isNotEmpty) {
        if (salarie.avatarUrl != null && salarie.avatarUrl!.isNotEmpty) {
          final url = salarie.avatarUrl!;
          if (url.startsWith('http')) {
            return CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              backgroundImage: NetworkImage(url),
            );
          } else {
            final file = io.File(url);
            if (file.existsSync()) {
              return CircleAvatar(
                radius: 16,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                backgroundImage: FileImage(file),
              );
            }
          }
        }
        
        // Initials if Salarie has no avatarUrl or local file doesn't exist
        final initial = salarie.prenom.isNotEmpty
            ? salarie.prenom[0].toUpperCase()
            : (salarie.nom.isNotEmpty ? salarie.nom[0].toUpperCase() : '?');
        return CircleAvatar(
          radius: 16,
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            initial,
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        );
      }
    }

    // 2. Fallbacks
    if (isForSelf) {
      // Outgoing message sent by the company manager/client user
      final p = appState.parametres;
      if (p != null && p.logoUrl != null && p.logoUrl!.isNotEmpty) {
        final url = p.logoUrl!;
        if (url.startsWith('http')) {
          return CircleAvatar(
            radius: 16,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            backgroundImage: NetworkImage(url),
          );
        } else {
          final file = io.File(url);
          if (file.existsSync()) {
            return CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              backgroundImage: FileImage(file),
            );
          }
        }
      }
      
      // Fallback for company initials/icon
      final initial = p != null && p.raisonSociale.isNotEmpty
          ? p.raisonSociale[0].toUpperCase()
          : 'C';
      return CircleAvatar(
        radius: 16,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Text(
          initial,
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.bold,
            fontSize: 12,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      );
    } else {
      // Incoming message from HMI Stars support (without a mapping salarie)
      final contactId = message.contactId;
      if (contactId != null && contactId.isNotEmpty) {
        final contact = appState.platformContacts.firstWhere(
          (c) => c['id'] == contactId,
          orElse: () => <String, dynamic>{},
        );
        if (contact.isNotEmpty) {
          final avatarUrl = contact['avatar_url'] as String?;
          if (avatarUrl != null && avatarUrl.isNotEmpty) {
            return CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              backgroundImage: NetworkImage(avatarUrl),
            );
          }
          final nom = contact['nom'] as String? ?? '';
          final prenom = contact['prenom'] as String? ?? '';
          final initial = prenom.isNotEmpty
              ? prenom[0].toUpperCase()
              : (nom.isNotEmpty ? nom[0].toUpperCase() : '?');
          return CircleAvatar(
            radius: 16,
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Text(
              initial,
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          );
        }
      }
      return Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 1,
          ),
        ),
        padding: const EdgeInsets.all(2),
        child: ClipOval(
          child: Image.asset(
            'assets/images/logo.jpeg',
            fit: BoxFit.contain,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSent = message.estEnvoyePar;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: isSent
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isSent) ...[
            _buildAvatar(context, false),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isSent
                    ? Theme.of(context).colorScheme.tertiary
                    : Theme.of(context).colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isSent ? 18 : 4),
                  bottomRight: Radius.circular(isSent ? 4 : 18),
                ),
                border: isSent
                    ? null
                    : Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant,
                        width: 1,
                      ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: message.estFichier
                  ? buildFileBubble(isSent, context)
                  : buildTextBubble(isSent, context),
            ),
          ),
          if (isSent) ...[
            const SizedBox(width: 8),
            _buildAvatar(context, true),
          ],
        ],
      ),
    );
  }

  String? extraireUrl(String texte) {
    final regex = RegExp(r'(https?:\/\/[^\s]+)');
    final match = regex.firstMatch(texte);
    return match?.group(0);
  }

  Widget buildTextBubble(bool isSent, BuildContext context) {
    final url = extraireUrl(message.contenu);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          message.contenu,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: isSent
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface,
            height: 1.4,
          ),
        ),
        if (url != null) ...[
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSent
                    ? Colors.white.withValues(alpha: 0.15)
                    : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSent
                      ? Colors.white.withValues(alpha: 0.3)
                      : Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSent
                          ? Colors.white.withValues(alpha: 0.2)
                          : Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.link,
                      color: isSent ? Colors.white : Theme.of(context).colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Lien partagé",
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isSent ? Colors.white : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          url,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: isSent ? Colors.white70 : Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          "Cliquez pour ouvrir",
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: isSent ? Colors.white54 : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.open_in_new,
                    size: 16,
                    color: isSent ? Colors.white70 : Theme.of(context).colorScheme.outline,
                  ),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              formatTime(message.dateEnvoi),
              style: GoogleFonts.inter(
                fontSize: 10,
                color: isSent
                    ? Colors.white60
                    : Theme.of(context).colorScheme.outline,
              ),
            ),
            if (isSent) ...[
              const SizedBox(width: 4),
              Icon(
                message.estLu ? Icons.done_all : Icons.done,
                size: 14,
                color: message.estLu ? Colors.lightBlueAccent : Colors.white54,
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget buildFileBubble(bool isSent, BuildContext context) {
    final urlString = message.fichierUrl;
    final nameString = message.fichierNom ?? message.contenu;
    
    if (urlString == null || urlString.isEmpty) return const SizedBox();

    final urls = urlString.split(',');
    final noms = nameString.split(',');

    final widgets = <Widget>[];

    for (int i = 0; i < urls.length; i++) {
      final url = urls[i];
      final nom = i < noms.length ? noms[i] : 'Fichier';

      final uLower = url.toLowerCase();
      final nLower = nom.toLowerCase();
      
      final currentIsImage = message.typeDocument == TypeDocument.media || 
          uLower.endsWith('.png') ||
          uLower.endsWith('.jpg') ||
          uLower.endsWith('.jpeg') ||
          uLower.endsWith('.gif') ||
          uLower.endsWith('.webp') ||
          nLower.endsWith('.png') ||
          nLower.endsWith('.jpg') ||
          nLower.endsWith('.jpeg') ||
          nLower.endsWith('.gif') ||
          nLower.endsWith('.webp');

      widgets.add(
        Padding(
          padding: EdgeInsets.only(bottom: i < urls.length - 1 ? 12.0 : 0),
          child: currentIsImage
            ? InkWell(
                onTap: () => afficherGrandApercuImage(context, url, nom),
                borderRadius: BorderRadius.circular(12),
                child: _buildSingleImage(isSent, context, url, i == urls.length - 1),
              )
            : InkWell(
                onTap: () => _onSingleFileTap(context, url, nom, currentIsImage),
                borderRadius: BorderRadius.circular(12),
                child: _buildSingleDocument(isSent, context, nom, i == urls.length - 1),
              ),
        )
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }

  Widget _buildSingleImage(bool isSent, BuildContext context, String url, bool isLast) {
    final isLocal = !url.startsWith('http');
    Widget imageWidget;
    
    if (isLocal) {
      imageWidget = Image.file(
        io.File(url),
        fit: BoxFit.cover,
        width: 200,
        height: 150,
        errorBuilder: (context, error, stackTrace) => Container(
          width: 200,
          height: 150,
          color: Colors.grey[300],
          child: const Icon(Icons.broken_image, size: 40),
        ),
      );
    } else {
      imageWidget = Image.network(
        url,
        fit: BoxFit.cover,
        width: 200,
        height: 150,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: 200,
            height: 150,
            color: isSent
                ? Colors.white.withValues(alpha: 0.1)
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            child: const Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => Container(
          width: 200,
          height: 150,
          color: Colors.grey[300],
          child: const Icon(Icons.broken_image, size: 40),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imageWidget,
            ),
            if (!isLocal)
              Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.open_in_new,
                  color: Colors.white,
                  size: 16,
                ),
              ),
          ],
        ),
        if (isLast) ...[
          const SizedBox(height: 6),
          _buildTimeAndReadStatus(isSent, context),
        ],
      ],
    );
  }

  Widget _buildSingleDocument(bool isSent, BuildContext context, String nom, bool isLast) {
    final currentTypeLabel = getTypeLabel(message.typeDocument);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSent
                    ? Colors.white.withValues(alpha: 0.2)
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.insert_drive_file,
                color: isSent
                    ? Colors.white
                    : Theme.of(context).colorScheme.primary,
                size: 22,
              ),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nom,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isSent
                          ? Colors.white
                          : Theme.of(context).colorScheme.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (currentTypeLabel != null)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isSent
                            ? Colors.white.withValues(alpha: 0.3)
                            : Theme.of(context).colorScheme.tertiaryFixed,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        currentTypeLabel,
                        style: GoogleFonts.inter(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: isSent
                              ? Colors.white
                              : Theme.of(context).colorScheme.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.open_in_new,
              color: isSent
                  ? Colors.white70
                  : Theme.of(context).colorScheme.outline,
              size: 16,
            ),
          ],
        ),
        if (isLast) ...[
          const SizedBox(height: 6),
          _buildTimeAndReadStatus(isSent, context),
        ],
      ],
    );
  }

  Widget _buildTimeAndReadStatus(bool isSent, BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          formatTime(message.dateEnvoi),
          style: GoogleFonts.inter(
            fontSize: 10,
            color: isSent
                ? Colors.white60
                : Theme.of(context).colorScheme.outline,
          ),
        ),
        if (isSent) ...[
          const SizedBox(width: 4),
          Icon(
            message.estLu ? Icons.done_all : Icons.done,
            size: 14,
            color: message.estLu ? Colors.lightBlueAccent : Colors.white54,
          ),
        ],
      ],
    );
  }

  String? getTypeLabel(TypeDocument? type) {
    switch (type) {
      case TypeDocument.fournisseur:
        return 'FOURNISSEUR (CHARGE)';
      case TypeDocument.releve_bancaire:
        return 'RELEVÉ BANCAIRE';
      case TypeDocument.chiffre_affaires:
        return 'CHIFFRE D\'AFFAIRES';
      case TypeDocument.kbis:
        return 'KBIS';
      case TypeDocument.tva:
        return 'ATTESTATION TVA';
      case TypeDocument.siret:
        return 'SIRET / SIREN';
      case TypeDocument.rib:
        return 'RIB';
      case TypeDocument.statuts:
        return 'STATUTS';
      case TypeDocument.media:
        return 'MÉDIA / PHOTO';
      case TypeDocument.autre:
        return 'AUTRE';
      default:
        return null;
    }
  }

  String formatTime(DateTime d) {
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}
