import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/main_shell.dart';
import '../../../../core/widgets/app_top_bar.dart' show formatRelativeTime;
import '../../../../core/services/platform_data_service.dart';
import '../../../entreprises/presentation/providers/entreprise_provider.dart';
import '../../domain/models/tache_urgente.dart';
import '../../../../core/utils/translation_extension.dart';
import '../../../../core/utils/toast_utils.dart';

class UrgentsPage extends StatefulWidget {
  const UrgentsPage({super.key});

  @override
  State<UrgentsPage> createState() => _UrgentsPageState();
}

class _UrgentsPageState extends State<UrgentsPage> {
  bool _isLoading = true;
  bool _isListView = false;
  String? _targetNoteId;
  int _activeTab = 0; // 0 = Tâches Urgentes, 1 = Notes & Rappels Urgents
  List<TacheUrgente> _taches = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String) {
      _targetNoteId = args;
    }
  }

  Future<void> _loadData() async {
    final provider = Provider.of<EntrepriseProvider>(context, listen: false);
    final dataService = PlatformDataService();
    try {
      final results = await Future.wait([
        provider.fetchAllNotes(),
        provider.fetchEntreprises(), // To get enterprise names
        dataService.fetchTachesUrgentes(),
      ]);
      if (mounted) {
        setState(() {
          _taches = results[2] as List<TacheUrgente>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[UrgentsPage] Error loading data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToSource(dynamic note) {
    Navigator.pushNamed(
      context,
      AppRoutes.notesRappels,
      arguments: note.id,
    );
  }

  Future<void> _toggleTacheAccomplie(TacheUrgente tache) async {
    final dataService = PlatformDataService();
    final nextVal = !tache.accomplie;
    try {
      await dataService.basculerTacheAccomplie(tache.id, nextVal);
      setState(() {
        _taches = _taches.map((t) => t.id == tache.id ? t.copyWith(accomplie: nextVal) : t).toList();
      });
      ToastUtils.show(
        context,
        nextVal ? context.tr('Tâche marquée comme accomplie', 'Task marked as completed') : context.tr('Tâche marquée comme non accomplie', 'Task marked as incomplete'),
        isError: false,
      );
    } catch (e) {
      ToastUtils.show(
        context,
        context.tr('Erreur lors de la mise à jour de la tâche', 'Error updating task'),
        isError: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final provider = Provider.of<EntrepriseProvider>(context);
    final urgentNotes = provider.allNotes.where((n) => n.estRappel).toList();

    return MainShell(
      currentRoute: AppRoutes.urgents,
      title: context.tr('Urgences', 'Urgent Tasks'),
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
                          Text(context.tr('Fichiers & Notes Urgentes', 'Urgent Files & Notes'), style: AppTextStyles.headlineMedium.copyWith(color: cs.onSurface)),
                          const SizedBox(height: 4),
                          Text(context.tr('Vérifiez rapidement les rappels et tâches urgentes reçus des entreprises', 'Quickly check urgent reminders and tasks received from companies'), 
                              style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurfaceVariant)),
                        ],
                      ),
                      // View Toggle
                      Row(
                        children: [
                          IconButton(
                            onPressed: () => setState(() => _isListView = false),
                            icon: Icon(
                              Icons.grid_view_rounded,
                              color: !_isListView ? cs.primary : cs.outline,
                            ),
                            tooltip: context.tr('Vue en blocs', 'Grid View'),
                          ),
                          IconButton(
                            onPressed: () => setState(() => _isListView = true),
                            icon: Icon(
                              Icons.view_list_rounded,
                              color: _isListView ? cs.primary : cs.outline,
                            ),
                            tooltip: context.tr('Vue en liste', 'List View'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  
                  // Tab selection
                  Row(
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _activeTab == 0 ? cs.primaryContainer : cs.surface,
                          foregroundColor: _activeTab == 0 ? cs.onPrimaryContainer : cs.onSurface,
                          elevation: 0,
                          side: BorderSide(color: _activeTab == 0 ? cs.primary : cs.outlineVariant),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        onPressed: () => setState(() => _activeTab = 0),
                        icon: const Icon(Icons.assignment_late_rounded),
                        label: Text('${context.tr('Tâches Urgentes', 'Urgent Tasks')} (${_taches.length})'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _activeTab == 1 ? cs.primaryContainer : cs.surface,
                          foregroundColor: _activeTab == 1 ? cs.onPrimaryContainer : cs.onSurface,
                          elevation: 0,
                          side: BorderSide(color: _activeTab == 1 ? cs.primary : cs.outlineVariant),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                        onPressed: () => setState(() => _activeTab = 1),
                        icon: const Icon(Icons.note_rounded),
                        label: Text('${context.tr('Notes & Rappels Urgents', 'Urgent Notes & Reminders')} (${urgentNotes.length})'),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),

                  if (_activeTab == 0) ...[
                    if (_taches.isEmpty)
                      _buildEmptyState(cs, context.tr('Aucune tâche urgente pour le moment', 'No urgent tasks for now'))
                    else if (_isListView)
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _taches.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final tache = _taches[index];
                          final entreprise = provider.entreprises.where((e) => e.id == tache.entrepriseId).firstOrNull;
                          final nom = entreprise?.nom ?? 'Entreprise Inconnue';
                          return _TacheUrgenteCard(
                            tache: tache,
                            entrepriseNom: nom,
                            isList: true,
                            onToggle: () => _toggleTacheAccomplie(tache),
                          );
                        },
                      )
                    else
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: _taches.map((tache) {
                          final entreprise = provider.entreprises.where((e) => e.id == tache.entrepriseId).firstOrNull;
                          final nom = entreprise?.nom ?? 'Entreprise Inconnue';
                          return ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 350),
                            child: _TacheUrgenteCard(
                              tache: tache,
                              entrepriseNom: nom,
                              isList: false,
                              onToggle: () => _toggleTacheAccomplie(tache),
                            ),
                          );
                        }).toList(),
                      ),
                  ] else ...[
                    if (urgentNotes.isEmpty)
                      _buildEmptyState(cs, context.tr('Aucun rappel urgent pour le moment', 'No urgent reminders for now'))
                    else if (_isListView)
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: urgentNotes.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final note = urgentNotes[index];
                          final entreprise = provider.entreprises.where((e) => e.id == note.entrepriseId).firstOrNull;
                          final nom = entreprise?.nom ?? 'Entreprise Inconnue';
                          return _UrgentNoteCard(
                            note: note,
                            entrepriseNom: nom,
                            isList: true,
                            onTap: () => _navigateToSource(note),
                            isHighlighted: note.id == _targetNoteId,
                          );
                        },
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
                            child: _UrgentNoteCard(
                              note: note,
                              entrepriseNom: nom,
                              isList: false,
                              onTap: () => _navigateToSource(note),
                              isHighlighted: note.id == _targetNoteId,
                            ),
                          );
                        }).toList(),
                      ),
                  ]
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyState(ColorScheme cs, String message) {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.2)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.warning_amber_rounded, size: 64, color: AppColors.warning.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(message, style: AppTextStyles.titleMedium.copyWith(color: cs.onSurface)),
          ],
        ),
      ),
    );
  }
}

