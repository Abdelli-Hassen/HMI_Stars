import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/main_shell.dart';
import '../../../../core/widgets/staggered_column.dart';
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
      title: 'Liste des Entreprises',
      body: Consumer<EntrepriseProvider>(
        builder: (context, ep, _) {
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
                        Text('Entreprises', style: AppTextStyles.headlineMedium),
                        const SizedBox(height: 4),
                        _Chip(label: "PORTEFEUILLE CLIENT", active: false),
                      ],
                    ),
                    Row(
                      children: [
                        SizedBox(
                          width: 280,
                          child: TextField(
                            onChanged: (val) => context.read<EntrepriseProvider>().setSearchQuery(val),
                            style: AppTextStyles.bodyMedium,
                            decoration: InputDecoration(
                              hintText: 'Rechercher (nom, email)...',
                              hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.outline),
                              prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.outline),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.outlineVariant),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.outlineVariant),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: AppColors.primary),
                              ),
                              filled: true,
                              fillColor: AppColors.surfaceContainerLowest,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () => _showAddDialog(context),
                            icon: const Icon(Icons.add_business, size: 18),
                            label: const Text('Ajouter une Entreprise'),
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
                        label: 'TOTAL (PORTEFEUILLE)',
                        value: ep.totalEntreprises.toString(),
                        icon: Icons.domain),
                    const SizedBox(width: 16),
                    _StatCard(
                        label: 'EN ATTENTE (BLOQUÉS)',
                        value: ep.dossiersEnAttente.toString(),
                        icon: Icons.hourglass_top,
                        iconBg: AppColors.errorContainer,
                        iconColor: AppColors.error),
                    const SizedBox(width: 16),
                    _StatCard(
                        label: 'EN COURS (TRAITEMENT)',
                        value: ep.dossiersEnCours.toString(),
                        icon: Icons.work_history,
                        iconBg: AppColors.tertiaryFixed,
                        iconColor: AppColors.tertiary),
                    const SizedBox(width: 16),
                    _StatCard(
                        label: 'TRAVAIL COMPLET',
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
                      'Erreur de chargement: ${ep.error}',
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
                            color: AppColors.outlineVariant
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
                                  _FilterChip(label: filter, active: isActive),
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
                              'Aucune entreprise trouvée avec ce filtre.',
                              style: AppTextStyles.bodyMedium),
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
  final _nomController = TextEditingController();
  final _gerantController = TextEditingController();
  final _descController = TextEditingController();
  final _emailController = TextEditingController();
  final _mdpController = TextEditingController();

  // Nouvelles informations générales
  final _adresseController = TextEditingController();
  final _effectifController = TextEditingController();

  // Informations juridiques
  final _sirenController = TextEditingController();
  final _siretController = TextEditingController();
  final _formeController = TextEditingController();
  final _tvaController = TextEditingController();
  final _rcsController = TextEditingController();
  final _capitalController = TextEditingController();


  Future<void> _creerEntreprise() async {
    if (_nomController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le nom de l\'entreprise est obligatoire.')),
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
    );

    try {
      await context
          .read<EntrepriseProvider>()
          .ajouterEntreprise(nouvelleEntreprise);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Entreprise ajoutée avec succès !'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
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
    _sirenController.dispose();
    _siretController.dispose();
    _formeController.dispose();
    _tvaController.dispose();
    _rcsController.dispose();
    _capitalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.surfaceContainerLowest,
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Nouvelle Entreprise', style: AppTextStyles.headlineSmall),
              const SizedBox(height: 8),
              Text('Renseignez les informations de base ainsi que les identifiants d\'accès pour l\'application.', style: AppTextStyles.bodyMedium),
              const SizedBox(height: 24),
              Text('1. Informations générales et accès', style: AppTextStyles.titleMedium),
              const SizedBox(height: 16),
              _buildField('Nom complet de l\'entreprise', _nomController),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildField('Adresse Email de connexion', _emailController, keyboardType: TextInputType.emailAddress)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildField('Mot de passe', _mdpController, isPassword: true)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildField('Nom du dirigeant/gérant', _gerantController)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildField('Nombre d\'effectif', _effectifController, keyboardType: TextInputType.number)),
                ],
              ),
              const SizedBox(height: 16),
              _buildField('Adresse physique', _adresseController),
              const SizedBox(height: 16),
              _buildField('Description générale', _descController),
              const SizedBox(height: 24),
              Text('2. Informations juridiques', style: AppTextStyles.titleMedium),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildField('N° SIREN', _sirenController)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildField('N° SIRET', _siretController)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildField('Forme juridique', _formeController)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildField('Capital social', _capitalController)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildField('N° de TVA', _tvaController)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildField('N° RCS', _rcsController)),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Annuler', style: TextStyle(color: AppColors.error)),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _creerEntreprise,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: const Text('Créer l\'Entreprise'),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.labelMedium),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          style: AppTextStyles.bodyMedium,
          decoration: InputDecoration(
            isDense: true,
            hintText: 'Saisir $label',
            hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.outlineVariant)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.outlineVariant)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary)),
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: active ? AppColors.success.withValues(alpha: 0.1) : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: AppTextStyles.labelSmall.copyWith(
        fontSize: 10, letterSpacing: 0.8, fontWeight: FontWeight.w700,
        color: active ? AppColors.success : AppColors.onSurfaceVariant,
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
    final effectiveColor = widget.iconColor ?? AppColors.primary;

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
            color: AppColors.surfaceContainerLowest,
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
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.value,
                      style: AppTextStyles.headlineMedium,
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: active ? AppColors.primary : AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: AppTextStyles.labelSmall.copyWith(
        fontWeight: FontWeight.w600,
        color: active ? Colors.white : AppColors.onSurfaceVariant,
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
    return Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: active ? AppColors.surfaceContainerLow : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 18, color: active ? AppColors.onSurface : AppColors.outline),
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
  bool _hovered = false;

  Color get _statusColor {
    if (widget.entreprise.statut == 'EN COURS') return AppColors.primary;
    if (widget.entreprise.statut == 'COMPLET') return AppColors.success;
    if (widget.entreprise.statut == 'ARCHIVÉ') return AppColors.outlineVariant;
    return AppColors.warning;
  }

  @override
  Widget build(BuildContext context) {
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
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: _hovered 
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : AppColors.outlineVariant.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(color: AppColors.primary.withValues(alpha: 0.15), blurRadius: 30, offset: const Offset(0, 12)),
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
                          AppColors.primary.withValues(alpha: _hovered ? 0.25 : 0.15),
                          AppColors.primary.withValues(alpha: _hovered ? 0.1 : 0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                    ),
                    child: widget.entreprise.logoUrl != null && widget.entreprise.logoUrl!.isNotEmpty
                        ? Image.network(
                            widget.entreprise.logoUrl!,
                            width: 52,
                            height: 52,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(Icons.domain, size: 28, color: AppColors.primary),
                          )
                        : Icon(Icons.domain, size: 28, color: AppColors.primary),
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    tooltip: 'Changer le statut',
                    offset: const Offset(0, 30),
                    onSelected: (newStatus) {
                       final updated = widget.entreprise.copyWith(statut: newStatus);
                       Provider.of<EntrepriseProvider>(context, listen: false).updateEntreprise(updated);
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'EN COURS', child: Text('En cours de travail')),
                      const PopupMenuItem(value: 'ATTENTE DOCS', child: Text('En attente des besoins')),
                      const PopupMenuItem(value: 'COMPLET', child: Text('Travail complet')),
                      const PopupMenuItem(value: 'ARCHIVÉ', child: Text('Archiver')),
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
                          Text(widget.entreprise.statut, style: AppTextStyles.labelSmall.copyWith(
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
              Text(widget.entreprise.nom, style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.person, size: 14, color: AppColors.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Expanded(child: Text('Dirigeant: ${widget.entreprise.nomGerant}', style: AppTextStyles.bodySmall, overflow: TextOverflow.ellipsis)),
                ],
              ),
              const SizedBox(height: 12),
              Text(widget.entreprise.description, style: AppTextStyles.bodySmall.copyWith(color: AppColors.onSurfaceVariant, fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.only(top: 14),
                decoration: BoxDecoration(border: Border(top: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.15)))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Voir le dossier', style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                    const Icon(Icons.arrow_forward, size: 18, color: AppColors.primary),
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
  bool _hovered = false;

  Color get _statusColor {
    if (widget.entreprise.statut == 'EN COURS') return AppColors.primary;
    if (widget.entreprise.statut == 'COMPLET') return AppColors.success;
    if (widget.entreprise.statut == 'ARCHIVÉ') return AppColors.outlineVariant;
    return AppColors.warning;
  }

  @override
  Widget build(BuildContext context) {
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
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _hovered 
                  ? AppColors.primary.withValues(alpha: 0.3)
                  : AppColors.outlineVariant.withValues(alpha: 0.3),
              width: 1,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(color: AppColors.primary.withValues(alpha: 0.10), blurRadius: 24, offset: const Offset(0, 8)),
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
                      AppColors.primary.withValues(alpha: _hovered ? 0.25 : 0.15),
                      AppColors.primary.withValues(alpha: _hovered ? 0.1 : 0.05),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
                ),
                child: widget.entreprise.logoUrl != null && widget.entreprise.logoUrl!.isNotEmpty
                    ? Image.network(
                        widget.entreprise.logoUrl!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Icon(Icons.domain, size: 24, color: AppColors.primary),
                        ),
                      )
                    : Icon(Icons.domain, size: 24, color: AppColors.primary),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.entreprise.nom, style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(widget.entreprise.description, style: AppTextStyles.bodySmall.copyWith(color: AppColors.onSurfaceVariant, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 1,
                child: Row(
                  children: [
                    Icon(Icons.person, size: 16, color: AppColors.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Expanded(child: Text(widget.entreprise.nomGerant, style: AppTextStyles.bodySmall, overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              PopupMenuButton<String>(
                tooltip: 'Changer le statut',
                offset: const Offset(0, 30),
                onSelected: (newStatus) {
                   final updated = widget.entreprise.copyWith(statut: newStatus);
                   Provider.of<EntrepriseProvider>(context, listen: false).updateEntreprise(updated);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'EN COURS', child: Text('En cours de travail')),
                  const PopupMenuItem(value: 'ATTENTE DOCS', child: Text('En attente des besoins')),
                  const PopupMenuItem(value: 'COMPLET', child: Text('Travail complet')),
                  const PopupMenuItem(value: 'ARCHIVÉ', child: Text('Archiver')),
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
                      Text(widget.entreprise.statut, style: AppTextStyles.labelSmall.copyWith(
                        fontSize: 10, fontWeight: FontWeight.w700, color: _statusColor, letterSpacing: 0.8,
                      )),
                      const SizedBox(width: 6),
                      Icon(Icons.arrow_drop_down, size: 16, color: _statusColor),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              const Icon(Icons.chevron_right, size: 24, color: AppColors.outline),
            ],
          ),
        ),
      ),
    );
  }
}

