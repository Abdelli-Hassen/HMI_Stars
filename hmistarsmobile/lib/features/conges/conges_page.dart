import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/providers/app_state.dart';
import '../../core/models/models.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/top_notification_banner.dart';

class CongesPage extends StatefulWidget {
  const CongesPage({super.key});

  @override
  State<CongesPage> createState() => _CongesPageState();
}

class _CongesPageState extends State<CongesPage> {

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final conges = appState.conges;
    final salaries = appState.salaries;

    // Show all recorded absences
    final filteredConges = conges;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => appState.loadConges(),
        child: CustomScrollView(
          slivers: [
            AppHeader.sliver(context: context),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'GESTION DU PERSONNEL',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.tertiary,
                        letterSpacing: 1.5,
                      ),
                    ),
                    Text(
                      'Congés & Absences',
                      style: GoogleFonts.manrope(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.primary,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Enregistrez et gérez les congés et absences de vos salariés.',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            if (filteredConges.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.beach_access_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune demande trouvée',
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Les demandes s\'afficheront ici.',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final conge = filteredConges[index];
                      final salarie = salaries.firstWhere(
                        (s) => s.id == conge.salarieId,
                        orElse: () => Salarie(
                          id: conge.salarieId,
                          entrepriseId: conge.entrepriseId,
                          nom: 'Inconnu',
                          prenom: '',
                          nomDeNaissance: 'Inconnu',
                          typeContrat: 'CDI',
                          email: '',
                        ),
                      );
                      return _buildCongeCard(context, conge, salarie, appState);
                    },
                    childCount: filteredConges.length,
                  ),
                ),
              ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCongeSheet(context, salaries, appState),
        icon: const Icon(Icons.add),
        label: const Text('Enregistrer absence'),
      ),
    );
  }

  Widget _buildCongeCard(BuildContext context, Conge conge, Salarie salarie, AppState appState) {
    final (typeLabel, typeIcon, typeColor) = _getTypeStyle(conge.typeConge);

    final duration = conge.dateFin.difference(conge.dateDebut).inDays + 1;
    final dateRangeStr = conge.estDemiJournee
        ? '${DateFormat('dd MMM yyyy', 'fr').format(conge.dateDebut)} (Demi-journée)'
        : 'Du ${DateFormat('dd MMM yyyy', 'fr').format(conge.dateDebut)} au ${DateFormat('dd MMM yyyy', 'fr').format(conge.dateFin)} ($duration jours)';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                  child: Text(
                    '${salarie.prenom.isNotEmpty ? salarie.prenom[0] : ''}${salarie.nom.isNotEmpty ? salarie.nom[0] : ''}',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSecondaryContainer,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        salarie.nomComplet,
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Text(
                        salarie.emploiPoste ?? 'Salarié',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.edit_outlined, color: Theme.of(context).colorScheme.primary.withOpacity(0.7)),
                  onPressed: () => _showEditCongeSheet(context, conge, appState.salaries, appState),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error.withOpacity(0.7)),
                  onPressed: () => _confirmDeleteConge(context, conge, appState),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(typeIcon, color: typeColor, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      typeLabel,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: typeColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        dateRangeStr,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                if (conge.commentaire.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      conge.commentaire,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteConge(BuildContext context, Conge conge, AppState appState) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Supprimer l\'absence',
          style: GoogleFonts.manrope(fontWeight: FontWeight.bold),
        ),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette absence ? Cela supprimera également les pointages générés correspondants.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await appState.deleteConge(conge.id!);
                if (context.mounted) {
                  TopNotificationBanner.show(
                    context,
                    'Absence supprimée avec succès.',
                    isError: false,
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  TopNotificationBanner.show(
                    context,
                    'Erreur lors de la suppression: $e',
                    isError: true,
                  );
                }
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }

  void _showAddCongeSheet(BuildContext context, List<Salarie> salaries, AppState appState) {
    if (salaries.isEmpty) {
      TopNotificationBanner.show(
        context,
        'Veuillez ajouter des salariés avant d\'enregistrer une absence.',
        isError: true,
      );
      return;
    }

    String? selectedSalarieId = salaries.first.id;
    String selectedType = 'conge_paye';
    DateTime debut = DateTime.now();
    DateTime fin = DateTime.now();
    bool estDemiJournee = false;
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: StatefulBuilder(
          builder: (ctx, setS) => Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  const SizedBox(height: 16),
                  Text(
                    'Enregistrer une absence / congé',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Salarie selection
                  Text(
                    'Salarié',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedSalarieId,
                    items: salaries.map((s) {
                      return DropdownMenuItem(
                        value: s.id,
                        child: Text(s.nomComplet),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setS(() {
                        selectedSalarieId = val;
                      });
                    },
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Type de conge selection
                  Text(
                    'Type de congé / absence',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    items: const [
                      DropdownMenuItem(value: 'conge_paye', child: Text('Congé Payé')),
                      DropdownMenuItem(value: 'maladie', child: Text('Arrêt Maladie')),
                      DropdownMenuItem(value: 'rtt', child: Text('RTT')),
                      DropdownMenuItem(value: 'exceptionnel', child: Text('Congé Exceptionnel')),
                      DropdownMenuItem(value: 'autre', child: Text('Autre Absence')),
                    ],
                    onChanged: (val) {
                      setS(() {
                        selectedType = val!;
                      });
                    },
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Dates pickers
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Date Début',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () async {
                                final d = await showDatePicker(
                                  context: context,
                                  initialDate: debut,
                                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (d != null) {
                                  setS(() {
                                    debut = d;
                                    if (fin.isBefore(debut)) {
                                      fin = debut;
                                    }
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(DateFormat('dd/MM/yyyy').format(debut)),
                                    const Icon(Icons.calendar_today, size: 16),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (!estDemiJournee)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Date Fin',
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () async {
                                  final d = await showDatePicker(
                                    context: context,
                                    initialDate: fin,
                                    firstDate: debut,
                                    lastDate: DateTime.now().add(const Duration(days: 365)),
                                  );
                                  if (d != null) {
                                    setS(() {
                                      fin = d;
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(DateFormat('dd/MM/yyyy').format(fin)),
                                      const Icon(Icons.calendar_today, size: 16),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Half day switch
                  CheckboxListTile(
                    value: estDemiJournee,
                    onChanged: (v) {
                      setS(() {
                        estDemiJournee = v ?? false;
                        if (estDemiJournee) {
                          fin = debut;
                        }
                      });
                    },
                    title: const Text('Demi-journée uniquement'),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.trailing,
                    activeColor: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  // Comment
                  Text(
                    'Commentaire / Motif',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Ex: Maladie avec certificat, congés annuels...',
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Submit
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (selectedSalarieId == null) return;
                        final newConge = Conge(
                          salarieId: selectedSalarieId!,
                          entrepriseId: appState.entrepriseId!,
                          typeConge: selectedType,
                          dateDebut: debut,
                          dateFin: estDemiJournee ? debut : fin,
                          estDemiJournee: estDemiJournee,
                          statut: 'approuve', // Admin-entered absence is approved by default
                          commentaire: commentController.text,
                        );

                        try {
                          await appState.addConge(newConge);
                          if (context.mounted) {
                            Navigator.pop(context);
                            TopNotificationBanner.show(
                              context,
                              'Absence enregistrée avec succès',
                              isError: false,
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            TopNotificationBanner.show(
                              context,
                              'Erreur: $e',
                              isError: true,
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Enregistrer'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showEditCongeSheet(BuildContext context, Conge conge, List<Salarie> salaries, AppState appState) {
    String? selectedSalarieId = conge.salarieId;
    String selectedType = conge.typeConge;
    DateTime debut = conge.dateDebut;
    DateTime fin = conge.dateFin;
    bool estDemiJournee = conge.estDemiJournee;
    final commentController = TextEditingController(text: conge.commentaire);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: StatefulBuilder(
          builder: (ctx, setS) => Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  const SizedBox(height: 16),
                  Text(
                    'Modifier l\'absence / congé',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w800,
                      fontSize: 20,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Salarie selection
                  Text(
                    'Salarié',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedSalarieId,
                    items: salaries.map((s) {
                      return DropdownMenuItem(
                        value: s.id,
                        child: Text(s.nomComplet),
                      );
                    }).toList(),
                    onChanged: (val) {
                      setS(() {
                        selectedSalarieId = val;
                      });
                    },
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Type de conge selection
                  Text(
                    'Type de congé / absence',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    value: selectedType,
                    items: const [
                      DropdownMenuItem(value: 'conge_paye', child: Text('Congé Payé')),
                      DropdownMenuItem(value: 'maladie', child: Text('Arrêt Maladie')),
                      DropdownMenuItem(value: 'rtt', child: Text('RTT')),
                      DropdownMenuItem(value: 'exceptionnel', child: Text('Congé Exceptionnel')),
                      DropdownMenuItem(value: 'autre', child: Text('Autre Absence')),
                    ],
                    onChanged: (val) {
                      setS(() {
                        selectedType = val!;
                      });
                    },
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Dates pickers
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Date Début',
                              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            InkWell(
                              onTap: () async {
                                final d = await showDatePicker(
                                  context: context,
                                  initialDate: debut,
                                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (d != null) {
                                  setS(() {
                                    debut = d;
                                    if (fin.isBefore(debut)) {
                                      fin = debut;
                                    }
                                  });
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(DateFormat('dd/MM/yyyy').format(debut)),
                                    const Icon(Icons.calendar_today, size: 16),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      if (!estDemiJournee)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Date Fin',
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 6),
                              InkWell(
                                onTap: () async {
                                  final d = await showDatePicker(
                                    context: context,
                                    initialDate: fin,
                                    firstDate: debut,
                                    lastDate: DateTime.now().add(const Duration(days: 365)),
                                  );
                                  if (d != null) {
                                    setS(() {
                                      fin = d;
                                    });
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(DateFormat('dd/MM/yyyy').format(fin)),
                                      const Icon(Icons.calendar_today, size: 16),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Half day switch
                  CheckboxListTile(
                    value: estDemiJournee,
                    onChanged: (v) {
                      setS(() {
                        estDemiJournee = v ?? false;
                        if (estDemiJournee) {
                          fin = debut;
                        }
                      });
                    },
                    title: const Text('Demi-journée uniquement'),
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.trailing,
                    activeColor: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  // Comment
                  Text(
                    'Commentaire / Motif',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: commentController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Ex: Maladie avec certificat, congés annuels...',
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Submit
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (selectedSalarieId == null) return;
                        final updates = {
                          'salarie_id': selectedSalarieId!,
                          'type_conge': selectedType,
                          'date_debut': debut.toIso8601String().split('T').first,
                          'date_fin': (estDemiJournee ? debut : fin).toIso8601String().split('T').first,
                          'est_demi_journee': estDemiJournee,
                          'commentaire': commentController.text,
                        };

                        try {
                          await appState.updateConge(conge.id!, updates);
                          if (context.mounted) {
                            Navigator.pop(context);
                            TopNotificationBanner.show(
                              context,
                              'Absence modifiée avec succès',
                              isError: false,
                            );
                          }
                        } catch (e) {
                          if (context.mounted) {
                            TopNotificationBanner.show(
                              context,
                              'Erreur: $e',
                              isError: true,
                            );
                          }
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Enregistrer les modifications'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  (String, IconData, Color) _getTypeStyle(String type) {
    switch (type) {
      case 'conge_paye':
        return ('Congé Payé', Icons.beach_access_outlined, Colors.blue);
      case 'maladie':
        return ('Arrêt Maladie', Icons.healing_outlined, Colors.redAccent);
      case 'rtt':
        return ('RTT', Icons.timer_outlined, Colors.teal);
      case 'exceptionnel':
        return ('Congé Exceptionnel', Icons.star_outline_rounded, Colors.orange);
      default:
        return ('Autre Absence', Icons.more_horiz, Colors.blueGrey);
    }
  }
}
