import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/main_shell.dart';
import '../../../../core/widgets/staggered_column.dart';
import '../../../../core/utils/translation_extension.dart';
import '../../domain/models/entreprise.dart';
import '../providers/entreprise_provider.dart';

class EntreprisesPage extends StatefulWidget {
  const EntreprisesPage({super.key});

  @override
  State<EntreprisesPage> createState() => _EntreprisesPageState();
}

class _EntreprisesPageState extends State<EntreprisesPage> {
  final List<String> _filters = [
    'Toutes les entreprises',
    'En cours de travail',
    'En attente des besoins',
    'Travail complet',
    'Archivées',
  ];
  bool _isListMode = false;

  String _translateFilter(BuildContext context, String filter) {
    switch (filter) {
      case 'Toutes les entreprises':
        return context.tr('Toutes les entreprises', 'All Companies');
      case 'En cours de travail':
        return context.tr('En cours de travail', 'In Progress');
      case 'En attente des besoins':
        return context.tr('En attente des besoins', 'Awaiting Docs');
      case 'Travail complet':
        return context.tr('Travail complet', 'Completed');
      case 'Archivées':
        return context.tr('Archivées', 'Archived');
      default:
        return filter;
    }
  }

  @override
  void initState() {
    super.initState();
    // Load enterprises from Supabase on first render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EntrepriseProvider>().fetchEntreprises();
    });
  }

  void _showAddDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const _AddEntrepriseDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MainShell(
      currentRoute: AppRoutes.entreprises,
      title: context.tr('Liste des Entreprises', 'List of Companies'),
      body: Consumer<EntrepriseProvider>(
        builder: (context, ep, _) {
          final cs = Theme.of(context).colorScheme;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: StaggeredColumn(
              children: [
                // ─── Header ───
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('Entreprises', 'Companies'), 
                          style: AppTextStyles.headlineMedium.copyWith(color: cs.onSurface)
                        ),
                        const SizedBox(height: 4),
                        _Chip(label: context.tr("PORTEFEUILLE CLIENT", "CLIENT PORTFOLIO"), active: false),
                      ],
                    ),
                    Row(
                      children: [
                        SizedBox(
                          width: 280,
                          child: TextField(
                            onChanged: (val) => context.read<EntrepriseProvider>().setSearchQuery(val),
                            style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurface),
                            decoration: InputDecoration(
                              hintText: context.tr('Rechercher (nom, email)...', 'Search (name, email)...'),
                              hintStyle: AppTextStyles.bodyMedium.copyWith(color: cs.outline),
                              prefixIcon: Icon(Icons.search, size: 20, color: cs.outline),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.35)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.35)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: cs.primary, width: 1.5),
                              ),
                              filled: true,
                              fillColor: cs.surfaceContainerLowest,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          decoration: BoxDecoration(
                            gradient: cs.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () => _showAddDialog(context),
                            icon: const Icon(Icons.add_business, size: 18),
                            label: Text(context.tr('Ajouter une Entreprise', 'Add Company')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ─── Stats Cards ───
                Row(
                  children: [
                    _StatCard(
                        label: context.tr('TOTAL (PORTEFEUILLE)', 'TOTAL (PORTFOLIO)'),
                        value: ep.totalEntreprises.toString(),
                        icon: Icons.domain),
                    const SizedBox(width: 16),
                    _StatCard(
                        label: context.tr('EN ATTENTE (BLOQUÉS)', 'AWAITING DOCS'),
                        value: ep.dossiersEnAttente.toString(),
                        icon: Icons.hourglass_top,
                        iconBg: AppColors.errorContainer,
                        iconColor: AppColors.error),
                    const SizedBox(width: 16),
                    _StatCard(
                        label: context.tr('EN COURS (TRAITEMENT)', 'IN PROGRESS'),
                        value: ep.dossiersEnCours.toString(),
                        icon: Icons.work_history,
                        iconBg: AppColors.tertiaryFixed,
                        iconColor: AppColors.tertiary),
                    const SizedBox(width: 16),
                    _StatCard(
                        label: context.tr('TRAVAIL COMPLET', 'COMPLETED'),
                        value: ep.dossiersComplets.toString(),
                        icon: Icons.check_circle_outline,
                        iconBg: AppColors.successLight,
                        iconColor: AppColors.success),
                  ],
                ),
                const SizedBox(height: 24),

                // ─── Loading indicator ───
                if (ep.status == LoadStatus.loading)
                  const LinearProgressIndicator(),

                // ─── Error ───
                if (ep.status == LoadStatus.error)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      context.tr('Erreur de chargement: ${ep.error}', 'Load error: ${ep.error}'),
                      style: TextStyle(color: AppColors.error),
                    ),
                  ),

                // ─── Filters ───
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border(
                        bottom: BorderSide(
                            color: cs.outlineVariant
                                .withValues(alpha: 0.15))),
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ..._filters.map((filter) {
                          final isActive = filter == ep.filtreActif;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8.0),
                            child: GestureDetector(
                              onTap: () => ep.setFiltre(filter),
                              child:
                                  _FilterChip(label: _translateFilter(context, filter), active: isActive),
                            ),
                          );
                        }),
                        const SizedBox(width: 16),
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _isListMode = false),
                              child: _ViewToggle(
                                  icon: Icons.grid_view,
                                  active: !_isListMode),
                            ),
                            const SizedBox(width: 4),
                            GestureDetector(
                              onTap: () =>
                                  setState(() => _isListMode = true),
                              child: _ViewToggle(
                                  icon: Icons.view_list,
                                  active: _isListMode),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ─── Entreprise Cards Grid ───
                ep.entreprisesFiltrees.isEmpty &&
                        ep.status == LoadStatus.loaded
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text(
                              context.tr('Aucune entreprise trouvée avec ce filtre.', 'No companies found with this filter.'),
                              style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurface)),
                        ),
                      )
                    : (_isListMode
                        ? Column(
                            children:
                                ep.entreprisesFiltrees.map((entreprise) {
                              return Padding(
                                padding:
                                    const EdgeInsets.only(bottom: 16.0),
                                child: _EntrepriseListTile(
                                    entreprise: entreprise),
                              );
                            }).toList(),
                          )
                        : Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            children: ep.entreprisesFiltrees
                                .map((e) => _EntrepriseCard(entreprise: e))
                                .toList(),
                          )),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AddEntrepriseDialog extends StatefulWidget {
  const _AddEntrepriseDialog();

  @override
  State<_AddEntrepriseDialog> createState() => _AddEntrepriseDialogState();
}

