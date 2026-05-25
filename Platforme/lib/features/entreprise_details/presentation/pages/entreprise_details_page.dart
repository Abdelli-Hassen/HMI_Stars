import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:file_saver/file_saver.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/main_shell.dart';
import '../../../../core/widgets/staggered_column.dart';
import '../../../../core/supabase_config.dart';
import '../../../entreprises/domain/models/salarie.dart';
import '../../../entreprises/domain/models/note_entreprise.dart';
import '../../../entreprises/domain/models/entreprise.dart';
import '../../../entreprises/presentation/providers/entreprise_provider.dart';
import '../../../../core/services/platform_data_service.dart';
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class EntrepriseDetailsPage extends StatefulWidget {
  const EntrepriseDetailsPage({super.key});

  @override
  State<EntrepriseDetailsPage> createState() => _EntrepriseDetailsPageState();
}

class _EntrepriseDetailsPageState extends State<EntrepriseDetailsPage> {
  String _activeTab = 'Informations';
  String? _loadedEntrepriseId;

  void _ensureDataLoaded(String entrepriseId) {
    if (_loadedEntrepriseId == entrepriseId) return;
    _loadedEntrepriseId = entrepriseId;
    final provider = Provider.of<EntrepriseProvider>(context, listen: false);
    provider.fetchSalariesForEntreprise(entrepriseId);
    provider.fetchNotesForEntreprise(entrepriseId);
    provider.fetchDocumentsForEntreprise(entrepriseId);
  }

  Future<void> _exportSalariePdf(Salarie s) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        build: (pw.Context context) {
          return [
            pw.Text('Dossier Complet du Salarie: ${s.nom} ${s.prenom}', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
            pw.SizedBox(height: 20),
            
            pw.Text('1. Identite & Etat Civil', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.Text('Nom: ${s.nom}'),
            pw.Text('Prenom: ${s.prenom}'),
            pw.Text('Nom de naissance: ${s.nomNaissance}'),
            pw.Text('Genre: ${s.genre}'),
            pw.Text('Date de naissance: ${s.dateNaissance != null ? "${s.dateNaissance!.day}/${s.dateNaissance!.month}/${s.dateNaissance!.year}" : "Non défini"}'),
            pw.Text('Lieu de naissance: ${s.lieuNaissance}'),
            pw.Text('Nationalite: ${s.nationalite}'),
            pw.SizedBox(height: 15),

            pw.Text('2. Coordonnees', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.Text('Adresse: ${s.adressePostale}'),
            pw.Text('Telephone: ${s.telephone}'),
            pw.Text('Email: ${s.email}'),
            pw.SizedBox(height: 15),

            pw.Text('3. Affiliation & Identite', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.Text('Numero CIN / Piece: ${s.cin}'),
            pw.Text('Securite Sociale (SS): ${s.numeroSecuriteSociale}'),
            pw.SizedBox(height: 15),

            pw.Text('4. Contrat & Poste', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.Text('Date d\'embauche: ${s.dateEmbauche != null ? "${s.dateEmbauche!.day}/${s.dateEmbauche!.month}/${s.dateEmbauche!.year}" : "Non défini"}'),
            pw.Text('Date fin de contrat: ${s.dateFinContrat != null ? "${s.dateFinContrat!.day}/${s.dateFinContrat!.month}/${s.dateFinContrat!.year}" : "Néant / CDI"}'),
            pw.Text('Type de contrat: ${s.typeContrat}'),
            pw.Text('Poste: ${s.emploiPoste}'),
            pw.Text('Est Actif: ${s.estActif ? "Oui" : "Non (Archive)"}'),
          ];
        },
      ),
    );
    final bytes = await pdf.save();
    await FileSaver.instance.saveFile(
      name: 'salarie_${s.nom}_${s.prenom}.pdf',
      bytes: bytes,
      mimeType: MimeType.pdf,
    );
  }

  Future<void> _exportSalariePointage(Salarie s) async {
    final entrepriseId = ModalRoute.of(context)?.settings.arguments as String?;
    final provider = Provider.of<EntrepriseProvider>(context, listen: false);
    final entreprise = entrepriseId != null 
        ? provider.entreprises.firstWhere((e) => e.id == entrepriseId, orElse: () => provider.entreprises.first) 
        : provider.entreprises.first;

    showDialog(
      context: context,
      builder: (context) => _ExportPointageDialog(
        salarie: s,
        entrepriseNom: entreprise.nom,
      ),
    );
  }



  void _showEmployeeDetailsModal(BuildContext context, Salarie salarie) {
    showDialog(
      context: context,
      builder: (context) => _SalarieDetailsDialog(salarie: salarie),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EntrepriseProvider>(context);

    if (provider.entreprises.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final entrepriseId = ModalRoute.of(context)?.settings.arguments as String?;
    
    // Fallback to first if no ID passed (e.g. direct load)
    final entreprise = entrepriseId != null 
        ? provider.entreprises.firstWhere((e) => e.id == entrepriseId, orElse: () => provider.entreprises.first) 
        : provider.entreprises.first;

    // Trigger data loading for this enterprise
    _ensureDataLoaded(entreprise.id);

    return MainShell(
      currentRoute: AppRoutes.entrepriseDetails,
      title: 'Dossier Entreprise',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: StaggeredColumn(
          children: [
            // ─── Header de l'entreprise ───
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    key: ValueKey(entreprise.logoUrl),
                    radius: 44,
                    backgroundColor: AppColors.surfaceContainerHigh,
                    backgroundImage: (entreprise.logoUrl != null && entreprise.logoUrl!.isNotEmpty)
                        ? NetworkImage(entreprise.logoUrl!)
                        : null,
                    child: (entreprise.logoUrl == null || entreprise.logoUrl!.isEmpty)
                        ? const Icon(Icons.domain, size: 44, color: AppColors.onSurfaceVariant)
                        : null,
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(entreprise.nom, style: AppTextStyles.headlineMedium, overflow: TextOverflow.ellipsis),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                              child: Text(entreprise.statut, style: AppTextStyles.labelSmall.copyWith(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary, letterSpacing: 0.8)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(entreprise.description, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.onSurfaceVariant), overflow: TextOverflow.ellipsis, maxLines: 2),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Flexible(child: _infoChip(Icons.person_outline, 'Gérant: ${entreprise.nomGerant}')),
                            const SizedBox(width: 16),
                            Flexible(child: _infoChip(Icons.email_outlined, entreprise.email)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => _EditEntrepriseDialog(entreprise: entreprise),
                      );
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(border: Border.all(color: AppColors.outlineVariant), borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.edit_outlined, size: 16, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text('Modifier', style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600, color: AppColors.primary)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
                     // ─── Tab Bar ───
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  _tabButton('Informations'),
                  _tabButton('Salariés'),
                  _tabButton('Archives des employés'),
                  _tabButton('Notes & Rappels'),
                ]),
              ),
            ),
            const SizedBox(height: 24),

            // ─── Tab Content ───
            if (_activeTab == 'Informations') _buildInformationsTab(entreprise),
            if (_activeTab == 'Salariés') _buildSalariesTab(context, provider.salariesPourEntreprise(entreprise.id), entreprise.id),
            if (_activeTab == 'Archives des employés') _buildArchivesTab(provider.archivesPourEntreprise(entreprise.id)),
            if (_activeTab == 'Notes & Rappels') _buildNotesTab(context, provider.notesPourEntreprise(entreprise.id), entreprise.id),
          ],
        ),
      ),
    );
  }

