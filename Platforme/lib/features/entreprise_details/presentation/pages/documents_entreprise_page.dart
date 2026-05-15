import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/main_shell.dart';

class DocumentsEntreprisePage extends StatefulWidget {
  const DocumentsEntreprisePage({super.key});

  @override
  State<DocumentsEntreprisePage> createState() => _DocumentsEntreprisePageState();
}

class _DocumentsEntreprisePageState extends State<DocumentsEntreprisePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _staggerController;
  int _selectedFolder = 0;
  bool _uploadHovered = false;

  final _folders = [
    _FolderData(Icons.folder, 'Tous les fichiers', 24),
    _FolderData(Icons.history_edu, 'Contrats', 3),
    _FolderData(Icons.payments, 'Fiches de Paie', 12),
    _FolderData(Icons.school, 'Diplômes', 5),
    _FolderData(Icons.account_balance, 'RIB & Admin', 4),
  ];

  // Map folder index to document type for filtering
  static const _folderTypeMap = {
    1: 'Contrat',
    2: 'Paie',
    3: 'Diplômes',
    4: 'Banque',
  };

  final _documents = const [
    _DocData('Contrat de Travail - CDI.pdf', 'Mis à jour par Expert RH', 'Contrat', '12 Mai 2026', 'Signé', true),
    _DocData('Avenant Contrat - Promotion.pdf', 'Mis à jour par Expert RH', 'Contrat', '05 Avril 2026', 'Signé', true),
    _DocData('Attestation Employeur.pdf', 'Génération automatique', 'Contrat', '20 Jan 2026', 'Validé', true),
    _DocData('Fiche de Paie - Juin 2026.pdf', 'Génération automatique', 'Paie', '30 Juin 2026', 'Signé', true),
    _DocData('Fiche de Paie - Mai 2026.pdf', 'Génération automatique', 'Paie', '31 Mai 2026', 'Signé', true),
    _DocData('Fiche de Paie - Avril 2026.pdf', 'Génération automatique', 'Paie', '30 Avril 2026', 'Signé', true),
    _DocData('Master Management.jpg', 'Téléversé par Jean Dupont', 'Diplômes', '15 Mars 2026', 'À vérifier', false),
    _DocData('Licence Économie.pdf', 'Téléversé par Jean Dupont', 'Diplômes', '15 Mars 2026', 'Validé', true),
    _DocData('RIB - Compte Personnel.pdf', 'Téléversé par Jean Dupont', 'Banque', '02 Fév 2026', 'Validé', true),
    _DocData('Mutuelle - Attestation.pdf', 'Téléversé par Expert RH', 'Banque', '10 Jan 2026', 'Signé', true),
  ];

  List<_DocData> get _filteredDocuments {
    if (_selectedFolder == 0) return _documents;
    final type = _folderTypeMap[_selectedFolder];
    if (type == null) return _documents;
    return _documents.where((d) => d.type == type).toList();
  }

  void _showUploadDialog() {
    showDialog(
      context: context,
      barrierColor: Colors.black54,
      builder: (ctx) => _UploadDialog(),
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
  void dispose() {
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainShell(
      currentRoute: AppRoutes.documentsEntreprise,
      title: 'Documents RH',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Page Header ───
            _buildHeader(),
            const SizedBox(height: 28),

            // ─── Bento Grid: Sidebar + Table ───
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Library Sidebar
                SizedBox(width: 260, child: _buildLibrarySidebar()),
                const SizedBox(width: 24),
                // Documents Table
                Expanded(child: _buildDocumentsTable()),
              ],
            ),
            const SizedBox(height: 24),

            // ─── Conformity + Upload Zone ───
            _buildConformityFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
                Text('Gérez les documents contractuels et administratifs de Jean Dupont.',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.onSurfaceVariant)),
              ],
            ),
            Row(children: [
              _HoverButton(
                label: 'Filtrer',
                icon: Icons.filter_list,
                filled: false,
                onTap: () {},
              ),
              const SizedBox(width: 10),
              _HoverButton(
                label: 'Nouveau Document',
                icon: Icons.upload,
                filled: true,
                onTap: _showUploadDialog,
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildLibrarySidebar() {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(-0.3, 0), end: Offset.zero).animate(
        CurvedAnimation(parent: _staggerController, curve: const Interval(0.15, 0.6, curve: Curves.easeOutCubic)),
      ),
      child: FadeTransition(
        opacity: CurvedAnimation(parent: _staggerController, curve: const Interval(0.15, 0.6)),
        child: Column(children: [
          // Folder list
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: const Border(left: BorderSide(color: AppColors.primary, width: 4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('BIBLIOTHÈQUE', style: AppTextStyles.labelSmall.copyWith(
                  letterSpacing: 1.5, fontWeight: FontWeight.w800, color: AppColors.primary,
                )),
                const SizedBox(height: 16),
                ...List.generate(_folders.length, (i) => _FolderItem(
                  data: _folders[i],
                  isActive: _selectedFolder == i,
                  onTap: () => setState(() => _selectedFolder = i),
                )),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Storage usage
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('STOCKAGE UTILISÉ', style: AppTextStyles.labelSmall.copyWith(
                  letterSpacing: 1.5, fontWeight: FontWeight.w800, color: AppColors.onSurfaceVariant,
                )),
                const SizedBox(height: 16),
                TweenAnimationBuilder(
                  tween: Tween<double>(begin: 0, end: 0.45),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: value,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text('450 Mo sur 1 Go (${(value * 100).round()}%)',
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.onSurfaceVariant)),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  Widget _buildDocumentsTable() {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0.1, 0), end: Offset.zero).animate(
        CurvedAnimation(parent: _staggerController, curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic)),
      ),
      child: FadeTransition(
        opacity: CurvedAnimation(parent: _staggerController, curve: const Interval(0.2, 0.7)),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
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
                    Text('Documents récents', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700)),
                    SizedBox(
                      width: 240,
                      height: 36,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Rechercher un document...',
                          hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.outline),
                          prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.outline),
                          filled: true,
                          fillColor: AppColors.surfaceContainerLow,
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
                color: AppColors.surfaceContainerLow.withValues(alpha: 0.5),
                child: Row(children: [
                  Expanded(flex: 3, child: Text('NOM DU DOCUMENT', style: _colHeader())),
                  Expanded(child: Text('TYPE', style: _colHeader())),
                  Expanded(child: Text('DERNIÈRE MODIFICATION', style: _colHeader())),
                  SizedBox(width: 100, child: Center(child: Text('STATUT', style: _colHeader()))),
                  const SizedBox(width: 40),
                ]),
              ),

              // Document Rows (filtered + staggered)
              ...List.generate(_filteredDocuments.length, (i) {
                final start = 0.25 + (i * 0.08);
                final end = (start + 0.3).clamp(0.0, 1.0);
                return SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(
                    CurvedAnimation(parent: _staggerController, curve: Interval(start, end, curve: Curves.easeOutCubic)),
                  ),
                  child: FadeTransition(
                    opacity: CurvedAnimation(parent: _staggerController, curve: Interval(start, end)),
                    child: _DocumentRow(data: _filteredDocuments[i]),
                  ),
                );
              }),
              if (_filteredDocuments.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.folder_open, size: 40, color: AppColors.outline),
                        const SizedBox(height: 8),
                        Text('Aucun document dans cette catégorie',
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.outline)),
                      ],
                    ),
                  ),
                ),

              // Pagination
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                color: AppColors.surfaceContainerLow.withValues(alpha: 0.3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Affichage de ${_filteredDocuments.length} sur ${_documents.length} fichiers', style: AppTextStyles.bodySmall.copyWith(color: AppColors.onSurfaceVariant)),
                    Row(children: [
                      _PaginationBtn(icon: Icons.chevron_left, isActive: false),
                      const SizedBox(width: 4),
                      _PaginationBtn(number: '1', isActive: true),
                      const SizedBox(width: 4),
                      _PaginationBtn(number: '2', isActive: false),
                      const SizedBox(width: 4),
                      _PaginationBtn(icon: Icons.chevron_right, isActive: false),
                    ]),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConformityFooter() {
    return SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
        CurvedAnimation(parent: _staggerController, curve: const Interval(0.5, 0.9, curve: Curves.easeOutCubic)),
      ),
      child: FadeTransition(
        opacity: CurvedAnimation(parent: _staggerController, curve: const Interval(0.5, 0.9)),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(children: [
            // Conformity card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(left: BorderSide(color: AppColors.primary, width: 4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Icon(Icons.task_alt, color: AppColors.primary, size: 22),
                      const SizedBox(width: 8),
                      Text('Conformité du dossier', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700)),
                    ]),
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        TweenAnimationBuilder(
                          tween: IntTween(begin: 0, end: 85),
                          duration: const Duration(milliseconds: 1500),
                          curve: Curves.easeOutCubic,
                          builder: (context, value, child) => Text(
                            '$value%',
                            style: AppTextStyles.displaySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFA33500).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text('ACTION REQUISE', style: AppTextStyles.labelSmall.copyWith(
                            fontSize: 9, fontWeight: FontWeight.w700, color: const Color(0xFFA33500),
                            letterSpacing: 0.5,
                          )),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Il manque encore 3 documents pour que le dossier administratif de Jean Dupont soit complet à 100%.',
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.onSurfaceVariant, height: 1.5),
                    ),
                  ],
                ),
              ),
            ),

            // Upload Drop Zone
            Expanded(
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                onEnter: (_) => setState(() => _uploadHovered = true),
                onExit: (_) => setState(() => _uploadHovered = false),
                child: GestureDetector(
                  onTap: _showUploadDialog,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: _uploadHovered ? Colors.white : AppColors.surfaceContainerLow,
                      border: Border(left: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.1))),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _uploadHovered ? AppColors.primary : AppColors.outlineVariant,
                          width: 2,
                          style: BorderStyle.solid,
                        ),
                        color: _uploadHovered ? Colors.white : AppColors.surfaceContainerLowest.withValues(alpha: 0.5),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            transform: Matrix4.translationValues(0, _uploadHovered ? -4 : 0, 0),
                            child: Icon(
                              Icons.cloud_upload_outlined,
                              size: 40,
                              color: _uploadHovered ? AppColors.primary : AppColors.outline,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text('Glissez vos fichiers ici',
                              style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          Text('Format PDF, JPG ou PNG (max 10Mo)',
                              style: AppTextStyles.bodySmall.copyWith(color: AppColors.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  TextStyle _colHeader() => AppTextStyles.labelSmall.copyWith(
        letterSpacing: 1.2,
        fontWeight: FontWeight.w700,
        color: AppColors.onSurfaceVariant,
      );
}

// ─── Data Classes ───

class _FolderData {
  final IconData icon;
  final String label;
  final int count;
  const _FolderData(this.icon, this.label, this.count);
}

class _DocData {
  final String name, subtitle, type, date, status;
  final bool isVerified;
  const _DocData(this.name, this.subtitle, this.type, this.date, this.status, this.isVerified);
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
                ? AppColors.surfaceContainer
                : _hovered
                    ? AppColors.surfaceContainerLow
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Icon(widget.data.icon, size: 20,
                  color: widget.isActive ? AppColors.primary : AppColors.onSurfaceVariant),
              const SizedBox(width: 10),
              Expanded(
                child: Text(widget.data.label, style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w500,
                  color: widget.isActive ? AppColors.primary : AppColors.onSurfaceVariant,
                )),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: widget.isActive ? AppColors.primary.withValues(alpha: 0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('${widget.data.count}', style: AppTextStyles.labelSmall.copyWith(
                  fontSize: 10,
                  color: widget.isActive ? AppColors.primary : AppColors.outline,
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
  final _DocData data;
  const _DocumentRow({required this.data});

  @override
  State<_DocumentRow> createState() => _DocumentRowState();
}

class _DocumentRowState extends State<_DocumentRow> {
  bool _hovered = false;

  IconData get _docIcon {
    switch (widget.data.type) {
      case 'Contrat': return Icons.description;
      case 'Paie': return Icons.picture_as_pdf;
      case 'Diplômes': return Icons.school;
      case 'Banque': return Icons.credit_card;
      default: return Icons.insert_drive_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        decoration: BoxDecoration(
          color: _hovered ? AppColors.primary.withValues(alpha: 0.02) : Colors.transparent,
          border: Border(bottom: BorderSide(color: AppColors.surfaceContainer)),
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
                    color: _hovered ? AppColors.primary : AppColors.primary.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(_docIcon, size: 20,
                      color: _hovered ? Colors.white : AppColors.primary),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.data.name, style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600)),
                    Text(widget.data.subtitle, style: AppTextStyles.bodySmall.copyWith(fontSize: 11, color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ]),
            ),
            // Type
            Expanded(
              child: Text(widget.data.type, style: AppTextStyles.bodySmall.copyWith(color: AppColors.onSurfaceVariant)),
            ),
            // Date
            Expanded(
              child: Text(widget.data.date, style: AppTextStyles.bodySmall.copyWith(color: AppColors.onSurfaceVariant)),
            ),
            // Status badge
            SizedBox(
              width: 100,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: widget.data.isVerified
                        ? AppColors.secondaryContainer
                        : const Color(0xFFA33500),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(width: 6, height: 6, decoration: BoxDecoration(
                        color: widget.data.isVerified ? AppColors.secondary : Colors.white,
                        shape: BoxShape.circle,
                      )),
                      const SizedBox(width: 6),
                      Text(widget.data.status, style: AppTextStyles.labelSmall.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: widget.data.isVerified
                            ? AppColors.onSecondaryContainer
                            : Colors.white,
                      )),
                    ],
                  ),
                ),
              ),
            ),
            // More menu
            SizedBox(
              width: 40,
              child: AnimatedOpacity(
                opacity: _hovered ? 1.0 : 0.3,
                duration: const Duration(milliseconds: 200),
                child: IconButton(
                  icon: const Icon(Icons.more_vert, size: 18),
                  color: _hovered ? AppColors.primary : AppColors.outline,
                  onPressed: () {},
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
            gradient: widget.filled ? AppColors.primaryGradient : null,
            color: widget.filled ? null : AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(8),
            boxShadow: widget.filled && _hovered
                ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 4))]
                : null,
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(widget.icon, size: 16,
                color: widget.filled ? Colors.white : AppColors.onSurfaceVariant),
            const SizedBox(width: 8),
            Text(widget.label, style: AppTextStyles.labelMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: widget.filled ? Colors.white : AppColors.onSurfaceVariant,
            )),
          ]),
        ),
      ),
    );
  }
}