class _UrgentNoteCard extends StatefulWidget {
  final dynamic note;
  final String entrepriseNom;
  final bool isList;
  final VoidCallback onTap;
  final bool isHighlighted;

  const _UrgentNoteCard({
    required this.note,
    required this.entrepriseNom,
    required this.isList,
    required this.onTap,
    this.isHighlighted = false,
  });

  @override
  State<_UrgentNoteCard> createState() => _UrgentNoteCardState();
}

class _UrgentNoteCardState extends State<_UrgentNoteCard> with TickerProviderStateMixin {
  bool _isHovered = false;
  AnimationController? _highlightController;
  Animation<double>? _highlightAnimation;

  @override
  void initState() {
    super.initState();
    _highlightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _highlightAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeOut)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.2).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.2, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.2).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.2, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)),
        weight: 15,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)),
        weight: 25,
      ),
    ]).animate(_highlightController!);

    if (widget.isHighlighted) {
      _highlightController?.forward();
    }
  }

  @override
  void didUpdateWidget(covariant _UrgentNoteCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isHighlighted && !oldWidget.isHighlighted) {
      _highlightController?.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _highlightController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accentColor = AppColors.warning;
    final anim = _highlightAnimation ?? const AlwaysStoppedAnimation<double>(0.0);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedBuilder(
        animation: anim,
        builder: (context, child) {
          final animValue = anim.value;
          final borderGlowColor = Color.lerp(
            _isHovered ? accentColor : accentColor.withValues(alpha: 0.4),
            AppColors.primary,
            animValue,
          )!;
          final borderWidth = _isHovered ? 2.0 : 1.0 + (animValue * 1.5);
          final shadows = [
            BoxShadow(
              color: Color.lerp(
                _isHovered ? accentColor.withValues(alpha: 0.2) : Colors.transparent,
                AppColors.primary.withValues(alpha: 0.65),
                animValue,
              )!,
              blurRadius: _isHovered ? 16.0 : 8.0 + (animValue * 16.0),
              spreadRadius: animValue * 2.0,
              offset: Offset(0, _isHovered ? 8.0 : 4.0),
            ),
          ];

          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            width: widget.isList ? double.infinity : null,
            transform: Matrix4.translationValues(0.0, _isHovered ? -4.0 : 0.0, 0.0),
            decoration: BoxDecoration(
              color: cs.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: borderGlowColor,
                width: borderWidth,
              ),
              boxShadow: shadows,
            ),
            child: child,
          );
        },
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(20),
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
                      Text(
                        formatRelativeTime(widget.note.dateRappel ?? widget.note.dateCreation),
                        style: AppTextStyles.labelSmall.copyWith(color: AppColors.error),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(widget.entrepriseNom, style: AppTextStyles.labelSmall.copyWith(color: cs.primary)),
                  const SizedBox(height: 4),
                  Text(widget.note.titre, style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold, color: cs.onSurface)),
                  const SizedBox(height: 8),
                  Text(
                    widget.note.contenu,
                    style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurfaceVariant),
                    maxLines: widget.isList ? 10 : 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TacheUrgenteCard extends StatefulWidget {
  final TacheUrgente tache;
  final String entrepriseNom;
  final bool isList;
  final VoidCallback onToggle;

  const _TacheUrgenteCard({
    required this.tache,
    required this.entrepriseNom,
    required this.isList,
    required this.onToggle,
  });

  @override
  State<_TacheUrgenteCard> createState() => _TacheUrgenteCardState();
}

