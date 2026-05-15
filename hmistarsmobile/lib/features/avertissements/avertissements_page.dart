import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/providers/app_state.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';

class AvertissementsPage extends StatefulWidget {
  const AvertissementsPage({super.key});

  @override
  State<AvertissementsPage> createState() => _AvertissementsPageState();
}

class _AvertissementsPageState extends State<AvertissementsPage> {
  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final templates = appState.templates;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surface.withOpacity(0.9),
            title: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/logo.jpeg',
                    width: 70,
                    height: 36,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'HMI Stars Consulting',
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.primary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Documents RH',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.tertiary,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Text(
                    'Avertissements',
                    style: GoogleFonts.manrope(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.primary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Lettres prédéfinies modifiables. Sélectionnez les destinataires avant l\'envoi.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ...templates.map(
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

  Widget _buildTemplateCard(
    BuildContext context,
    TemplateAvertissement template,
    AppState appState,
  ) {
    final (icon, color) = _typeStyle(template.type);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _typeLabel(template.type),
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: color,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Text(
                        template.titre,
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Preview
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              template.contenu.substring(
                    0,
                    template.contenu.length.clamp(0, 120),
                  ) +
                  '...',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _editTemplate(context, template, appState),
                    icon: Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Modifier'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        _showSendDialog(context, template, appState),
                    icon: Icon(Icons.send, size: 16),
                    label: const Text('Envoyer'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _editTemplate(
    BuildContext context,
    TemplateAvertissement template,
    AppState appState,
  ) {
    final contentController = TextEditingController(text: template.contenu);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: DraggableScrollableSheet(
          initialChildSize: 0.85,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          builder: (_, sc) => Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),
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
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Modifier: ${template.titre}',
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          appState.updateTemplate(
                            template.id,
                            contentController.text,
                          );
                          Navigator.pop(ctx);
                        },
                        child: const Text('Confirmer'),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: TextField(
                      controller: contentController,
                      maxLines: null,
                      expands: true,
                      textAlignVertical: TextAlignVertical.top,
                      decoration: const InputDecoration(
                        hintText: 'Contenu du document...',
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showSendDialog(
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
                'Envoyer: ${template.titre}',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              Text(
                'Sélectionnez les destinataires',
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
                    if (v ?? false)
                      selected.add(s.id);
                    else
                      selected.remove(s.id);
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
                'Annuler',
                style: GoogleFonts.inter(
                  color: Theme.of(context).colorScheme.outline,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: selected.isEmpty
                  ? null
                  : () {
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Document envoyé à ${selected.length} salarié(s)',
                          ),
                          backgroundColor: Colors.green,
                        ),
                      );
                    },
              child: Text('Envoyer (${selected.length})'),
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

  String _typeLabel(TypeAvertissement type) {
    switch (type) {
      case TypeAvertissement.ficheAvertissement:
        return 'AVERTISSEMENT';
      case TypeAvertissement.convocation:
        return 'CONVOCATION';
      case TypeAvertissement.information:
        return 'INFORMATION';
    }
  }
}
