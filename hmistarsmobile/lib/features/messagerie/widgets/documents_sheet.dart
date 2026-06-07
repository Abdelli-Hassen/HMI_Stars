import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/widgets/mobile_file_previewer.dart';

import '../../../core/models/models.dart';
import '../../../core/providers/app_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Main categories (direction of flow)
// ─────────────────────────────────────────────────────────────────────────────
enum _MainCategory { all, sentByMe, receivedFromHmi }

extension _MainCategoryX on _MainCategory {
  String get label {
    switch (this) {
      case _MainCategory.all:
        return 'Tous';
      case _MainCategory.sentByMe:
        return 'Envoyés';
      case _MainCategory.receivedFromHmi:
        return 'Reçus';
    }
  }

  IconData get icon {
    switch (this) {
      case _MainCategory.all:
        return Icons.folder_copy_outlined;
      case _MainCategory.sentByMe:
        return Icons.upload_outlined;
      case _MainCategory.receivedFromHmi:
        return Icons.download_outlined;
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers mapping TypeDocument → display data
// ─────────────────────────────────────────────────────────────────────────────
class _DocMeta {
  final String label;
  final IconData icon;
  final Color color;
  const _DocMeta(this.label, this.icon, this.color);
}

const _typeDocMeta = <TypeDocument, _DocMeta>{
  TypeDocument.fournisseur: _DocMeta(
    'Fournisseurs',
    Icons.store_outlined,
    Color(0xFF6366F1),
  ),
  TypeDocument.releve_bancaire: _DocMeta(
    'Relevés Bancaires',
    Icons.account_balance_outlined,
    Color(0xFF0EA5E9),
  ),
  TypeDocument.chiffre_affaires: _DocMeta(
    "Chiffre d'Affaires",
    Icons.bar_chart_rounded,
    Color(0xFF10B981),
  ),
  TypeDocument.kbis: _DocMeta(
    'Kbis',
    Icons.business_center_outlined,
    Color(0xFFF59E0B),
  ),
  TypeDocument.tva: _DocMeta(
    'TVA',
    Icons.receipt_long_outlined,
    Color(0xFFEF4444),
  ),
  TypeDocument.siret: _DocMeta(
    'SIRET',
    Icons.badge_outlined,
    Color(0xFF8B5CF6),
  ),
  TypeDocument.rib: _DocMeta(
    'RIB',
    Icons.credit_card_outlined,
    Color(0xFF06B6D4),
  ),
  TypeDocument.statuts: _DocMeta(
    'Statuts',
    Icons.gavel_outlined,
    Color(0xFFF97316),
  ),
  TypeDocument.media: _DocMeta(
    'Médias',
    Icons.perm_media_outlined,
    Color(0xFFEC4899),
  ),
  TypeDocument.autre: _DocMeta(
    'Autres',
    Icons.insert_drive_file_outlined,
    Color(0xFF6B7280),
  ),
};

_DocMeta _metaFor(TypeDocument? type) =>
    _typeDocMeta[type ?? TypeDocument.autre] ?? _typeDocMeta[TypeDocument.autre]!;

String _formatDate(DateTime dt) => DateFormat('dd/MM/yyyy').format(dt);

// ─────────────────────────────────────────────────────────────────────────────
// Widget
// ─────────────────────────────────────────────────────────────────────────────
class DocumentsSheet extends StatefulWidget {
  const DocumentsSheet({super.key});

  @override
  State<DocumentsSheet> createState() => _DocumentsSheetState();
}

class _DocumentsSheetState extends State<DocumentsSheet>
    with SingleTickerProviderStateMixin {
  _MainCategory _mainCat = _MainCategory.all;
  TypeDocument? _subCat; // null = show all sub-types

  // Track which file URL is being opened to show loading feedback
  String? _openingUrl;

  @override
  void initState() {
    super.initState();
    // Refresh fichiers when the sheet opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AppState>().loadFichiers();
      }
    });
  }

  // ── filtering ────────────────────────────────────────────────────────────
  List<Fichier> _applyFilters(List<Fichier> fichiers) {
    var list = fichiers;

    // Main category
    switch (_mainCat) {
      case _MainCategory.sentByMe:
        list = list.where((f) => f.estEnvoyeParUser).toList();
        break;
      case _MainCategory.receivedFromHmi:
        list = list.where((f) => !f.estEnvoyeParUser).toList();
        break;
      case _MainCategory.all:
        break;
    }

    // Sub-category
    if (_subCat != null) {
      list = list
          .where((f) => (f.typeDocument ?? TypeDocument.autre) == _subCat)
          .toList();
    }

    return list;
  }