class _TacheUrgenteCardState extends State<_TacheUrgenteCard> {
  bool _isHovered = false;

  String _translateDbText(BuildContext context, String text) {
    if (text.startsWith('Mettre à jour les dossiers salariés')) {
      return context.tr(
        'Mettre à jour les dossiers salariés',
        'Update employee files',
      );
    }
    if (text.startsWith('Veuillez compléter les informations manquantes')) {
      return context.tr(
        "Veuillez compléter les informations manquantes (date de naissance, contrat) pour l'ensemble de vos salariés.",
        "Please complete the missing information (date of birth, contract) for all of your employees."
      );
    }
    return text;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final cardColor = widget.tache.accomplie 
        ? cs.surfaceContainerLow.withValues(alpha: 0.6) 
        : cs.surfaceContainerLowest;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        width: widget.isList ? double.infinity : null,
        transform: Matrix4.translationValues(0.0, _isHovered && !widget.tache.accomplie ? -4.0 : 0.0, 0.0),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.tache.accomplie 
                ? cs.outlineVariant.withValues(alpha: 0.5)
                : (_isHovered ? cs.primary : cs.outlineVariant.withValues(alpha: 0.3)),
            width: widget.tache.accomplie ? 1.0 : (_isHovered ? 2.0 : 1.0),
          ),
          boxShadow: widget.tache.accomplie 
              ? [] 
              : [
                  BoxShadow(
                    color: _isHovered ? cs.primary.withValues(alpha: 0.1) : Colors.transparent,
                    blurRadius: 12.0,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Checkbox directly on card
              Transform.scale(
                scale: 1.2,
                child: Checkbox(
                  value: widget.tache.accomplie,
                  onChanged: (_) => widget.onToggle(),
                  activeColor: cs.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.entrepriseNom,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: widget.tache.accomplie ? cs.outline : cs.primary,
                            decoration: widget.tache.accomplie ? TextDecoration.lineThrough : null,
                          ),
                        ),
                        Text(
                          '${context.tr('Échéance', 'Deadline')}: ${widget.tache.dateEcheance.day}/${widget.tache.dateEcheance.month}/${widget.tache.dateEcheance.year}',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: widget.tache.accomplie ? cs.outline : AppColors.error,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _translateDbText(context, widget.tache.titre),
                      style: AppTextStyles.titleMedium.copyWith(
                        fontWeight: FontWeight.bold,
                        color: widget.tache.accomplie ? cs.outline : cs.onSurface,
                        decoration: widget.tache.accomplie ? TextDecoration.lineThrough : null,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _translateDbText(context, widget.tache.description),
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: widget.tache.accomplie ? cs.outline : cs.onSurfaceVariant,
                        decoration: widget.tache.accomplie ? TextDecoration.lineThrough : null,
                      ),
                      maxLines: widget.isList ? 10 : 3,
                      overflow: TextOverflow.ellipsis,
                    ),
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
