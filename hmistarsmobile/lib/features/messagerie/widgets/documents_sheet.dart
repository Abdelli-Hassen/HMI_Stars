import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DocumentsSheet extends StatefulWidget {
  const DocumentsSheet({super.key});

  @override
  State<DocumentsSheet> createState() => _DocumentsSheetState();
}

class _DocumentsSheetState extends State<DocumentsSheet> {
  String _selectedCategory = 'all';

  final _categories = {
    'all': 'Tous',
    'fournisseur': 'Fournisseurs',
    'bancaire': 'Bancaires',
    'ca': 'Chiffre d\'Affaires',
    'autre': 'Autres',
  };

  final _documents = [
    {
      'nom': 'Relevé Décembre 2026.pdf',
      'cat': 'bancaire',
      'date': '15/01/2026',
      'icon': Icons.account_balance,
    },
    {
      'nom': 'Facture Fournisseur #2451.pdf',
      'cat': 'fournisseur',
      'date': '10/01/2026',
      'icon': Icons.store,
    },
    {
      'nom': 'CA Novembre 2026.pdf',
      'cat': 'ca',
      'date': '05/12/2026',
      'icon': Icons.receipt_long,
    },
    {
      'nom': 'Facture Client #1120.pdf',
      'cat': 'ca',
      'date': '02/12/2026',
      'icon': Icons.receipt,
    },
    {
      'nom': 'Contrat Fournisseur.pdf',
      'cat': 'fournisseur',
      'date': '01/12/2026',
      'icon': Icons.description,
    },
    {
      'nom': 'Relevé Novembre 2026.pdf',
      'cat': 'bancaire',
      'date': '15/12/2026',
      'icon': Icons.account_balance,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filtered = _selectedCategory == 'all'
        ? _documents
        : _documents.where((d) => d['cat'] == _selectedCategory).toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      builder: (ctx, sc) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
              child: Text(
                'Documents',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Category filter chips
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: _categories.entries.map((entry) {
                  final isSelected = _selectedCategory == entry.key;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = entry.key),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        entry.value,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            Divider(
              height: 1,
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            Expanded(
              child: ListView.builder(
                controller: sc,
                padding: const EdgeInsets.all(16),
                itemCount: filtered.length,
                itemBuilder: (ctx, idx) {
                  final doc = filtered[idx];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerLowest,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Theme.of(
                              context,
                            ).colorScheme.tertiary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            doc['icon'] as IconData,
                            color: Theme.of(context).colorScheme.tertiary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                doc['nom'] as String,
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              Text(
                                doc['date'] as String,
                                style: GoogleFonts.inter(
                                  fontSize: 11,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.download_outlined,
                            color: Theme.of(context).colorScheme.outline,
                            size: 20,
                          ),
                          onPressed: () {},
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