class _AddEntrepriseDialogState extends State<_AddEntrepriseDialog> {
  ColorScheme get cs => Theme.of(context).colorScheme;
  final _nomController = TextEditingController();
  final _gerantController = TextEditingController();
  final _descController = TextEditingController();
  final _emailController = TextEditingController();
  final _mdpController = TextEditingController();

  // Nouvelles informations générales
  final _adresseController = TextEditingController();
  final _effectifController = TextEditingController();
  final _telephoneController = TextEditingController();

  // Informations juridiques
  final _sirenController = TextEditingController();
  final _siretController = TextEditingController();
  final _formeController = TextEditingController();
  final _tvaController = TextEditingController();
  final _rcsController = TextEditingController();
  final _capitalController = TextEditingController();
  final _codeApeController = TextEditingController();


  Future<void> _creerEntreprise() async {
    if (_nomController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('Le nom de l\'entreprise est obligatoire.', 'Company name is required.'))),
      );
      return;
    }

    // id is a placeholder; Supabase will generate the real UUID
    final nouvelleEntreprise = Entreprise(
      id: '', // will be replaced by Supabase response
      nom: _nomController.text,
      nomGerant: _gerantController.text,
      description: _descController.text,
      email: _emailController.text,
      motDePasse: _mdpController.text,
      statut: 'EN COURS',
      dateCreation: DateTime.now(),
      adressePhysique: _adresseController.text,
      effectif: int.tryParse(_effectifController.text) ?? 0,
      nSiren: _sirenController.text,
      nSiret: _siretController.text,
      formeJuridique: _formeController.text,
      nTva: _tvaController.text,
      nRcs: _rcsController.text,
      capitaleSocial: _capitalController.text,
      telephone: _telephoneController.text,
      codeApe: _codeApeController.text,
    );

    try {
      await context
          .read<EntrepriseProvider>()
          .ajouterEntreprise(nouvelleEntreprise);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('Entreprise ajoutée avec succès !', 'Company added successfully!')),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.tr('Erreur: ', 'Error: ') + e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _gerantController.dispose();
    _descController.dispose();
    _emailController.dispose();
    _mdpController.dispose();
    _adresseController.dispose();
    _effectifController.dispose();
    _telephoneController.dispose();
    _sirenController.dispose();
    _siretController.dispose();
    _formeController.dispose();
    _tvaController.dispose();
    _rcsController.dispose();
    _capitalController.dispose();
    _codeApeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: cs.surfaceContainerLowest,
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.tr('Nouvelle Entreprise', 'New Company'), style: AppTextStyles.headlineSmall.copyWith(color: cs.onSurface)),
              const SizedBox(height: 8),
              Text(context.tr('Renseignez les informations de base ainsi que les identifiants d\'accès pour l\'application.', 'Fill in the basic information and access credentials for the application.'), style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(height: 24),
              Text(context.tr('1. Informations générales et accès', '1. General information & access'), style: AppTextStyles.titleMedium.copyWith(color: cs.onSurface)),
              const SizedBox(height: 16),
              _buildField(context.tr('Nom complet de l\'entreprise', 'Company full name'), _nomController),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildField(context.tr('Adresse Email de connexion', 'Login Email address'), _emailController, keyboardType: TextInputType.emailAddress)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildField(context.tr('Mot de passe', 'Password'), _mdpController, isPassword: true)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildField(context.tr('Nom du dirigeant/gérant', 'Manager/director name'), _gerantController)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildField(context.tr('Nombre d\'effectif', 'Employee count'), _effectifController, keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildField(context.tr('Téléphone de l\'entreprise', 'Company phone number'), _telephoneController, keyboardType: TextInputType.phone)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildField(context.tr('Adresse physique', 'Physical address'), _adresseController)),
                ],
              ),
              const SizedBox(height: 16),
              _buildField(context.tr('Description générale', 'General description'), _descController),
              const SizedBox(height: 24),
              Text(context.tr('2. Informations juridiques', '2. Legal information'), style: AppTextStyles.titleMedium.copyWith(color: cs.onSurface)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildField(context.tr('N° SIREN', 'SIREN Number'), _sirenController)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildField(context.tr('N° SIRET', 'SIRET Number'), _siretController)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildField(context.tr('Forme juridique', 'Legal form'), _formeController)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildField(context.tr('Capital social', 'Share capital'), _capitalController)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildField(context.tr('N° de TVA', 'VAT Number'), _tvaController)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildField(context.tr('N° RCS', 'RCS Number'), _rcsController)),
                ],
              ),
              const SizedBox(height: 16),
              _buildField(context.tr('Code APE / NAF', 'APE / NAF Code'), _codeApeController),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(context.tr('Annuler', 'Cancel'), style: TextStyle(color: AppColors.error)),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _creerEntreprise,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: Text(context.tr('Créer l\'Entreprise', 'Create Company')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {bool isPassword = false, TextInputType? keyboardType}) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelMedium.copyWith(color: cs.onSurface)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurface),
          decoration: InputDecoration(
            isDense: true,
            hintText: context.tr('Saisir ', 'Enter ') + label,
            hintStyle: AppTextStyles.bodySmall.copyWith(color: cs.outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.35))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.35))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: cs.primary, width: 1.5)),
          ),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool active;
  const _Chip({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: active ? AppColors.success.withValues(alpha: 0.1) : cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: AppTextStyles.labelSmall.copyWith(
        fontSize: 10, letterSpacing: 0.8, fontWeight: FontWeight.w700,
        color: active ? AppColors.success : cs.onSurfaceVariant,
      )),
    );
  }
}