  Widget _tabButton(String label) {
    bool active = _activeTab == label;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = label),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          decoration: BoxDecoration(
            color: active ? AppColors.surfaceContainerLowest : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: active ? [BoxShadow(color: AppColors.onSurface.withValues(alpha: 0.04), blurRadius: 4)] : null,
          ),
          child: Text(label, style: AppTextStyles.labelMedium.copyWith(
            color: active ? AppColors.primary : AppColors.onSurfaceVariant,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          )),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.primary),
        const SizedBox(width: 4),
        Flexible(child: Text(text, style: AppTextStyles.bodySmall.copyWith(color: AppColors.onSurface), overflow: TextOverflow.ellipsis)),
      ],
    );
  }

  Widget _buildInformationsTab(Entreprise entreprise) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Général
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(16)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.info_outline, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('INFORMATIONS GÉNÉRALES', style: AppTextStyles.labelSmall.copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 24),
              _readField('Nom complet de l\'entreprise', entreprise.nom),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _readField('Date de création', "${entreprise.dateCreation.day}/${entreprise.dateCreation.month}/${entreprise.dateCreation.year}")),
                const SizedBox(width: 16),
                Expanded(child: _readField('N° d\'effectif', entreprise.effectif == 0 ? 'Non défini' : '${entreprise.effectif}')),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _readField('Téléphone', entreprise.telephone.isEmpty ? 'Non défini' : entreprise.telephone)),
                const SizedBox(width: 16),
                Expanded(child: _readField('Adresse physique', entreprise.adressePhysique.isEmpty ? 'Non défini' : entreprise.adressePhysique)),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _readField('Adresse Email', entreprise.email)),
                const SizedBox(width: 16),
                Expanded(child: _readField('Nom de dirigeant', entreprise.nomGerant)),
              ]),
            ]),
          ),
        ),
        const SizedBox(width: 16),
        // Juridique
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(16)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const Icon(Icons.gavel_outlined, size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text('INFORMATIONS JURIDIQUES', style: AppTextStyles.labelSmall.copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w700)),
              ]),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(child: _readField('N° SIREN', entreprise.nSiren.isEmpty ? 'Non défini' : entreprise.nSiren)),
                const SizedBox(width: 16),
                Expanded(child: _readField('N° SIRET', entreprise.nSiret.isEmpty ? 'Non défini' : entreprise.nSiret)),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _readField('Forme juridique', entreprise.formeJuridique.isEmpty ? 'Non défini' : entreprise.formeJuridique)),
                const SizedBox(width: 16),
                Expanded(child: _readField('Capital social', entreprise.capitaleSocial.isEmpty ? 'Non défini' : entreprise.capitaleSocial)),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _readField('N° TVA Intracommunautaire', entreprise.nTva.isEmpty ? 'Non défini' : entreprise.nTva)),
                const SizedBox(width: 16),
                Expanded(child: _readField('N° RCS', entreprise.nRcs.isEmpty ? 'Non défini' : entreprise.nRcs)),
              ]),
              const SizedBox(height: 16),
              _readField('Code APE / NAF', entreprise.codeApe.isEmpty ? 'Non défini' : entreprise.codeApe),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _readField(String label, String value) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: AppTextStyles.labelMedium.copyWith(color: AppColors.onSurfaceVariant, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
        child: Text(value.isEmpty ? 'Non défini' : value, style: AppTextStyles.bodyMedium),
      ),
    ]);
  }

  Widget _buildSalariesTab(BuildContext context, List<Salarie> salaries, String entrepriseId) {
    if (salaries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Center(child: Text('Aucun salarié actif.', style: AppTextStyles.bodyMedium)),
            const SizedBox(height: 16),
             ElevatedButton.icon(
                  onPressed: () {
                    showDialog(context: context, builder: (_) => _AddSalarieDialog(entrepriseId: entrepriseId));
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Ajouter un salarié'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            ),
          ]
        )
      );
    }
    return Container(
      decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Liste des Salariés', style: AppTextStyles.titleMedium),
                ElevatedButton.icon(
                  onPressed: () {
                     showDialog(context: context, builder: (_) => _AddSalarieDialog(entrepriseId: entrepriseId));
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Ajouter un salarié'),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                ),
              ],
            ),
          ),
          Divider(color: AppColors.outlineVariant.withValues(alpha: 0.2), height: 1),
          // Liste
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: salaries.length,
            separatorBuilder: (context, index) => Divider(color: AppColors.outlineVariant.withValues(alpha: 0.1), height: 1),
            itemBuilder: (context, index) {
              final salarie = salaries[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.surfaceContainerLow,
                      backgroundImage: (salarie.avatarUrl != null && salarie.avatarUrl!.isNotEmpty)
                          ? NetworkImage(salarie.avatarUrl!)
                          : null,
                      child: (salarie.avatarUrl == null || salarie.avatarUrl!.isEmpty)
                          ? Icon(Icons.person, color: AppColors.onSurfaceVariant)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${salarie.nom} ${salarie.prenom}', style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700)),
                          Text('Né(e): ${salarie.nomNaissance} | CIN: ${salarie.cin}', style: AppTextStyles.bodySmall.copyWith(color: AppColors.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _exportSalariePointage(salarie),
                      icon: const Icon(Icons.access_time, size: 16),
                      label: const Text('Pointage'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => _exportSalariePdf(salarie),
                      icon: const Icon(Icons.download, size: 16),
                      label: const Text('Exporter'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => _showEmployeeDetailsModal(context, salarie),
                      child: const Text('Plus d\'infos'),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.archive_outlined, color: Colors.orange),
                      tooltip: 'Archiver l\'employé',
                      onPressed: () {
                        Provider.of<EntrepriseProvider>(context, listen: false).archiverSalarie(salarie.id, salarie.entrepriseId);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Employé archivé avec succès.'), backgroundColor: Colors.orange));
                      },
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.error),
                      tooltip: 'Supprimer l\'employé',
                      onPressed: () {
                        Provider.of<EntrepriseProvider>(context, listen: false).supprimerArchive(salarie.id, salarie.entrepriseId);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Employé supprimé définitivement.'), backgroundColor: AppColors.error));
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }


  Widget _buildArchivesTab(List<Salarie> archives) {
    if (archives.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(16)),
        child: Center(child: Text('Aucune archive d\'employé.', style: AppTextStyles.bodyMedium)),
      );
    }
    return Container(
      decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Employés Archivés (${archives.length})', style: AppTextStyles.titleMedium),
                    const SizedBox(height: 4),
                    Text('Liste des employés inactifs (ayant quitté l\'entreprise).', style: AppTextStyles.bodySmall.copyWith(color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ],
            ),
          ),
          Divider(color: AppColors.outlineVariant.withValues(alpha: 0.2), height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: archives.length,
            separatorBuilder: (context, index) => Divider(color: AppColors.outlineVariant.withValues(alpha: 0.1), height: 1),
            itemBuilder: (context, index) {
              final s = archives[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.surfaceContainerLow,
                      backgroundImage: (s.avatarUrl != null && s.avatarUrl!.isNotEmpty)
                          ? NetworkImage(s.avatarUrl!)
                          : null,
                      child: (s.avatarUrl == null || s.avatarUrl!.isEmpty)
                          ? const Icon(Icons.person_off, color: AppColors.onSurfaceVariant)
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${s.nom} ${s.prenom}', style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700, decoration: TextDecoration.lineThrough)),
                          Text('Né(e): ${s.nomNaissance} | CIN: ${s.cin}', style: AppTextStyles.bodySmall.copyWith(color: AppColors.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _exportSalariePointage(s),
                      icon: const Icon(Icons.access_time, size: 16),
                      label: const Text('Pointage'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => _exportSalariePdf(s),
                      icon: const Icon(Icons.download, size: 16),
                      label: const Text('Exporter'),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => _showEmployeeDetailsModal(context, s),
                      child: const Text('Plus d\'infos'),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.unarchive_outlined, color: AppColors.success),
                      tooltip: 'Désarchiver l\'employé',
                      onPressed: () {
                        Provider.of<EntrepriseProvider>(context, listen: false).desarchiverSalarie(s.id, s.entrepriseId);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Employé désarchivé avec succès.'), backgroundColor: AppColors.success));
                      },
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.error),
                      tooltip: 'Supprimer l\'archive',
                      onPressed: () {
                        Provider.of<EntrepriseProvider>(context, listen: false).supprimerArchive(s.id, s.entrepriseId);
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Archive supprimée définitivement.'), backgroundColor: AppColors.error));
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotesTab(BuildContext context, List<NoteEntreprise> notes, String entrepriseId) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Notes & Rappels (${notes.length})', style: AppTextStyles.titleMedium),
              ElevatedButton.icon(
                onPressed: () {
                  showDialog(context: context, builder: (_) => _AddNoteDialog(entrepriseId: entrepriseId));
                },
                icon: const Icon(Icons.add),
                label: const Text('Ajouter'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (notes.isEmpty)
            const Center(child: Text('Aucune note ou rappel pour cette entreprise.'))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: notes.length,
              separatorBuilder: (_, i) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final note = notes[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: note.estRappel ? AppColors.warning.withValues(alpha: 0.08) : AppColors.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: note.estRappel ? AppColors.warning.withValues(alpha: 0.4) : AppColors.outlineVariant.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(note.estRappel ? Icons.notifications_active : Icons.sticky_note_2_outlined,
                            color: note.estRappel ? AppColors.warning : AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text(note.titre, style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700))),
                        Text('${note.dateCreation.day}/${note.dateCreation.month}/${note.dateCreation.year}',
                            style: AppTextStyles.bodySmall.copyWith(color: AppColors.onSurfaceVariant)),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                          tooltip: 'Supprimer',
                          onPressed: () async {
                            try {
                              await Provider.of<EntrepriseProvider>(context, listen: false).supprimerNote(note.id, entrepriseId);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Note supprimée.'), backgroundColor: AppColors.success));
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error));
                              }
                            }
                          },
                        ),
                      ]),
                      const SizedBox(height: 8),
                      Text(note.contenu, style: AppTextStyles.bodyMedium),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _AddNoteDialog extends StatefulWidget {
  final String entrepriseId;
  const _AddNoteDialog({required this.entrepriseId});

  @override
  State<_AddNoteDialog> createState() => _AddNoteDialogState();
}

class _AddNoteDialogState extends State<_AddNoteDialog> {
  final _titreController = TextEditingController();
  final _contenuController = TextEditingController();
  bool _isRappel = false;
  bool _isLoading = false;

  Future<void> _ajouter() async {
    if (_titreController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Le titre est obligatoire.')));
      return;
    }

    setState(() => _isLoading = true);

    final note = NoteEntreprise(
      id: '',
      entrepriseId: widget.entrepriseId,
      titre: _titreController.text,
      contenu: _contenuController.text,
      dateCreation: DateTime.now(),
      estRappel: _isRappel,
    );

    try {
      await Provider.of<EntrepriseProvider>(context, listen: false).ajouterNote(note);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Note ajoutée avec succès !'), backgroundColor: AppColors.success));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  @override
  void dispose() {
    _titreController.dispose();
    _contenuController.dispose();
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Ajouter une Note', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 24),
            TextField(
              controller: _titreController,
              decoration: const InputDecoration(labelText: 'Titre', border: OutlineInputBorder(), isDense: true),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contenuController,
              maxLines: 4,
              decoration: const InputDecoration(labelText: 'Contenu', border: OutlineInputBorder(), isDense: true),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: const Text('Rappel'),
              subtitle: const Text('Marquer comme rappel important'),
              value: _isRappel,
              onChanged: (v) => setState(() => _isRappel = v),
              activeThumbColor: AppColors.primary,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: _isLoading ? null : () => Navigator.pop(context), child: const Text('Annuler', style: TextStyle(color: AppColors.error))),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _ajouter,
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Ajouter'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}


class _EditEntrepriseDialog extends StatefulWidget {
  final Entreprise entreprise;
  const _EditEntrepriseDialog({required this.entreprise});

  @override
  State<_EditEntrepriseDialog> createState() => _EditEntrepriseDialogState();
}

class _EditEntrepriseDialogState extends State<_EditEntrepriseDialog> {
  late TextEditingController _nomController;
  late TextEditingController _gerantController;
  late TextEditingController _descController;
  late TextEditingController _emailController;
  late TextEditingController _mdpController;
  late TextEditingController _adresseController;
  late TextEditingController _effectifController;
  late TextEditingController _sirenController;
  late TextEditingController _siretController;
  late TextEditingController _formeController;
  late TextEditingController _tvaController;
  late TextEditingController _rcsController;
  late TextEditingController _capitalController;
  late TextEditingController _telephoneController;
  late TextEditingController _codeApeController;

  String? _logoUrl;
  bool _isUploadingLogo = false;

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.entreprise.nom);
    _gerantController = TextEditingController(text: widget.entreprise.nomGerant);
    _descController = TextEditingController(text: widget.entreprise.description);
    _emailController = TextEditingController(text: widget.entreprise.email);
    _mdpController = TextEditingController(text: widget.entreprise.motDePasse);
    _adresseController = TextEditingController(text: widget.entreprise.adressePhysique);
    _effectifController = TextEditingController(text: widget.entreprise.effectif.toString());
    _sirenController = TextEditingController(text: widget.entreprise.nSiren);
    _siretController = TextEditingController(text: widget.entreprise.nSiret);
    _formeController = TextEditingController(text: widget.entreprise.formeJuridique);
    _tvaController = TextEditingController(text: widget.entreprise.nTva);
    _rcsController = TextEditingController(text: widget.entreprise.nRcs);
    _capitalController = TextEditingController(text: widget.entreprise.capitaleSocial);
    _telephoneController = TextEditingController(text: widget.entreprise.telephone);
    _codeApeController = TextEditingController(text: widget.entreprise.codeApe);
    _logoUrl = widget.entreprise.logoUrl;
  }

  Future<void> _changeLogo() async {
    final messenger = ScaffoldMessenger.of(context);
    final provider = Provider.of<EntrepriseProvider>(context, listen: false);
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.bytes == null || file.name.isEmpty) return;

      setState(() => _isUploadingLogo = true);

      final success = await provider.uploadEntrepriseLogo(widget.entreprise.id, file.bytes!, file.name);

      if (!mounted) return;
      
      if (success) {
        final updatedEntreprise = provider.entreprises.firstWhere((e) => e.id == widget.entreprise.id, orElse: () => widget.entreprise);
        setState(() {
          _logoUrl = updatedEntreprise.logoUrl;
          _isUploadingLogo = false;
        });
        messenger.showSnackBar(const SnackBar(
          content: Text('Logo mis à jour avec succès !'),
          backgroundColor: AppColors.success,
        ));
      } else {
        setState(() => _isUploadingLogo = false);
        messenger.showSnackBar(const SnackBar(
          content: Text('Erreur lors de la mise à jour du logo.'),
          backgroundColor: AppColors.error,
        ));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingLogo = false);
        messenger.showSnackBar(SnackBar(
          content: Text('Erreur lors de la sélection du fichier : $e'),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  void _sauvegarder() {
    if (_nomController.text.isEmpty || _emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nom et Email sont obligatoires.')),
      );
      return;
    }

    final entrepriseAjournee = widget.entreprise.copyWith(
      nom: _nomController.text,
      nomGerant: _gerantController.text,
      description: _descController.text,
      email: _emailController.text,
      motDePasse: _mdpController.text,
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
      logoUrl: _logoUrl,
    );

    Provider.of<EntrepriseProvider>(context, listen: false).updateEntreprise(entrepriseAjournee);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Informations modifiées avec succès !'), backgroundColor: AppColors.success),
    );
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
    _telephoneController.dispose();
    _codeApeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.surfaceContainerLowest,
      child: Container(
        width: 500,
        height: 700,
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Text('Modifier l\'Entreprise', style: AppTextStyles.headlineSmall),
            const SizedBox(height: 16),
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    key: ValueKey(_logoUrl),
                    radius: 40,
                    backgroundColor: AppColors.surfaceContainerHigh,
                    backgroundImage: (_logoUrl != null && _logoUrl!.isNotEmpty)
                        ? NetworkImage(_logoUrl!)
                        : null,
                    child: (_logoUrl == null || _logoUrl!.isEmpty)
                        ? const Icon(Icons.domain, size: 40, color: AppColors.onSurfaceVariant)
                        : null,
                  ),
                  if (_isUploadingLogo)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Material(
                      elevation: 2,
                      shape: const CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      color: AppColors.primary,
                      child: InkWell(
                        onTap: _changeLogo,
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(Icons.camera_alt, size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    Row(
                      children: [
                        Expanded(child: _buildField('Téléphone de l\'entreprise', _telephoneController, keyboardType: TextInputType.phone)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildField('Adresse physique', _adresseController)),
                      ],
                    ),
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
                    const SizedBox(height: 16),
                    _buildField('Code APE / NAF', _codeApeController),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Annuler', style: TextStyle(color: AppColors.error)),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _sauvegarder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Enregistrer'),
                ),
              ],
            ),
          ],
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

class _AddSalarieDialog extends StatefulWidget {
  final String entrepriseId;
  const _AddSalarieDialog({required this.entrepriseId});

  @override
  State<_AddSalarieDialog> createState() => _AddSalarieDialogState();
}

class _AddSalarieDialogState extends State<_AddSalarieDialog> {
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _nomNaissanceController = TextEditingController();
  final _cinController = TextEditingController();
  final _nssController = TextEditingController();
  final _lieuNaissanceController = TextEditingController();
  final _nationaliteController = TextEditingController();
  final _adressePostaleController = TextEditingController();
  final _telController = TextEditingController();
  final _emailController = TextEditingController();
  final _emploiPosteController = TextEditingController();
  final descriptionController = TextEditingController();

  String _genre = 'M';
  String _typeContrat = 'CDI';
  bool _isLoading = false;
  DateTime? _dateNaissance;
  DateTime? _dateEmbauche;
  DateTime? _dateFinContrat;

  Uint8List? _avatarBytes;
  String _avatarName = '';

  // Pièces jointes
  Map<String, Uint8List?> fichiers = {
    'piece_identite': null,
    'carte_vitale': null,
    'justificatif_domicile': null,
    'contrat_signe': null,
  };
  Map<String, String> fichiersNoms = {
    'piece_identite': '',
    'carte_vitale': '',
    'justificatif_domicile': '',
    'contrat_signe': '',
  };

  bool get _needsDateFin => _typeContrat == 'CDD' || _typeContrat == 'Stage';

  Future<void> _pickDate(String field) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(1950),
      lastDate: DateTime(2050),
      locale: const Locale('fr'),
    );
    if (picked != null) {
      setState(() {
        if (field == 'naissance') _dateNaissance = picked;
        if (field == 'embauche') _dateEmbauche = picked;
        if (field == 'fin') _dateFinContrat = picked;
      });
    }
  }

  Future<void> _pickFile(String key) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'docx'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.bytes != null) {
        setState(() {
          fichiers[key] = file.bytes;
          fichiersNoms[key] = file.name;
        });
      }
    }
  }

  Future<void> _pickAvatar() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.bytes != null) {
        setState(() {
          _avatarBytes = file.bytes;
          _avatarName = file.name;
        });
      }
    }
  }

  Future<void> _ajouter() async {
    if (_nomController.text.isEmpty || _prenomController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nom et Prénom sont obligatoires.')));
      return;
    }

    if (_needsDateFin && _dateFinContrat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('La date de fin de contrat est obligatoire pour un contrat $_typeContrat.'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isLoading = true);

    final s = Salarie(
      id: '',
      entrepriseId: widget.entrepriseId,
      nom: _nomController.text,
      prenom: _prenomController.text,
      genre: _genre,
      nomNaissance: _nomNaissanceController.text.isEmpty ? _nomController.text : _nomNaissanceController.text,
      cin: _cinController.text,
      numeroSecuriteSociale: _nssController.text,
      dateNaissance: _dateNaissance,
      lieuNaissance: _lieuNaissanceController.text,
      nationalite: _nationaliteController.text,
      adressePostale: _adressePostaleController.text,
      telephone: _telController.text,
      email: _emailController.text,
      dateEmbauche: _dateEmbauche ?? DateTime.now(),
      typeContrat: _typeContrat,
      dateFinContrat: _dateFinContrat,
      emploiPoste: _emploiPosteController.text,
      description: descriptionController.text,
      aPieceIdentite: fichiers['piece_identite'] != null,
      aCarteVitale: fichiers['carte_vitale'] != null,
      aJustificatifDomicile: fichiers['justificatif_domicile'] != null,
      aContratSigne: fichiers['contrat_signe'] != null,
      estActif: true,
    );

    try {
      final created = await Provider.of<EntrepriseProvider>(context, listen: false).ajouterSalarie(s);

      // Upload les fichiers si présents
      final salarieId = created.id;
      final storage = SupabaseConfig.adminClient.storage.from('documents');

      for (final entry in fichiers.entries) {
        if (entry.value != null) {
          final fileName = fichiersNoms[entry.key]!;
          final ext = fileName.split('.').last.toLowerCase();
          final path = 'salaries/$salarieId/${entry.key}.$ext';
          await storage.uploadBinary(path, entry.value!, fileOptions: FileOptions(upsert: true, contentType: _mimeType(ext)));
        }
      }

      // Upload avatar if present
      if (_avatarBytes != null && _avatarName.isNotEmpty) {
        await Provider.of<EntrepriseProvider>(context, listen: false)
            .uploadSalarieAvatar(salarieId, _avatarBytes!, _avatarName, widget.entrepriseId);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Salarié ajouté avec succès !'), backgroundColor: AppColors.success));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  String _mimeType(String ext) {
    switch (ext) {
      case 'pdf': return 'application/pdf';
      case 'jpg': case 'jpeg': return 'image/jpeg';
      case 'png': return 'image/png';
      case 'docx': return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default: return 'application/octet-stream';
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Non défini';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.surfaceContainerLowest,
      child: Container(
        width: 650,
        padding: const EdgeInsets.all(32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ajouter un Salarié', style: AppTextStyles.headlineSmall),
              const SizedBox(height: 24),
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.surfaceContainerLow,
                      backgroundImage: _avatarBytes != null
                          ? MemoryImage(_avatarBytes!)
                          : null,
                      child: _avatarBytes == null
                          ? const Icon(Icons.person, size: 50, color: AppColors.onSurfaceVariant)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.primary,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                          onPressed: _pickAvatar,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Nom / Prénom
              Row(children: [
                Expanded(child: TextField(controller: _nomController, decoration: const InputDecoration(labelText: 'Nom *', border: OutlineInputBorder(), isDense: true))),
                const SizedBox(width: 16),
                Expanded(child: TextField(controller: _prenomController, decoration: const InputDecoration(labelText: 'Prénom *', border: OutlineInputBorder(), isDense: true))),
              ]),
              const SizedBox(height: 16),

              // Nom naissance / Genre
              Row(children: [
                Expanded(child: TextField(controller: _nomNaissanceController, decoration: const InputDecoration(labelText: 'Nom de Naissance', border: OutlineInputBorder(), isDense: true))),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _genre,
                    decoration: const InputDecoration(labelText: 'Genre', border: OutlineInputBorder(), isDense: true),
                    items: const [
                      DropdownMenuItem(value: 'M', child: Text('Masculin')),
                      DropdownMenuItem(value: 'F', child: Text('Féminin')),
                    ],
                    onChanged: (v) => setState(() => _genre = v!),
                  ),
                )
              ]),
              const SizedBox(height: 16),

              // CIN / NSS
              Row(children: [
                Expanded(child: TextField(controller: _cinController, decoration: const InputDecoration(labelText: 'CIN', border: OutlineInputBorder(), isDense: true))),
                const SizedBox(width: 16),
                Expanded(child: TextField(controller: _nssController, decoration: const InputDecoration(labelText: 'N° Sécurité Sociale', border: OutlineInputBorder(), isDense: true))),
              ]),
              const SizedBox(height: 16),

              // Date naissance / Lieu naissance
              Row(children: [
                Expanded(child: _datePicker('Date de naissance', _dateNaissance, () => _pickDate('naissance'))),
                const SizedBox(width: 16),
                Expanded(child: TextField(controller: _lieuNaissanceController, decoration: const InputDecoration(labelText: 'Lieu de naissance', border: OutlineInputBorder(), isDense: true))),
              ]),
              const SizedBox(height: 16),

              // Nationalité / Adresse
              Row(children: [
                Expanded(child: TextField(controller: _nationaliteController, decoration: const InputDecoration(labelText: 'Nationalité', border: OutlineInputBorder(), isDense: true))),
                const SizedBox(width: 16),
                Expanded(child: TextField(controller: _adressePostaleController, decoration: const InputDecoration(labelText: 'Adresse Postale', border: OutlineInputBorder(), isDense: true))),
              ]),
              const SizedBox(height: 16),

              // Tel / Email
              Row(children: [
                Expanded(child: TextField(controller: _telController, decoration: const InputDecoration(labelText: 'Téléphone', border: OutlineInputBorder(), isDense: true))),
                const SizedBox(width: 16),
                Expanded(child: TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder(), isDense: true))),
              ]),
              const SizedBox(height: 16),

              // Type contrat / Poste
              Row(children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _typeContrat,
                    decoration: const InputDecoration(labelText: 'Type Contrat', border: OutlineInputBorder(), isDense: true),
                    items: const [
                      DropdownMenuItem(value: 'CDI', child: Text('CDI')),
                      DropdownMenuItem(value: 'CDD', child: Text('CDD')),
                      DropdownMenuItem(value: 'Apprentissage', child: Text('Apprentissage')),
                      DropdownMenuItem(value: 'Stage', child: Text('Stage')),
                    ],
                    onChanged: (v) => setState(() => _typeContrat = v!),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(child: TextField(controller: _emploiPosteController, decoration: const InputDecoration(labelText: 'Poste Occupé', border: OutlineInputBorder(), isDense: true))),
              ]),
              const SizedBox(height: 16),

              // Date embauche / Date fin contrat
              Row(children: [
                Expanded(child: _datePicker('Date d\'embauche', _dateEmbauche, () => _pickDate('embauche'))),
                const SizedBox(width: 16),
                Expanded(
                  child: _datePicker(
                    'Date fin de contrat${_needsDateFin ? " *" : ""}',
                    _dateFinContrat,
                    () => _pickDate('fin'),
                  ),
                ),
              ]),
              if (_needsDateFin && _dateFinContrat == null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('⚠ Obligatoire pour un contrat $_typeContrat', style: TextStyle(color: AppColors.error, fontSize: 11)),
                ),
              const SizedBox(height: 16),

              // Description / Note
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description / Note sur le salarié',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),

              const SizedBox(height: 24),

              Text('Pièces jointes', style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text('Formats acceptés : PDF, JPG, PNG, DOCX', style: AppTextStyles.bodySmall.copyWith(color: AppColors.onSurfaceVariant)),
              const SizedBox(height: 12),

              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _fileChip('Pièce d\'identité', 'piece_identite'),
                  _fileChip('Carte Vitale', 'carte_vitale'),
                  _fileChip('Justificatif domicile', 'justificatif_domicile'),
                  _fileChip('Contrat signé', 'contrat_signe'),
                ],
              ),

              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: _isLoading ? null : () => Navigator.pop(context), child: const Text('Annuler', style: TextStyle(color: AppColors.error))),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _ajouter,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                    child: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Ajouter le Salarié'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _datePicker(String label, DateTime? value, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
          suffixIcon: const Icon(Icons.calendar_today, size: 16),
        ),
        child: Text(
          _formatDate(value),
          style: AppTextStyles.bodyMedium.copyWith(color: value != null ? AppColors.onSurface : AppColors.outline),
        ),
      ),
    );
  }

  Widget _fileChip(String label, String key) {
    final hasFile = fichiers[key] != null;
    final fileName = fichiersNoms[key] ?? '';
    return InkWell(
      onTap: () => _pickFile(key),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: hasFile ? AppColors.success.withValues(alpha: 0.08) : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: hasFile ? AppColors.success.withValues(alpha: 0.4) : AppColors.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasFile ? Icons.check_circle : Icons.upload_file,
              size: 16,
              color: hasFile ? AppColors.success : AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              hasFile ? fileName : label,
              style: AppTextStyles.labelSmall.copyWith(
                fontWeight: FontWeight.w600,
                color: hasFile ? AppColors.success : AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditSalarieDialog extends StatefulWidget {
  final Salarie salarie;
  const _EditSalarieDialog({required this.salarie});

  @override
  State<_EditSalarieDialog> createState() => _EditSalarieDialogState();
}

class _EditSalarieDialogState extends State<_EditSalarieDialog> {
  late final TextEditingController _nomController;
  late final TextEditingController _prenomController;
  late final TextEditingController _nomNaissanceController;
  late final TextEditingController _cinController;
  late final TextEditingController _nssController;
  late final TextEditingController _lieuNaissanceController;
  late final TextEditingController _nationaliteController;
  late final TextEditingController _adressePostaleController;
  late final TextEditingController _telController;
  late final TextEditingController _emailController;
  late final TextEditingController _emploiPosteController;
  late final TextEditingController descriptionController;

  late String _genre;
  late String _typeContrat;
  bool _isLoading = false;
  DateTime? _dateNaissance;
  DateTime? _dateEmbauche;
  DateTime? _dateFinContrat;

  Uint8List? _avatarBytes;
  String _avatarName = '';

  // Pièces jointes
  Map<String, Uint8List?> fichiers = {
    'piece_identite': null,
    'carte_vitale': null,
    'justificatif_domicile': null,
    'contrat_signe': null,
  };
  Map<String, String> fichiersNoms = {
    'piece_identite': '',
    'carte_vitale': '',
    'justificatif_domicile': '',
    'contrat_signe': '',
  };

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.salarie.nom);
    _prenomController = TextEditingController(text: widget.salarie.prenom);
    _nomNaissanceController = TextEditingController(text: widget.salarie.nomNaissance);
    _cinController = TextEditingController(text: widget.salarie.cin);
    _nssController = TextEditingController(text: widget.salarie.numeroSecuriteSociale);
    _lieuNaissanceController = TextEditingController(text: widget.salarie.lieuNaissance);
    _nationaliteController = TextEditingController(text: widget.salarie.nationalite);
    _adressePostaleController = TextEditingController(text: widget.salarie.adressePostale);
    _telController = TextEditingController(text: widget.salarie.telephone);
    _emailController = TextEditingController(text: widget.salarie.email);
    _emploiPosteController = TextEditingController(text: widget.salarie.emploiPoste);
    descriptionController = TextEditingController(text: widget.salarie.description);

    _genre = widget.salarie.genre.isEmpty ? 'M' : widget.salarie.genre;
    _typeContrat = widget.salarie.typeContrat.isEmpty ? 'CDI' : widget.salarie.typeContrat;
    _dateNaissance = widget.salarie.dateNaissance;
    _dateEmbauche = widget.salarie.dateEmbauche;
    _dateFinContrat = widget.salarie.dateFinContrat;
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _nomNaissanceController.dispose();
    _cinController.dispose();
    _nssController.dispose();
    _lieuNaissanceController.dispose();
    _nationaliteController.dispose();
    _adressePostaleController.dispose();
    _telController.dispose();
    _emailController.dispose();
    _emploiPosteController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  bool get _needsDateFin => _typeContrat == 'CDD' || _typeContrat == 'Stage';

  Future<void> _pickDate(String field) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(1950),
      lastDate: DateTime(2050),
      locale: const Locale('fr'),
    );
    if (picked != null) {
      setState(() {
        if (field == 'naissance') _dateNaissance = picked;
        if (field == 'embauche') _dateEmbauche = picked;
        if (field == 'fin') _dateFinContrat = picked;
      });
    }
  }

  Future<void> _pickFile(String key) async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'docx'],
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.bytes != null) {
        setState(() {
          fichiers[key] = file.bytes;
          fichiersNoms[key] = file.name;
        });
      }
    }
  }

  Future<void> _pickAvatar() async {
    final result = await FilePicker.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      if (file.bytes != null) {
        setState(() {
          _avatarBytes = file.bytes;
          _avatarName = file.name;
        });
      }
    }
  }

  Future<void> _enregistrer() async {
    if (_nomController.text.isEmpty || _prenomController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nom et Prénom sont obligatoires.')));
      return;
    }

    if (_needsDateFin && _dateFinContrat == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('La date de fin de contrat est obligatoire pour un contrat $_typeContrat.'), backgroundColor: AppColors.error),
      );
      return;
    }

    setState(() => _isLoading = true);

    final s = Salarie(
      id: widget.salarie.id,
      entrepriseId: widget.salarie.entrepriseId,
      nom: _nomController.text,
      prenom: _prenomController.text,
      genre: _genre,
      nomNaissance: _nomNaissanceController.text.isEmpty ? _nomController.text : _nomNaissanceController.text,
      cin: _cinController.text,
      numeroSecuriteSociale: _nssController.text,
      dateNaissance: _dateNaissance,
      lieuNaissance: _lieuNaissanceController.text,
      nationalite: _nationaliteController.text,
      adressePostale: _adressePostaleController.text,
      telephone: _telController.text,
      email: _emailController.text,
      dateEmbauche: _dateEmbauche ?? DateTime.now(),
      typeContrat: _typeContrat,
      dateFinContrat: _dateFinContrat,
      emploiPoste: _emploiPosteController.text,
      description: descriptionController.text,
      aPieceIdentite: widget.salarie.aPieceIdentite || fichiers['piece_identite'] != null,
      aCarteVitale: widget.salarie.aCarteVitale || fichiers['carte_vitale'] != null,
      aJustificatifDomicile: widget.salarie.aJustificatifDomicile || fichiers['justificatif_domicile'] != null,
      aContratSigne: widget.salarie.aContratSigne || fichiers['contrat_signe'] != null,
      estActif: widget.salarie.estActif,
    );

    try {
      await Provider.of<EntrepriseProvider>(context, listen: false).modifierSalarie(s);

      // Upload les nouveaux fichiers si présents
      final storage = SupabaseConfig.adminClient.storage.from('documents');

      for (final entry in fichiers.entries) {
        if (entry.value != null) {
          final fileName = fichiersNoms[entry.key]!;
          final ext = fileName.split('.').last.toLowerCase();
          final path = 'salaries/${widget.salarie.id}/${entry.key}.$ext';
          await storage.uploadBinary(path, entry.value!, fileOptions: FileOptions(upsert: true, contentType: _mimeType(ext)));
        }
      }

      // Upload avatar if present
      if (_avatarBytes != null && _avatarName.isNotEmpty) {
        await Provider.of<EntrepriseProvider>(context, listen: false)
            .uploadSalarieAvatar(widget.salarie.id, _avatarBytes!, _avatarName, widget.salarie.entrepriseId);
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Données du salarié modifiées avec succès !'), backgroundColor: AppColors.success));
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  String _mimeType(String ext) {
    if (ext == 'pdf') return 'application/pdf';
    if (ext == 'png') return 'image/png';
    if (ext == 'jpg' || ext == 'jpeg') return 'image/jpeg';
    if (ext == 'docx') return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    return 'application/octet-stream';
  }

  Widget _buildField(String label, TextEditingController controller, {bool required = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(label, style: AppTextStyles.labelMedium.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.w600)),
            if (required) Text(' *', style: const TextStyle(color: AppColors.error)),
          ],
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.outline)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
          ),
          style: AppTextStyles.bodyMedium,
        ),
      ],
    );
  }

  Widget _fileChip(String label, String key, bool initiallyHasFile) {
    final hasNewFile = fichiers[key] != null;
    final hasFile = hasNewFile || initiallyHasFile;
    final fileName = hasNewFile ? fichiersNoms[key]! : 'Fichier existant';
    return InkWell(
      onTap: () => _pickFile(key),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: hasFile ? AppColors.success.withValues(alpha: 0.08) : AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: hasFile ? AppColors.success.withValues(alpha: 0.4) : AppColors.outlineVariant),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasFile ? Icons.check_circle : Icons.upload_file,
              size: 16,
              color: hasFile ? AppColors.success : AppColors.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              hasFile ? (hasNewFile ? fileName : '$label (Existant - Modifier)') : label,
              style: AppTextStyles.labelSmall.copyWith(
                fontWeight: FontWeight.w600,
                color: hasFile ? AppColors.success : AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.surfaceContainerLowest,
      child: Container(
        width: 650,
        padding: const EdgeInsets.all(32),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Modifier le Salarié', style: AppTextStyles.headlineSmall),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 24),
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: AppColors.surfaceContainerLow,
                      backgroundImage: _avatarBytes != null
                          ? MemoryImage(_avatarBytes!)
                          : (widget.salarie.avatarUrl != null && widget.salarie.avatarUrl!.isNotEmpty
                              ? NetworkImage(widget.salarie.avatarUrl!) as ImageProvider
                              : null),
                      child: (_avatarBytes == null && (widget.salarie.avatarUrl == null || widget.salarie.avatarUrl!.isEmpty))
                          ? const Icon(Icons.person, size: 50, color: AppColors.onSurfaceVariant)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: AppColors.primary,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.camera_alt, size: 16, color: Colors.white),
                          onPressed: _pickAvatar,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('État Civil', style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Genre', style: AppTextStyles.labelMedium.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _genre,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'M', child: Text('Masculin')),
                            DropdownMenuItem(value: 'F', child: Text('Féminin')),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => _genre = v);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: _buildField('Nom', _nomController, required: true)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildField('Prénom', _prenomController, required: true)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildField('Nom de naissance', _nomNaissanceController)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildField('CIN', _cinController)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildField('N° Sécurité Sociale', _nssController)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Date de naissance', style: AppTextStyles.labelMedium.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () => _pickDate('naissance'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(border: Border.all(color: AppColors.outline), borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_dateNaissance != null ? "${_dateNaissance!.day}/${_dateNaissance!.month}/${_dateNaissance!.year}" : 'Choisir date', style: AppTextStyles.bodyMedium),
                                const Icon(Icons.calendar_today, size: 16, color: AppColors.onSurfaceVariant),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: _buildField('Lieu de naissance', _lieuNaissanceController)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildField('Nationalité', _nationaliteController)),
                  const SizedBox(width: 16),
                  const Expanded(child: SizedBox()),
                ],
              ),
              const SizedBox(height: 24),
              Text('Coordonnées', style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildField('Adresse postale', _adressePostaleController),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildField('Téléphone', _telController)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildField('Email', _emailController)),
                ],
              ),
              const SizedBox(height: 24),
              Text('Contrat & Poste', style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Date d\'embauche', style: AppTextStyles.labelMedium.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () => _pickDate('embauche'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(border: Border.all(color: AppColors.outline), borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_dateEmbauche != null ? "${_dateEmbauche!.day}/${_dateEmbauche!.month}/${_dateEmbauche!.year}" : 'Choisir date', style: AppTextStyles.bodyMedium),
                                const Icon(Icons.calendar_today, size: 16, color: AppColors.onSurfaceVariant),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Type de contrat', style: AppTextStyles.labelMedium.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _typeContrat,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          items: const [
                            DropdownMenuItem(value: 'CDI', child: Text('CDI')),
                            DropdownMenuItem(value: 'CDD', child: Text('CDD')),
                            DropdownMenuItem(value: 'Apprentissage', child: Text('Apprentissage')),
                            DropdownMenuItem(value: 'Stage', child: Text('Stage')),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => _typeContrat = v);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (_needsDateFin) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Date de fin de contrat', style: AppTextStyles.labelMedium.copyWith(color: AppColors.onSurface, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () => _pickDate('fin'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(border: Border.all(color: AppColors.outline), borderRadius: BorderRadius.circular(8)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_dateFinContrat != null ? "${_dateFinContrat!.day}/${_dateFinContrat!.month}/${_dateFinContrat!.year}" : 'Choisir date', style: AppTextStyles.bodyMedium),
                                  const Icon(Icons.calendar_today, size: 16, color: AppColors.onSurfaceVariant),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(child: SizedBox()),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              _buildField('Emploi / Poste', _emploiPosteController),
              const SizedBox(height: 24),
              _buildField('Description / Note sur le salarié', descriptionController),
              const SizedBox(height: 24),
              Text('Pièces Jointes (Modifier/Ajouter)', style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _fileChip('Pièce d\'identité', 'piece_identite', widget.salarie.aPieceIdentite),
                  _fileChip('Carte Vitale', 'carte_vitale', widget.salarie.aCarteVitale),
                  _fileChip('Justificatif domicile', 'justificatif_domicile', widget.salarie.aJustificatifDomicile),
                  _fileChip('Contrat signé', 'contrat_signe', widget.salarie.aContratSigne),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: const Text('Annuler'),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _enregistrer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                        : const Text('Enregistrer'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _ExportPointageDialog extends StatefulWidget {
  final Salarie salarie;
  final String entrepriseNom;

  const _ExportPointageDialog({
    required this.salarie,
    required this.entrepriseNom,
  });

  @override
  State<_ExportPointageDialog> createState() => _ExportPointageDialogState();
}

class _ExportPointageDialogState extends State<_ExportPointageDialog> {
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  bool _isLoading = false;

  final List<String> _months = [
    'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
  ];

  final List<int> _years = List.generate(5, (index) => DateTime.now().year - index);

  Future<void> _export() async {
    setState(() => _isLoading = true);
    const separator = ',';

    try {
      final dataService = PlatformDataService();
      final pointages = await dataService.fetchPointagesForSalarieAndMonth(
        widget.salarie.id,
        _selectedYear,
        _selectedMonth,
      );

      final Map<String, Map<String, dynamic>> pointageMap = {};
      for (final p in pointages) {
        final dStr = p['date'] as String?;
        if (dStr != null) {
          final dateOnly = dStr.split('T').first;
          pointageMap[dateOnly] = p;
        }
      }

      final daysInMonth = DateTime(_selectedYear, _selectedMonth + 1, 0).day;
      int presents = 0;
      int absents = 0;
      int nonRenseignes = 0;

      final rows = <List<String>>[];

      for (int day = 1; day <= daysInMonth; day++) {
        final date = DateTime(_selectedYear, _selectedMonth, day);
        final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
        final displayDate = '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';

        String status = '';
        String note = '';

        if (pointageMap.containsKey(dateKey)) {
          final p = pointageMap[dateKey]!;
          final estPointe = p['est_pointe'] as bool? ?? false;
          note = p['note'] as String? ?? '';
          if (estPointe) {
            status = 'Présent';
            presents++;
          } else {
            status = note.isNotEmpty ? 'Congé' : 'Absent';
            absents++;
          }
        } else {
          status = 'Non renseigné';
          nonRenseignes++;
        }

        rows.add([displayDate, status, note]);
      }

      final buffer = StringBuffer();
      
      buffer.writeln('Rapport de Pointage Mensuel$separator');
      buffer.writeln('Salarié$separator${escapeCsv("${widget.salarie.prenom} ${widget.salarie.nom}", separator)}');
      buffer.writeln('Entreprise$separator${escapeCsv(widget.entrepriseNom, separator)}');
      buffer.writeln('Période$separator${_months[_selectedMonth - 1]} $_selectedYear');
      buffer.writeln('Jours Présents$separator$presents');
      buffer.writeln('Jours Absents/Congés$separator$absents');
      buffer.writeln('Jours Non Renseignés$separator$nonRenseignes');
      buffer.writeln('');
      
      buffer.writeln('Date${separator}Statut${separator}Note / Description');
      
      for (final row in rows) {
        final dateEsc = escapeCsv(row[0], separator);
        final statusEsc = escapeCsv(row[1], separator);
        final noteEsc = escapeCsv(row[2], separator);
        buffer.writeln('$dateEsc$separator$statusEsc$separator$noteEsc');
      }

      final csvContent = buffer.toString();
      
      final utf8BOM = [0xEF, 0xBB, 0xBF];
      final bytes = Uint8List.fromList([...utf8BOM, ...utf8.encode(csvContent)]);

      final monthStr = _selectedMonth.toString().padLeft(2, '0');
      final fileName = 'pointage_${widget.salarie.nom.replaceAll(' ', '_')}_${widget.salarie.prenom.replaceAll(' ', '_')}_${monthStr}_$_selectedYear.csv';

      await FileSaver.instance.saveFile(
        name: fileName,
        bytes: bytes,
        mimeType: MimeType.csv,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rapport exporté avec succès : $fileName'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'export : $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String escapeCsv(String field, String separator) {
    if (field.contains(separator) || field.contains('"') || field.contains('\n') || field.contains('\r')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.surfaceContainerLowest,
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Exporter le Pointage',
              style: AppTextStyles.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Salarié : ${widget.salarie.prenom} ${widget.salarie.nom}',
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(height: 24),

            DropdownButtonFormField<int>(
              initialValue: _selectedMonth,
              decoration: const InputDecoration(
                labelText: 'Mois',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: List.generate(12, (index) {
                return DropdownMenuItem(
                  value: index + 1,
                  child: Text(_months[index]),
                );
              }),
              onChanged: _isLoading ? null : (v) => setState(() => _selectedMonth = v!),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<int>(
              initialValue: _selectedYear,
              decoration: const InputDecoration(
                labelText: 'Année',
                border: OutlineInputBorder(),
                isDense: true,
              ),
              items: _years.map((y) {
                return DropdownMenuItem(
                  value: y,
                  child: Text(y.toString()),
                );
              }).toList(),
              onChanged: _isLoading ? null : (v) => setState(() => _selectedYear = v!),
            ),
            const SizedBox(height: 24),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: CircularProgressIndicator(),
                ),
              )
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Annuler', style: TextStyle(color: AppColors.error)),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () => _export(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Exporter'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _SalarieDetailsDialog extends StatefulWidget {
  final Salarie salarie;

  const _SalarieDetailsDialog({required this.salarie});

  @override
  State<_SalarieDetailsDialog> createState() => _SalarieDetailsDialogState();
}

class _SalarieDetailsDialogState extends State<_SalarieDetailsDialog> {
  bool _loadingFiles = true;
  Map<String, String> _fileUrls = {};

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    try {
      final list = await SupabaseConfig.adminClient.storage
          .from('documents')
          .list(path: 'salaries/${widget.salarie.id}');

      final Map<String, String> urls = {};
      for (final f in list) {
        final parts = f.name.split('.');
        if (parts.isNotEmpty) {
          final key = parts.first;
          final path = 'salaries/${widget.salarie.id}/${f.name}';
          final url = SupabaseConfig.adminClient.storage
              .from('documents')
              .getPublicUrl(path);
          urls[key] = url;
        }
      }
      if (mounted) {
        setState(() {
          _fileUrls = urls;
          _loadingFiles = false;
        });
      }
    } catch (e) {
      debugPrint('Error listing documents: $e');
      if (mounted) {
        setState(() => _loadingFiles = false);
      }
    }
  }

  Future<void> _downloadOrViewFile(String label, String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Impossible d\'ouvrir le fichier $label.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de l\'ouverture du fichier : $e')),
        );
      }
    }
  }

  Widget _readField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            value.isEmpty ? 'Non défini' : value,
            style: AppTextStyles.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: AppTextStyles.labelMedium.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _docChip(String key, String label, bool available) {
    final url = _fileUrls[key];
    final isClickable = available && url != null;

    return MouseRegion(
      cursor: isClickable ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: isClickable ? () => _downloadOrViewFile(label, url) : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: available
                ? (isClickable
                    ? AppColors.success.withValues(alpha: 0.1)
                    : AppColors.success.withValues(alpha: 0.05))
                : AppColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: available
                  ? (isClickable
                      ? AppColors.success.withValues(alpha: 0.3)
                      : AppColors.success.withValues(alpha: 0.15))
                  : AppColors.error.withValues(alpha: 0.3),
              width: isClickable ? 1.5 : 1.0,
            ),
            boxShadow: isClickable
                ? [
                    BoxShadow(
                      color: AppColors.success.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (available && _loadingFiles)
                const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.success),
                  ),
                )
              else
                Icon(
                  available
                      ? (isClickable ? Icons.cloud_download : Icons.check_circle)
                      : Icons.cancel,
                  size: 14,
                  color: available ? AppColors.success : AppColors.error,
                ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: available ? AppColors.success : AppColors.error,
                  decoration: isClickable ? TextDecoration.underline : TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final salarie = widget.salarie;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.surfaceContainerLowest,
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(32),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Informations du Salarié', style: AppTextStyles.headlineSmall),
                  Row(
                    children: [
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          showDialog(
                            context: context,
                            builder: (context) => _EditSalarieDialog(salarie: widget.salarie),
                          );
                        },
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Modifier'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: AppColors.surfaceContainerLow,
                  backgroundImage: (salarie.avatarUrl != null && salarie.avatarUrl!.isNotEmpty)
                      ? NetworkImage(salarie.avatarUrl!)
                      : null,
                  child: (salarie.avatarUrl == null || salarie.avatarUrl!.isEmpty)
                      ? const Icon(Icons.person, size: 50, color: AppColors.onSurfaceVariant)
                      : null,
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('État Civil & Identité'),
              Row(
                children: [
                  Expanded(child: _readField('Genre', salarie.genre == 'M' ? 'Masculin' : (salarie.genre == 'F' ? 'Féminin' : salarie.genre))),
                  const SizedBox(width: 16),
                  Expanded(child: _readField('Nom', salarie.nom)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _readField('Prénom', salarie.prenom)),
                  const SizedBox(width: 16),
                  Expanded(child: _readField('Nom de naissance', salarie.nomNaissance)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _readField('CIN', salarie.cin)),
                  const SizedBox(width: 16),
                  Expanded(child: _readField('N° Sécurité Sociale', salarie.numeroSecuriteSociale)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _readField('Date de naissance', salarie.dateNaissance != null ? "${salarie.dateNaissance!.day}/${salarie.dateNaissance!.month}/${salarie.dateNaissance!.year}" : "Non défini")),
                  const SizedBox(width: 16),
                  Expanded(child: _readField('Lieu de naissance', salarie.lieuNaissance)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _readField('Nationalité', salarie.nationalite)),
                  const SizedBox(width: 16),
                  const Expanded(child: SizedBox()),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Coordonnées'),
              _readField('Adresse postale', salarie.adressePostale),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _readField('Téléphone', salarie.telephone)),
                  const SizedBox(width: 16),
                  Expanded(child: _readField('Email', salarie.email)),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Informations Professionnelles'),
              Row(
                children: [
                  Expanded(child: _readField('Date d\'embauche', salarie.dateEmbauche != null ? "${salarie.dateEmbauche!.day}/${salarie.dateEmbauche!.month}/${salarie.dateEmbauche!.year}" : "Non défini")),
                  const SizedBox(width: 16),
                  Expanded(child: _readField('Type de contrat', salarie.typeContrat)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _readField('Date de fin', salarie.dateFinContrat != null ? "${salarie.dateFinContrat!.day}/${salarie.dateFinContrat!.month}/${salarie.dateFinContrat!.year}" : "—")),
                  const SizedBox(width: 16),
                  Expanded(child: _readField('Emploi/Poste', salarie.emploiPoste)),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionTitle('Description / Note'),
              _readField('Description / Note sur le salarié', salarie.description),
              const SizedBox(height: 24),
              _buildSectionTitle('Pièces jointes'),
              Text(
                'Les pièces jointes en vert souligné sont téléchargeables. Cliquez pour les ouvrir.',
                style: AppTextStyles.bodySmall.copyWith(color: AppColors.onSurfaceVariant, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _docChip('piece_identite', 'Pièce d\'identité', salarie.aPieceIdentite),
                  _docChip('carte_vitale', 'Carte Vitale', salarie.aCarteVitale),
                  _docChip('justificatif_domicile', 'Justificatif domicile', salarie.aJustificatifDomicile),
                  _docChip('contrat_signe', 'Contrat signé', salarie.aContratSigne),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}



