import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/providers/app_state.dart';
import '../../core/models/models.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/top_notification_banner.dart';
import '../../core/utils/translation_extension.dart';

/// Global helper to show the recipient selector dialog and launch mail client.
void showTemplateSendDialog(
  BuildContext context,
  TemplateAvertissement template,
  AppState appState,
) {
  final salaries = appState.salaries;
  final selected = <String>{};
  showDialog(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setS) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${context.tr('Envoyer', 'Send')}: ${template.titre}',
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            Text(
              context.tr('Sélectionnez les destinataires', 'Select recipients'),
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 350,
          child: ListView.builder(
            itemCount: salaries.length,
            itemBuilder: (ctx, idx) {
              final s = salaries[idx];
              return CheckboxListTile(
                value: selected.contains(s.id),
                onChanged: (v) => setS(() {
                  if (v ?? false) {
                    selected.add(s.id);
                  } else {
                    selected.remove(s.id);
                  }
                }),
                title: Text(
                  s.nomComplet,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  s.emploiPoste ?? '',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: Theme.of(context).colorScheme.tertiary,
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              context.tr('Annuler', 'Cancel'),
              style: GoogleFonts.inter(
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: selected.isEmpty
                ? null
                : () async {
                    final selectedSalaries = salaries.where((s) => selected.contains(s.id)).toList();
                    final emails = selectedSalaries
                        .where((s) => s.email != null && s.email!.isNotEmpty)
                        .map((s) => s.email!)
                        .join(',');

                    if (emails.isEmpty) {
                      TopNotificationBanner.show(
                        context,
                        context.tr(
                          'Aucun salarié sélectionné n\'a d\'adresse e-mail.',
                          'No selected employee has an email address.',
                        ),
                        isError: true,
                      );
                      return;
                    }
                    String emailBody = template.contenu;
                    final lines = emailBody.split('\n');
                    if (lines.isNotEmpty && lines.first.trim().toLowerCase().startsWith('objet')) {
                      lines.removeAt(0);
                      while (lines.isNotEmpty && lines.first.trim().isEmpty) {
                        lines.removeAt(0);
                      }
                      emailBody = lines.join('\n');
                    }

                    final String url = 'mailto:$emails'
                        '?subject=${Uri.encodeComponent(template.titre)}'
                        '&body=${Uri.encodeComponent(emailBody).replaceAll('+', '%20')}';
                    final Uri emailUri = Uri.parse(url);

                    Navigator.pop(ctx);

                    try {
                      if (await canLaunchUrl(emailUri)) {
                        await launchUrl(emailUri);
                      } else {
                        await launchUrl(emailUri);
                      }
                    } catch (e) {
                      TopNotificationBanner.show(
                        context,
                        context.tr(
                          'Erreur lors de l\'envoi de l\'e-mail : $e',
                          'Error sending email: $e',
                        ),
                        isError: true,
                      );
                    }
                  },
            child: Text('${context.tr('Envoyer', 'Send')} (${selected.length})'),
          ),
        ],
      ),
    ),
  );
}

class AvertissementsPage extends StatefulWidget {
  const AvertissementsPage({super.key});

  @override
  State<AvertissementsPage> createState() => _AvertissementsPageState();
}

class _AvertissementsPageState extends State<AvertissementsPage> {
  TypeAvertissement? _activeCategory;

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final templates = appState.templates;
    final filteredTemplates = _activeCategory != null
        ? templates.where((t) => t.type == _activeCategory).toList()
        : [];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          AppHeader.sliver(context: context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: _activeCategory == null
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('Avertissements', 'Warnings'),
                          style: GoogleFonts.manrope(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: Theme.of(context).colorScheme.primary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          context.tr(
                            'Lettres prédéfinies modifiables. Sélectionnez les destinataires avant l\'envoi.',
                            'Predefined editable letters. Select recipients before sending.',
                          ),
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildCategoryListItem(
                          context: context,
                          type: TypeAvertissement.ficheAvertissement,
                          title: context.tr('Avertissements', 'Warnings'),
                          icon: Icons.warning_amber_rounded,
                          color: Colors.orange,
                          templatesCount: templates.where((t) => t.type == TypeAvertissement.ficheAvertissement).length,
                        ),
                        _buildCategoryListItem(
                          context: context,
                          type: TypeAvertissement.convocation,
                          title: context.tr('Convocations', 'Convocations'),
                          icon: Icons.event_note_rounded,
                          color: Theme.of(context).colorScheme.primary,
                          templatesCount: templates.where((t) => t.type == TypeAvertissement.convocation).length,
                        ),
                        _buildCategoryListItem(
                          context: context,
                          type: TypeAvertissement.information,
                          title: context.tr('Informations', 'Information'),
                          icon: Icons.info_outline_rounded,
                          color: Colors.blue,
                          templatesCount: templates.where((t) => t.type == TypeAvertissement.information).length,
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            setState(() {
                              _activeCategory = null;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.arrow_back_ios_new_rounded,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  context.tr('Catégories', 'Categories'),
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _getCategoryTitle(context, _activeCategory!),
                              style: GoogleFonts.manrope(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: Theme.of(context).colorScheme.primary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => TemplateEditCreatePage(
                                      category: _activeCategory!,
                                    ),
                                  ),
                                );
                              },
                              icon: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.add,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (filteredTemplates.isEmpty)
                          Container(
                            padding: const EdgeInsets.all(30),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Center(
                              child: Text(
                                context.tr(
                                  'Aucun modèle disponible dans cette catégorie.',
                                  'No template available in this category.',
                                ),
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          )
                        else
                          ...filteredTemplates.map(
                            (t) => _buildTemplateCard(context, t, appState),
                          ),
                        const SizedBox(height: 100),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryListItem({
    required BuildContext context,
    required TypeAvertissement type,
    required String title,
    required IconData icon,
    required Color color,
    required int templatesCount,
  }) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _activeCategory = type;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.manrope(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    templatesCount == 0
                        ? context.tr('Aucun modèle disponible', 'No template available')
                        : templatesCount == 1
                            ? context.tr('1 modèle disponible', '1 template available')
                            : context.tr(
                                '$templatesCount modèles disponibles',
                                '$templatesCount templates available',
                              ),
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Theme.of(context).colorScheme.outline,
            ),
          ],
        ),
      ),
    );
  }

  String _getCategoryTitle(BuildContext context, TypeAvertissement type) {
    switch (type) {
      case TypeAvertissement.ficheAvertissement:
        return context.tr('Avertissements', 'Warnings');
      case TypeAvertissement.convocation:
        return context.tr('Convocations', 'Convocations');
      case TypeAvertissement.information:
        return context.tr('Informations', 'Information');
    }
  }

  Widget _buildTemplateCard(
    BuildContext context,
    TemplateAvertissement template,
    AppState appState,
  ) {
    final (icon, color) = _typeStyle(template.type);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TemplateDetailPage(
              template: template,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _typeLabel(context, template.type),
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: color,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    template.titre,
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(context.tr('Confirmer la suppression', 'Confirm deletion')),
                    content: Text(context.tr(
                      'Voulez-vous vraiment supprimer le modèle "${template.titre}" ?',
                      'Do you really want to delete the template "${template.titre}"?',
                    )),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        child: Text(context.tr('Annuler', 'Cancel')),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: TextButton.styleFrom(foregroundColor: Colors.red),
                        child: Text(context.tr('Supprimer', 'Delete')),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await appState.deleteTemplate(template.id);
                  if (context.mounted) {
                    TopNotificationBanner.show(
                      context,
                      context.tr('Modèle supprimé avec succès.', 'Template deleted successfully.'),
                      isError: false,
                    );
                  }
                }
              },
              icon: Icon(
                Icons.delete_outline_rounded,
                color: Theme.of(context).colorScheme.error.withOpacity(0.8),
                size: 20,
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Theme.of(context).colorScheme.outline,
            ),
          ],
        ),
      ),
    );
  }

  (IconData, Color) _typeStyle(TypeAvertissement type) {
    switch (type) {
      case TypeAvertissement.ficheAvertissement:
        return (Icons.warning_amber_outlined, Colors.orange);
      case TypeAvertissement.convocation:
        return (
          Icons.event_note_outlined,
          Theme.of(context).colorScheme.primary,
        );
      case TypeAvertissement.information:
        return (Icons.info_outline, Colors.blue);
    }
  }

  String _typeLabel(BuildContext context, TypeAvertissement type) {
    switch (type) {
      case TypeAvertissement.ficheAvertissement:
        return context.tr('AVERTISSEMENT', 'WARNING');
      case TypeAvertissement.convocation:
        return context.tr('CONVOCATION', 'CONVOCATION');
      case TypeAvertissement.information:
        return context.tr('INFORMATION', 'INFORMATION');
    }
  }
}