class _StatCard extends StatefulWidget {
  final String label, value;
  final IconData icon;
  final Color? iconBg;
  final Color? iconColor;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    this.iconBg,
    this.iconColor,
  });

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final effectiveColor = widget.iconColor ?? cs.primary;

    return Expanded(
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCirc,
          transform: Matrix4.translationValues(0, _hovered ? -4 : 0, 0),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: effectiveColor.withValues(alpha: _hovered ? 0.3 : 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: effectiveColor.withValues(alpha: _hovered ? 0.15 : 0.0),
                blurRadius: _hovered ? 16 : 0,
                spreadRadius: _hovered ? 2 : 0,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.label,
                      style: AppTextStyles.labelSmall.copyWith(
                        letterSpacing: 1,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurfaceVariant,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.value,
                      style: AppTextStyles.headlineMedium.copyWith(color: cs.onSurface),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      effectiveColor.withValues(alpha: _hovered ? 0.25 : 0.15),
                      effectiveColor.withValues(alpha: _hovered ? 0.1 : 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: effectiveColor.withValues(alpha: 0.2),
                  ),
                ),
                child: Icon(widget.icon, color: effectiveColor, size: 22),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  const _FilterChip({required this.label, required this.active});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: active ? cs.primary : cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: AppTextStyles.labelSmall.copyWith(
        fontWeight: FontWeight.w600,
        color: active ? Colors.white : cs.onSurfaceVariant,
      )),
    );
  }
}

class _ViewToggle extends StatelessWidget {
  final IconData icon;
  final bool active;
  const _ViewToggle({required this.icon, required this.active});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: active ? cs.surfaceContainerLow : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 18, color: active ? cs.onSurface : cs.outline),
    );
  }
}