// ─── Pagination Button ───

class _PaginationBtn extends StatefulWidget {
  final IconData? icon;
  final String? number;
  final bool isActive;

  const _PaginationBtn({this.icon, this.number, required this.isActive});

  @override
  State<_PaginationBtn> createState() => _PaginationBtnState();
}

class _PaginationBtnState extends State<_PaginationBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: widget.isActive
              ? AppColors.primary
              : _hovered
                  ? AppColors.surfaceContainerHigh
                  : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(16),
          boxShadow: widget.isActive
              ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.2), blurRadius: 4)]
              : null,
        ),
        child: Center(
          child: widget.icon != null
              ? Icon(widget.icon, size: 16,
                  color: widget.isActive ? Colors.white : AppColors.onSurfaceVariant)
              : Text(widget.number!, style: AppTextStyles.labelSmall.copyWith(
                  fontWeight: FontWeight.w700,
                  color: widget.isActive ? Colors.white : AppColors.onSurfaceVariant,
                )),
        ),
      ),
    );
  }
}

// ─── Upload Dialog ───

class _UploadDialog extends StatefulWidget {
  @override
  State<_UploadDialog> createState() => _UploadDialogState();
}

class _UploadDialogState extends State<_UploadDialog>
    with SingleTickerProviderStateMixin {
  String _selectedType = 'Contrat';
  bool _dropHovered = false;
  bool _fileAdded = false;
  String? _fileName;
  String? _fileSize;
  double _uploadProgress = 0;
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _progressController.addListener(() {
      setState(() => _uploadProgress = _progressController.value);
    });
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      allowMultiple: false,
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      final sizeKb = (file.size / 1024).toStringAsFixed(1);
      final sizeMb = (file.size / (1024 * 1024)).toStringAsFixed(2);
      setState(() {
        _fileAdded = true;
        _fileName = file.name;
        _fileSize = file.size > 1024 * 1024 ? '$sizeMb Mo' : '$sizeKb Ko';
      });
      _progressController.forward(from: 0).then((_) {
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) Navigator.pop(context);
        });
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: 520,
          constraints: const BoxConstraints(maxHeight: 560),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.onSurface.withValues(alpha: 0.12),
                blurRadius: 32,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.cloud_upload, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Téléverser un Document', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700)),
                            Text('Format PDF, JPG ou PNG (max 10Mo)',
                                style: AppTextStyles.bodySmall.copyWith(color: AppColors.onSurfaceVariant, fontSize: 11)),
                          ],
                        ),
                      ]),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.close, size: 16, color: AppColors.onSurfaceVariant),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Drop Zone
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    onEnter: (_) => setState(() => _dropHovered = true),
                    onExit: (_) => setState(() => _dropHovered = false),
                    child: GestureDetector(
                      onTap: _fileAdded ? null : _pickFile,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 36),
                        decoration: BoxDecoration(
                          color: _dropHovered
                              ? AppColors.primary.withValues(alpha: 0.04)
                              : AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _dropHovered ? AppColors.primary : AppColors.outlineVariant,
                            width: 2,
                          ),
                        ),
                        child: _fileAdded
                            ? _buildUploadProgress()
                            : Column(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 250),
                                    transform: Matrix4.translationValues(0, _dropHovered ? -4 : 0, 0),
                                    child: Icon(
                                      Icons.cloud_upload_outlined,
                                      size: 44,
                                      color: _dropHovered ? AppColors.primary : AppColors.outline,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text('Cliquez ou glissez vos fichiers ici',
                                      style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Text('Taille maximale : 10 Mo par fichier',
                                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.outline, fontSize: 11)),
                                ],
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Document Type Dropdown
                  Text('TYPE DE DOCUMENT',
                      style: AppTextStyles.labelSmall.copyWith(
                          letterSpacing: 1.2, fontWeight: FontWeight.w700, color: AppColors.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButton<String>(
                      value: _selectedType,
                      isExpanded: true,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.outline),
                      items: ['Contrat', 'Paie', 'Diplômes', 'Banque']
                          .map((t) => DropdownMenuItem(value: t, child: Text(t, style: AppTextStyles.bodyMedium)))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedType = v!),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description field
                  Text('DESCRIPTION (OPTIONNEL)',
                      style: AppTextStyles.labelSmall.copyWith(
                          letterSpacing: 1.2, fontWeight: FontWeight.w700, color: AppColors.onSurfaceVariant)),
                  const SizedBox(height: 8),
                  TextField(
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'Ajoutez une note ou une description...',
                      hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.outline),
                      filled: true,
                      fillColor: AppColors.surfaceContainerLow,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: 24),

                  // Actions
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border.all(color: AppColors.outlineVariant),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('Annuler', style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: _fileAdded ? null : _pickFile,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            decoration: BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.upload, size: 16, color: Colors.white),
                                const SizedBox(width: 6),
                                Text('Téléverser',
                                    style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700, color: Colors.white)),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUploadProgress() {
    final done = _uploadProgress >= 1.0;
    return Column(
      children: [
        Icon(
          done ? Icons.check_circle : Icons.description,
          size: 40,
          color: done ? AppColors.success : AppColors.primary,
        ),
        const SizedBox(height: 8),
        if (_fileName != null)
          Text(
            _fileName!,
            style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        if (_fileSize != null)
          Text(
            _fileSize!,
            style: AppTextStyles.bodySmall.copyWith(fontSize: 10, color: AppColors.outline),
          ),
        const SizedBox(height: 8),
        Text(
          done ? 'Téléversement terminé !' : 'Téléversement en cours...',
          style: AppTextStyles.labelLarge.copyWith(
            fontWeight: FontWeight.w700,
            color: done ? AppColors.success : AppColors.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          height: 6,
          width: 280,
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(3),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _uploadProgress,
            child: Container(
              decoration: BoxDecoration(
                gradient: done
                    ? const LinearGradient(colors: [AppColors.success, Color(0xFF66BB6A)])
                    : AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${(_uploadProgress * 100).round()}%',
          style: AppTextStyles.labelSmall.copyWith(
            fontWeight: FontWeight.w700,
            color: done ? AppColors.success : AppColors.primary,
          ),
        ),
      ],
    );
  }
}
