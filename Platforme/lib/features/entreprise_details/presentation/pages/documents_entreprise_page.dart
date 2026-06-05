import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/main_shell.dart';
import '../../../entreprises/presentation/providers/entreprise_provider.dart';
import '../../../entreprises/domain/models/document_entreprise.dart';

class DocumentsEntreprisePage extends StatefulWidget {
  const DocumentsEntreprisePage({super.key});

  @override
  State<DocumentsEntreprisePage> createState() => _DocumentsEntreprisePageState();
}

class _DocumentsEntreprisePageState extends State<DocumentsEntreprisePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _staggerController;
  int _selectedFolder = 0;
  String? _selectedEntrepriseId = 'all';
  String _searchQuery = '';
  int _visibleCount = 20;
  static const int _pageSize = 20;
  String _currentSort = 'recent';
  bool _initialized = false;

  // Library folder structure definitions
  static const _folderLabels = [
    'Tous les fichiers',
    'Comptabilité',
    'Social & Paie',
    'Fiscalité',
    'Banque & Relevés',
    'Juridique',
    'Médias & Photos',
    'Autres documents',
  ];

  String _categorizeDocument(DocumentEntreprise doc) {
    final nameLower = doc.nom.toLowerCase();
    final catLower = doc.categorie.toLowerCase();

    // 1. Social & Paie (contracts, payslips, hire declarations, etc.)
    if (nameLower.contains('contrat') ||
        nameLower.contains('cdi') ||
        nameLower.contains('cdd') ||
        nameLower.contains('paie') ||
        nameLower.contains('bulletin') ||
        nameLower.contains('salaire') ||
        nameLower.contains('embauche') ||
        nameLower.contains('social') ||
        nameLower.contains('dsn') ||
        catLower.contains('social') ||
        catLower.contains('paie')) {
      return 'Social & Paie';
    }

    // 2. Banque & Relevés
    if (nameLower.contains('rib') ||
        nameLower.contains('banque') ||
        nameLower.contains('releve') ||
        nameLower.contains('relevé') ||
        nameLower.contains('bancaire') ||
        nameLower.contains('bank') ||
        catLower.contains('relevé') ||
        catLower.contains('banque') ||
        catLower.contains('finance')) {
      return 'Banque & Relevés';
    }

    // 3. Fiscalité (TVA, Impôts, etc.)
    if (nameLower.contains('fiscal') ||
        nameLower.contains('impot') ||
        nameLower.contains('impôt') ||
        nameLower.contains('tva') ||
        nameLower.contains('liasse') ||
        nameLower.contains('taxe') ||
        catLower.contains('fiscal') ||
        catLower.contains('impot')) {
      return 'Fiscalité';
    }

    // 4. Juridique (KBis, statuts, PV, AG)
    if (nameLower.contains('statut') ||
        nameLower.contains('kbis') ||
        nameLower.contains('juridique') ||
        nameLower.contains('pv') ||
        nameLower.contains('assemblee') ||
        nameLower.contains('assemblée') ||
        nameLower.contains('greffe') ||
        catLower.contains('juridique')) {
      return 'Juridique';
    }

    // 5. Comptabilité (Sales, purchases, invoices: supplier, chiffre d'affaires, compta)
    if (nameLower.contains('facture') ||
        nameLower.contains('compta') ||
        nameLower.contains('achat') ||
        nameLower.contains('vente') ||
        nameLower.contains('client') ||
        nameLower.contains('fournisseur') ||
        nameLower.contains('ca ') ||
        nameLower.contains('chiffre d') ||
        catLower.contains('comptable') ||
        catLower.contains('client') ||
        catLower.contains('fournisseur')) {
      return 'Comptabilité';
    }

    // 6. Médias & Photos (images, photos, videos, etc.)
    if (nameLower.contains('.jpg') ||
        nameLower.contains('.jpeg') ||
        nameLower.contains('.png') ||
        nameLower.contains('.gif') ||
        nameLower.contains('.webp') ||
        nameLower.contains('.mp4') ||
        nameLower.contains('.mov') ||
        nameLower.contains('media') ||
        nameLower.contains('photo') ||
        nameLower.contains('image') ||
        nameLower.contains('scan') ||
        nameLower.contains('img_') ||
        catLower.contains('média') ||
        catLower.contains('media') ||
        catLower.contains('image') ||
        catLower.contains('photo')) {
      return 'Médias & Photos';
    }

    return 'Autres documents';
  }

  List<DocumentEntreprise> getFilteredDocuments(List<DocumentEntreprise> allDocs) {
    List<DocumentEntreprise> filtered = allDocs;

    // Search query filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((d) => d.nom.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    // Sidebar Folder category filter
    if (_selectedFolder != 0) {
      final folderLabel = _folderLabels[_selectedFolder];
      filtered = filtered.where((d) => _categorizeDocument(d) == folderLabel).toList();
    }

    // Apply sorting
    switch (_currentSort) {
      case 'ancien':
        filtered.sort((a, b) => a.dateAjout.compareTo(b.dateAjout));
        break;
      case 'nom_asc':
        filtered.sort((a, b) => a.nom.toLowerCase().compareTo(b.nom.toLowerCase()));
        break;
      case 'nom_desc':
        filtered.sort((a, b) => b.nom.toLowerCase().compareTo(a.nom.toLowerCase()));
        break;
      case 'recent':
      default:
        filtered.sort((a, b) => b.dateAjout.compareTo(a.dateAjout));
        break;
    }

    return filtered;
  }

  String _getSortLabel(String sortKey) {
    switch (sortKey) {
      case 'ancien':
        return 'Date (plus ancien)';
      case 'nom_asc':
        return 'Nom (A-Z)';
      case 'nom_desc':
        return 'Nom (Z-A)';
      case 'recent':
      default:
        return 'Date (plus récent)';
    }
  }

  void _showSortMenu(BuildContext context) async {
    final RenderBox button = context.findRenderObject() as RenderBox;
    final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
    final RelativeRect position = RelativeRect.fromRect(
      Rect.fromPoints(
        button.localToGlobal(Offset.zero, ancestor: overlay),
        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
      ),
      Offset.zero & overlay.size,
    );

    final result = await showMenu<String>(
      context: context,
      position: position,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: cs.outlineVariant, width: 1),
      ),
      color: cs.surfaceContainerLowest,
      items: [
        PopupMenuItem(
          value: 'recent',
          child: Text('Date (plus récent)', style: AppTextStyles.bodyMedium),
        ),
        PopupMenuItem(
          value: 'ancien',
          child: Text('Date (plus ancien)', style: AppTextStyles.bodyMedium),
        ),
        PopupMenuItem(
          value: 'nom_asc',
          child: Text('Nom (A-Z)', style: AppTextStyles.bodyMedium),
        ),
        PopupMenuItem(
          value: 'nom_desc',
          child: Text('Nom (Z-A)', style: AppTextStyles.bodyMedium),
        ),
      ],
      initialValue: _currentSort,
    );

    if (result != null) {
      setState(() {
        _currentSort = result;
      });
    }
  }

  void _showEntrepriseSearchDialog(BuildContext context, EntrepriseProvider provider) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String dialogSearchQuery = '';
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final cs = Theme.of(context).colorScheme;
            final filteredEntreprises = provider.entreprises
                .where((e) => e.nom.toLowerCase().contains(dialogSearchQuery.toLowerCase()))
                .toList();

            return Dialog(
              backgroundColor: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(
                  maxWidth: 480,
                  maxHeight: 560,
                ),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: cs.outlineVariant, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 16, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Sélectionner une entreprise',
                            style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w800),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.of(context).pop(),
                            color: cs.outline,
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: TextField(
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: "Cherchez votre entreprise",
                          prefixIcon: Icon(Icons.search, color: cs.outline),
                          filled: true,
                          fillColor: cs.surfaceContainerLow,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onChanged: (value) {
                          setDialogState(() {
                            dialogSearchQuery = value;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        itemCount: filteredEntreprises.length + 1,
                        itemBuilder: (context, index) {
                          final cs = Theme.of(context).colorScheme;
                          if (index == 0) {
                            final isSelected = _selectedEntrepriseId == 'all';
                            return Container(
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? cs.primary.withValues(alpha: 0.08)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListTile(
                                hoverColor: cs.surfaceContainerLow,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                leading: CircleAvatar(
                                  radius: 14,
                                  backgroundColor: cs.primary.withValues(alpha: 0.1),
                                  child: Icon(Icons.business, color: cs.primary, size: 16),
                                ),
                                title: Text(
                                  'Toutes les entreprises',
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected ? cs.primary : cs.onSurface,
                                  ),
                                ),
                                trailing: isSelected
                                    ? Icon(Icons.check_circle, color: cs.primary, size: 20)
                                    : null,
                                onTap: () {
                                  setState(() {
                                    _selectedEntrepriseId = 'all';
                                    _visibleCount = _pageSize;
                                  });
                                  provider.fetchDocumentsForEntreprise('all');
                                  Navigator.of(context).pop();
                                },
                              ),
                            );
                          }
                          final ent = filteredEntreprises[index - 1];
                          final isSelected = ent.id == _selectedEntrepriseId;

                          return Container(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? cs.primary.withValues(alpha: 0.08)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              hoverColor: cs.surfaceContainerLow,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                              ),
                              title: Text(
                                ent.nom,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? cs.primary : cs.onSurface,
                                ),
                              ),
                              trailing: isSelected
                                  ? Icon(Icons.check_circle, color: cs.primary, size: 20)
                                  : null,
                              onTap: () {
                                setState(() {
                                  _selectedEntrepriseId = ent.id;
                                  _visibleCount = _pageSize;
                                });
                                provider.fetchDocumentsForEntreprise(ent.id);
                                Navigator.of(context).pop();
                              },
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _staggerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final provider = Provider.of<EntrepriseProvider>(context);
    
    if (provider.entreprises.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        provider.fetchEntreprises();
      });
    } else if (_selectedEntrepriseId == 'all' && !_initialized) {
      final routeArg = ModalRoute.of(context)?.settings.arguments as String?;
      final initialId = routeArg ?? 'all';
      _selectedEntrepriseId = initialId;
      _initialized = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        provider.fetchDocumentsForEntreprise(initialId);
      });
    }
  }

  @override
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final provider = Provider.of<EntrepriseProvider>(context);

    if (provider.entreprises.isEmpty) {
      return const MainShell(
        currentRoute: AppRoutes.documentsEntreprise,
        title: 'Documents RH',
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final activeId = _selectedEntrepriseId ?? 'all';
    final allDocs = provider.documentsPourEntreprise(activeId);
    
    // Count per category
    int totalCount = allDocs.length;
    int comptaCount = 0;
    int socialPaieCount = 0;
    int fiscaliteCount = 0;
    int banqueCount = 0;
    int juridiqueCount = 0;
    int mediaCount = 0;
    int autresCount = 0;

    for (var doc in allDocs) {
      final category = _categorizeDocument(doc);
      if (category == 'Comptabilité') {
        comptaCount++;
      } else if (category == 'Social & Paie') {
        socialPaieCount++;
      } else if (category == 'Fiscalité') {
        fiscaliteCount++;
      } else if (category == 'Banque & Relevés') {
        banqueCount++;
      } else if (category == 'Juridique') {
        juridiqueCount++;
      } else if (category == 'Médias & Photos') {
        mediaCount++;
      } else if (category == 'Autres documents') {
        autresCount++;
      }
    }

    final folders = [
      _FolderData(Icons.folder, 'Tous les fichiers', totalCount),
      _FolderData(Icons.receipt_long, 'Comptabilité', comptaCount),
      _FolderData(Icons.supervised_user_circle, 'Social & Paie', socialPaieCount),
      _FolderData(Icons.gavel, 'Fiscalité', fiscaliteCount),
      _FolderData(Icons.account_balance, 'Banque & Relevés', banqueCount),
      _FolderData(Icons.business_center, 'Juridique', juridiqueCount),
      _FolderData(Icons.photo_library, 'Médias & Photos', mediaCount),
      _FolderData(Icons.more_horiz, 'Autres documents', autresCount),
    ];

    final filteredDocs = getFilteredDocuments(allDocs);

    return MainShell(
      currentRoute: AppRoutes.documentsEntreprise,
      title: 'Documents RH',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Page Header ───
            _buildHeader(provider),
            const SizedBox(height: 28),

            // ─── Bento Grid: Sidebar + Table ───
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Library Sidebar
                SizedBox(width: 260, child: _buildLibrarySidebar(folders)),
                const SizedBox(width: 24),
                // Documents Table
                Expanded(child: _buildDocumentsTable(filteredDocs, filteredDocs.length)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(EntrepriseProvider provider) {
    final activeId = _selectedEntrepriseId ?? 'all';
    final currentEntrepriseName = activeId == 'all'
        ? 'Toutes les entreprises'
        : provider.entreprises.firstWhere(
            (e) => e.id == activeId,
            orElse: () => provider.entreprises.first,
          ).nom;

    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero).animate(
        CurvedAnimation(parent: _staggerController, curve: const Interval(0, 0.4, curve: Curves.easeOutCubic)),
      ),
      child: FadeTransition(
        opacity: CurvedAnimation(parent: _staggerController, curve: const Interval(0, 0.4)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Documents RH', style: AppTextStyles.headlineLarge.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text('Gerez les documents contractuels et administratifs de ',
                        style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurfaceVariant)),
                    GestureDetector(
                      onTap: () => _showEntrepriseSearchDialog(context, provider),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: IntrinsicWidth(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: cs.primary.withValues(alpha: 0.24)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  currentEntrepriseName,
                                  style: AppTextStyles.bodyMedium.copyWith(
                                    color: cs.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(Icons.arrow_drop_down, color: cs.primary, size: 18),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Row(children: [
              Builder(
                builder: (buttonContext) {
                  return _HoverButton(
                    label: _getSortLabel(_currentSort),
                    icon: Icons.sort,
                    filled: false,
                    onTap: () => _showSortMenu(buttonContext),
                  );
                },
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildLibrarySidebar(List<_FolderData> folders) {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(-0.3, 0), end: Offset.zero).animate(
        CurvedAnimation(parent: _staggerController, curve: const Interval(0.15, 0.6, curve: Curves.easeOutCubic)),
      ),
      child: FadeTransition(
        opacity: CurvedAnimation(parent: _staggerController, curve: const Interval(0.15, 0.6)),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('BIBLIOTHEQUE', style: AppTextStyles.labelSmall.copyWith(
                letterSpacing: 1.5, fontWeight: FontWeight.w800, color: cs.primary,
              )),
              const SizedBox(height: 16),
              ...List.generate(folders.length, (i) => _FolderItem(
                data: folders[i],
                isActive: _selectedFolder == i,
                onTap: () => setState(() {
                  _selectedFolder = i;
                  _visibleCount = _pageSize;
                }),
              )),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDocumentsTable(List<DocumentEntreprise> filteredDocs, int totalDocsCount) {
    final displayedDocs = filteredDocs.take(_visibleCount).toList();
    final hasMore = _visibleCount < filteredDocs.length;

    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0.1, 0), end: Offset.zero).animate(
        CurvedAnimation(parent: _staggerController, curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic)),
      ),
      child: FadeTransition(
        opacity: CurvedAnimation(parent: _staggerController, curve: const Interval(0.2, 0.7)),
        child: Container(
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest,
            border: Border.all(color: cs.outlineVariant, width: 1),
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Table Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Documents recents', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700)),
                    SizedBox(
                      width: 240,
                      height: 36,
                      child: TextField(
                        onChanged: (val) {
                          setState(() {
                            _searchQuery = val;
                            _visibleCount = _pageSize;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Rechercher un document...',
                          hintStyle: AppTextStyles.bodySmall.copyWith(color: cs.outline),
                          prefixIcon: Icon(Icons.search, size: 18, color: cs.outline),
                          filled: true,
                          fillColor: cs.surfaceContainerLow,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          isDense: true,
                        ),
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),

              // Column Headers
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                color: cs.surfaceContainerLow.withValues(alpha: 0.5),
                child: Row(children: [
                  Expanded(flex: 3, child: Text('NOM DU DOCUMENT', style: _colHeader())),
                  Expanded(child: Text('TYPE', style: _colHeader())),
                  Expanded(child: Text('DATE AJOUTE', style: _colHeader())),
                  const SizedBox(width: 40),
                ]),
              ),

              // Document Rows
              ...List.generate(displayedDocs.length, (i) {
                final start = 0.25 + (i * 0.08);
                final end = (start + 0.3).clamp(0.0, 1.0);
                return SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(
                    CurvedAnimation(parent: _staggerController, curve: Interval(start, end, curve: Curves.easeOutCubic)),
                  ),
                  child: FadeTransition(
                    opacity: CurvedAnimation(parent: _staggerController, curve: Interval(start, end)),
                    child: _DocumentRow(
                      doc: displayedDocs[i],
                    ),
                  ),
                );
              }),
              if (displayedDocs.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.folder_open, size: 40, color: cs.outline),
                        const SizedBox(height: 8),
                        Text('Aucun document dans cette categorie',
                            style: AppTextStyles.bodySmall.copyWith(color: cs.outline)),
                      ],
                    ),
                  ),
                ),

              // Pagination info / Charger plus
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                color: cs.surfaceContainerLow.withValues(alpha: 0.3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Affichage de ${displayedDocs.length} sur ${filteredDocs.length} documents',
                      style: AppTextStyles.bodySmall.copyWith(color: cs.onSurfaceVariant),
                    ),
                    if (hasMore)
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _visibleCount += _pageSize;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: cs.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.add, size: 14, color: Colors.white),
                                const SizedBox(width: 6),
                                Text(
                                  'Charger plus',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      Text(
                        'Tous les documents affiches',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: cs.outline,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TextStyle _colHeader() => AppTextStyles.labelSmall.copyWith(
        letterSpacing: 1.2,
        fontWeight: FontWeight.w700,
        color: cs.onSurfaceVariant,
      );
}

// ─── Data Classes ───

class _FolderData {
  final IconData icon;
  final String label;
  final int count;
  const _FolderData(this.icon, this.label, this.count);
}

// ─── Animated Folder Item ───

class _FolderItem extends StatefulWidget {
  final _FolderData data;
  final bool isActive;
  final VoidCallback onTap;

  const _FolderItem({required this.data, required this.isActive, required this.onTap});

  @override
  State<_FolderItem> createState() => _FolderItemState();
}

class _FolderItemState extends State<_FolderItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.only(bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: widget.isActive
                ? cs.surfaceContainer
                : _hovered
                    ? cs.surfaceContainerLow
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(widget.data.icon, size: 20,
                  color: widget.isActive ? cs.primary : cs.onSurfaceVariant),
              const SizedBox(width: 10),
              Expanded(
                child: Text(widget.data.label, style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w500,
                  color: widget.isActive ? cs.primary : cs.onSurfaceVariant,
                )),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: widget.isActive ? cs.primary.withValues(alpha: 0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${widget.data.count}', style: AppTextStyles.labelSmall.copyWith(
                  fontSize: 10,
                  color: widget.isActive ? cs.primary : cs.outline,
                  fontWeight: FontWeight.w700,
                )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Animated Document Row ───

class _DocumentRow extends StatefulWidget {
  final DocumentEntreprise doc;
  const _DocumentRow({required this.doc});

  @override
  State<_DocumentRow> createState() => _DocumentRowState();
}

class _DocumentRowState extends State<_DocumentRow> {
  bool _hovered = false;

  IconData get _docIcon {
    final format = widget.doc.format.toLowerCase();
    if (format.contains('pdf')) return Icons.picture_as_pdf;
    if (format.contains('png') || format.contains('jpg') || format.contains('jpeg') || format.contains('webp')) return Icons.image;
    return Icons.description;
  }

  Future<void> _viewDocument() async {
    final url = widget.doc.url;
    if (url != null) {
      final uri = Uri.tryParse(url);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final formattedDate = "${widget.doc.dateAjout.day}/${widget.doc.dateAjout.month}/${widget.doc.dateAjout.year}";

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        decoration: BoxDecoration(
          color: _hovered ? cs.primary.withValues(alpha: 0.02) : Colors.transparent,
          border: Border(bottom: BorderSide(color: cs.surfaceContainer)),
        ),
        child: Row(
          children: [
            // Icon + Name
            Expanded(
              flex: 3,
              child: Row(children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _hovered ? cs.primary : cs.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_docIcon, size: 20,
                      color: _hovered ? Colors.white : cs.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.doc.nom,
                    style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ]),
            ),
            // Type
            Expanded(
              child: Text(widget.doc.categorie, style: AppTextStyles.bodySmall.copyWith(color: cs.onSurfaceVariant)),
            ),
            // Date
            Expanded(
              child: Text(formattedDate, style: AppTextStyles.bodySmall.copyWith(color: cs.onSurfaceVariant)),
            ),
            // More menu
            SizedBox(
              width: 40,
              child: AnimatedOpacity(
                opacity: _hovered ? 1.0 : 0.3,
                duration: const Duration(milliseconds: 200),
                child: IconButton(
                  icon: const Icon(Icons.more_vert, size: 18),
                  color: _hovered ? cs.primary : cs.outline,
                  onPressed: () {
                    final RenderBox button = context.findRenderObject() as RenderBox;
                    final RenderBox overlay = Navigator.of(context).overlay!.context.findRenderObject() as RenderBox;
                    final RelativeRect position = RelativeRect.fromRect(
                      Rect.fromPoints(
                        button.localToGlobal(Offset.zero, ancestor: overlay),
                        button.localToGlobal(button.size.bottomRight(Offset.zero), ancestor: overlay),
                      ),
                      Offset.zero & overlay.size,
                    );
                    showMenu<String>(
                      context: context,
                      position: position,
                      items: [
                        PopupMenuItem(
                          value: 'view',
                          child: Row(
                            children: [
                              Icon(Icons.open_in_new, size: 18, color: cs.primary),
                              const SizedBox(width: 8),
                              Text('Ouvrir / Voir', style: AppTextStyles.bodyMedium),
                            ],
                          ),
                        ),
                      ],
                    ).then((value) {
                      if (value == 'view') {
                        _viewDocument();
                      }
                    });
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Hover Button ───

class _HoverButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;

  const _HoverButton({required this.label, required this.icon, required this.filled, required this.onTap});

  @override
  State<_HoverButton> createState() => _HoverButtonState();
}

class _HoverButtonState extends State<_HoverButton> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() { _hovered = false; _pressed = false; }),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          transform: Matrix4.diagonal3Values(_pressed ? 0.95 : 1.0, _pressed ? 0.95 : 1.0, 1.0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: widget.filled ? cs.primaryGradient : null,
            color: widget.filled ? null : cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(8),
            boxShadow: widget.filled && _hovered
                ? [BoxShadow(color: cs.primary.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4))]
                : null,
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(widget.icon, size: 16,
                color: widget.filled ? Colors.white : cs.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(widget.label, style: AppTextStyles.labelMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: widget.filled ? Colors.white : cs.onSurfaceVariant,
            )),
          ]),
        ),
      ),
    );
  }
}
