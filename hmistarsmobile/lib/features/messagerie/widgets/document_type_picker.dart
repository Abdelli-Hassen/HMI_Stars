import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/models.dart';

class DocumentTypePicker extends StatelessWidget {
  const DocumentTypePicker({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Type de Document',
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Veuillez sélectionner la catégorie de ce document avant l\'envoi.',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTypeOption(
                    context,
                    type: TypeDocument.fournisseur,
                    icon: Icons.store_outlined,
                    title: 'Fournisseur (Charge)',
                    subtitle: 'Factures, bons de livraison, charges',
                    color: Colors.deepOrange,
                  ),
                  _buildTypeOption(
                    context,
                    type: TypeDocument.releve_bancaire,
                    icon: Icons.account_balance_outlined,
                    title: 'Relevé Bancaire',
                    subtitle: 'Relevés de compte, extraits bancaires',
                    color: Colors.blue,
                  ),
                  _buildTypeOption(
                    context,
                    type: TypeDocument.chiffre_affaires,
                    icon: Icons.receipt_long_outlined,
                    title: 'Chiffre d\'Affaires',
                    subtitle: 'Factures clients, tickets de caisse, CA',
                    color: Colors.teal,
                  ),
                  _buildTypeOption(
                    context,
                    type: TypeDocument.kbis,
                    icon: Icons.business_outlined,
                    title: 'KBIS',
                    subtitle: 'Extrait Kbis, immatriculation',
                    color: Colors.purple,
                  ),
                  _buildTypeOption(
                    context,
                    type: TypeDocument.tva,
                    icon: Icons.percent_outlined,
                    title: 'Attestation TVA',
                    subtitle: 'Attestation de vigilance TVA, déclarations',
                    color: Colors.indigo,
                  ),
                  _buildTypeOption(
                    context,
                    type: TypeDocument.siret,
                    icon: Icons.badge_outlined,
                    title: 'SIRET / SIREN',
                    subtitle: 'Numéro SIRET, avis de situation INSEE',
                    color: Colors.amber[800]!,
                  ),
                  _buildTypeOption(
                    context,
                    type: TypeDocument.rib,
                    icon: Icons.credit_card_outlined,
                    title: 'RIB',
                    subtitle: 'Relevé d\'identité bancaire',
                    color: Colors.cyan,
                  ),
                  _buildTypeOption(
                    context,
                    type: TypeDocument.statuts,
                    icon: Icons.gavel_outlined,
                    title: 'Statuts',
                    subtitle: 'Statuts de l\'entreprise signés',
                    color: Colors.red,
                  ),
                  _buildTypeOption(
                    context,
                    type: TypeDocument.media,
                    icon: Icons.image_outlined,
                    title: 'Média / Photo',
                    subtitle: 'Photo, image, capture ou média',
                    color: Colors.pink,
                  ),
                  _buildTypeOption(
                    context,
                    type: TypeDocument.autre,
                    icon: Icons.folder_outlined,
                    title: 'Autre Document',
                    subtitle: 'Tout autre type de document',
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeOption(
    BuildContext context, {
    required TypeDocument type,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return InkWell(
      onTap: () => Navigator.pop(context, type),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: Theme.of(context).colorScheme.outline,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