class _EntrepriseCard extends StatefulWidget {
  final Entreprise entreprise;
  const _EntrepriseCard({required this.entreprise});

  @override
  State<_EntrepriseCard> createState() => _EntrepriseCardState();
}

class _EntrepriseCardState extends State<_EntrepriseCard> {
  ColorScheme get cs => Theme.of(context).colorScheme;
  bool _hovered = false;

  Color get _statusColor {
    if (widget.entreprise.statut == 'EN COURS') return cs.primary;
    if (widget.entreprise.statut == 'COMPLET') return AppColors.success;
    if (widget.entreprise.statut == 'ARCHIVÉ') return cs.outlineVariant;
    return AppColors.warning;
  }

  String _translateStatus(String status) {
    if (status == 'EN COURS') return context.tr('EN COURS', 'IN PROGRESS');
    if (status == 'COMPLET') return context.tr('COMPLET', 'COMPLETED');
    if (status == 'ARCHIVÉ') return context.tr('ARCHIVÉ', 'ARCHIVED');
    return context.tr('ATTENTE DOCS', 'AWAITING DOCS');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, AppRoutes.entrepriseDetails, arguments: widget.entreprise.id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCirc,
          width: 280,
          padding: const EdgeInsets.all(24),
          transform: Matrix4.translationValues(0.0, _hovered ? -6.0 : 0.0, 0.0),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _hovered 
                  ? cs.primary.withValues(alpha: 0.5)
                  : cs.outline.withValues(alpha: 0.35),
              width: 1,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(color: cs.primary.withValues(alpha: 0.15), blurRadius: 30, offset: const Offset(0, 12)),
                    BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 4)),
                  ]
                : [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 12, offset: const Offset(0, 6)),
                  ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: widget.entreprise.logoUrl != null && widget.entreprise.logoUrl!.isNotEmpty ? EdgeInsets.zero : const EdgeInsets.all(12),
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      gradient: widget.entreprise.logoUrl != null && widget.entreprise.logoUrl!.isNotEmpty ? null : LinearGradient(
                        colors: [
                          cs.primary.withValues(alpha: _hovered ? 0.25 : 0.15),
                          cs.primary.withValues(alpha: _hovered ? 0.1 : 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
                    ),
                    child: widget.entreprise.logoUrl != null && widget.entreprise.logoUrl!.isNotEmpty
                        ? Image.network(
                            widget.entreprise.logoUrl!,
                            width: 52,
                            height: 52,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(Icons.domain, size: 28, color: cs.primary),
                          )
                        : Icon(Icons.domain, size: 28, color: cs.primary),
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    tooltip: context.tr('Changer le statut', 'Change status'),
                    offset: const Offset(0, 30),
                    onSelected: (newStatus) {
                       final updated = widget.entreprise.copyWith(statut: newStatus);
                       Provider.of<EntrepriseProvider>(context, listen: false).updateEntreprise(updated);
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(value: 'EN COURS', child: Text(context.tr('En cours de travail', 'In Progress'))),
                      PopupMenuItem(value: 'ATTENTE DOCS', child: Text(context.tr('En attente des besoins', 'Awaiting Docs'))),
                      PopupMenuItem(value: 'COMPLET', child: Text(context.tr('Travail complet', 'Completed'))),
                      PopupMenuItem(value: 'ARCHIVÉ', child: Text(context.tr('Archiver', 'Archive'))),
                    ],
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(_translateStatus(widget.entreprise.statut), style: AppTextStyles.labelSmall.copyWith(
                            fontSize: 9, fontWeight: FontWeight.w700, color: _statusColor, letterSpacing: 0.8,
                          )),
                          const SizedBox(width: 4),
                          Icon(Icons.arrow_drop_down, size: 14, color: _statusColor),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                widget.entreprise.nom, 
                style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w800, color: cs.onSurface), 
                overflow: TextOverflow.ellipsis
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.person, size: 14, color: cs.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      context.tr('Dirigeant: ${widget.entreprise.nomGerant}', 'Manager: ${widget.entreprise.nomGerant}'), 
                      style: AppTextStyles.bodySmall.copyWith(color: cs.onSurfaceVariant), 
                      overflow: TextOverflow.ellipsis
                    )
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(widget.entreprise.description, style: AppTextStyles.bodySmall.copyWith(color: cs.onSurfaceVariant, fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.only(top: 14),
                decoration: BoxDecoration(border: Border(top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.15)))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      context.tr('Voir le dossier', 'View details'), 
                      style: AppTextStyles.labelMedium.copyWith(color: cs.primary, fontWeight: FontWeight.w600)
                    ),
                    Icon(Icons.arrow_forward, size: 18, color: cs.primary),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EntrepriseListTile extends StatefulWidget {
  final Entreprise entreprise;
  const _EntrepriseListTile({required this.entreprise});

  @override
  State<_EntrepriseListTile> createState() => _EntrepriseListTileState();
}

