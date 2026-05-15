import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/models.dart';
import '../../../core/theme/app_theme.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  const MessageBubble({super.key, required this.message});

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
            CircleAvatar(
              radius: 16,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Icon(
                Icons.star,
                color: Theme.of(context).colorScheme.tertiary,
                size: 14,
              ),
            ),
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
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: message.estFichier
                  ? _buildFileBubble(isSent, context)
                  : _buildTextBubble(isSent, context),
            ),
          ),
          if (isSent) const SizedBox(width: 4),
        ],
      ),
    );
  }

  Widget _buildTextBubble(bool isSent, BuildContext context) {
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
        const SizedBox(height: 4),
        Text(
          _formatTime(message.dateEnvoi),
          style: GoogleFonts.inter(
            fontSize: 10,
            color: isSent
                ? Colors.white60
                : Theme.of(context).colorScheme.outline,
          ),
        ),
      ],
    );
  }

  Widget _buildFileBubble(bool isSent, BuildContext context) {
    final typeLabel = _typeLabel(message.typeDocument);
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
                    ? Colors.white.withOpacity(0.2)
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
                    message.fichierNom ?? message.contenu,
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
                  if (typeLabel != null)
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isSent
                            ? Colors.white.withOpacity(0.3)
                            : Theme.of(context).colorScheme.tertiaryFixed,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        typeLabel,
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
          ],
        ),
        const SizedBox(height: 4),
        Text(
          _formatTime(message.dateEnvoi),
          style: GoogleFonts.inter(
            fontSize: 10,
            color: isSent
                ? Colors.white60
                : Theme.of(context).colorScheme.outline,
          ),
        ),
      ],
    );
  }

  String? _typeLabel(TypeDocument? type) {
    switch (type) {
      case TypeDocument.fournisseur:
        return 'FOURNISSEUR (CHARGE)';
      case TypeDocument.releve_bancaire:
        return 'RELEVÉ BANCAIRE';
      case TypeDocument.chiffre_affaires:
        return 'CHIFFRE D\'AFFAIRES';
      case TypeDocument.autre:
        return 'AUTRE';
      default:
        return null;
    }
  }

  String _formatTime(DateTime d) {
    return '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }
}
