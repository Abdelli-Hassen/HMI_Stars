import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/models/models.dart';
import '../../../core/utils/translation_extension.dart';

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
                  context.tr('Type de Document', 'Document Type'),
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.tr('Veuillez sélectionner la catégorie de ce document avant l\'envoi.', 'Please select the category of this document before sending.'),
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
                    title: context.tr('Fournisseur (Charge)', 'Supplier (Expense)'),
                    subtitle: context.tr('Factures, bons de livraison, charges', 'Invoices, delivery notes, expenses'),
                    color: Colors.deepOrange,
                  ),
                  _buildTypeOption(
                    context,
                    type: TypeDocument.releve_bancaire,
                    icon: Icons.account_balance_outlined,
                    title: context.tr('Relevé Bancaire', 'Bank Statement'),
                    subtitle: context.tr('Relevés de compte, extraits bancaires', 'Account statements, bank extracts'),
                    color: Colors.blue,
                  ),
                  _buildTypeOption(
                    context,
                    type: TypeDocument.chiffre_affaires,
                    icon: Icons.receipt_long_outlined,
                    title: context.tr('Chiffre d\'Affaires', 'Revenue'),
                    subtitle: context.tr('Factures clients, tickets de caisse, CA', 'Client invoices, receipts, revenue'),
                    color: Colors.teal,
                  ),
                  _buildTypeOption(
                    context,
                    type: TypeDocument.kbis,
                    icon: Icons.business_outlined,
                    title: 'KBIS',
                    subtitle: context.tr('Extrait Kbis, immatriculation', 'Kbis extract, registration'),
                    color: Colors.purple,
                  ),
                  _buildTypeOption(
                    context,
                    type: TypeDocument.tva,
                    icon: Icons.percent_outlined,
                    title: context.tr('Attestation TVA', 'VAT Certificate'),
                    subtitle: context.tr('Attestation de vigilance TVA, déclarations', 'VAT vigilance certificate, declarations'),
                    color: Colors.indigo,
                  ),
                  _buildTypeOption(
                    context,
                    type: TypeDocument.siret,
                    icon: Icons.badge_outlined,
                    title: 'SIRET / SIREN',
                    subtitle: context.tr('Numéro SIRET, avis de situation INSEE', 'SIRET number, INSEE status notice'),
                    color: Colors.amber[800]!,
                  ),
                  _buildTypeOption(
                    context,
                    type: TypeDocument.rib,
                    icon: Icons.credit_card_outlined,
                    title: 'RIB',
                    subtitle: context.tr('Relevé d\'identité bancaire', 'Bank identity statement'),
                    color: Colors.cyan,
                  ),
                  _buildTypeOption(
                    context,
                    type: TypeDocument.statuts,
                    icon: Icons.gavel_outlined,
                    title: context.tr('Statuts', 'Articles of Association'),
                    subtitle: context.tr('Statuts de l\'entreprise signés', 'Signed company articles'),
                    color: Colors.red,
                  ),
                  _buildTypeOption(
                    context,
                    type: TypeDocument.media,
                    icon: Icons.image_outlined,
                    title: context.tr('Média / Photo', 'Media / Photo'),
                    subtitle: context.tr('Photo, image, capture ou média', 'Photo, image, capture or media'),
                    color: Colors.pink,
                  ),
                  _buildTypeOption(
                    context,
                    type: TypeDocument.autre,
                    icon: Icons.folder_outlined,
                    title: context.tr('Autre Document', 'Other Document'),
                    subtitle: context.tr('Tout autre type de document', 'Any other type of document'),
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