/// Dedicated full-screen template detail viewer
class TemplateDetailPage extends StatelessWidget {
  final TemplateAvertissement template;

  const TemplateDetailPage({super.key, required this.template});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    
    // Locate the latest version in cache to update UI when returning from edit
    final latestTemplate = appState.templates.firstWhere(
      (t) => t.id == template.id,
      orElse: () => template,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          latestTemplate.titre,
          style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TemplateEditCreatePage(
                    template: latestTemplate,
                  ),
                ),
              );
            },
            icon: const Icon(Icons.edit_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      latestTemplate.contenu,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        height: 1.6,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () => showTemplateSendDialog(context, latestTemplate, appState),
                icon: const Icon(Icons.send),
                label: Text(context.tr(
                  'Sélectionner les destinataires & Envoyer',
                  'Select recipients & Send',
                )),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dedicated full-screen template editor (create / edit) page
class TemplateEditCreatePage extends StatefulWidget {
  final TemplateAvertissement? template;
  final TypeAvertissement? category;

  const TemplateEditCreatePage({
    super.key,
    this.template,
    this.category,
  }) : assert(template != null || category != null);

  @override
  State<TemplateEditCreatePage> createState() => _TemplateEditCreatePageState();
}

class _TemplateEditCreatePageState extends State<TemplateEditCreatePage> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.template?.titre ?? '');
    _contentController = TextEditingController(text: widget.template?.contenu ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.template != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing
              ? context.tr('Modifier le modèle', 'Edit template')
              : context.tr('Nouveau modèle', 'New template'),
          style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: context.tr('Titre du modèle', 'Template title'),
                  hintText: context.tr(
                    'Ex: Avertissement pour insubordination',
                    'E.g., Warning for insubordination',
                  ),
                  border: const OutlineInputBorder(),
                ),
                style: GoogleFonts.manrope(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: TextField(
                  controller: _contentController,
                  maxLines: null,
                  expands: true,
                  textAlignVertical: TextAlignVertical.top,
                  decoration: InputDecoration(
                    labelText: context.tr('Contenu de la lettre', 'Letter content'),
                    hintText: context.tr(
                      'Saisissez le texte prédéfini ici...',
                      'Enter the predefined text here...',
                    ),
                    border: const OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                  style: GoogleFonts.inter(),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : Text(context.tr('Enregistrer', 'Save')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();

    if (title.isEmpty || content.isEmpty) {
      TopNotificationBanner.show(
        context,
        context.tr(
          'Veuillez remplir le titre et le contenu.',
          'Please fill in the title and content.',
        ),
        isError: true,
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final appState = context.read<AppState>();
      if (widget.template != null) {
        // Edit mode
        await appState.updateTemplate(widget.template!.id, title, content);
      } else {
        // Creation mode
        final newTemplate = TemplateAvertissement(
          id: '',
          entrepriseId: appState.entrepriseId,
          titre: title,
          contenu: content,
          type: widget.category!,
        );
        await appState.addTemplate(newTemplate);
      }

      if (mounted) {
        Navigator.pop(context);
        TopNotificationBanner.show(
          context,
          context.tr('Modèle enregistré avec succès.', 'Template saved successfully.'),
          isError: false,
        );
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      TopNotificationBanner.show(
        context,
        context.tr(
          'Erreur lors de l\'enregistrement : $e',
          'Error saving template: $e',
        ),
        isError: true,
      );
    }
  }
}
