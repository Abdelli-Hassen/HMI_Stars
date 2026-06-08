import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/models/models.dart';

class EmployeeDayList extends StatefulWidget {
  final DateTime day;
  const EmployeeDayList({super.key, required this.day});

  @override
  State<EmployeeDayList> createState() => _EmployeeDayListState();
}

class _EmployeeDayListState extends State<EmployeeDayList> {
  String _sortBy = 'default';

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final salaries = appState.getSalariesForDay(widget.day);
    final pointableSalaries = salaries.where((s) => !appState.isSalarieEnConge(s.id, widget.day)).toList();
    final allPointed = pointableSalaries.isNotEmpty && pointableSalaries.every((s) => appState.getPointageStatus(widget.day, s.id));

    final sorted = [...salaries];
    if (_sortBy == 'alphabetical') {
      sorted.sort((a, b) => a.nomComplet.toLowerCase().compareTo(b.nomComplet.toLowerCase()));
    } else {
      // Sort: non-pointed first, then secondary alphabetical
      sorted.sort((a, b) {
        final aPointed = appState.getPointageStatus(widget.day, a.id);
        final bPointed = appState.getPointageStatus(widget.day, b.id);
        if (aPointed == bPointed) {
          return a.nomComplet.toLowerCase().compareTo(b.nomComplet.toLowerCase());
        }
        return aPointed ? 1 : -1;
      });
    }

