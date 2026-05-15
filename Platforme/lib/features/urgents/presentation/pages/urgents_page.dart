import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/main_shell.dart';
import '../../../entreprises/presentation/providers/entreprise_provider.dart';

class UrgentsPage extends StatefulWidget {
  const UrgentsPage({super.key});

  @override
  State<UrgentsPage> createState() => _UrgentsPageState();
}

class _UrgentsPageState extends State<UrgentsPage> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  Future<void> _loadData() async {
    final provider = Provider.of<EntrepriseProvider>(context, listen: false);
    await Future.wait([
      provider.fetchAllNotes(),
      provider.fetchEntreprises(), // To get enterprise names
    ]);
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<EntrepriseProvider>(context);
    // Filter to get only urgent rappels
    final urgentNotes = provider.allNotes.where((n) => n.estRappel).toList();

    return MainShell(
      currentRoute: AppRoutes.urgents,
      title: 'Urgences',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Fichiers & Notes Urgentes', style: AppTextStyles.headlineMedium),
                          const SizedBox(height: 4),
                          Text('Vérifiez rapidement les rappels urgents reçus des entreprises', 
                              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.onSurfaceVariant)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  if (urgentNotes.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.2)),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.warning_amber_rounded, size: 64, color: AppColors.warning.withValues(alpha: 0.5)),
                            const SizedBox(height: 16),
                            Text('Aucun rappel urgent pour le moment', style: AppTextStyles.titleMedium),
                          ],
                        ),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: urgentNotes.map((note) {
                        final entreprise = provider.entreprises.where((e) => e.id == note.entrepriseId).firstOrNull;
                        final nom = entreprise?.nom ?? 'Entreprise Inconnue';
                        return ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 350),
                          child: _buildUrgentCard(note, nom),
                        );
                      }).toList(),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildUrgentCard(dynamic note, String entrepriseNom) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Urgent', style: AppTextStyles.labelSmall.copyWith(color: AppColors.warning)),
              ),
              if (note.dateRappel != null)
                Text('${note.dateRappel!.day}/${note.dateRappel!.month}/${note.dateRappel!.year}', style: AppTextStyles.labelSmall.copyWith(color: AppColors.error)),
            ],
          ),
          const SizedBox(height: 12),
          Text(entrepriseNom, style: AppTextStyles.labelSmall.copyWith(color: AppColors.primary)),
          const SizedBox(height: 4),
          Text(note.titre, style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(note.contenu, style: AppTextStyles.bodyMedium, maxLines: 3, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