  // ── open URL ────────────────────────────────────────────────────────────
  Future<void> _openFile(Fichier fichier) async {
    MobileFilePreviewer.show(context, fichier.url, fichier.nom);
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      maxChildSize: 0.95,
      minChildSize: 0.5,
      expand: false,
      builder: (ctx, sc) => Container(
        decoration: BoxDecoration(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Handle ──────────────────────────────────────────────────
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Title row ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cs.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.folder_copy_rounded,
                      color: cs.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Documents',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w800,
                      fontSize: 22,
                      color: cs.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Main category tabs ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: cs.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: _MainCategory.values.map((cat) {
                    final isSelected = _mainCat == cat;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _mainCat = cat;
                          _subCat = null;
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.symmetric(vertical: 9),
                          decoration: BoxDecoration(
                            color: isSelected ? cs.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: cs.primary.withOpacity(0.25),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                cat.icon,
                                size: 15,
                                color: isSelected
                                    ? Colors.white
                                    : cs.onSurfaceVariant,
                              ),
                              const SizedBox(width: 5),
                              Text(
                                cat.label,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? Colors.white
                                      : cs.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Sub-category chips ────────────────────────────────────────
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  // "All" chip
                  _SubChip(
                    label: 'Tous',
                    icon: Icons.apps_rounded,
                    color: cs.primary,
                    isSelected: _subCat == null,
                    onTap: () => setState(() => _subCat = null),
                  ),
                  ...TypeDocument.values.map((type) {
                    final meta = _metaFor(type);
                    return _SubChip(
                      label: meta.label,
                      icon: meta.icon,
                      color: meta.color,
                      isSelected: _subCat == type,
                      onTap: () => setState(
                        () => _subCat = _subCat == type ? null : type,
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 8),

            Divider(height: 1, color: cs.outlineVariant),

            // ── Document list ────────────────────────────────────────────
            Expanded(
              child: Consumer<AppState>(
                builder: (context, state, _) {
                  if (state.isLoadingFichiers && state.fichiers.isEmpty) {
                    return const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    );
                  }

                  final filtered = _applyFilters(state.fichiers);

                  if (filtered.isEmpty) {
                    return _EmptyState(
                      mainCat: _mainCat,
                      subCat: _subCat,
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => state.loadFichiers(),
                    child: ListView.builder(
                      controller: sc,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) => _DocumentTile(
                        fichier: filtered[i],
                        isOpening: _openingUrl == filtered[i].id,
                        onOpen: () => _openFile(filtered[i]),
                      ),
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

// ─────────────────────────────────────────────────────────────────────────────
// Sub-category chip widget
// ─────────────────────────────────────────────────────────────────────────────
class _SubChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _SubChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.15) : cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: isSelected ? color : cs.onSurfaceVariant),
            const SizedBox(width: 5),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? color : cs.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Document tile
// ─────────────────────────────────────────────────────────────────────────────
class _DocumentTile extends StatelessWidget {
  final Fichier fichier;
  final bool isOpening;
  final VoidCallback onOpen;

  const _DocumentTile({
    required this.fichier,
    required this.isOpening,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final meta = _metaFor(fichier.typeDocument);
    final sentByMe = fichier.estEnvoyeParUser;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
            child: Row(
              children: [
                // Icon
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: meta.color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(meta.icon, color: meta.color, size: 22),
                ),
                const SizedBox(width: 13),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fichier.nom,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          _Badge(
                            label: meta.label,
                            color: meta.color,
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            sentByMe
                                ? Icons.upload_outlined
                                : Icons.download_outlined,
                            size: 12,
                            color: sentByMe
                                ? cs.primary.withOpacity(0.7)
                                : cs.tertiary.withOpacity(0.7),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            _formatDate(fichier.creeLe),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Open/Download button
                SizedBox(
                  width: 40,
                  height: 40,
                  child: isOpening
                      ? const Center(
                          child: SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : IconButton(
                          icon: Icon(
                            Icons.open_in_new_rounded,
                            size: 19,
                            color: cs.primary,
                          ),
                          onPressed: onOpen,
                          tooltip: 'Ouvrir',
                          padding: EdgeInsets.zero,
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Small coloured badge
// ─────────────────────────────────────────────────────────────────────────────
class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty state
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final _MainCategory mainCat;
  final TypeDocument? subCat;
  const _EmptyState({required this.mainCat, required this.subCat});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final subLabel = subCat != null ? _metaFor(subCat).label : '';
    final mainLabel = mainCat == _MainCategory.all ? '' : mainCat.label;
    final detail = [mainLabel, subLabel].where((s) => s.isNotEmpty).join(' · ');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.folder_open_rounded,
              size: 64,
              color: cs.outlineVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'Aucun document',
              style: GoogleFonts.manrope(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            if (detail.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                detail,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
