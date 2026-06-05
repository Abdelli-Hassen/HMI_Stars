import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/main_shell.dart';
import '../../../../core/widgets/staggered_column.dart';
import '../../../../core/utils/translation_extension.dart';
import '../../../entreprises/domain/models/note_entreprise.dart';
import '../../../entreprises/presentation/providers/entreprise_provider.dart';

class NotesRappelsPage extends StatefulWidget {
  const NotesRappelsPage({super.key});

  @override
  State<NotesRappelsPage> createState() => _NotesRappelsPageState();
}

class _NotesRappelsPageState extends State<NotesRappelsPage> {
  String _activeTab = 'Toutes';
  final TextEditingController _newNoteCtrl = TextEditingController();
  final TextEditingController _newNoteBodyCtrl = TextEditingController();
  final TextEditingController _searchCtrl = TextEditingController();
  final TextEditingController _newTodoCtrl = TextEditingController();
  String _selectedCategory = 'Note';
  bool _inputExpanded = false;
  bool _dataLoaded = false;
  bool _showAllTodos = false;

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

  String _translateTab(BuildContext context, String tab) {
    if (tab == 'Toutes') return context.tr('Toutes', 'All');
    if (tab == 'Épinglées') return context.tr('Épinglées', 'Pinned');
    return context.tr('Rappels', 'Reminders');
  }

  // Todos remain local (no DB table for them)
  final List<_TodoItem> _todos = [];

