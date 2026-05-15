import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/main_shell.dart';
import '../../../../core/widgets/staggered_column.dart';
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
  bool _isReminderOn = false;
  bool _inputExpanded = false;
  bool _dataLoaded = false;


  // Todos remain local (no DB table for them)
  final List<_TodoItem> _todos = [
    _TodoItem('Envoyer les attestations employeur', true),
    _TodoItem('Commander les tickets restaurant', false),
    _TodoItem('Mettre à jour le registre du personnel', false),
    _TodoItem('Archiver les dossiers 2023', true),
    _TodoItem('Planifier la réunion CSE de Mai', false),
    _TodoItem('Vérifier les DPAE en cours', false),
  ];

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
    _CategoryDef('Formation', Icons.school, Color(0xFF6A1B9A)),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aucune entreprise disponible pour créer une note.'), backgroundColor: AppColors.error));
      return;
    }


    final note = NoteEntreprise(
      id: '',
      entrepriseId: targetId,
      titre: _newNoteCtrl.text.trim(),
      contenu: _newNoteBodyCtrl.text.trim(),
      dateCreation: DateTime.now(),
      estRappel: _isReminderOn || _selectedCategory == 'Rappel',
    );

    try {
      await provider.ajouterNote(note);
      if (mounted) {
        setState(() {
          _newNoteCtrl.clear();
          _newNoteBodyCtrl.clear();
          _isReminderOn = false;
          _selectedCategory = 'Note';
          _inputExpanded = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Note ajoutée !'), backgroundColor: AppColors.success));
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
      _todos.add(_TodoItem(_newTodoCtrl.text.trim(), false));
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
    final provider = Provider.of<EntrepriseProvider>(context);
    if (!_dataLoaded) {
      _dataLoaded = true;
      provider.fetchAllNotes();
    }
    final allNotes = provider.allNotes;
    final filteredNotes = _getFilteredNotes(allNotes);
    return MainShell(
      currentRoute: AppRoutes.notesRappels,
      title: 'Notes & Rappels',
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
                    Text('Notes & Rappels', style: AppTextStyles.headlineLarge.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                    const SizedBox(height: 4),
                    Text('Organisez vos tâches, notes et rappels professionnels.',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.onSurfaceVariant)),
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
                        hintText: 'Rechercher...',
                        hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.outline),
                        prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.outline),
                        filled: true,
                        fillColor: AppColors.surfaceContainerLow,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        isDense: true,
                      ),
                      style: AppTextStyles.bodySmall,
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
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(20),
                border: Border(left: BorderSide(color: _currentCat.color, width: 4)),
                boxShadow: [
                  BoxShadow(color: AppColors.onSurface.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title input row
                  Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _currentCat.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(_currentCat.icon, size: 20, color: _currentCat.color),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: TextField(
                          controller: _newNoteCtrl,
                          onTap: () { if (!_inputExpanded) setState(() => _inputExpanded = true); },
                          onSubmitted: (_) => _addNote(),
                          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            hintText: 'Titre de la note...',
                            hintStyle: AppTextStyles.bodyLarge.copyWith(color: AppColors.outline, fontWeight: FontWeight.w500),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      // Collapse/Expand toggle
                      MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => setState(() => _inputExpanded = !_inputExpanded),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 32, height: 32,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _inputExpanded ? Icons.expand_less : Icons.expand_more,
                              size: 18, color: AppColors.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Expanded details
                  AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Description field
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: TextField(
                              controller: _newNoteBodyCtrl,
                              maxLines: 3,
                              style: AppTextStyles.bodySmall,
                              decoration: InputDecoration(
                                hintText: 'Description (optionnel)...',
                                hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.outline),
                                border: InputBorder.none,
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Category label
                          Text('CATÉGORIE', style: AppTextStyles.labelSmall.copyWith(
                            letterSpacing: 1.2, fontWeight: FontWeight.w800, color: AppColors.onSurfaceVariant,
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

                          // Reminder toggle + Submit
                          Row(
                            children: [
                              // Reminder toggle
                              MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () => setState(() => _isReminderOn = !_isReminderOn),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: _isReminderOn
                                          ? AppColors.warning.withValues(alpha: 0.1)
                                          : AppColors.surfaceContainerLow,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(
                                        color: _isReminderOn ? AppColors.warning : AppColors.outlineVariant,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.alarm,
                                          size: 16,
                                          color: _isReminderOn ? AppColors.warning : AppColors.outline,
                                        ),
                                        const SizedBox(width: 6),
                                        Text('Rappel', style: AppTextStyles.labelSmall.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: _isReminderOn ? AppColors.warning : AppColors.outline,
                                        )),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
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
                                    _isReminderOn = false;
                                  }),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    child: Text('Annuler', style: AppTextStyles.labelMedium.copyWith(
                                      fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant,
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
                    crossFadeState: _inputExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 300),
                    sizeCurve: Curves.easeOutCubic,
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
                          color: active ? AppColors.primary : AppColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(tab, style: AppTextStyles.labelMedium.copyWith(
                          fontWeight: FontWeight.w600,
                          color: active ? Colors.white : AppColors.onSurfaceVariant,
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
                            color: AppColors.surfaceContainerLowest,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Center(
                            child: Column(
                              children: [
                                Icon(Icons.sticky_note_2_outlined, size: 48, color: AppColors.outline),
                                const SizedBox(height: 12),
                                Text('Aucune note trouvée', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.outline)),
                              ],
                            ),
                          ),
                        )
                      : Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: filteredNotes.map((note) => _NoteCard(
                            data: note,
                            onPin: () => setState(() => note.isPinned = !note.isPinned),
                            onDelete: () async {
                              try {
                                await provider.supprimerNote(note.id, note.entrepriseId);
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Note supprimée.'), backgroundColor: AppColors.success));
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
                        color: AppColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(16),
                        border: const Border(left: BorderSide(color: AppColors.primary, width: 4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('À FAIRE', style: AppTextStyles.labelSmall.copyWith(
                                letterSpacing: 1.5, fontWeight: FontWeight.w800, color: AppColors.primary,
                              )),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${_todos.where((t) => !t.done).length} restantes',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          ..._todos.map((todo) => _TodoRow(
                            item: todo,
                            onToggle: () => setState(() => todo.done = !todo.done),
                            onDelete: () => setState(() => _todos.remove(todo)),
                          )),
                          const SizedBox(height: 12),
                          // ─── Add Todo Input ───
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.add, size: 16, color: AppColors.outline),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _newTodoCtrl,
                                    onSubmitted: (_) => _addTodo(),
                                    style: AppTextStyles.bodySmall,
                                    decoration: InputDecoration(
                                      hintText: 'Ajouter une tâche...',
                                      hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.outline),
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 8),
                                    ),
                                  ),
                                ),
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: _addTodo,
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Icon(Icons.arrow_upward, size: 14, color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Upcoming Reminders
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('RAPPELS À VENIR', style: AppTextStyles.labelSmall.copyWith(
                            letterSpacing: 1.5, fontWeight: FontWeight.w800, color: AppColors.onSurfaceVariant,
                          )),
                          const SizedBox(height: 16),
                          ...allNotes.where((n) => n.estRappel).map((n) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              children: [
                                Container(
                                  width: 36, height: 36,
                                  decoration: BoxDecoration(
                                    color: AppColors.warning.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.alarm, size: 18, color: AppColors.warning),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(n.titre, style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w600),
                                          maxLines: 1, overflow: TextOverflow.ellipsis),
                                      Text(n.dateRappel != null ? '${n.dateRappel!.day}/${n.dateRappel!.month}/${n.dateRappel!.year}' : 'À définir',
                                          style: AppTextStyles.bodySmall.copyWith(fontSize: 10, color: AppColors.outline)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          )),
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
  final VoidCallback onDelete;

  const _NoteCard({required this.data, required this.onPin, required this.onDelete});

  @override
  State<_NoteCard> createState() => _NoteCardState();
}

class _NoteCardState extends State<_NoteCard> {
  bool _hovered = false;

  Color _getColorForTag(String tag) {
    switch (tag) {
      case 'Rappel': return const Color(0xFFE65100);
      case 'Contrats': return const Color(0xFF00695C);
      case 'RH': return const Color(0xFF2E7D32);
      case 'Formation': return const Color(0xFF6A1B9A);
      case 'Congés': return const Color(0xFF0277BD);
      case 'Recrutement': return const Color(0xFFC62828);
      default: return const Color(0xFF1A237E);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d = widget.data;
    final color = _getColorForTag(d.tag);
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
        transform: Matrix4.translationValues(0, _hovered ? -3 : 0, 0),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border(left: BorderSide(color: color, width: 4)),
          boxShadow: _hovered
              ? [BoxShadow(color: color.withValues(alpha: 0.12), blurRadius: 16, offset: const Offset(0, 6))]
              : [BoxShadow(color: AppColors.onSurface.withValues(alpha: 0.04), blurRadius: 4)],
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
                          size: 16, color: AppColors.onSurfaceVariant,
                        ),
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
            Text(d.titre, style: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700),
                maxLines: 2, overflow: TextOverflow.ellipsis),
            if (d.contenu.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(d.contenu, style: AppTextStyles.bodySmall.copyWith(color: AppColors.onSurfaceVariant, height: 1.4),
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
            Text(dateStr, style: AppTextStyles.bodySmall.copyWith(fontSize: 10, color: AppColors.outline)),
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
            color: _hovered ? AppColors.primary.withValues(alpha: 0.04) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 20, height: 20,
                decoration: BoxDecoration(
                  color: widget.item.done ? AppColors.primary : Colors.transparent,
                  border: Border.all(
                    color: widget.item.done ? AppColors.primary : AppColors.outline,
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
                    color: widget.item.done ? AppColors.outline : AppColors.onSurface,
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
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(10),
            boxShadow: _hovered
                ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 4))]
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

  @override
  Widget build(BuildContext context) {
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
                    ? AppColors.surfaceContainerHigh
                    : AppColors.surfaceContainerLow,
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
                  color: widget.isActive ? widget.cat.color : AppColors.onSurfaceVariant),
              const SizedBox(width: 6),
              Text(widget.cat.label, style: AppTextStyles.labelSmall.copyWith(
                fontWeight: widget.isActive ? FontWeight.w700 : FontWeight.w500,
                color: widget.isActive ? widget.cat.color : AppColors.onSurfaceVariant,
              )),
            ],
          ),
        ),
      ),
    );
  }
}
