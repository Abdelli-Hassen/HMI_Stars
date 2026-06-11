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
import '../../../../core/utils/translation_extension.dart';
import '../../../../core/utils/toast_utils.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/widgets/file_previewer.dart';
import '../../../../core/widgets/web_image.dart';
import '../../../entreprises/domain/models/template_avertissement.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;

class EntrepriseDetailsPage extends StatefulWidget {
  const EntrepriseDetailsPage({super.key});

  @override
  State<EntrepriseDetailsPage> createState() => _EntrepriseDetailsPageState();
}

class _EntrepriseDetailsPageState extends State<EntrepriseDetailsPage> {
  ColorScheme get cs => Theme.of(context).colorScheme;
  String _activeTab = 'Informations';
  String? _loadedEntrepriseId;
  String? _persistedEntrepriseId;
  String? _selectedWarningCategory;

  @override
  void initState() {
    super.initState();
    _loadPersistedId();
  }

  Future<void> _loadPersistedId() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('last_viewed_entreprise_id');
    if (id != null && mounted) {
      setState(() {
        _persistedEntrepriseId = id;
      });
    }
  }

  void _ensureDataLoaded(String entrepriseId) {
    if (_loadedEntrepriseId == entrepriseId) return;
    _loadedEntrepriseId = entrepriseId;
    final provider = Provider.of<EntrepriseProvider>(context, listen: false);
    provider.fetchSalariesForEntreprise(entrepriseId, force: true);
    provider.fetchNotesForEntreprise(entrepriseId, force: true);
    provider.fetchDocumentsForEntreprise(entrepriseId, force: true);
    provider.fetchModelesForEntreprise(entrepriseId, force: true);
  }

  Future<void> _exportSalariePdf(Salarie s) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.MultiPage(
        build: (pw.Context pdfCtx) {
          final isM = s.genre.trim().toUpperCase().startsWith('M');
          final genderStr = isM ? context.tr('Masculin', 'Male') : context.tr('Féminin', 'Female');
          final activeStr = s.estActif ? context.tr('Oui', 'Yes') : context.tr('Non (Archivé)', 'No (Archived)');
          final undefinedStr = context.tr('Non défini', 'Not defined');
          final noneCdiStr = context.tr('Néant / CDI', 'None / CDI');

          return [
            pw.Text('${context.tr('Dossier Complet du Salarié: ', 'Complete Employee File: ')}${s.nom} ${s.prenom}', style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
            pw.SizedBox(height: 20),
            
            pw.Text(context.tr('1. Identité & État Civil', '1. Identity & Civil Status'), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.Text('${context.tr('Nom: ', 'Last Name: ')}${s.nom}'),
            pw.Text('${context.tr('Prénom: ', 'First Name: ')}${s.prenom}'),
            pw.Text('${context.tr('Nom de naissance: ', 'Birth Name: ')}${s.nomNaissance}'),
            pw.Text('${context.tr('Genre: ', 'Gender: ')}$genderStr'),
            pw.Text('${context.tr('Date de naissance: ', 'Date of Birth: ')}${s.dateNaissance != null ? "${s.dateNaissance!.day}/${s.dateNaissance!.month}/${s.dateNaissance!.year}" : undefinedStr}'),
            pw.Text('${context.tr('Lieu de naissance: ', 'Place of Birth: ')}${s.lieuNaissance}'),
            pw.Text('${context.tr('Nationalité: ', 'Nationality: ')}${s.nationalite}'),
            pw.SizedBox(height: 15),

            pw.Text(context.tr('2. Coordonnées', '2. Contact Info'), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.Text('${context.tr('Adresse: ', 'Address: ')}${s.adressePostale}'),
            pw.Text('${context.tr('Téléphone: ', 'Phone: ')}${s.telephone}'),
            pw.Text('${context.tr('Email: ', 'Email: ')}${s.email}'),
            pw.SizedBox(height: 15),

            pw.Text(context.tr('3. Affiliation & Identité', '3. Affiliation & Identity'), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.Text('${context.tr('Numéro CIN / Pièce: ', 'ID Card Number: ')}${s.cin}'),
            pw.Text('${context.tr('Sécurité Sociale (SS): ', 'Social Security (SS): ')}${s.numeroSecuriteSociale}'),
            pw.SizedBox(height: 15),

            pw.Text(context.tr('4. Contrat & Poste', '4. Contract & Job'), style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.Text('${context.tr('Date d\'embauche: ', 'Hire Date: ')}${s.dateEmbauche != null ? "${s.dateEmbauche!.day}/${s.dateEmbauche!.month}/${s.dateEmbauche!.year}" : undefinedStr}'),
            pw.Text('${context.tr('Date fin de contrat: ', 'Contract End Date: ')}${s.dateFinContrat != null ? "${s.dateFinContrat!.day}/${s.dateFinContrat!.month}/${s.dateFinContrat!.year}" : noneCdiStr}'),
            pw.Text('${context.tr('Type de contrat: ', 'Contract Type: ')}${s.typeContrat}'),
            pw.Text('${context.tr('Poste: ', 'Job Title: ')}${s.emploiPoste}'),
            pw.Text('${context.tr('Est Actif: ', 'Is Active: ')}$activeStr'),
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
    final cs = Theme.of(context).colorScheme;
    final provider = Provider.of<EntrepriseProvider>(context);

    if (provider.entreprises.isEmpty) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final argId = ModalRoute.of(context)?.settings.arguments as String?;
    final resolvedId = argId ?? _persistedEntrepriseId;

    if (argId != null && argId != _persistedEntrepriseId) {
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString('last_viewed_entreprise_id', argId);
      });
    }
    
    // Fallback to first if no ID passed (e.g. direct load)
    final entreprise = resolvedId != null 
        ? provider.entreprises.firstWhere((e) => e.id == resolvedId, orElse: () => provider.entreprises.first) 
        : provider.entreprises.first;

    // Trigger data loading for this enterprise
    _ensureDataLoaded(entreprise.id);

    return MainShell(
      currentRoute: AppRoutes.entrepriseDetails,
      title: context.tr('Dossier Entreprise', 'Company Folder'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: StaggeredColumn(
          children: [
            // ─── Header de l'entreprise ───
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: cs.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: (entreprise.logoUrl != null && entreprise.logoUrl!.isNotEmpty)
                        ? () => FilePreviewer.show(context, entreprise.logoUrl!, '${entreprise.nom}_logo.png')
                        : null,
                    child: MouseRegion(
                      cursor: (entreprise.logoUrl != null && entreprise.logoUrl!.isNotEmpty)
                          ? SystemMouseCursors.click
                          : SystemMouseCursors.basic,
                      child: Container(
                        key: ValueKey(entreprise.logoUrl),
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerHigh,
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: (entreprise.logoUrl != null && entreprise.logoUrl!.isNotEmpty)
                              ? WebImage(url: entreprise.logoUrl!, fit: BoxFit.cover)
                              : Icon(Icons.domain, size: 44, color: cs.onSurfaceVariant),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(entreprise.nom, style: AppTextStyles.headlineMedium.copyWith(color: cs.onSurface), overflow: TextOverflow.ellipsis),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                              child: Text(
                                context.tr(entreprise.statut, entreprise.statut == 'EN COURS' ? 'IN PROGRESS' : (entreprise.statut == 'COMPLET' ? 'COMPLETED' : (entreprise.statut == 'ARCHIVÉ' ? 'ARCHIVED' : 'AWAITING DOCS'))),
                                style: AppTextStyles.labelSmall.copyWith(fontSize: 10, fontWeight: FontWeight.w700, color: cs.primary, letterSpacing: 0.8)
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(entreprise.description, style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurfaceVariant), overflow: TextOverflow.ellipsis, maxLines: 2),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Flexible(child: _infoChip(Icons.person_outline, context.tr('Gérant: ${entreprise.nomGerant}', 'Manager: ${entreprise.nomGerant}'))),
                            const SizedBox(width: 16),
                            Flexible(child: _infoChip(Icons.email_outlined, entreprise.email)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InkWell(
                        onTap: () async {
                          final provider = Provider.of<EntrepriseProvider>(context, listen: false);
                          await Future.wait([
                            provider.fetchEntreprises(force: true),
                            provider.fetchSalariesForEntreprise(entreprise.id, force: true),
                            provider.fetchNotesForEntreprise(entreprise.id, force: true),
                            provider.fetchDocumentsForEntreprise(entreprise.id, force: true),
                          ]);
                          if (mounted) {
                            ToastUtils.show(
                              context,
                              context.trStatic('Données actualisées !', 'Data refreshed!'),
                              isError: false,
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(border: Border.all(color: cs.outlineVariant), borderRadius: BorderRadius.circular(10)),
                          child: Icon(Icons.refresh, size: 16, color: cs.primary),
                        ),
                      ),
                      const SizedBox(width: 12),
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
                          decoration: BoxDecoration(border: Border.all(color: cs.outlineVariant), borderRadius: BorderRadius.circular(10)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit_outlined, size: 16, color: cs.primary),
                              const SizedBox(width: 6),
                              Text(context.tr('Modifier', 'Edit'), style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600, color: cs.primary)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
                     // ─── Tab Bar ───
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(color: cs.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(children: [
                  _tabButton('Informations', context.tr('Informations', 'Information')),
                  _tabButton('Salariés', context.tr('Salariés', 'Employees')),
                  _tabButton('Archives des employés', context.tr('Archives des employés', 'Employee Archives')),
                  _tabButton('Avertissements', context.tr('Avertissements', 'Warnings')),
                  _tabButton('Notes & Rappels', context.tr('Notes & Rappels', 'Notes & Reminders')),
                ]),
              ),
            ),
            const SizedBox(height: 24),

            // ─── Tab Content ───
            if (_activeTab == 'Informations') _buildInformationsTab(entreprise),
            if (_activeTab == 'Salariés') _buildSalariesTab(context, provider.salariesPourEntreprise(entreprise.id), entreprise.id),
            if (_activeTab == 'Archives des employés') _buildArchivesTab(provider.archivesPourEntreprise(entreprise.id)),
            if (_activeTab == 'Avertissements') _buildAvertissementsTab(context, provider.modelesPourEntreprise(entreprise.id), provider.salariesPourEntreprise(entreprise.id), entreprise.id),
            if (_activeTab == 'Notes & Rappels') _buildNotesTab(context, provider.notesPourEntreprise(entreprise.id), entreprise.id),
          ],
        ),
      ),
    );
  }

  Widget _tabButton(String key, String displayLabel) {
    bool active = _activeTab == key;
    return GestureDetector(
      onTap: () => setState(() => _activeTab = key),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          decoration: BoxDecoration(
            color: active ? cs.surfaceContainerLowest : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: active ? [BoxShadow(color: cs.onSurface.withValues(alpha: 0.04), blurRadius: 4)] : null,
          ),
          child: Text(displayLabel, style: AppTextStyles.labelMedium.copyWith(
            color: active ? cs.primary : cs.onSurfaceVariant,
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
        Icon(icon, size: 14, color: cs.primary),
        const SizedBox(width: 4),
        Flexible(child: Text(text, style: AppTextStyles.bodySmall.copyWith(color: cs.onSurface), overflow: TextOverflow.ellipsis)),
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
            decoration: BoxDecoration(
              color: cs.surfaceContainerLowest, 
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outline.withValues(alpha: 0.35)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.info_outline, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Text(context.tr('INFORMATIONS GÉNÉRALES', 'GENERAL INFORMATION'), style: AppTextStyles.labelSmall.copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w700, color: cs.onSurfaceVariant)),
              ]),
              const SizedBox(height: 24),
              _readField(context.tr('Nom complet de l\'entreprise', 'Company full name'), entreprise.nom),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _readField(context.tr('Date de création (Système)', 'Creation Date (System)'), "${entreprise.dateCreation.day}/${entreprise.dateCreation.month}/${entreprise.dateCreation.year}")),
                const SizedBox(width: 16),
                Expanded(child: _readField(context.tr('N° d\'effectif', 'Employee count'), '${entreprise.effectif}')),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _readField(context.tr('Téléphone', 'Phone Number'), entreprise.telephone.isEmpty ? 'Non défini' : entreprise.telephone)),
                const SizedBox(width: 16),
                Expanded(child: _readField(context.tr('Adresse physique', 'Physical address'), entreprise.adressePhysique.isEmpty ? 'Non défini' : entreprise.adressePhysique)),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _readField(context.tr('Adresse Email', 'Email Address'), entreprise.email)),
                const SizedBox(width: 16),
                Expanded(child: _readField(context.tr('Nom de dirigeant', 'Manager name'), entreprise.nomGerant)),
              ]),
            ]),
          ),
        ),
        const SizedBox(width: 16),
        // Juridique
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLowest, 
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outline.withValues(alpha: 0.35)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Icon(Icons.gavel_outlined, size: 18, color: cs.primary),
                const SizedBox(width: 8),
                Text(context.tr('INFORMATIONS JURIDIQUES', 'LEGAL INFORMATION'), style: AppTextStyles.labelSmall.copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w700, color: cs.onSurfaceVariant)),
              ]),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(child: _readField(context.tr('N° SIREN', 'SIREN Number'), entreprise.nSiren.isEmpty ? 'Non défini' : entreprise.nSiren)),
                const SizedBox(width: 16),
                Expanded(child: _readField(context.tr('N° SIRET', 'SIRET Number'), entreprise.nSiret.isEmpty ? 'Non défini' : entreprise.nSiret)),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _readField(context.tr('Forme juridique', 'Legal form'), entreprise.formeJuridique.isEmpty ? 'Non défini' : entreprise.formeJuridique)),
                const SizedBox(width: 16),
                Expanded(child: _readField(context.tr('Capital social', 'Share capital'), entreprise.capitaleSocial.isEmpty ? 'Non défini' : entreprise.capitaleSocial)),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _readField(context.tr('N° de TVA', 'VAT Number'), entreprise.nTva.isEmpty ? 'Non défini' : entreprise.nTva)),
                const SizedBox(width: 16),
                Expanded(child: _readField(context.tr('N° RCS', 'RCS Number'), entreprise.nRcs.isEmpty ? 'Non défini' : entreprise.nRcs)),
              ]),
              const SizedBox(height: 16),
              Row(children: [
                Expanded(child: _readField(context.tr('Code APE / NAF', 'APE / NAF Code'), entreprise.codeApe.isEmpty ? 'Non défini' : entreprise.codeApe)),
                const SizedBox(width: 16),
                Expanded(
                  child: _readField(
                    context.tr('Date de création d\'entreprise', 'Company Creation Date'),
                    entreprise.dateCreationReelle != null
                        ? "${entreprise.dateCreationReelle!.day.toString().padLeft(2, '0')}/${entreprise.dateCreationReelle!.month.toString().padLeft(2, '0')}/${entreprise.dateCreationReelle!.year}"
                        : context.tr('Non défini', 'Not defined'),
                  ),
                ),
              ]),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _readField(String label, String value) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: AppTextStyles.labelMedium.copyWith(color: cs.onSurfaceVariant, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(color: cs.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
        child: Text(
          (value.isEmpty || value == 'Non défini') ? context.tr('Non défini', 'Not defined') : value,
          style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurface)
        ),
      ),
    ]);
  }

  Widget _buildSalariesTab(BuildContext context, List<Salarie> salaries, String entrepriseId) {
    if (salaries.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: cs.surfaceContainerLowest, borderRadius: BorderRadius.circular(16)),
        child: Column(
          children: [
            Center(child: Text(context.tr('Aucun salarié actif.', 'No active employees.'), style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurface))),
            const SizedBox(height: 16),
             ElevatedButton.icon(
                  onPressed: () {
                    showDialog(context: context, builder: (_) => _AddSalarieDialog(entrepriseId: entrepriseId));
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(context.tr('Ajouter un salarié', 'Add an employee')),
                  style: ElevatedButton.styleFrom(backgroundColor: cs.primary, foregroundColor: Colors.white),
            ),
          ]
        )
      );
    }
    return Container(
      decoration: BoxDecoration(color: cs.surfaceContainerLowest, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(context.tr('Liste des Salariés', 'Employee List'), style: AppTextStyles.titleMedium.copyWith(color: cs.onSurface)),
                ElevatedButton.icon(
                  onPressed: () {
                     showDialog(context: context, builder: (_) => _AddSalarieDialog(entrepriseId: entrepriseId));
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(context.tr('Ajouter un salarié', 'Add an employee')),
                  style: ElevatedButton.styleFrom(backgroundColor: cs.primary, foregroundColor: Colors.white),
                ),
              ],
            ),
          ),
          Divider(color: cs.outlineVariant.withValues(alpha: 0.2), height: 1),
          // Liste
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: salaries.length,
            separatorBuilder: (context, index) => Divider(color: cs.outlineVariant.withValues(alpha: 0.1), height: 1),
            itemBuilder: (context, index) {
              final cs = Theme.of(context).colorScheme;
              final salarie = salaries[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: (salarie.avatarUrl != null && salarie.avatarUrl!.isNotEmpty)
                          ? () => FilePreviewer.show(context, salarie.avatarUrl!, '${salarie.nom}_${salarie.prenom}_avatar.png')
                          : null,
                      child: MouseRegion(
                        cursor: (salarie.avatarUrl != null && salarie.avatarUrl!.isNotEmpty)
                            ? SystemMouseCursors.click
                            : SystemMouseCursors.basic,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerLow,
                            shape: BoxShape.circle,
                          ),
                          child: ClipOval(
                            child: (salarie.avatarUrl != null &&
                                    salarie.avatarUrl!.isNotEmpty)
                                ? WebImage(url: salarie.avatarUrl!, fit: BoxFit.cover)
                                : Center(
                                    child: Text(
                                      salarie.prenom.isNotEmpty
                                          ? salarie.prenom[0].toUpperCase()
                                          : (salarie.nom.isNotEmpty
                                              ? salarie.nom[0].toUpperCase()
                                              : '?'),
                                      style: TextStyle(
                                        color: cs.primary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${salarie.nom} ${salarie.prenom}', style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700, color: cs.onSurface)),
                          Text(context.tr('Né(e): ${salarie.nomNaissance} | CIN: ${salarie.cin}', 'Born: ${salarie.nomNaissance} | ID: ${salarie.cin}'), style: AppTextStyles.bodySmall.copyWith(color: cs.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _exportSalariePointage(salarie),
                      icon: const Icon(Icons.access_time, size: 16),
                      label: Text(context.tr('Pointage', 'Attendance')),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => _exportSalariePdf(salarie),
                      icon: const Icon(Icons.download, size: 16),
                      label: Text(context.tr('Exporter', 'Export')),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => _showEmployeeDetailsModal(context, salarie),
                      child: Text(context.tr('Plus d\'infos', 'More info')),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.archive_outlined, color: Colors.orange),
                      tooltip: context.tr('Archiver l\'employé', 'Archive employee'),
                      onPressed: () {
                        Provider.of<EntrepriseProvider>(context, listen: false).archiverSalarie(salarie.id, salarie.entrepriseId);
                        ToastUtils.show(
                          context,
                          context.tr('Employé archivé avec succès.', 'Employee archived successfully.'),
                          isError: false,
                        );
                      },
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.error),
                      tooltip: context.tr('Supprimer l\'employé', 'Delete employee'),
                      onPressed: () {
                        Provider.of<EntrepriseProvider>(context, listen: false).supprimerArchive(salarie.id, salarie.entrepriseId);
                        ToastUtils.show(
                          context,
                          context.tr('Employé supprimé définitivement.', 'Employee deleted permanently.'),
                          isError: true,
                        );
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
        decoration: BoxDecoration(color: cs.surfaceContainerLowest, borderRadius: BorderRadius.circular(16)),
        child: Center(child: Text(context.tr('Aucune archive d\'employé.', 'No archived employees.'), style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurface))),
      );
    }
    return Container(
      decoration: BoxDecoration(color: cs.surfaceContainerLowest, borderRadius: BorderRadius.circular(16)),
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
                    Text(context.tr('Employés Archivés (${archives.length})', 'Archived Employees (${archives.length})'), style: AppTextStyles.titleMedium.copyWith(color: cs.onSurface)),
                    const SizedBox(height: 4),
                    Text(context.tr('Liste des employés inactifs (ayant quitté l\'entreprise).', 'List of inactive employees (who left the company).'), style: AppTextStyles.bodySmall.copyWith(color: cs.onSurfaceVariant)),
                  ],
                ),
              ],
            ),
          ),
          Divider(color: cs.outlineVariant.withValues(alpha: 0.2), height: 1),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: archives.length,
            separatorBuilder: (context, index) => Divider(color: cs.outlineVariant.withValues(alpha: 0.1), height: 1),
            itemBuilder: (context, index) {
              final cs = Theme.of(context).colorScheme;
              final s = archives[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: cs.surfaceContainerLow,
                      backgroundImage: (s.avatarUrl != null &&
                              s.avatarUrl!.isNotEmpty)
                          ? NetworkImage(s.avatarUrl!)
                          : null,
                      child: (s.avatarUrl == null ||
                              s.avatarUrl!.isEmpty)
                          ? Center(
                              child: Text(
                                s.prenom.isNotEmpty
                                    ? s.prenom[0].toUpperCase()
                                    : (s.nom.isNotEmpty ? s.nom[0].toUpperCase() : '?'),
                                style: TextStyle(
                                  color: cs.onSurfaceVariant,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${s.nom} ${s.prenom}', style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700, decoration: TextDecoration.lineThrough, color: cs.onSurface)),
                          Text(context.tr('Né(e): ${s.nomNaissance} | CIN: ${s.cin}', 'Born: ${s.nomNaissance} | ID: ${s.cin}'), style: AppTextStyles.bodySmall.copyWith(color: cs.onSurfaceVariant)),
                        ],
                      ),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _exportSalariePointage(s),
                      icon: const Icon(Icons.access_time, size: 16),
                      label: Text(context.tr('Pointage', 'Attendance')),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton.icon(
                      onPressed: () => _exportSalariePdf(s),
                      icon: const Icon(Icons.download, size: 16),
                      label: Text(context.tr('Exporter', 'Export')),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () => _showEmployeeDetailsModal(context, s),
                      child: Text(context.tr('Plus d\'infos', 'More info')),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.unarchive_outlined, color: AppColors.success),
                      tooltip: context.tr('Désarchiver l\'employé', 'Unarchive employee'),
                      onPressed: () {
                        Provider.of<EntrepriseProvider>(context, listen: false).desarchiverSalarie(s.id, s.entrepriseId);
                        ToastUtils.show(
                          context,
                          context.tr('Employé désarchivé avec succès.', 'Employee unarchived successfully.'),
                          isError: false,
                        );
                      },
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.error),
                      tooltip: context.tr('Supprimer l\'archive', 'Delete archive'),
                      onPressed: () {
                        Provider.of<EntrepriseProvider>(context, listen: false).supprimerArchive(s.id, s.entrepriseId);
                        ToastUtils.show(
                          context,
                          context.tr('Archive supprimée définitivement.', 'Archive deleted permanently.'),
                          isError: true,
                        );
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

  // ─── Avertissements Tab ─────────────────────────────────────────────────────

  Widget _buildAvertissementsTab(
    BuildContext context,
    List<ModeleAvertissement> modeles,
    List<Salarie> salaries,
    String entrepriseId,
  ) {
    final cs = Theme.of(context).colorScheme;
    final categories = <_AvertCat>[
      _AvertCat('ficheAvertissement', context.tr('Avertissements', 'Warnings'), Icons.warning_amber_outlined, const Color(0xFFE65100)),
      _AvertCat('convocation', context.tr('Convocations', 'Summons'), Icons.event_note_outlined, cs.primary),
      _AvertCat('information', context.tr('Informations', 'Information'), Icons.info_outline, const Color(0xFF0277BD)),
    ];

    // Detect and append custom warning categories
    final defaultTypes = {'ficheAvertissement', 'convocation', 'information'};
    for (final m in modeles) {
      if (m.type.isNotEmpty && !defaultTypes.contains(m.type) && !categories.any((c) => c.type == m.type)) {
        categories.add(_AvertCat(m.type, m.type, Icons.folder_open_outlined, Colors.blueGrey));
      }
    }

    final filtered = _selectedWarningCategory != null
        ? modeles.where((m) => m.type == _selectedWarningCategory).toList()
        : <ModeleAvertissement>[];

    if (_selectedWarningCategory == null) {
      // ─ Category grid view ─
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('Avertissements', 'Warnings'),
                    style: AppTextStyles.headlineMedium.copyWith(fontWeight: FontWeight.w800, color: cs.onSurface),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.tr('Modèles de lettres prédéfinis, catégorisés et envoyables aux salariés.', 'Predefined letter templates, categorised and sendable to employees.'),
                    style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
              // Add Category button
              InkWell(
                onTap: () => _showNewCategoryDialog(context, entrepriseId),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add, size: 16, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(context.tr('Nouvelle catégorie', 'New category'), style: AppTextStyles.labelMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Category cards
          Row(
            children: categories.map((cat) {
              final count = modeles.where((m) => m.type == cat.type).length;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedWarningCategory = cat.type),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: cs.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
                          boxShadow: [BoxShadow(color: cs.onSurface.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 3))],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: cat.color.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(cat.icon, color: cat.color, size: 26),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(cat.label, style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700, color: cs.onSurface)),
                                  const SizedBox(height: 4),
                                  Text(
                                    context.tr('$count modèle${count > 1 ? "s" : ""}', '$count template${count > 1 ? "s" : ""}'),
                                    style: AppTextStyles.bodySmall.copyWith(color: cat.color, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded, color: cs.outline),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      );
    }

    // ─ Template list view ─
    final cat = categories.firstWhere((c) => c.type == _selectedWarningCategory, orElse: () => categories.first);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Back button + title
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            MouseRegion(
              cursor: SystemMouseCursors.click,
              child: GestureDetector(
                onTap: () => setState(() => _selectedWarningCategory = null),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: cs.primary),
                    const SizedBox(width: 8),
                    Text(context.tr('Catégories', 'Categories'), style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600, color: cs.primary)),
                  ],
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: cat.color.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(cat.icon, color: cat.color, size: 18),
                ),
                const SizedBox(width: 10),
                Text(cat.label, style: AppTextStyles.headlineSmall.copyWith(fontWeight: FontWeight.w800, color: cs.onSurface)),
                const SizedBox(width: 16),
                // Add button
                InkWell(
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => _AvertModeleDialog(
                      entrepriseId: entrepriseId,
                      type: _selectedWarningCategory!,
                      isCategoryFixed: true,
                      onSave: (titre, contenu, type) async {
                        final provider = Provider.of<EntrepriseProvider>(context, listen: false);
                        await provider.ajouterModele(ModeleAvertissement(
                          id: '',
                          entrepriseId: entrepriseId,
                          titre: titre,
                          contenu: contenu,
                          type: type,
                        ));
                        setState(() {
                          _selectedWarningCategory = type;
                        });
                        if (context.mounted) {
                          ToastUtils.show(context, context.tr('Modèle créé avec succès.', 'Template created successfully.'), isError: false);
                        }
                      },
                    ),
                  ),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.add, size: 16, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(context.tr('Nouveau modèle', 'New template'), style: AppTextStyles.labelMedium.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),

        if (filtered.isEmpty)
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(cat.icon, size: 48, color: cs.outline),
                  const SizedBox(height: 12),
                  Text(
                    context.tr('Aucun modèle dans cette catégorie.', 'No templates in this category.'),
                    style: AppTextStyles.bodyMedium.copyWith(color: cs.outline),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    context.tr('Cliquez sur "Nouveau modèle" pour en créer un.', 'Click "New template" to create one.'),
                    style: AppTextStyles.bodySmall.copyWith(color: cs.outline),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final m = filtered[index];
              final cs2 = Theme.of(context).colorScheme;
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: cs2.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cs2.outlineVariant.withValues(alpha: 0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: cat.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(cat.label.toUpperCase(), style: AppTextStyles.labelSmall.copyWith(fontSize: 9, letterSpacing: 1.0, fontWeight: FontWeight.w800, color: cat.color)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(m.titre, style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700, color: cs2.onSurface), overflow: TextOverflow.ellipsis),
                        ),
                        // Preview
                        InkWell(
                          onTap: () => _showAvertPreviewDialog(context, m),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(Icons.visibility_outlined, size: 18, color: cs2.primary),
                          ),
                        ),
                        // Edit
                        InkWell(
                          onTap: () => showDialog(
                            context: context,
                            builder: (_) => _AvertModeleDialog(
                              entrepriseId: entrepriseId,
                              type: m.type,
                              initialTitre: m.titre,
                              initialContenu: m.contenu,
                              isCategoryFixed: true,
                              onSave: (titre, contenu, type) async {
                                final provider = Provider.of<EntrepriseProvider>(context, listen: false);
                                await provider.modifierModele(m.copyWith(titre: titre, contenu: contenu, type: type));
                                setState(() {
                                  _selectedWarningCategory = type;
                                });
                                if (context.mounted) {
                                  ToastUtils.show(context, context.tr('Modèle mis à jour.', 'Template updated.'), isError: false);
                                }
                              },
                            ),
                          ),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(Icons.edit_outlined, size: 18, color: cs2.primary),
                          ),
                        ),
                        // Send by email
                        InkWell(
                          onTap: () => _showAvertSendDialog(context, m, salaries),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(Icons.send_outlined, size: 18, color: cs2.primary),
                          ),
                        ),
                        // Delete
                        InkWell(
                          onTap: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                backgroundColor: cs2.surfaceContainerLowest,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                title: Text(context.tr('Confirmer la suppression', 'Confirm deletion'), style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700)),
                                content: Text(context.tr('Supprimer le modèle "${m.titre}" ?', 'Delete template "${m.titre}"?'), style: AppTextStyles.bodyMedium),
                                actions: [
                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(context.tr('Annuler', 'Cancel'))),
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    style: TextButton.styleFrom(foregroundColor: AppColors.error),
                                    child: Text(context.tr('Supprimer', 'Delete')),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true && context.mounted) {
                              await Provider.of<EntrepriseProvider>(context, listen: false).supprimerModele(m.id, entrepriseId);
                              if (context.mounted) {
                                ToastUtils.show(context, context.tr('Modèle supprimé.', 'Template deleted.'), isError: false);
                              }
                            }
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.all(8),
                            child: Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      m.contenu,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(color: cs2.onSurfaceVariant, height: 1.55),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.tr('Créé le ${m.dateCreation.day}/${m.dateCreation.month}/${m.dateCreation.year}', 'Created ${m.dateCreation.day}/${m.dateCreation.month}/${m.dateCreation.year}'),
                      style: AppTextStyles.bodySmall.copyWith(fontSize: 10, color: cs2.outline),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  void _showAvertSendDialog(BuildContext context, ModeleAvertissement modele, List<Salarie> salaries) {
    final selected = <String>{};
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final cs = Theme.of(ctx).colorScheme;
          return AlertDialog(
            backgroundColor: cs.surfaceContainerLowest,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr('Envoyer: ${modele.titre}', 'Send: ${modele.titre}'), style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700, color: cs.primary)),
                const SizedBox(height: 4),
                Text(context.tr('Sélectionnez les destinataires', 'Select recipients'), style: AppTextStyles.bodySmall.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
            content: SizedBox(
              width: 400,
              height: 320,
              child: salaries.isEmpty
                  ? Center(child: Text(context.tr('Aucun salarié actif pour cette entreprise.', 'No active employees for this company.'), style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurfaceVariant)))
                  : ListView.builder(
                      itemCount: salaries.length,
                      itemBuilder: (_, i) {
                        final s = salaries[i];
                        return CheckboxListTile(
                          value: selected.contains(s.id),
                          onChanged: (v) => setS(() {
                            if (v ?? false) selected.add(s.id); else selected.remove(s.id);
                          }),
                          activeColor: cs.primary,
                          title: Text('${s.nom} ${s.prenom}', style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600)),
                          subtitle: Text(s.emploiPoste ?? '', style: AppTextStyles.bodySmall.copyWith(color: cs.onSurfaceVariant)),
                          controlAffinity: ListTileControlAffinity.leading,
                          dense: true,
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(context.tr('Annuler', 'Cancel'), style: TextStyle(color: cs.outline))),
              ElevatedButton(
                onPressed: selected.isEmpty ? null : () async {
                  final emails = salaries
                      .where((s) => selected.contains(s.id) && s.email.isNotEmpty)
                      .map((s) => s.email)
                      .join(',');
                  if (emails.isEmpty) {
                    Navigator.pop(ctx);
                    ToastUtils.show(context, context.tr('Aucun email trouvé pour les salariés sélectionnés.', 'No email found for selected employees.'), isError: true);
                    return;
                  }
                  
                  String emailBody = modele.contenu;
                  final lines = emailBody.split('\n');
                  if (lines.isNotEmpty && lines.first.trim().toLowerCase().startsWith('objet')) {
                    lines.removeAt(0);
                    while (lines.isNotEmpty && lines.first.trim().isEmpty) {
                      lines.removeAt(0);
                    }
                    emailBody = lines.join('\n');
                  }

                  final encodedTo = Uri.encodeComponent(emails);
                  final encodedSubject = Uri.encodeComponent(modele.titre).replaceAll('+', '%20');
                  final encodedBody = Uri.encodeComponent(emailBody).replaceAll('+', '%20');
                  final gmailUrl = 'https://mail.google.com/mail/?view=cm&fs=1&to=$encodedTo&su=$encodedSubject&body=$encodedBody';
                  final uri = Uri.parse(gmailUrl);

                  // Launch URL synchronously before popping the navigator to bypass web browser popup blocker.
                  url_launcher.launchUrl(uri, mode: url_launcher.LaunchMode.platformDefault).catchError((_) {
                    if (context.mounted) {
                      ToastUtils.show(context, context.tr('Impossible d\'ouvrir Gmail.', 'Could not open Gmail.'), isError: true);
                    }
                    return false;
                  });

                  Navigator.pop(ctx);
                },
                style: ElevatedButton.styleFrom(backgroundColor: cs.primary, foregroundColor: Colors.white),
                child: Text(context.tr('Envoyer (${selected.length})', 'Send (${selected.length})')),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAvertPreviewDialog(BuildContext context, ModeleAvertissement modele) {
    showDialog(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          backgroundColor: cs.surfaceContainerLowest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            context.tr('Aperçu du modèle', 'Template Preview'),
            style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700, color: cs.primary),
          ),
          content: SizedBox(
            width: 600,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${context.tr("Objet : ", "Subject: ")}${modele.titre}',
                    style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: cs.onSurface),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
                    ),
                    child: SelectableText(
                      modele.contenu,
                      style: AppTextStyles.bodyMedium.copyWith(height: 1.5, color: cs.onSurface),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.tr('Fermer', 'Close'), style: TextStyle(color: cs.outline)),
            ),
          ],
        );
      },
    );
  }

  void _showNewCategoryDialog(BuildContext context, String entrepriseId) {
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    showDialog(
      context: context,
      builder: (ctx) {
        final cs = Theme.of(ctx).colorScheme;
        return AlertDialog(
          backgroundColor: cs.surfaceContainerLowest,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            context.tr('Nouvelle catégorie', 'New Category'),
            style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700, color: cs.primary),
          ),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: nameController,
              style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurface),
              decoration: InputDecoration(
                labelText: context.tr('Nom de la catégorie', 'Category Name'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
              validator: (val) {
                if (val == null || val.trim().isEmpty) {
                  return context.tr('Veuillez saisir un nom', 'Please enter a name');
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(context.tr('Annuler', 'Cancel'), style: TextStyle(color: cs.outline)),
            ),
            ElevatedButton(
              onPressed: () {
                if (!formKey.currentState!.validate()) return;
                final catName = nameController.text.trim();
                Navigator.pop(ctx);
                
                // Open the create template dialog with this category fixed!
                showDialog(
                  context: context,
                  builder: (_) => _AvertModeleDialog(
                    entrepriseId: entrepriseId,
                    type: catName,
                    isCategoryFixed: true,
                    onSave: (titre, contenu, type) async {
                      final provider = Provider.of<EntrepriseProvider>(context, listen: false);
                      await provider.ajouterModele(ModeleAvertissement(
                        id: '',
                        entrepriseId: entrepriseId,
                        titre: titre,
                        contenu: contenu,
                        type: type,
                      ));
                      setState(() {
                        _selectedWarningCategory = type;
                      });
                      if (context.mounted) {
                        ToastUtils.show(context, context.tr('Modèle et catégorie créés.', 'Template and category created.'), isError: false);
                      }
                    },
                  ),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: cs.primary, foregroundColor: Colors.white),
              child: Text(context.tr('Créer', 'Create')),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNotesTab(BuildContext context, List<NoteEntreprise> notes, String entrepriseId) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: cs.surfaceContainerLowest, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(context.tr('Notes & Rappels (${notes.length})', 'Notes & Reminders (${notes.length})'), style: AppTextStyles.titleMedium.copyWith(color: cs.onSurface)),
              ElevatedButton.icon(
                onPressed: () {
                  showDialog(context: context, builder: (_) => _AddNoteDialog(entrepriseId: entrepriseId));
                },
                icon: const Icon(Icons.add),
                label: Text(context.tr('Ajouter', 'Add')),
                style: ElevatedButton.styleFrom(backgroundColor: cs.primary, foregroundColor: Colors.white),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (notes.isEmpty)
            Center(child: Text(context.tr('Aucune note ou rappel pour cette entreprise.', 'No notes or reminders for this company.'), style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurface)))
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: notes.length,
              separatorBuilder: (_, i) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final cs = Theme.of(context).colorScheme;
                final note = notes[index];
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: note.estRappel ? AppColors.warning.withValues(alpha: 0.08) : cs.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: note.estRappel ? AppColors.warning.withValues(alpha: 0.4) : cs.outlineVariant.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(note.estRappel ? Icons.notifications_active : Icons.sticky_note_2_outlined,
                            color: note.estRappel ? AppColors.warning : cs.primary, size: 20),
                        const SizedBox(width: 8),
                        Expanded(child: Text(note.titre, style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700, color: cs.onSurface))),
                        Text('${note.dateCreation.day}/${note.dateCreation.month}/${note.dateCreation.year}',
                            style: AppTextStyles.bodySmall.copyWith(color: cs.onSurfaceVariant)),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                          tooltip: context.tr('Supprimer', 'Delete'),
                          onPressed: () async {
                            try {
                              await Provider.of<EntrepriseProvider>(context, listen: false).supprimerNote(note.id, entrepriseId);
                              if (context.mounted) {
                                ToastUtils.show(
                                  context,
                                  context.tr('Note supprimée.', 'Note deleted.'),
                                  isError: false,
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ToastUtils.show(
                                  context,
                                  context.tr('Erreur: ', 'Error: ') + e.toString(),
                                  isError: true,
                                );
                              }
                            }
                          },
                        ),
                      ]),
                      const SizedBox(height: 8),
                      Text(note.contenu, style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurface)),
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
  ColorScheme get cs => Theme.of(context).colorScheme;
  final _titreController = TextEditingController();
  final _contenuController = TextEditingController();
  bool _isRappel = false;
  bool _isLoading = false;

  DateTime? _deadlineDate;
  TimeOfDay? _deadlineTime;

  Future<void> _selectDeadlineDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _deadlineDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() {
        _deadlineDate = picked;
      });
    }
  }

  Future<void> _selectDeadlineTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _deadlineTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() {
        _deadlineTime = picked;
      });
    }
  }

  Future<void> _ajouter() async {
    if (_titreController.text.isEmpty) {
      ToastUtils.show(
        context,
        context.tr('Le titre est obligatoire.', 'Title is required.'),
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);

    DateTime? limitDate;
    if (_isRappel && _deadlineDate != null) {
      final time = _deadlineTime ?? const TimeOfDay(hour: 12, minute: 0);
      limitDate = DateTime(
        _deadlineDate!.year,
        _deadlineDate!.month,
        _deadlineDate!.day,
        time.hour,
        time.minute,
      );
    }

    final note = NoteEntreprise(
      id: '',
      entrepriseId: widget.entrepriseId,
      titre: _titreController.text,
      contenu: _contenuController.text,
      dateCreation: DateTime.now(),
      estRappel: _isRappel,
      dateRappel: limitDate,
    );

    try {
      await Provider.of<EntrepriseProvider>(context, listen: false).ajouterNote(note);
      if (mounted) {
        Navigator.pop(context);
        ToastUtils.show(
          context,
          context.tr('Note ajoutée avec succès !', 'Note added successfully!'),
          isError: false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ToastUtils.show(
          context,
          context.tr('Erreur: ', 'Error: ') + e.toString(),
          isError: true,
        );
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
    final cs = Theme.of(context).colorScheme;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: cs.surfaceContainerLowest,
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr('Ajouter une Note', 'Add Note'), style: AppTextStyles.headlineSmall.copyWith(color: cs.onSurface)),
            const SizedBox(height: 24),
            TextField(
              controller: _titreController,
              decoration: InputDecoration(
                labelText: context.tr('Titre', 'Title'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.35))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.35))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: cs.primary, width: 1.5)),
                isDense: true,
              ),
              style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurface),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contenuController,
              maxLines: 4,
              decoration: InputDecoration(
                labelText: context.tr('Contenu', 'Content'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.35))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.35))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: cs.primary, width: 1.5)),
                isDense: true,
              ),
              style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurface),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text(context.tr('Rappel', 'Reminder'), style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurface)),
              subtitle: Text(context.tr('Marquer comme rappel important', 'Mark as important reminder'), style: AppTextStyles.bodySmall.copyWith(color: cs.onSurfaceVariant)),
              value: _isRappel,
              onChanged: (v) => setState(() => _isRappel = v),
              activeThumbColor: cs.primary,
              contentPadding: EdgeInsets.zero,
            ),
            if (_isRappel) ...[
              const SizedBox(height: 16),
              Text(
                context.tr('DATE LIMITE & HEURE', 'DEADLINE DATE & TIME'),
                style: AppTextStyles.labelSmall.copyWith(
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w800,
                  color: cs.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _selectDeadlineDate(context),
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                      _deadlineDate == null
                          ? context.tr('Sélectionner Date', 'Select Date')
                          : '${_deadlineDate!.day}/${_deadlineDate!.month}/${_deadlineDate!.year}',
                    ),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      foregroundColor: cs.onSurface,
                      side: BorderSide(color: cs.outlineVariant),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    onPressed: () => _selectDeadlineTime(context),
                    icon: const Icon(Icons.access_time, size: 16),
                    label: Text(
                      _deadlineTime == null
                          ? context.tr('Sélectionner Heure', 'Select Time')
                          : _deadlineTime!.format(context),
                    ),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      foregroundColor: cs.onSurface,
                      side: BorderSide(color: cs.outlineVariant),
                    ),
                  ),
                  if (_deadlineDate != null || _deadlineTime != null) ...[
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.clear, color: AppColors.error),
                      onPressed: () {
                        setState(() {
                          _deadlineDate = null;
                          _deadlineTime = null;
                        });
                      },
                      tooltip: context.tr('Effacer', 'Clear'),
                    ),
                  ],
                ],
              ),
            ],
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: _isLoading ? null : () => Navigator.pop(context), child: Text(context.tr('Annuler', 'Cancel'), style: const TextStyle(color: AppColors.error))),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _isLoading ? null : _ajouter,
                  style: ElevatedButton.styleFrom(backgroundColor: cs.primary, foregroundColor: Colors.white),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(context.tr('Ajouter', 'Add')),
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
  ColorScheme get cs => Theme.of(context).colorScheme;
  late TextEditingController _nomController;
  late TextEditingController _gerantController;
  late TextEditingController _descController;
  late TextEditingController _emailController;
  late TextEditingController _mdpController;
  late TextEditingController _adresseController;
  late TextEditingController _sirenController;
  late TextEditingController _siretController;
  late TextEditingController _formeController;
  late TextEditingController _tvaController;
  late TextEditingController _rcsController;
  late TextEditingController _capitalController;
  late TextEditingController _telephoneController;
  late TextEditingController _codeApeController;

  DateTime? _dateCreationReelle;
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
    _sirenController = TextEditingController(text: widget.entreprise.nSiren);
    _siretController = TextEditingController(text: widget.entreprise.nSiret);
    _formeController = TextEditingController(text: widget.entreprise.formeJuridique);
    _tvaController = TextEditingController(text: widget.entreprise.nTva);
    _rcsController = TextEditingController(text: widget.entreprise.nRcs);
    _capitalController = TextEditingController(text: widget.entreprise.capitaleSocial);
    _telephoneController = TextEditingController(text: widget.entreprise.telephone);
    _codeApeController = TextEditingController(text: widget.entreprise.codeApe);
    _logoUrl = widget.entreprise.logoUrl;
    _dateCreationReelle = widget.entreprise.dateCreationReelle;
  }

  Future<void> _changeLogo() async {
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
        ToastUtils.show(
          context,
          context.trStatic('Logo mis à jour avec succès !', 'Logo updated successfully!'),
          isError: false,
        );
      } else {
        setState(() => _isUploadingLogo = false);
        ToastUtils.show(
          context,
          context.trStatic('Erreur lors de la mise à jour du logo.', 'Error updating logo.'),
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingLogo = false);
        ToastUtils.show(
          context,
          context.trStatic('Erreur lors de la sélection du fichier : ', 'Error selecting file: ') + e.toString(),
          isError: true,
        );
      }
    }
  }

  void _sauvegarder() {
    if (_nomController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _gerantController.text.isEmpty ||
        _telephoneController.text.isEmpty ||
        _sirenController.text.isEmpty ||
        _siretController.text.isEmpty ||
        _formeController.text.isEmpty ||
        _capitalController.text.isEmpty ||
        _tvaController.text.isEmpty ||
        _rcsController.text.isEmpty ||
        _codeApeController.text.isEmpty ||
        _dateCreationReelle == null) {
      ToastUtils.show(
        context,
        context.trStatic('Veuillez remplir tous les champs obligatoires.', 'Please fill in all required fields.'),
        isError: true,
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
      nSiren: _sirenController.text,
      nSiret: _siretController.text,
      formeJuridique: _formeController.text,
      nTva: _tvaController.text,
      nRcs: _rcsController.text,
      capitaleSocial: _capitalController.text,
      telephone: _telephoneController.text,
      codeApe: _codeApeController.text,
      logoUrl: _logoUrl,
      dateCreationReelle: _dateCreationReelle,
    );

    Provider.of<EntrepriseProvider>(context, listen: false).updateEntreprise(entrepriseAjournee);
    Navigator.pop(context);
    ToastUtils.show(
      context,
      context.trStatic('Informations modifiées avec succès !', 'Information modified successfully!'),
      isError: false,
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
    final cs = Theme.of(context).colorScheme;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: cs.surfaceContainerLowest,
      child: Container(
        width: 500,
        height: 700,
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Text(context.tr('Modifier l\'Entreprise', 'Edit Company'), style: AppTextStyles.headlineSmall.copyWith(color: cs.onSurface)),
            const SizedBox(height: 16),
            Center(
              child: Stack(
                children: [
                  Container(
                    key: ValueKey(_logoUrl),
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerHigh,
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child: (_logoUrl != null && _logoUrl!.isNotEmpty)
                          ? WebImage(url: _logoUrl!, fit: BoxFit.cover)
                          : Icon(Icons.domain, size: 40, color: cs.onSurfaceVariant),
                    ),
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
                      color: cs.primary,
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
                    _buildField(context.tr('Nom du dirigeant/gérant', 'Manager/director name'), _gerantController),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(child: _buildField(context.tr('Téléphone de l\'entreprise', 'Company phone number'), _telephoneController, keyboardType: TextInputType.phone)),
                        const SizedBox(width: 16),
                        Expanded(child: _buildField(context.tr('Adresse physique', 'Physical address'), _adresseController, required: false)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildField(context.tr('Description générale', 'General description'), _descController, required: false),
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
                    Row(
                      children: [
                        Expanded(child: _buildField(context.tr('Code APE / NAF', 'APE / NAF Code'), _codeApeController)),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildDatePickerField(
                            context.tr('Date de création d\'entreprise', 'Company Creation Date'),
                            _dateCreationReelle,
                            (date) => setState(() => _dateCreationReelle = date),
                          ),
                        ),
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
                  child: Text(context.tr('Annuler', 'Cancel'), style: TextStyle(color: AppColors.error)),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: _sauvegarder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: Text(context.tr('Enregistrer', 'Save')),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {bool isPassword = false, TextInputType? keyboardType, bool required = true}) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: AppTextStyles.labelMedium.copyWith(color: cs.onSurface, fontWeight: FontWeight.w600),
            children: [
              if (required)
                const TextSpan(
                  text: '* ',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              TextSpan(text: label),
            ],
          ),
        ),
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

  Widget _buildDatePickerField(String label, DateTime? selectedDate, Function(DateTime) onDateSelected, {bool required = true}) {
    final cs = Theme.of(context).colorScheme;
    final dateStr = selectedDate != null
        ? "${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}"
        : "";

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            style: AppTextStyles.labelMedium.copyWith(color: cs.onSurface, fontWeight: FontWeight.w600),
            children: [
              if (required)
                const TextSpan(
                  text: '* ',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
              TextSpan(text: label),
            ],
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: selectedDate ?? DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime.now(),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: cs,
                  ),
                  child: child!,
                );
              },
            );
            if (picked != null) {
              onDateSelected(picked);
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: cs.outline.withValues(alpha: 0.35)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  dateStr.isEmpty ? context.tr('Sélectionner une date', 'Select a date') : dateStr,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: dateStr.isEmpty ? cs.outline : cs.onSurface,
                  ),
                ),
                Icon(Icons.calendar_today, size: 16, color: cs.outline),
              ],
            ),
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
  ColorScheme get cs => Theme.of(context).colorScheme;
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
    if (_nomController.text.isEmpty ||
        _prenomController.text.isEmpty ||
        _genre.isEmpty ||
        _nomNaissanceController.text.isEmpty ||
        _cinController.text.isEmpty ||
        _nssController.text.isEmpty ||
        _dateNaissance == null ||
        _lieuNaissanceController.text.isEmpty ||
        _nationaliteController.text.isEmpty ||
        _telController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _dateEmbauche == null ||
        _emploiPosteController.text.isEmpty) {
      ToastUtils.show(
        context,
        context.tr('Veuillez remplir tous les champs obligatoires.', 'Please fill in all required fields.'),
        isError: true,
      );
      return;
    }

    if (_needsDateFin && _dateFinContrat == null) {
      ToastUtils.show(
        context,
        context.tr('La date de fin de contrat est obligatoire pour un contrat ', 'Contract End Date is required for contract ') + _typeContrat,
        isError: true,
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
      nomNaissance: _nomNaissanceController.text,
      cin: _cinController.text,
      numeroSecuriteSociale: _nssController.text,
      dateNaissance: _dateNaissance,
      lieuNaissance: _lieuNaissanceController.text,
      nationalite: _nationaliteController.text,
      adressePostale: _adressePostaleController.text,
      telephone: _telController.text,
      email: _emailController.text,
      dateEmbauche: _dateEmbauche!,
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

      if (_avatarBytes != null && _avatarName.isNotEmpty) {
        await Provider.of<EntrepriseProvider>(context, listen: false)
            .uploadSalarieAvatar(salarieId, _avatarBytes!, _avatarName, widget.entrepriseId);
      }

      if (mounted) {
        Navigator.pop(context);
        ToastUtils.show(
          context,
          context.tr('Salarié ajouté avec succès !', 'Employee added successfully!'),
          isError: false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ToastUtils.show(
          context,
          '${context.tr('Erreur: ', 'Error: ')}$e',
          isError: true,
        );
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

  String _formatDate(BuildContext context, DateTime? date) {
    if (date == null) return context.tr('Non défini', 'Not defined');
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Widget _buildLabel(String label, {bool required = true}) {
    return RichText(
      text: TextSpan(
        style: AppTextStyles.labelMedium.copyWith(color: cs.onSurface, fontWeight: FontWeight.w600),
        children: [
          if (required)
            const TextSpan(
              text: '* ',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          TextSpan(text: label),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {bool required = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, required: required),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
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

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: cs.surfaceContainerLowest,
      child: Container(
        width: 650,
        padding: const EdgeInsets.all(32),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(context.tr('Ajouter un Salarié', 'Add Employee'), style: AppTextStyles.headlineSmall.copyWith(color: cs.onSurface)),
              const SizedBox(height: 24),
              Center(
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: cs.surfaceContainerLow,
                      backgroundImage: _avatarBytes != null
                          ? MemoryImage(_avatarBytes!)
                          : null,
                      child: _avatarBytes == null
                          ? Icon(Icons.person, size: 50, color: cs.onSurfaceVariant)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: cs.primary,
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

              Row(children: [
                Expanded(child: _buildField(context.tr('Nom', 'Last Name'), _nomController)),
                const SizedBox(width: 16),
                Expanded(child: _buildField(context.tr('Prénom', 'First Name'), _prenomController)),
              ]),
              const SizedBox(height: 16),

              Row(children: [
                Expanded(child: _buildField(context.tr('Nom de Naissance', 'Birth Name'), _nomNaissanceController)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel(context.tr('Genre', 'Gender')),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _genre,
                        style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurface),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.35))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.35))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: cs.primary, width: 1.5)),
                          isDense: true,
                        ),
                        items: [
                          DropdownMenuItem(value: 'M', child: Text(context.tr('Masculin', 'Male'), style: TextStyle(color: cs.onSurface))),
                          DropdownMenuItem(value: 'F', child: Text(context.tr('Féminin', 'Female'), style: TextStyle(color: cs.onSurface))),
                        ],
                        onChanged: (v) => setState(() => _genre = v!),
                      ),
                    ],
                  ),
                )
              ]),
              const SizedBox(height: 16),

              Row(children: [
                Expanded(child: _buildField(context.tr('CIN', 'ID Card Number'), _cinController)),
                const SizedBox(width: 16),
                Expanded(child: _buildField(context.tr('N° Sécurité Sociale', 'Social Security Number'), _nssController)),
              ]),
              const SizedBox(height: 16),

              Row(children: [
                Expanded(child: _datePicker(context.tr('Date de naissance', 'Date of Birth'), _dateNaissance, () => _pickDate('naissance'))),
                const SizedBox(width: 16),
                Expanded(child: _buildField(context.tr('Lieu de naissance', 'Place of Birth'), _lieuNaissanceController)),
              ]),
              const SizedBox(height: 16),

              Row(children: [
                Expanded(child: _buildField(context.tr('Nationalité', 'Nationality'), _nationaliteController)),
                const SizedBox(width: 16),
                Expanded(child: _buildField(context.tr('Adresse Postale', 'Postal Address'), _adressePostaleController, required: false)),
              ]),
              const SizedBox(height: 16),

              Row(children: [
                Expanded(child: _buildField(context.tr('Téléphone', 'Phone Number'), _telController)),
                const SizedBox(width: 16),
                Expanded(child: _buildField(context.tr('Email', 'Email'), _emailController)),
              ]),
              const SizedBox(height: 16),

              Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel(context.tr('Type Contrat', 'Contract Type')),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _typeContrat,
                        style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurface),
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.35))),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.35))),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: cs.primary, width: 1.5)),
                          isDense: true,
                        ),
                        items: [
                          DropdownMenuItem(value: 'CDI', child: Text(context.tr('CDI', 'CDI'), style: TextStyle(color: cs.onSurface))),
                          DropdownMenuItem(value: 'CDD', child: Text(context.tr('CDD', 'CDD'), style: TextStyle(color: cs.onSurface))),
                          DropdownMenuItem(value: 'Apprentissage', child: Text(context.tr('Apprentissage', 'Apprenticeship'), style: TextStyle(color: cs.onSurface))),
                          DropdownMenuItem(value: 'Stage', child: Text(context.tr('Stage', 'Internship'), style: TextStyle(color: cs.onSurface))),
                        ],
                        onChanged: (v) => setState(() => _typeContrat = v!),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(child: _buildField(context.tr('Poste Occupé', 'Job Title'), _emploiPosteController)),
              ]),
              const SizedBox(height: 16),

              Row(children: [
                Expanded(child: _datePicker(context.tr('Date d\'embauche', 'Hire Date'), _dateEmbauche, () => _pickDate('embauche'))),
                const SizedBox(width: 16),
                Expanded(
                  child: _datePicker(
                    context.tr('Date fin de contrat', 'Contract End Date'),
                    _dateFinContrat,
                    () => _pickDate('fin'),
                    required: _needsDateFin,
                  ),
                ),
              ]),
              if (_needsDateFin && _dateFinContrat == null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(context.tr('⚠ Obligatoire pour un contrat ', '⚠ Required for contract ') + _typeContrat, style: TextStyle(color: AppColors.error, fontSize: 11)),
                ),
              const SizedBox(height: 16),

              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLabel(context.tr('Description / Note sur le salarié', 'Description / Employee Note'), required: false),
                  const SizedBox(height: 6),
                  TextField(
                    controller: descriptionController,
                    maxLines: 3,
                    style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurface),
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.35))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.35))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: cs.primary, width: 1.5)),
                      isDense: true,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              Text(context.tr('Pièces jointes', 'Attachments'), style: AppTextStyles.titleSmall.copyWith(fontWeight: FontWeight.w700, color: cs.onSurface)),
              const SizedBox(height: 8),
              Text(context.tr('Formats acceptés : PDF, JPG, PNG, DOCX', 'Accepted formats: PDF, JPG, PNG, DOCX'), style: AppTextStyles.bodySmall.copyWith(color: cs.onSurfaceVariant)),
              const SizedBox(height: 12),

              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _fileChip(context.tr('Pièce d\'identité', 'ID Document'), 'piece_identite'),
                  _fileChip(context.tr('Carte Vitale', 'Health Card'), 'carte_vitale'),
                  _fileChip(context.tr('Justificatif domicile', 'Proof of Address'), 'justificatif_domicile'),
                  _fileChip(context.tr('Contrat signé', 'Signed Contract'), 'contrat_signe'),
                ],
              ),

              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: _isLoading ? null : () => Navigator.pop(context), child: Text(context.tr('Annuler', 'Cancel'), style: const TextStyle(color: AppColors.error))),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _ajouter,
                    style: ElevatedButton.styleFrom(backgroundColor: cs.primary, foregroundColor: Colors.white),
                    child: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(context.tr('Ajouter le Salarié', 'Add Employee')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _datePicker(String label, DateTime? value, VoidCallback onTap, {bool required = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, required: required),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: InputDecorator(
            decoration: InputDecoration(
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.35))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.35))),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: cs.primary, width: 1.5)),
              isDense: true,
              suffixIcon: const Icon(Icons.calendar_today, size: 16),
            ),
            child: Text(
              _formatDate(context, value),
              style: AppTextStyles.bodyMedium.copyWith(color: value != null ? cs.onSurface : cs.outline),
            ),
          ),
        ),
      ],
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
          color: hasFile ? AppColors.success.withValues(alpha: 0.08) : cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: hasFile ? AppColors.success.withValues(alpha: 0.4) : cs.outline.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasFile ? Icons.check_circle : Icons.upload_file,
              size: 16,
              color: hasFile ? AppColors.success : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              hasFile ? fileName : label,
              style: AppTextStyles.labelSmall.copyWith(
                fontWeight: FontWeight.w600,
                color: hasFile ? AppColors.success : cs.onSurfaceVariant,
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
  ColorScheme get cs => Theme.of(context).colorScheme;
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

    final g = widget.salarie.genre.trim().toUpperCase();
    if (g.startsWith('M')) {
      _genre = 'M';
    } else if (g.startsWith('F')) {
      _genre = 'F';
    } else {
      _genre = 'M';
    }
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
    if (_nomController.text.isEmpty ||
        _prenomController.text.isEmpty ||
        _nomNaissanceController.text.isEmpty ||
        _cinController.text.isEmpty ||
        _nssController.text.isEmpty ||
        _dateNaissance == null ||
        _lieuNaissanceController.text.isEmpty ||
        _nationaliteController.text.isEmpty ||
        _telController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _dateEmbauche == null ||
        _emploiPosteController.text.isEmpty) {
      ToastUtils.show(
        context,
        context.trStatic('Veuillez remplir tous les champs obligatoires.', 'Please fill in all required fields.'),
        isError: true,
      );
      return;
    }

    if (_needsDateFin && _dateFinContrat == null) {
      ToastUtils.show(
        context,
        context.trStatic('La date de fin de contrat est obligatoire pour un contrat ', 'Contract End Date is required for contract ') + _typeContrat,
        isError: true,
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
      nomNaissance: _nomNaissanceController.text,
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
      avatarUrl: widget.salarie.avatarUrl,
    );

    try {
      await Provider.of<EntrepriseProvider>(context, listen: false).modifierSalarie(s);

      final storage = SupabaseConfig.adminClient.storage.from('documents');

      for (final entry in fichiers.entries) {
        if (entry.value != null) {
          final fileName = fichiersNoms[entry.key]!;
          final ext = fileName.split('.').last.toLowerCase();
          final path = 'salaries/${widget.salarie.id}/${entry.key}.$ext';
          await storage.uploadBinary(path, entry.value!, fileOptions: FileOptions(upsert: true, contentType: _mimeType(ext)));
        }
      }

      if (_avatarBytes != null && _avatarName.isNotEmpty) {
        await Provider.of<EntrepriseProvider>(context, listen: false)
            .uploadSalarieAvatar(widget.salarie.id, _avatarBytes!, _avatarName, widget.salarie.entrepriseId);
      }

      if (mounted) {
        Navigator.pop(context);
        ToastUtils.show(
          context,
          context.trStatic('Données du salarié modifiées avec succès !', 'Employee data modified successfully!'),
          isError: false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ToastUtils.show(
          context,
          context.trStatic('Erreur: ', 'Error: ') + e.toString(),
          isError: true,
        );
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

  Widget _buildLabel(String label, {bool required = true}) {
    return RichText(
      text: TextSpan(
        style: AppTextStyles.labelMedium.copyWith(color: cs.onSurface, fontWeight: FontWeight.w600),
        children: [
          if (required)
            const TextSpan(
              text: '* ',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          TextSpan(text: label),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {bool required = true}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, required: required),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.35))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.35))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: cs.primary, width: 1.5)),
          ),
          style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurface),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: cs.surfaceContainerLowest,
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
                  Text(context.tr('Modifier le Salarié', 'Edit Employee'), style: AppTextStyles.headlineSmall.copyWith(color: cs.onSurface)),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: 24),
              Center(
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: (widget.salarie.avatarUrl != null && widget.salarie.avatarUrl!.isNotEmpty)
                          ? () => FilePreviewer.show(context, widget.salarie.avatarUrl!, '${widget.salarie.nom}_${widget.salarie.prenom}_avatar.png')
                          : null,
                      child: MouseRegion(
                        cursor: (widget.salarie.avatarUrl != null && widget.salarie.avatarUrl!.isNotEmpty)
                            ? SystemMouseCursors.click
                            : SystemMouseCursors.basic,
                        child: Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerLow,
                            shape: BoxShape.circle,
                          ),
                          child: ClipOval(
                            child: _avatarBytes != null
                                ? Image.memory(_avatarBytes!, fit: BoxFit.cover)
                                : (widget.salarie.avatarUrl != null &&
                                        widget.salarie.avatarUrl!.isNotEmpty)
                                    ? WebImage(url: widget.salarie.avatarUrl!, fit: BoxFit.cover)
                                    : Center(
                                        child: Text(
                                          widget.salarie.prenom.isNotEmpty
                                              ? widget.salarie.prenom[0].toUpperCase()
                                              : (widget.salarie.nom.isNotEmpty
                                                  ? widget.salarie.nom[0].toUpperCase()
                                                  : '?'),
                                          style: TextStyle(
                                            color: cs.primary,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 24,
                                          ),
                                        ),
                                      ),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: cs.primary,
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
              Text(context.tr('État Civil', 'Civil Status'), style: AppTextStyles.labelMedium.copyWith(color: cs.primary, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.tr('Genre', 'Gender'), style: AppTextStyles.labelMedium.copyWith(color: cs.onSurface, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _genre,
                          style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurface),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.35))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.35))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: cs.primary, width: 1.5)),
                          ),
                          items: [
                            DropdownMenuItem(value: 'M', child: Text(context.tr('Masculin', 'Male'), style: TextStyle(color: cs.onSurface))),
                            DropdownMenuItem(value: 'F', child: Text(context.tr('Féminin', 'Female'), style: TextStyle(color: cs.onSurface))),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => _genre = v);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: _buildField(context.tr('Nom', 'Last Name'), _nomController, required: true)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildField(context.tr('Prénom', 'First Name'), _prenomController, required: true)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildField(context.tr('Nom de naissance', 'Birth Name'), _nomNaissanceController)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildField(context.tr('CIN', 'ID Card Number'), _cinController)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildField(context.tr('N° Sécurité Sociale', 'Social Security Number'), _nssController)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.tr('Date de naissance', 'Date of Birth'), style: AppTextStyles.labelMedium.copyWith(color: cs.onSurface, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () => _pickDate('naissance'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(border: Border.all(color: cs.outline.withValues(alpha: 0.35)), borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_dateNaissance != null ? "${_dateNaissance!.day}/${_dateNaissance!.month}/${_dateNaissance!.year}" : context.tr('Choisir date', 'Choose date'), style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurface)),
                                Icon(Icons.calendar_today, size: 16, color: cs.onSurfaceVariant),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: _buildField(context.tr('Lieu de naissance', 'Place of Birth'), _lieuNaissanceController)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildField(context.tr('Nationalité', 'Nationality'), _nationaliteController)),
                  const SizedBox(width: 16),
                  const Expanded(child: SizedBox()),
                ],
              ),
              const SizedBox(height: 24),
              Text(context.tr('Coordonnées', 'Contact Info'), style: AppTextStyles.labelMedium.copyWith(color: cs.primary, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              _buildField(context.tr('Adresse postale', 'Postal Address'), _adressePostaleController),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildField(context.tr('Téléphone', 'Phone Number'), _telController)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildField(context.tr('Email', 'Email'), _emailController)),
                ],
              ),
              const SizedBox(height: 24),
              Text(context.tr('Contrat & Poste', 'Contract & Job'), style: AppTextStyles.labelMedium.copyWith(color: cs.primary, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(context.tr('Date d\'embauche', 'Hire Date'), style: AppTextStyles.labelMedium.copyWith(color: cs.onSurface, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () => _pickDate('embauche'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(border: Border.all(color: cs.outline.withValues(alpha: 0.35)), borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_dateEmbauche != null ? "${_dateEmbauche!.day}/${_dateEmbauche!.month}/${_dateEmbauche!.year}" : context.tr('Choisir date', 'Choose date'), style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurface)),
                                Icon(Icons.calendar_today, size: 16, color: cs.onSurfaceVariant),
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
                        Text(context.tr('Type de contrat', 'Contract Type'), style: AppTextStyles.labelMedium.copyWith(color: cs.onSurface, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _typeContrat,
                          style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurface),
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.35))),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.35))),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: cs.primary, width: 1.5)),
                          ),
                          items: [
                            DropdownMenuItem(value: 'CDI', child: Text(context.tr('CDI', 'CDI'), style: TextStyle(color: cs.onSurface))),
                            DropdownMenuItem(value: 'CDD', child: Text(context.tr('CDD', 'CDD'), style: TextStyle(color: cs.onSurface))),
                            DropdownMenuItem(value: 'Apprentissage', child: Text(context.tr('Apprentissage', 'Apprenticeship'), style: TextStyle(color: cs.onSurface))),
                            DropdownMenuItem(value: 'Stage', child: Text(context.tr('Stage', 'Internship'), style: TextStyle(color: cs.onSurface))),
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
                          Text(context.tr('Date de fin de contrat', 'Contract End Date'), style: AppTextStyles.labelMedium.copyWith(color: cs.onSurface, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          InkWell(
                            onTap: () => _pickDate('fin'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(border: Border.all(color: cs.outline.withValues(alpha: 0.35)), borderRadius: BorderRadius.circular(8)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(_dateFinContrat != null ? "${_dateFinContrat!.day}/${_dateFinContrat!.month}/${_dateFinContrat!.year}" : context.tr('Choisir date', 'Choose date'), style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurface)),
                                  Icon(Icons.calendar_today, size: 16, color: cs.onSurfaceVariant),
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
              _buildField(context.tr('Emploi / Poste', 'Job / Position'), _emploiPosteController),
              const SizedBox(height: 24),
              _buildField(context.tr('Description / Note sur le salarié', 'Description / Employee Note'), descriptionController),
              const SizedBox(height: 24),
              Text(context.tr('Pièces Jointes (Modifier/Ajouter)', 'Attachments (Edit/Add)'), style: AppTextStyles.labelMedium.copyWith(color: cs.primary, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _fileChip(context.tr('Pièce d\'identité', 'ID Document'), 'piece_identite', widget.salarie.aPieceIdentite),
                  _fileChip(context.tr('Carte Vitale', 'Health Card'), 'carte_vitale', widget.salarie.aCarteVitale),
                  _fileChip(context.tr('Justificatif domicile', 'Proof of Address'), 'justificatif_domicile', widget.salarie.aJustificatifDomicile),
                  _fileChip(context.tr('Contrat signé', 'Signed Contract'), 'contrat_signe', widget.salarie.aContratSigne),
                ],
              ),
              const SizedBox(height: 32),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                    child: Text(context.tr('Annuler', 'Cancel')),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _enregistrer,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                        : Text(context.tr('Enregistrer', 'Save')),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fileChip(String label, String key, bool initiallyHasFile) {
    final hasNewFile = fichiers[key] != null;
    final hasFile = hasNewFile || initiallyHasFile;
    final fileName = hasNewFile ? fichiersNoms[key]! : context.trStatic('Fichier existant', 'Existing file');
    return InkWell(
      onTap: () => _pickFile(key),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: hasFile ? AppColors.success.withValues(alpha: 0.08) : cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: hasFile ? AppColors.success.withValues(alpha: 0.4) : cs.outline.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              hasFile ? Icons.check_circle : Icons.upload_file,
              size: 16,
              color: hasFile ? AppColors.success : cs.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              hasFile ? (hasNewFile ? fileName : context.trStatic('$label (Existant - Modifier)', '$label (Existing - Edit)')) : label,
              style: AppTextStyles.labelSmall.copyWith(
                fontWeight: FontWeight.w600,
                color: hasFile ? AppColors.success : cs.onSurfaceVariant,
              ),
            ),
          ],
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
  ColorScheme get cs => Theme.of(context).colorScheme;
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;
  bool _isLoading = false;

  final List<String> _monthsFr = [
    'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
  ];
  final List<String> _monthsEn = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
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
        String typeOfLeave = '';
        String displayNote = '';

        if (pointageMap.containsKey(dateKey)) {
          final p = pointageMap[dateKey]!;
          final estPointe = p['est_pointe'] as bool? ?? false;
          final note = p['note'] as String? ?? '';
          displayNote = note;

          if (estPointe) {
            status = context.trStatic('Présent', 'Present');
            presents++;
          } else {
            status = note.isNotEmpty 
                ? context.trStatic('Congé', 'Leave') 
                : context.trStatic('Absent', 'Absent');
            absents++;

            if (note.isNotEmpty) {
              final prefixes = [
                'Congé Payé (Demi-journée)',
                'Congé Payé',
                'Arrêt Maladie (Demi-journée)',
                'Arrêt Maladie',
                'RTT (Demi-journée)',
                'RTT',
                'Congé Exceptionnel (Demi-journée)',
                'Congé Exceptionnel',
                'Autre Absence (Demi-journée)',
                'Autre Absence',
                'Maladie (Demi-journée)',
                'Maladie',
                'Arrêt (Demi-journée)',
                'Arrêt',
                'Conge (Demi-journée)',
                'Conge'
              ];

              for (final prefix in prefixes) {
                if (note.startsWith(prefix)) {
                  typeOfLeave = prefix;
                  final remaining = note.substring(prefix.length).trim();
                  if (remaining.startsWith(':')) {
                    displayNote = remaining.substring(1).trim();
                  } else if (remaining.isEmpty) {
                    displayNote = '';
                  }
                  break;
                }
              }
            }
          }
        } else {
          status = context.trStatic('Non renseigné', 'Unreported');
          nonRenseignes++;
        }

        rows.add([displayDate, status, typeOfLeave, displayNote]);
      }

      final buffer = StringBuffer();
      
      final title = context.trStatic('Rapport de Pointage Mensuel', 'Monthly Attendance Report');
      final employeeLbl = context.trStatic('Salarié', 'Employee');
      final companyLbl = context.trStatic('Entreprise', 'Company');
      final periodLbl = context.trStatic('Période', 'Period');
      final presentLbl = context.trStatic('Jours Présents', 'Days Present');
      final absentLbl = context.trStatic('Jours Absents/Congés', 'Days Absent/Leave');
      final unrepLbl = context.trStatic('Jours Non Renseignés', 'Days Unreported');
      final dateLbl = context.trStatic('Date', 'Date');
      final statusLbl = context.trStatic('Statut', 'Status');
      final typeLbl = context.trStatic('Type d\'absence/congé', 'Type of Leave/Absence');
      final noteLbl = context.trStatic('Note / Description', 'Note / Description');

      buffer.writeln('$title$separator');
      buffer.writeln('$employeeLbl$separator${escapeCsv("${widget.salarie.prenom} ${widget.salarie.nom}", separator)}');
      buffer.writeln('$companyLbl$separator${escapeCsv(widget.entrepriseNom, separator)}');
      buffer.writeln('$periodLbl$separator${context.trStatic(_monthsFr[_selectedMonth - 1], _monthsEn[_selectedMonth - 1])} $_selectedYear');
      buffer.writeln('$presentLbl$separator$presents');
      buffer.writeln('$absentLbl$separator$absents');
      buffer.writeln('$unrepLbl$separator$nonRenseignes');
      buffer.writeln('');
      
      buffer.writeln('$dateLbl$separator$statusLbl$separator$typeLbl$separator$noteLbl');
      
      for (final row in rows) {
        final dateEsc = escapeCsv(row[0], separator);
        final statusEsc = escapeCsv(row[1], separator);
        final typeEsc = escapeCsv(row[2], separator);
        final noteEsc = escapeCsv(row[3], separator);
        buffer.writeln('$dateEsc$separator$statusEsc$separator$typeEsc$separator$noteEsc');
      }

      final csvContent = buffer.toString();
      
      final utf8BOM = [0xEF, 0xBB, 0xBF];
      final bytes = Uint8List.fromList([...utf8BOM, ...utf8.encode(csvContent)]);

      final monthStr = _selectedMonth.toString().padLeft(2, '0');
      final filePrefix = context.trStatic('pointage', 'attendance');
      final fileName = '${filePrefix}_${widget.salarie.nom.replaceAll(' ', '_')}_${widget.salarie.prenom.replaceAll(' ', '_')}_${monthStr}_$_selectedYear.csv';

      await FileSaver.instance.saveFile(
        name: fileName,
        bytes: bytes,
        mimeType: MimeType.csv,
      );

      if (mounted) {
        Navigator.pop(context);
        ToastUtils.show(
          context,
          context.trStatic('Rapport exporté avec succès : ', 'Report exported successfully: ') + fileName,
          isError: false,
        );
      }
    } catch (e) {
      if (mounted) {
        ToastUtils.show(
          context,
          context.trStatic('Erreur lors de l\'export : ', 'Error during export: ') + e.toString(),
          isError: true,
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
    final cs = Theme.of(context).colorScheme;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: cs.surfaceContainerLowest,
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.tr('Exporter le Pointage', 'Export Attendance'),
              style: AppTextStyles.headlineSmall.copyWith(color: cs.onSurface),
            ),
            const SizedBox(height: 8),
            Text(
              context.tr('Salarié : ', 'Employee: ') + '${widget.salarie.prenom} ${widget.salarie.nom}',
              style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 24),

            DropdownButtonFormField<int>(
              initialValue: _selectedMonth,
              style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurface),
              decoration: InputDecoration(
                labelText: context.tr('Mois', 'Month'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.35))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.35))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: cs.primary, width: 1.5)),
                isDense: true,
              ),
              items: List.generate(12, (index) {
                return DropdownMenuItem(
                  value: index + 1,
                  child: Text(context.tr(_monthsFr[index], _monthsEn[index]), style: TextStyle(color: cs.onSurface)),
                );
              }),
              onChanged: _isLoading ? null : (v) => setState(() => _selectedMonth = v!),
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<int>(
              initialValue: _selectedYear,
              style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurface),
              decoration: InputDecoration(
                labelText: context.tr('Année', 'Year'),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.35))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.35))),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: cs.primary, width: 1.5)),
                isDense: true,
              ),
              items: _years.map((y) {
                return DropdownMenuItem(
                  value: y,
                  child: Text(y.toString(), style: TextStyle(color: cs.onSurface)),
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
                    child: Text(context.tr('Annuler', 'Cancel'), style: const TextStyle(color: AppColors.error)),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: () => _export(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cs.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(context.tr('Exporter', 'Export')),
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
  ColorScheme get cs => Theme.of(context).colorScheme;
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

  void _downloadOrViewFile(String label, String url) {
    FilePreviewer.show(context, url, label);
  }

  Widget _readField(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelMedium.copyWith(
            color: cs.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            (value.isEmpty || value == 'Non défini') ? context.tr('Non défini', 'Not defined') : value,
            style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurface),
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
          color: cs.primary,
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
    final cs = Theme.of(context).colorScheme;
    final salarie = widget.salarie;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: cs.surfaceContainerLowest,
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
                  Text(context.tr('Informations du Salarié', 'Employee Details'), style: AppTextStyles.headlineSmall.copyWith(color: cs.onSurface)),
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
                        label: Text(context.tr('Modifier', 'Edit')),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cs.primary,
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
                child: GestureDetector(
                  onTap: (salarie.avatarUrl != null && salarie.avatarUrl!.isNotEmpty)
                      ? () => FilePreviewer.show(context, salarie.avatarUrl!, '${salarie.nom}_${salarie.prenom}_avatar.png')
                      : null,
                  child: MouseRegion(
                    cursor: (salarie.avatarUrl != null && salarie.avatarUrl!.isNotEmpty)
                        ? SystemMouseCursors.click
                        : SystemMouseCursors.basic,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerLow,
                        shape: BoxShape.circle,
                      ),
                      child: ClipOval(
                        child: (salarie.avatarUrl != null && salarie.avatarUrl!.isNotEmpty)
                            ? WebImage(url: salarie.avatarUrl!, fit: BoxFit.cover)
                            : Icon(Icons.person, size: 50, color: cs.onSurfaceVariant),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildSectionTitle(context.tr('État Civil & Identité', 'Civil Status & Identity')),
              Row(
                children: [
                  Expanded(child: _readField(context.tr('Genre', 'Gender'), salarie.genre == 'M' ? context.tr('Masculin', 'Male') : (salarie.genre == 'F' ? context.tr('Féminin', 'Female') : salarie.genre))),
                  const SizedBox(width: 16),
                  Expanded(child: _readField(context.tr('Nom', 'Last Name'), salarie.nom)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _readField(context.tr('Prénom', 'First Name'), salarie.prenom)),
                  const SizedBox(width: 16),
                  Expanded(child: _readField(context.tr('Nom de naissance', 'Birth Name'), salarie.nomNaissance)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _readField(context.tr('CIN', 'ID Card Number'), salarie.cin)),
                  const SizedBox(width: 16),
                  Expanded(child: _readField(context.tr('N° Sécurité Sociale', 'Social Security Number'), salarie.numeroSecuriteSociale)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _readField(context.tr('Date de naissance', 'Date of Birth'), salarie.dateNaissance != null ? "${salarie.dateNaissance!.day}/${salarie.dateNaissance!.month}/${salarie.dateNaissance!.year}" : "Non défini")),
                  const SizedBox(width: 16),
                  Expanded(child: _readField(context.tr('Lieu de naissance', 'Place of Birth'), salarie.lieuNaissance)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _readField(context.tr('Nationalité', 'Nationality'), salarie.nationalite)),
                  const SizedBox(width: 16),
                  const Expanded(child: SizedBox()),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionTitle(context.tr('Coordonnées', 'Contact Info')),
              _readField(context.tr('Adresse postale', 'Postal Address'), salarie.adressePostale),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _readField(context.tr('Téléphone', 'Phone Number'), salarie.telephone)),
                  const SizedBox(width: 16),
                  Expanded(child: _readField(context.tr('Email', 'Email'), salarie.email)),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionTitle(context.tr('Informations Professionnelles', 'Professional Details')),
              Row(
                children: [
                  Expanded(child: _readField(context.tr('Date d\'embauche', 'Hire Date'), salarie.dateEmbauche != null ? "${salarie.dateEmbauche!.day}/${salarie.dateEmbauche!.month}/${salarie.dateEmbauche!.year}" : "Non défini")),
                  const SizedBox(width: 16),
                  Expanded(child: _readField(context.tr('Type de contrat', 'Contract Type'), salarie.typeContrat)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _readField(context.tr('Date de fin', 'End Date'), salarie.dateFinContrat != null ? "${salarie.dateFinContrat!.day}/${salarie.dateFinContrat!.month}/${salarie.dateFinContrat!.year}" : "—")),
                  const SizedBox(width: 16),
                  Expanded(child: _readField(context.tr('Emploi/Poste', 'Job Title'), salarie.emploiPoste)),
                ],
              ),
              const SizedBox(height: 24),
              _buildSectionTitle(context.tr('Description / Note', 'Description / Note')),
              _readField(context.tr('Description / Note sur le salarié', 'Description / Employee Note'), salarie.description),
              const SizedBox(height: 24),
              _buildSectionTitle(context.tr('Pièces jointes', 'Attachments')),
              Text(
                context.tr('Les pièces jointes en vert souligné sont téléchargeables. Cliquez pour les ouvrir.', 'Attachments underlined in green are downloadable. Click to open them.'),
                style: AppTextStyles.bodySmall.copyWith(color: cs.onSurfaceVariant, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _docChip('piece_identite', context.tr('Pièce d\'identité', 'ID Document'), salarie.aPieceIdentite),
                  _docChip('carte_vitale', context.tr('Carte Vitale', 'Health Card'), salarie.aCarteVitale),
                  _docChip('justificatif_domicile', context.tr('Justificatif domicile', 'Proof of Address'), salarie.aJustificatifDomicile),
                  _docChip('contrat_signe', context.tr('Contrat signé', 'Signed Contract'), salarie.aContratSigne),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AvertCat {
  final String type;
  final String label;
  final IconData icon;
  final Color color;
  const _AvertCat(this.type, this.label, this.icon, this.color);
}

class _AvertModeleDialog extends StatefulWidget {
  final String entrepriseId;
  final String type;
  final String? initialTitre;
  final String? initialContenu;
  final bool isCategoryFixed;
  final Future<void> Function(String titre, String contenu, String type) onSave;

  const _AvertModeleDialog({
    required this.entrepriseId,
    required this.type,
    this.initialTitre,
    this.initialContenu,
    this.isCategoryFixed = false,
    required this.onSave,
  });

  @override
  State<_AvertModeleDialog> createState() => _AvertModeleDialogState();
}

class _AvertModeleDialogState extends State<_AvertModeleDialog> {
  final _titreController = TextEditingController();
  final _contenuController = TextEditingController();
  final _customTypeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  late String _selectedType;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titreController.text = widget.initialTitre ?? '';
    _contenuController.text = widget.initialContenu ?? '';
    
    _selectedType = widget.type;
    if (widget.type != 'ficheAvertissement' && widget.type != 'convocation' && widget.type != 'information') {
      _selectedType = 'custom';
      _customTypeController.text = widget.type;
    }
  }

  @override
  void dispose() {
    _titreController.dispose();
    _contenuController.dispose();
    _customTypeController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final categoryType = _selectedType == 'custom' ? _customTypeController.text.trim() : _selectedType;
    if (categoryType.isEmpty) {
      ToastUtils.show(context, context.tr('Veuillez spécifier une catégorie', 'Please specify a category'), isError: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      await widget.onSave(_titreController.text.trim(), _contenuController.text.trim(), categoryType);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ToastUtils.show(
          context,
          context.tr('Erreur : ', 'Error: ') + e.toString(),
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isEdit = widget.initialTitre != null;
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: cs.surfaceContainerLowest,
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(32),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit 
                  ? context.tr('Modifier le Modèle', 'Edit Template')
                  : context.tr('Ajouter un Modèle', 'Add Template'),
                style: AppTextStyles.headlineSmall.copyWith(color: cs.onSurface),
              ),
              const SizedBox(height: 24),
              if (!widget.isCategoryFixed) ...[
                // Category selection dropdown
                DropdownButtonFormField<String>(
                  value: _selectedType,
                  style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurface),
                  dropdownColor: cs.surfaceContainerLowest,
                  decoration: InputDecoration(
                    labelText: context.tr('Catégorie de lettre', 'Letter Category'),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.35))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.35))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: cs.primary, width: 1.5)),
                    isDense: true,
                  ),
                  items: [
                    DropdownMenuItem(value: 'ficheAvertissement', child: Text(context.tr('Fiche Avertissement', 'Warning Card'))),
                    DropdownMenuItem(value: 'convocation', child: Text(context.tr('Convocation', 'Summons'))),
                    DropdownMenuItem(value: 'information', child: Text(context.tr('Information', 'Information'))),
                    DropdownMenuItem(value: 'custom', child: Text(context.tr('Autre (Catégorie personnalisée)', 'Other (Custom Category)'))),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => _selectedType = val);
                    }
                  },
                ),
                if (_selectedType == 'custom') ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _customTypeController,
                    style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurface),
                    decoration: InputDecoration(
                      labelText: context.tr('Nom de la catégorie personnalisée', 'Custom Category Name'),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.35))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.35))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: cs.primary, width: 1.5)),
                      isDense: true,
                    ),
                    validator: (val) {
                      if (_selectedType == 'custom' && (val == null || val.trim().isEmpty)) {
                        return context.tr('Veuillez saisir le nom de la catégorie', 'Please enter the category name');
                      }
                      return null;
                    },
                  ),
                ],
                const SizedBox(height: 16),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _titreController,
                style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurface),
                decoration: InputDecoration(
                  labelText: context.tr('Titre du modèle (Sujet)', 'Template Title (Subject)'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.35))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.35))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: cs.primary, width: 1.5)),
                  isDense: true,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return context.tr('Veuillez saisir un titre', 'Please enter a title');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _contenuController,
                maxLines: 8,
                style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurface),
                decoration: InputDecoration(
                  labelText: context.tr('Contenu du modèle', 'Template Content'),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.35))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.35))),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: cs.primary, width: 1.5)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return context.tr('Veuillez saisir le contenu', 'Please enter the content');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        context.tr('Annuler', 'Cancel'),
                        style: const TextStyle(color: AppColors.error),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: Colors.white,
                      ),
                      child: Text(
                        isEdit ? context.tr('Modifier', 'Save') : context.tr('Ajouter', 'Add'),
                      ),
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
