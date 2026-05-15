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
                        Row(
                          children: [
                            _Chip(label: "PORTEFEUILLE CLIENT", active: false),
                            const SizedBox(width: 8),
                            _Chip(label: "MISE À JOUR : AUJOURD'HUI", active: true),
                          ],
                        ),
                      ],
                    ),
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
                const SizedBox(height: 24),

                // ─── Stats Cards ───
                Row(
                  children: [
                    _StatCard(
                        label: 'TOTAL ENTREPRISES',
                        value: ep.totalEntreprises.toString(),
                        icon: Icons.domain),
                    const SizedBox(width: 16),
                    _StatCard(
                        label: 'MES DOSSIERS (EN COURS)',
                        value: ep.dossiersEnCours.toString(),
                        icon: Icons.work_history),
                    const SizedBox(width: 16),
                    _StatCard(
                        label: 'EN ATTENTE (DOCUMENTS)',
                        value: ep.dossiersEnAttente.toString(),
                        icon: Icons.hourglass_top,
                        iconBg: AppColors.tertiaryFixed,
                        iconColor: AppColors.tertiary),
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

class _StatCard extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color? iconBg;
  final Color? iconColor;
  const _StatCard({required this.label, required this.value, required this.icon, this.iconBg, this.iconColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTextStyles.labelSmall.copyWith(letterSpacing: 1, fontWeight: FontWeight.w700), overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Text(value, style: AppTextStyles.headlineMedium, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: iconBg ?? AppColors.primaryFixed,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor ?? AppColors.primary, size: 22),
            ),
          ],
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

class _EntrepriseCard extends StatelessWidget {
  final Entreprise entreprise;
  const _EntrepriseCard({required this.entreprise});

  Color get _statusColor {
    if (entreprise.statut == 'EN COURS') return AppColors.primary;
    if (entreprise.statut == 'COMPLET') return AppColors.success;
    if (entreprise.statut == 'ARCHIVÉ') return AppColors.outlineVariant;
    return AppColors.warning;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, AppRoutes.entrepriseDetails, arguments: entreprise.id),
        child: Container(
          width: 280,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.15)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.surfaceContainerHigh,
                    child: Icon(Icons.domain, size: 28, color: AppColors.onSurfaceVariant),
                  ),
                  const Spacer(),
                  PopupMenuButton<String>(
                    tooltip: 'Changer le statut',
                    offset: const Offset(0, 30),
                    onSelected: (newStatus) {
                       final updated = entreprise.copyWith(statut: newStatus);
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
                          Text(entreprise.statut, style: AppTextStyles.labelSmall.copyWith(
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
              const SizedBox(height: 14),
              Text(entreprise.nom, style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.person, size: 14, color: AppColors.onSurfaceVariant),
                  const SizedBox(width: 4),
                  Expanded(child: Text('Dirigeant: ${entreprise.nomGerant}', style: AppTextStyles.bodySmall, overflow: TextOverflow.ellipsis)),
                ],
              ),
              const SizedBox(height: 10),
              Text(entreprise.description, style: AppTextStyles.bodySmall.copyWith(color: AppColors.onSurfaceVariant, fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.only(top: 12),
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

class _EntrepriseListTile extends StatelessWidget {
  final Entreprise entreprise;
  const _EntrepriseListTile({required this.entreprise});

  Color get _statusColor {
    if (entreprise.statut == 'EN COURS') return AppColors.primary;
    if (entreprise.statut == 'COMPLET') return AppColors.success;
    if (entreprise.statut == 'ARCHIVÉ') return AppColors.outlineVariant;
    return AppColors.warning;
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, AppRoutes.entrepriseDetails, arguments: entreprise.id),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.15)),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: AppColors.surfaceContainerHigh,
                child: Icon(Icons.domain, size: 24, color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entreprise.nom, style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w800), overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(entreprise.description, style: AppTextStyles.bodySmall.copyWith(color: AppColors.onSurfaceVariant, fontSize: 11), maxLines: 1, overflow: TextOverflow.ellipsis),
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
                    Expanded(child: Text(entreprise.nomGerant, style: AppTextStyles.bodySmall, overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              PopupMenuButton<String>(
                tooltip: 'Changer le statut',
                offset: const Offset(0, 30),
                onSelected: (newStatus) {
                   final updated = entreprise.copyWith(statut: newStatus);
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
                      Text(entreprise.statut, style: AppTextStyles.labelSmall.copyWith(
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