  List<NoteEntreprise> _getFilteredNotes(List<NoteEntreprise> allNotes) {
    var list = allNotes;
    if (_activeTab == 'Épinglées') list = list.where((n) => n.isPinned).toList();
    if (_activeTab == 'Rappels') list = list.where((n) => n.estRappel).toList();
    final q = _searchCtrl.text.toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((n) =>
        n.titre.toLowerCase().contains(q) ||
        n.contenu.toLowerCase().contains(q) ||
        n.tag.toLowerCase().contains(q)
      ).toList();
    }
    return list;
  }

  static const _categories = [
    _CategoryDef('Note', Icons.sticky_note_2, Color(0xFF1A237E)),
    _CategoryDef('Rappel', Icons.alarm, Color(0xFFE65100)),
    _CategoryDef('Contrats', Icons.history_edu, Color(0xFF00695C)),
    _CategoryDef('RH', Icons.people, Color(0xFF2E7D32)),
    _CategoryDef('Congés', Icons.event_available, Color(0xFF0277BD)),
    _CategoryDef('Recrutement', Icons.person_add, Color(0xFFC62828)),
  ];

  _CategoryDef get _currentCat => _categories.firstWhere((c) => c.label == _selectedCategory);

  void _addNote() async {
    if (_newNoteCtrl.text.trim().isEmpty) return;
    final provider = Provider.of<EntrepriseProvider>(context, listen: false);
    // Use the first enterprise as default target, or empty string if none
    final entreprises = provider.entreprises;
    final targetId = entreprises.isNotEmpty ? entreprises.first.id : '';

    if (targetId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('Aucune entreprise disponible pour créer une note.', 'No companies available to create a note.')), backgroundColor: AppColors.error));
      return;
    }


    DateTime? limitDate;
    if (_selectedCategory == 'Rappel' && _deadlineDate != null) {
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
      entrepriseId: targetId,
      titre: _newNoteCtrl.text.trim(),
      contenu: _newNoteBodyCtrl.text.trim(),
      dateCreation: DateTime.now(),
      estRappel: _selectedCategory == 'Rappel',
      dateRappel: limitDate,
      tag: _selectedCategory,
    );

    try {
      await provider.ajouterNote(note);
      if (mounted) {
        setState(() {
          _newNoteCtrl.clear();
          _newNoteBodyCtrl.clear();
          _selectedCategory = 'Note';
          _inputExpanded = false;
          _deadlineDate = null;
          _deadlineTime = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('Note ajoutée !', 'Note added!')), backgroundColor: AppColors.success));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error));
      }
    }
  }

  void _addTodo() {
    if (_newTodoCtrl.text.trim().isEmpty) return;
    setState(() {
      _todos.insert(0, _TodoItem(_newTodoCtrl.text.trim(), false));
      _newTodoCtrl.clear();
    });
  }

  @override
  void dispose() {
    _newNoteCtrl.dispose();
    _newNoteBodyCtrl.dispose();
    _searchCtrl.dispose();
    _newTodoCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final provider = Provider.of<EntrepriseProvider>(context);
    if (!_dataLoaded) {
      _dataLoaded = true;
      provider.fetchAllNotes();
    }
    final allNotes = provider.allNotes;
    final filteredNotes = _getFilteredNotes(allNotes);
    return MainShell(
      currentRoute: AppRoutes.notesRappels,
      title: context.tr('Notes & Rappels', 'Notes & Reminders'),
      body: SingleChildScrollView(
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
                    Text(
                      context.tr('Notes & Rappels', 'Notes & Reminders'), 
                      style: AppTextStyles.headlineLarge.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5, color: cs.onSurface)
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.tr('Organisez vos tâches, notes et rappels professionnels.', 'Organize your professional tasks, notes, and reminders.'),
                      style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurfaceVariant)
                    ),
                  ],
                ),
                Row(children: [
                  // Search
                  SizedBox(
                    width: 220,
                    height: 36,
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: context.tr('Rechercher...', 'Search...'),
                        hintStyle: AppTextStyles.bodySmall.copyWith(color: cs.outline),
                        prefixIcon: Icon(Icons.search, size: 18, color: cs.outline),
                        filled: true,
                        fillColor: cs.surfaceContainerLow,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        isDense: true,
                      ),
                      style: AppTextStyles.bodySmall.copyWith(color: cs.onSurface),
                    ),
                  ),
                ]),
              ],
            ),
            const SizedBox(height: 20),

            // ─── Enhanced Note Creation Panel ───
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              padding: _inputExpanded ? const EdgeInsets.all(24) : EdgeInsets.zero,
              decoration: BoxDecoration(
                color: _inputExpanded ? cs.surfaceContainerLowest : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _inputExpanded 
                      ? cs.outlineVariant.withValues(alpha: 0.5) 
                      : Colors.transparent,
                  width: 1,
                ),
                boxShadow: _inputExpanded ? [
                  BoxShadow(
                    color: cs.onSurface.withValues(alpha: 0.03),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ] : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title input row - Styled like the To-Do input
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _inputExpanded 
                            ? _currentCat.color.withValues(alpha: 0.3) 
                            : cs.outlineVariant.withValues(alpha: 0.5)
                      ),
                    ),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _currentCat.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(_currentCat.icon, size: 18, color: _currentCat.color),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _newNoteCtrl,
                            onTap: () { if (!_inputExpanded) setState(() => _inputExpanded = true); },
                            onSubmitted: (_) => _addNote(),
                            style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: cs.onSurface),
                            decoration: InputDecoration(
                              hintText: context.tr('Titre de la note...', 'Note title...'),
                              hintStyle: AppTextStyles.bodyMedium.copyWith(color: cs.outline, fontWeight: FontWeight.w500),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                          ),
                        ),
                        // Collapse/Expand toggle button
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => setState(() => _inputExpanded = !_inputExpanded),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: _inputExpanded ? _currentCat.color : cs.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: AnimatedRotation(
                                turns: _inputExpanded ? 0.5 : 0.0,
                                duration: const Duration(milliseconds: 200),
                                child: Icon(
                                  Icons.expand_more,
                                  size: 18, 
                                  color: _inputExpanded ? Colors.white : cs.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Expanded details
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOutCubic,
                    child: !_inputExpanded 
                        ? const SizedBox.shrink()
                        : Padding(
                            padding: const EdgeInsets.only(top: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Description field
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: cs.surfaceContainerLow,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.3)),
                                  ),
                                  child: TextField(
                                    controller: _newNoteBodyCtrl,
                                    maxLines: 5,
                                    minLines: 3,
                                    style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurface),
                                    decoration: InputDecoration(
                                      hintText: context.tr('Description (optionnel)...', 'Description (optional)...'),
                                      hintStyle: AppTextStyles.bodyMedium.copyWith(color: cs.outline),
                                      border: InputBorder.none,
                                      isDense: false,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 16),

                                // Category label
                                Text(context.tr('CATÉGORIE', 'CATEGORY'), style: AppTextStyles.labelSmall.copyWith(
                                  letterSpacing: 1.2, fontWeight: FontWeight.w800, color: cs.onSurfaceVariant,
                                )),
                                const SizedBox(height: 10),

                                // Category Chips
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: _categories.map((cat) {
                                    final active = _selectedCategory == cat.label;
                                    return _CategoryChip(
                                      cat: cat,
                                      isActive: active,
                                      onTap: () => setState(() => _selectedCategory = cat.label),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(height: 16),

                                // Deadline Date / Time selection
                                if (_selectedCategory == 'Rappel') ...[
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
                                  const SizedBox(height: 16),
                                ],

                                // Submit row
                                Row(
                                  children: [
                                    const Spacer(),
                                    // Cancel
                                    MouseRegion(
                                      cursor: SystemMouseCursors.click,
                                      child: GestureDetector(
                                        onTap: () => setState(() {
                                          _inputExpanded = false;
                                          _newNoteCtrl.clear();
                                          _newNoteBodyCtrl.clear();
                                          _selectedCategory = 'Note';
                                        }),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                          child: Text(context.tr('Annuler', 'Cancel'), style: AppTextStyles.labelMedium.copyWith(
                                            fontWeight: FontWeight.w600, color: cs.onSurfaceVariant,
                                          )),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Add button
                                    _AddButton(onTap: _addNote),
                                  ],
                                ),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ─── Tabs ───
            Row(
              children: ['Toutes', 'Épinglées', 'Rappels'].map((tab) {
                final active = _activeTab == tab;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      onTap: () => setState(() => _activeTab = tab),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: active ? cs.primary : cs.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(_translateTab(context, tab), style: AppTextStyles.labelMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: active ? Colors.white : cs.onSurfaceVariant,
                        )),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // ─── Content: Notes Grid + Todo Sidebar ───
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Notes Grid
                Expanded(
                  flex: 3,
                  child: filteredNotes.isEmpty
                      ? Container(
                          padding: const EdgeInsets.all(48),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.sticky_note_2_outlined, size: 48, color: cs.outline),
                                const SizedBox(height: 12),
                                Text(context.tr('Aucune note trouvée', 'No notes found'), style: AppTextStyles.bodyMedium.copyWith(color: cs.outline)),
                              ],
                            ),
                          ),
                        )
                      : Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: filteredNotes.map((note) => _NoteCard(
                            data: note,
                            onPin: () async {
                              try {
                                final updated = note.copyWith(isPinned: !note.isPinned);
                                await provider.updateNote(updated);
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error));
                                }
                              }
                            },
                            onEdit: () => _editNote(note),
                            onDelete: () async {
                              try {
                                await provider.supprimerNote(note.id, note.entrepriseId);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.tr('Note supprimée.', 'Note deleted.')), backgroundColor: AppColors.success));
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error));
                                }
                              }
                            },
                          )).toList(),
                        ),
                ),
                const SizedBox(width: 20),

                // ─── Todo Sidebar ───
                SizedBox(
                  width: 280,
                  child: Column(children: [
                    // To-Do List
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: cs.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('À FAIRE', style: AppTextStyles.labelSmall.copyWith(
                                letterSpacing: 1.5, fontWeight: FontWeight.w800, color: cs.primary,
                              )),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: cs.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${_todos.where((t) => !t.done).length} restantes',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    fontSize: 10, fontWeight: FontWeight.w700, color: cs.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // ─── Add Todo Input ───
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: cs.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.add, size: 20, color: cs.outline),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: _newTodoCtrl,
                                    onSubmitted: (_) => _addTodo(),
                                    style: AppTextStyles.bodyMedium,
                                    decoration: InputDecoration(
                                      hintText: 'Ajouter une tâche...',
                                      hintStyle: AppTextStyles.bodyMedium.copyWith(color: cs.outline),
                                      border: InputBorder.none,
                                      enabledBorder: InputBorder.none,
                                      focusedBorder: InputBorder.none,
                                      errorBorder: InputBorder.none,
                                      disabledBorder: InputBorder.none,
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                    ),
                                  ),
                                ),
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: _addTodo,
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: cs.primary,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(Icons.arrow_upward, size: 18, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          ...(_showAllTodos ? _todos : _todos.take(10)).map((todo) => _TodoRow(
                            item: todo,
                            onToggle: () => setState(() => todo.done = !todo.done),
                            onDelete: () => setState(() => _todos.remove(todo)),
                          )),
                          if (_todos.length > 10)
                            Center(
                              child: Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: TextButton(
                                  onPressed: () => setState(() => _showAllTodos = !_showAllTodos),
                                  child: Text(
                                    _showAllTodos ? 'Voir moins' : 'Voir plus (${_todos.length - 10})',
                                    style: AppTextStyles.labelSmall.copyWith(color: cs.primary),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  void _editNote(NoteEntreprise note) {
    final titleCtrl = TextEditingController(text: note.titre);
    final contentCtrl = TextEditingController(text: note.contenu);
    String selectedTag = note.tag;
    DateTime? deadlineDate = note.dateRappel;
    TimeOfDay? deadlineTime = note.dateRappel != null
        ? TimeOfDay(hour: note.dateRappel!.hour, minute: note.dateRappel!.minute)
        : null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final cs = Theme.of(context).colorScheme;

          Future<void> selectDate() async {
            final DateTime? picked = await showDatePicker(
              context: context,
              initialDate: deadlineDate ?? DateTime.now(),
              firstDate: DateTime.now().subtract(const Duration(days: 365)),
              lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
            );
            if (picked != null) {
              setDialogState(() {
                deadlineDate = picked;
              });
            }
          }

          Future<void> selectTime() async {
            final TimeOfDay? picked = await showTimePicker(
              context: context,
              initialTime: deadlineTime ?? TimeOfDay.now(),
            );
            if (picked != null) {
              setDialogState(() {
                deadlineTime = picked;
              });
            }
          }

          return AlertDialog(
            backgroundColor: cs.surfaceContainerLowest,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text('Modifier la note', style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700)),
            content: SizedBox(
              width: 440,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Titre', style: AppTextStyles.labelSmall.copyWith(color: cs.onSurfaceVariant)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: titleCtrl,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        isDense: true,
                      ),
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Text('Contenu', style: AppTextStyles.labelSmall.copyWith(color: cs.onSurfaceVariant)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: contentCtrl,
                      maxLines: 4,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    Text('CATÉGORIE', style: AppTextStyles.labelSmall.copyWith(
                      letterSpacing: 1.2, fontWeight: FontWeight.w800, color: cs.onSurfaceVariant,
                    )),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories.map((cat) {
                        final active = selectedTag == cat.label;
                        return MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => setDialogState(() => selectedTag = cat.label),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: active ? cat.color.withValues(alpha: 0.15) : cs.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: active ? cat.color : cs.outlineVariant,
                                  width: active ? 2 : 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(cat.icon, size: 14, color: active ? cat.color : cs.outline),
                                  const SizedBox(width: 6),
                                  Text(cat.label, style: AppTextStyles.labelSmall.copyWith(
                                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                                    color: active ? cat.color : cs.onSurfaceVariant,
                                  )),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    if (selectedTag == 'Rappel') ...[
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
                            onPressed: selectDate,
                            icon: const Icon(Icons.calendar_today, size: 16),
                            label: Text(
                              deadlineDate == null
                                  ? context.tr('Sélectionner Date', 'Select Date')
                                  : '${deadlineDate!.day}/${deadlineDate!.month}/${deadlineDate!.year}',
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
                            onPressed: selectTime,
                            icon: const Icon(Icons.access_time, size: 16),
                            label: Text(
                              deadlineTime == null
                                  ? context.tr('Sélectionner Heure', 'Select Time')
                                  : deadlineTime!.format(context),
                            ),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              foregroundColor: cs.onSurface,
                              side: BorderSide(color: cs.outlineVariant),
                            ),
                          ),
                          if (deadlineDate != null || deadlineTime != null) ...[
                            const SizedBox(width: 12),
                            IconButton(
                              icon: const Icon(Icons.clear, color: AppColors.error),
                              onPressed: () {
                                setDialogState(() {
                                  deadlineDate = null;
                                  deadlineTime = null;
                                });
                              },
                              tooltip: context.tr('Effacer', 'Clear'),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Annuler', style: AppTextStyles.labelMedium.copyWith(color: cs.outline)),
              ),
              ElevatedButton(
                onPressed: () async {
                  final provider = Provider.of<EntrepriseProvider>(context, listen: false);
                  DateTime? limitDate;
                  if (selectedTag == 'Rappel' && deadlineDate != null) {
                    final time = deadlineTime ?? const TimeOfDay(hour: 12, minute: 0);
                    limitDate = DateTime(
                      deadlineDate!.year,
                      deadlineDate!.month,
                      deadlineDate!.day,
                      time.hour,
                      time.minute,
                    );
                  }
                  final updatedNote = note.copyWith(
                    titre: titleCtrl.text.trim(),
                    contenu: contentCtrl.text.trim(),
                    tag: selectedTag,
                    estRappel: selectedTag == 'Rappel',
                    dateRappel: limitDate,
                  );
                  try {
                    await provider.updateNote(updatedNote);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Note modifiée.'), backgroundColor: AppColors.success));
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e'), backgroundColor: AppColors.error));
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: const Text('Enregistrer'),
              ),
            ],
          );
        },
      ),
    );
  }
}

// _NoteData class removed — using NoteEntreprise from domain models instead

class _TodoItem {
  final String label;
  bool done;
  _TodoItem(this.label, this.done);
}

class _CategoryDef {
  final String label;
  final IconData icon;
  final Color color;
  const _CategoryDef(this.label, this.icon, this.color);
}

// ─── Note Card ───

class _NoteCard extends StatefulWidget {
  final NoteEntreprise data;
  final VoidCallback onPin;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _NoteCard({required this.data, required this.onPin, required this.onEdit, required this.onDelete});

  @override
  State<_NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<_NoteCard> {
  bool _hovered = false;

  Color _getColorForTag(BuildContext context, String tag) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    switch (tag) {
      case 'Rappel': return isDark ? const Color(0xFFFFB74D) : const Color(0xFFE65100);
      case 'Contrats': return isDark ? const Color(0xFF4DB6AC) : const Color(0xFF00695C);
      case 'RH': return isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32);
      case 'Congés': return isDark ? const Color(0xFF64B5F6) : const Color(0xFF0277BD);
      case 'Recrutement': return isDark ? const Color(0xFFE57373) : const Color(0xFFC62828);
      default: return isDark ? const Color(0xFF9FA8DA) : const Color(0xFF1A237E);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final d = widget.data;
    final color = _getColorForTag(context, d.tag);
    final dateStr = '${d.dateCreation.day}/${d.dateCreation.month}/${d.dateCreation.year}';
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        width: 280,
        padding: const EdgeInsets.all(20),
        transform: Matrix4.translationValues(0, _hovered ? -4 : 0, 0),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered ? color.withValues(alpha: 0.4) : cs.outlineVariant.withValues(alpha: 0.5),
            width: _hovered ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _hovered ? color.withValues(alpha: 0.25) : cs.onSurface.withValues(alpha: 0.04),
              blurRadius: _hovered ? 20 : 4,
              spreadRadius: _hovered ? 3 : 0,
              offset: _hovered ? const Offset(0, 8) : const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(d.tag, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color, letterSpacing: 0.5)),
                ),
                if (d.isPinned) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.push_pin, size: 14, color: color),
                ],
                if (d.estRappel) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.alarm, size: 14, color: AppColors.warning),
                ],
                const Spacer(),
                AnimatedOpacity(
                  opacity: _hovered ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: widget.onPin,
                        child: Icon(
                          d.isPinned ? Icons.push_pin : Icons.push_pin_outlined,
                          size: 16, color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: widget.onEdit,
                        child: Icon(Icons.edit_outlined, size: 16, color: cs.primary),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: widget.onDelete,
                        child: const Icon(Icons.delete_outline, size: 16, color: AppColors.error),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(d.titre, style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700, color: cs.onSurface),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            if (d.contenu.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(d.contenu, style: AppTextStyles.bodySmall.copyWith(color: cs.onSurfaceVariant, height: 1.4),
                  maxLines: 3, overflow: TextOverflow.ellipsis),
            ],
            if (d.estRappel && d.dateRappel != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.alarm, size: 12, color: AppColors.warning),
                    const SizedBox(width: 4),
                    Text('${d.dateRappel!.day}/${d.dateRappel!.month}/${d.dateRappel!.year}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.warning)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 10),
            Text(dateStr, style: AppTextStyles.bodySmall.copyWith(fontSize: 10, color: cs.outline)),
          ],
        ),
      ),
    );
  }
}