class _EntrepriseListTileState extends State<_EntrepriseListTile> {
  ColorScheme get cs => Theme.of(context).colorScheme;
  bool _hovered = false;

  Color get _statusColor {
    if (widget.entreprise.statut == 'EN COURS') return cs.primary;
    if (widget.entreprise.statut == 'COMPLET') return AppColors.success;
    if (widget.entreprise.statut == 'ARCHIVÉ') return cs.outlineVariant;
    return AppColors.warning;
  }

  String _translateStatus(String status) {
    if (status == 'EN COURS') return context.tr('EN COURS', 'IN PROGRESS');
    if (status == 'COMPLET') return context.tr('COMPLET', 'COMPLETED');
    if (status == 'ARCHIVÉ') return context.tr('ARCHIVÉ', 'ARCHIVED');
    return context.tr('ATTENTE DOCS', 'AWAITING DOCS');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, AppRoutes.entrepriseDetails, arguments: widget.entreprise.id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCirc,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          transform: Matrix4.translationValues(0.0, _hovered ? -4.0 : 0.0, 0.0),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _hovered 
                  ? cs.primary.withValues(alpha: 0.5)
                  : cs.outline.withValues(alpha: 0.35),
              width: 1,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(color: cs.primary.withValues(alpha: 0.10), blurRadius: 24, offset: const Offset(0, 8)),
                    BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 4)),
                  ]
                : [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: widget.entreprise.logoUrl != null && widget.entreprise.logoUrl!.isNotEmpty ? EdgeInsets.zero : const EdgeInsets.all(12),
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  gradient: widget.entreprise.logoUrl != null && widget.entreprise.logoUrl!.isNotEmpty ? null : LinearGradient(
                    colors: [
                      cs.primary.withValues(alpha: _hovered ? 0.25 : 0.15),
                      cs.primary.withValues(alpha: _hovered ? 0.1 : 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cs.primary.withValues(alpha: 0.2)),
                ),
                child: widget.entreprise.logoUrl != null && widget.entreprise.logoUrl!.isNotEmpty
                    ? Image.network(
                        widget.entreprise.logoUrl!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Icon(Icons.domain, size: 24, color: cs.primary),
                        ),
                      )
                    : Icon(Icons.domain, size: 24, color: cs.primary),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.entreprise.nom, 
                      style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w800, color: cs.onSurface), 
                      overflow: TextOverflow.ellipsis
                    ),
                    const SizedBox(height: 4),
                    Text(widget.entreprise.description, style: AppTextStyles.bodySmall.copyWith(color: cs.onSurfaceVariant, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: Row(
                  children: [
                    Icon(Icons.person, size: 16, color: cs.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.entreprise.nomGerant, 
                        style: AppTextStyles.bodySmall.copyWith(color: cs.onSurface), 
                        overflow: TextOverflow.ellipsis
                      )
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              PopupMenuButton<String>(
                tooltip: context.tr('Changer le statut', 'Change status'),
                offset: const Offset(0, 30),
                onSelected: (newStatus) {
                   final updated = widget.entreprise.copyWith(statut: newStatus);
                   Provider.of<EntrepriseProvider>(context, listen: false).updateEntreprise(updated);
                },
                itemBuilder: (context) => [
                  PopupMenuItem(value: 'EN COURS', child: Text(context.tr('En cours de travail', 'In Progress'))),
                  PopupMenuItem(value: 'ATTENTE DOCS', child: Text(context.tr('En attente des besoins', 'Awaiting Docs'))),
                  PopupMenuItem(value: 'COMPLET', child: Text(context.tr('Travail complet', 'Completed'))),
                  PopupMenuItem(value: 'ARCHIVÉ', child: Text(context.tr('Archiver', 'Archive'))),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_translateStatus(widget.entreprise.statut), style: AppTextStyles.labelSmall.copyWith(
                        fontSize: 10, fontWeight: FontWeight.w700, color: _statusColor, letterSpacing: 0.8,
                      )),
                      const SizedBox(width: 6),
                      Icon(Icons.arrow_drop_down, size: 16, color: _statusColor),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Icon(Icons.chevron_right, size: 24, color: cs.outline),
            ],
          ),
        ),
      ),
    );
  }
}

