import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:file_saver/file_saver.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/main_shell.dart';
import '../../../../core/widgets/staggered_column.dart';
import '../../../entreprises/domain/models/salarie.dart';
import '../../../entreprises/domain/models/document_entreprise.dart';
import '../../../entreprises/domain/models/note_entreprise.dart';
import '../../../entreprises/domain/models/entreprise.dart';
import '../../../entreprises/presentation/providers/entreprise_provider.dart';

class EntrepriseDetailsPage extends StatefulWidget {
  const EntrepriseDetailsPage({super.key});

  @override
  State<EntrepriseDetailsPage> createState() => _EntrepriseDetailsPageState();
}

class _EntrepriseDetailsPageState extends State<EntrepriseDetailsPage> {
  String _activeTab = 'Informations';
  String _selectedDocCategory = 'Toutes';
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
    final csvData = 'NOM,PRENOM,DATE,HEURES\n${s.nom},${s.prenom},${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year},8\n';
    final bytes = Uint8List.fromList(csvData.codeUnits);
    await FileSaver.instance.saveFile(
      name: 'pointage_${s.nom}_${s.prenom}.csv',
      bytes: bytes,
      mimeType: MimeType.csv,
    );
    if(mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fichier de pointage telecharge.'), backgroundColor: AppColors.success));
    }
  }



  void _showEmployeeDetailsModal(BuildContext context, Salarie salarie) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
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
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSectionTitle('État Civil & Identité'),
                Row(
                  children: [
                    Expanded(child: _readField('Genre', salarie.genre)),
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
                    Expanded(child: _readField('N° Sécurité Sociale', salarie.numeroSecuriteSociale)),
                    const SizedBox(width: 16),
                    Expanded(child: _readField('Date de naissance', salarie.dateNaissance != null ? "${salarie.dateNaissance!.day}/${salarie.dateNaissance!.month}/${salarie.dateNaissance!.year}" : "Non défini")),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _readField('Lieu de naissance', salarie.lieuNaissance)),
                    const SizedBox(width: 16),
                    Expanded(child: _readField('Nationalité', salarie.nationalite)),
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
                _buildSectionTitle('Pièces jointes'),
                Row(
                  children: [
                    _docChip('Pièce d\'identité', true),
                    const SizedBox(width: 8),
                    _docChip('Carte Vitale', true),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _docChip('Justificatif domicile', true),
                    const SizedBox(width: 8),
                    _docChip('Contrat signé', true),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)),
    );
  }

  Widget _docChip(String label, bool available) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: available ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: available ? AppColors.success.withValues(alpha: 0.3) : AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(available ? Icons.check_circle : Icons.cancel, size: 14, color: available ? AppColors.success : AppColors.error),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: available ? AppColors.success : AppColors.error)),
        ],
      ),
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
                    radius: 44,
                    backgroundColor: AppColors.surfaceContainerHigh,
                    child: const Icon(Icons.domain, size: 44, color: AppColors.onSurfaceVariant),
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
            const SizedBox(height: 20),

            // ─── Tab Bar ───
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  _tabButton('Informations'),
                  _tabButton('Salariés'),
                  _tabButton('Documents'),
                  _tabButton('Archives des employés'),
                  _tabButton('Notes & Rappels'),
                ]),
              ),
            ),
            const SizedBox(height: 24),

            // ─── Tab Content ───
            if (_activeTab == 'Informations') _buildInformationsTab(entreprise),
            if (_activeTab == 'Salariés') _buildSalariesTab(context, provider.salariesPourEntreprise(entreprise.id), entreprise.id),
            if (_activeTab == 'Documents') _buildDocumentsTab(context, provider.documentsPourEntreprise(entreprise.id)),
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
                Expanded(child: _readField('N° d\'effectif', entreprise.effectif == 0 ? 'Non défini' : '${entreprise.effectif}')),
              ]),
              const SizedBox(height: 16),
              _readField('Adresse physique', entreprise.adressePhysique.isEmpty ? 'Non défini' : entreprise.adressePhysique),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _readField('Adresse Email', entreprise.email)),
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
                    CircleAvatar(backgroundColor: AppColors.surfaceContainerLow, child: Icon(Icons.person, color: AppColors.onSurfaceVariant)),
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

  Widget _buildDocumentsTab(BuildContext context, List<DocumentEntreprise> docs) {
    var filteredDocs = _selectedDocCategory == 'Toutes' ? docs : docs.where((d) => d.categorie == _selectedDocCategory).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Documents (${filteredDocs.length})', style: AppTextStyles.titleMedium),
              DropdownButton<String>(
                value: _selectedDocCategory,
                items: [
                   'Toutes',
                   'Fichiers comptables', 'Fichiers fiscaux', 'Fichiers sociaux / paie',
                   'Fichiers juridiques', 'Fichiers administratifs', 'Fichiers clients / fournisseurs',
                   'Fichiers banques & finances', 'Autres documents'
                ].map((c) => DropdownMenuItem(value: c, child: Text(c, style: AppTextStyles.bodyMedium))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedDocCategory = val);
                },
              ),
            ]
          ),
          const SizedBox(height: 24),
          if (filteredDocs.isEmpty)
             const Center(child: Text('Aucun document trouvé.'))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredDocs.length,
              separatorBuilder: (context, index) => const Divider(),
              itemBuilder: (ctx, idx) {
                 final doc = filteredDocs[idx];
                 return ListTile(
                   leading: CircleAvatar(backgroundColor: AppColors.surfaceContainerLow, child: Icon(Icons.description, color: AppColors.primary)),
                   title: Text(doc.nom, style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700)),
                   subtitle: Text('${doc.categorie} | Ajouté le ${doc.dateAjout.day}/${doc.dateAjout.month}/${doc.dateAjout.year}', style: AppTextStyles.bodySmall),
                   trailing: OutlinedButton(
                      child: const Text('Catégoriser'),
                      onPressed: () {
                         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Catégorisation en cours de développement.'), backgroundColor: AppColors.primary));
                      }
                   ),
                 );
              }
            )
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Employés Archivés (${archives.length})', style: AppTextStyles.titleMedium),
          const SizedBox(height: 8),
          Text('Liste des employés inactifs (ayant quitté l\'entreprise).', style: AppTextStyles.bodySmall.copyWith(color: AppColors.onSurfaceVariant)),
          const SizedBox(height: 24),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: archives.length,
            separatorBuilder: (_, i) => const Divider(),
            itemBuilder: (context, index) {
              final s = archives[index];
              final dateFin = s.dateFinContrat;
              return ListTile(
                leading: CircleAvatar(backgroundColor: AppColors.surfaceContainerLow, child: const Icon(Icons.person_off, color: AppColors.onSurfaceVariant)),
                title: Text('${s.nom} ${s.prenom}', style: AppTextStyles.labelMedium.copyWith(decoration: TextDecoration.lineThrough)),
                subtitle: Text('Fin contrat : ${dateFin != null ? "${dateFin.day}/${dateFin.month}/${dateFin.year}" : "Inconnu"}', style: AppTextStyles.bodySmall),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8), side: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.3))),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  OutlinedButton(
                    onPressed: () => _showEmployeeDetailsModal(context, s),
                    child: const Text('Dossier'),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.download_outlined, color: AppColors.primary),
                    tooltip: 'Télécharger les informations',
                    onPressed: () => _exportSalariePdf(s),
                  ),
                  const SizedBox(width: 4),
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
                ]),
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.surfaceContainerLowest,
      child: Container(
        width: 500,
        height: 600,
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Text('Modifier l\'Entreprise', style: AppTextStyles.headlineSmall),
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

  String _genre = 'M';
  String _typeContrat = 'CDI';
  bool _isLoading = false;

  Future<void> _ajouter() async {
    if (_nomController.text.isEmpty || _prenomController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nom et Prénom sont obligatoires.')));
      return;
    }

    setState(() => _isLoading = true);

    final s = Salarie(
      id: '', // DB generates UUID
      entrepriseId: widget.entrepriseId,
      nom: _nomController.text,
      prenom: _prenomController.text,
      genre: _genre,
      nomNaissance: _nomNaissanceController.text.isEmpty ? _nomController.text : _nomNaissanceController.text,
      cin: _cinController.text,
      numeroSecuriteSociale: _nssController.text,
      dateNaissance: DateTime(1990, 1, 1),
      lieuNaissance: _lieuNaissanceController.text,
      nationalite: _nationaliteController.text,
      adressePostale: _adressePostaleController.text,
      telephone: _telController.text,
      email: _emailController.text,
      dateEmbauche: DateTime.now(),
      typeContrat: _typeContrat,
      emploiPoste: _emploiPosteController.text,
      estActif: true,
    );

    try {
      await Provider.of<EntrepriseProvider>(context, listen: false).ajouterSalarie(s);
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.surfaceContainerLowest,
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ajouter un Salarié', style: AppTextStyles.headlineSmall),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(child: TextField(controller: _nomController, decoration: const InputDecoration(labelText: 'Nom', border: OutlineInputBorder(), isDense: true))),
                  const SizedBox(width: 16),
                  Expanded(child: TextField(controller: _prenomController, decoration: const InputDecoration(labelText: 'Prénom', border: OutlineInputBorder(), isDense: true))),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
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
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: TextField(controller: _cinController, decoration: const InputDecoration(labelText: 'CIN', border: OutlineInputBorder(), isDense: true))),
                  const SizedBox(width: 16),
                  Expanded(child: TextField(controller: _nssController, decoration: const InputDecoration(labelText: 'N° Sécurité Sociale', border: OutlineInputBorder(), isDense: true))),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: TextField(controller: _lieuNaissanceController, decoration: const InputDecoration(labelText: 'Lieu de naissance', border: OutlineInputBorder(), isDense: true))),
                  const SizedBox(width: 16),
                  Expanded(child: TextField(controller: _nationaliteController, decoration: const InputDecoration(labelText: 'Nationalité', border: OutlineInputBorder(), isDense: true))),
                ],
              ),
              const SizedBox(height: 16),
              TextField(controller: _adressePostaleController, decoration: const InputDecoration(labelText: 'Adresse Postale', border: OutlineInputBorder(), isDense: true)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: TextField(controller: _telController, decoration: const InputDecoration(labelText: 'Téléphone', border: OutlineInputBorder(), isDense: true))),
                  const SizedBox(width: 16),
                  Expanded(child: TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder(), isDense: true))),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
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
              )
            ],
          ),
        ),
      ),
    );
  }
}