// ─── Todo Row ───

class _TodoRow extends StatefulWidget {
  final _TodoItem item;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _TodoRow({required this.item, required this.onToggle, required this.onDelete});

  @override
  State<_TodoRow> createState() => _TodoRowState();
}

class _TodoRowState extends State<_TodoRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onToggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: _hovered ? cs.primary.withValues(alpha: 0.04) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 20, height: 20,
                decoration: BoxDecoration(
                  color: widget.item.done ? cs.primary : Colors.transparent,
                  border: Border.all(
                    color: widget.item.done ? cs.primary : cs.outline,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: widget.item.done
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.item.label,
                  style: AppTextStyles.bodySmall.copyWith(
                    fontWeight: FontWeight.w500,
                    decoration: widget.item.done ? TextDecoration.lineThrough : null,
                    color: widget.item.done ? cs.outline : cs.onSurface,
                  ),
                ),
              ),
              // Delete on hover
              AnimatedOpacity(
                opacity: _hovered ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 150),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: widget.onDelete,
                    child: const Icon(Icons.close, size: 14, color: AppColors.error),
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

// ─── Add Button ───

class _AddButton extends StatefulWidget {
  final VoidCallback onTap;
  const _AddButton({required this.onTap});

  @override
  State<_AddButton> createState() => _AddButtonState();
}