    final dateStr = _formatDate(widget.day);
    final isFuture = widget.day.isAfter(DateTime.now()) &&
        !(widget.day.year == DateTime.now().year &&
            widget.day.month == DateTime.now().month &&
            widget.day.day == DateTime.now().day);
    final hasActiveEmployees = salaries.any((s) => !appState.isSalarieEnConge(s.id, widget.day));

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 16),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Liste des Salariés',
                                style: GoogleFonts.manrope(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w800,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              Text(
                                dateStr,
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            PopupMenuButton<String>(
                              icon: Icon(
                                _sortBy == 'alphabetical' ? Icons.sort_by_alpha : Icons.sort,
                                color: Theme.of(context).colorScheme.primary,
                                size: 20,
                              ),
                              tooltip: 'Trier les salariés',
                              onSelected: (value) {
                                setState(() {
                                  _sortBy = value;
                                });
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'default',
                                  child: Row(
                                    children: [
                                      Icon(Icons.playlist_add_check, size: 18, color: Theme.of(context).colorScheme.primary),
                                      const SizedBox(width: 8),
                                      Text('Non pointés en premier', style: GoogleFonts.inter(fontSize: 13)),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'alphabetical',
                                  child: Row(
                                    children: [
                                      Icon(Icons.sort_by_alpha, size: 18, color: Theme.of(context).colorScheme.primary),
                                      const SizedBox(width: 8),
                                      Text('Ordre alphabétique', style: GoogleFonts.inter(fontSize: 13)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (!isFuture && hasActiveEmployees) ...[
                              const SizedBox(width: 4),
                              IconButton(
                                icon: Icon(
                                  allPointed ? Icons.remove_done : Icons.done_all,
                                  color: allPointed 
                                      ? Colors.red 
                                      : Theme.of(context).colorScheme.primary,
                                  size: 20,
                                ),
                                tooltip: allPointed ? 'Tout décocher' : 'Tout cocher',
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      backgroundColor: Theme.of(context).colorScheme.surface,
                                      title: Text(
                                        allPointed ? 'Tout décocher ?' : 'Tout cocher ?',
                                        style: GoogleFonts.manrope(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 18,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                      content: Text(
                                        allPointed
                                            ? 'Voulez-vous décocher la présence de tous les salariés actifs pour ce jour ?'
                                            : 'Voulez-vous cocher la présence de tous les salariés actifs pour ce jour ?',
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: Theme.of(context).colorScheme.onSurface,
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
                                          onPressed: () {
                                            Navigator.pop(ctx);
                                            for (var s in salaries) {
                                              final isConge = appState.isSalarieEnConge(s.id, widget.day);
                                              if (!isConge) {
                                                appState.setPointage(widget.day, s.id, !allPointed);
                                              }
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: allPointed 
                                                ? Colors.red 
                                                : Theme.of(context).colorScheme.primary,
                                            foregroundColor: Colors.white,
                                          ),
                                          child: Text(
                                            'Confirmer',
                                            style: GoogleFonts.inter(
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _sortBy == 'alphabetical' ? Icons.sort_by_alpha : Icons.sort,
                            size: 14,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _sortBy == 'alphabetical' ? 'Triage: Ordre alphabétique' : 'Triage: Non pointés en premier',
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Divider(
                color: Theme.of(context).colorScheme.outlineVariant,
                height: 1,
              ),
              // List
              Expanded(
                child: ListView.separated(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: sorted.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (ctx, idx) {
                    final salarie = sorted[idx];
                    final isPointed = appState.getPointageStatus(
                      widget.day,
                      salarie.id,
                    );
                    return _buildEmployeeRow(
                      context,
                      salarie,
                      isPointed,
                      appState,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmployeeRow(
    BuildContext context,
    Salarie salarie,
    bool isPointed,
    AppState appState,
  ) {
    final hasConge = appState.isSalarieEnConge(salarie.id, widget.day);
    final congeLabel = hasConge ? appState.getCongeDescriptionForSalarie(salarie.id, widget.day) : '';

    Color cardBg;
    Border? cardBorder;
    if (isPointed) {
      cardBg = Theme.of(context).colorScheme.surfaceContainerLow.withValues(alpha: 0.5);
      cardBorder = Border.all(color: Colors.green.withValues(alpha: 0.2));
    } else if (hasConge) {
      cardBg = Colors.blue.shade50.withValues(alpha: 0.3);
      cardBorder = Border.all(color: Colors.blue.withValues(alpha: 0.2));
    } else {
      cardBg = Theme.of(context).colorScheme.surfaceContainerLowest;
      cardBorder = null;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: cardBorder,
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHigh,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                salarie.prenom.isNotEmpty
                    ? salarie.prenom[0].toUpperCase()
                    : '?',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Name & status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  salarie.nomComplet,
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                if (isPointed)
                  Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 13),
                      const SizedBox(width: 4),
                      Text(
                        'Présence Validée',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  )
                else if (hasConge)
                  Row(
                    children: [
                      Icon(Icons.beach_access, color: Colors.blue, size: 13),
                      const SizedBox(width: 4),
                      Text(
                        'En Congé ($congeLabel)',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  )
                else
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Attente Vérification',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.orange.shade700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Description button + checkbox
          Row(
            children: [
              GestureDetector(
                onTap: () => _showNoteDialog(context, salarie, appState),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outlineVariant,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.notes,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Note',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // Checkbox
              Transform.scale(
                scale: 1.2,
                child: Checkbox(
                  value: isPointed,
                  onChanged: (hasConge || (widget.day.isAfter(DateTime.now()) &&
                          !(widget.day.year == DateTime.now().year &&
                              widget.day.month == DateTime.now().month &&
                              widget.day.day == DateTime.now().day)))
                      ? null
                      : (val) {
                          context.read<AppState>().setPointage(
                            widget.day,
                            salarie.id,
                            val ?? false,
                          );
                        },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  activeColor: Theme.of(context).colorScheme.tertiary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showNoteDialog(
    BuildContext context,
    Salarie salarie,
    AppState appState,
  ) {
    final noteController = TextEditingController(
      text: appState.getNoteForDay(widget.day, salarie.id),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              salarie.nomComplet,
              style: GoogleFonts.manrope(
                fontWeight: FontWeight.w800,
                fontSize: 18,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            Text(
              _formatDate(widget.day),
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'NOTE',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.primary,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: noteController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Écrire une note pour ce salarié...',
                hintStyle: GoogleFonts.inter(
                  fontSize: 13,
                  color: Theme.of(context).colorScheme.outlineVariant,
                ),
              ),
            ),
          ],
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
            onPressed: () {
              appState.setNote(widget.day, salarie.id, noteController.text);
              Navigator.pop(ctx);
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime day) {
    const months = [
      'Janvier',
      'Février',
      'Mars',
      'Avril',
      'Mai',
      'Juin',
      'Juillet',
      'Août',
      'Septembre',
      'Octobre',
      'Novembre',
      'Décembre',
    ];
    const weekdays = [
      'Lundi',
      'Mardi',
      'Mercredi',
      'Jeudi',
      'Vendredi',
      'Samedi',
      'Dimanche',
    ];
    return '${weekdays[day.weekday - 1]}, ${day.day} ${months[day.month - 1]} ${day.year}';
  }
}
