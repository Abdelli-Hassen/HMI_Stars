import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/main_shell.dart';
import '../../../../core/widgets/app_top_bar.dart' show formatRelativeTime;
import '../../../entreprises/presentation/providers/entreprise_provider.dart';

class UrgentsPage extends StatefulWidget {
  const UrgentsPage({super.key});

  @override
  State<UrgentsPage> createState() => _UrgentsPageState();
}

class _UrgentsPageState extends State<UrgentsPage> {
  bool _isLoading = true;
  bool _isListView = false;
  String? _targetNoteId;

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

  void _navigateToSource(dynamic note) {
    // Navigate to the global Notes & Rappels page where all notes can be modified or deleted.
    Navigator.pushNamed(context, AppRoutes.notesRappels);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
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
                          Text('Fichiers & Notes Urgentes', style: AppTextStyles.headlineMedium.copyWith(color: cs.onSurface)),
                          const SizedBox(height: 4),
                          Text('Vérifiez rapidement les rappels urgents reçus des entreprises', 
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
                            tooltip: 'Vue en blocs',
                          ),
                          IconButton(
                            onPressed: () => setState(() => _isListView = true),
                            icon: Icon(
                              Icons.view_list_rounded,
                              color: _isListView ? cs.primary : cs.outline,
                            ),
                            tooltip: 'Vue en liste',
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  if (urgentNotes.isEmpty)
                    Container(
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
                            Text('Aucun rappel urgent pour le moment', style: AppTextStyles.titleMedium.copyWith(color: cs.onSurface)),
                          ],
                        ),
                      ),
                    )
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