class _AddButtonState extends State<_AddButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: cs.primaryGradient,
            borderRadius: BorderRadius.circular(10),
            boxShadow: _hovered
                ? [BoxShadow(color: cs.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, size: 18, color: _hovered ? Colors.white : Colors.white.withValues(alpha: 0.9)),
              const SizedBox(width: 6),
              Text('Ajouter', style: AppTextStyles.labelMedium.copyWith(
                fontWeight: FontWeight.w700,
                color: Colors.white,
              )),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Category Chip ───

class _CategoryChip extends StatefulWidget {
  final _CategoryDef cat;
  final bool isActive;
  final VoidCallback onTap;

  const _CategoryChip({required this.cat, required this.isActive, required this.onTap});

  @override
  State<_CategoryChip> createState() => _CategoryChipState();
}

class _CategoryChipState extends State<_CategoryChip> {
  bool _hovered = false;

  String _translateCategory(BuildContext context, String cat) {
    if (cat == 'Note') return context.tr('Note', 'Note');
    if (cat == 'Rappel') return context.tr('Rappel', 'Reminder');
    if (cat == 'Contrats') return context.tr('Contrats', 'Contracts');
    if (cat == 'RH') return context.tr('RH', 'HR');
    if (cat == 'Congés') return context.tr('Congés', 'Leave');
    if (cat == 'Recrutement') return context.tr('Recrutement', 'Recruitment');
    return cat;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: widget.isActive
                ? widget.cat.color.withValues(alpha: 0.12)
                : _hovered
                    ? cs.surfaceContainerHigh
                    : cs.surfaceContainerLow,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: widget.isActive ? widget.cat.color : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(widget.cat.icon, size: 14,
                  color: widget.isActive ? widget.cat.color : cs.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(_translateCategory(context, widget.cat.label), style: AppTextStyles.labelSmall.copyWith(
                fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w500,
                color: widget.isActive ? widget.cat.color : cs.onSurfaceVariant,
              )),
            ],
          ),
        ),
      ),
    );
  }
}
