import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/providers/app_state.dart';
import '../../../core/models/models.dart';
import '../../../core/utils/translation_extension.dart';

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

    final dateStr = _formatDate(context, widget.day);
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
                                context.tr('Liste des Salariés', 'Employee List'),
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
                              tooltip: context.tr('Trier les salariés', 'Sort employees'),
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
                                      Text(context.tr('Non pointés en premier', 'Not pointed first'), style: GoogleFonts.inter(fontSize: 13)),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: 'alphabetical',
                                  child: Row(
                                    children: [
                                      Icon(Icons.sort_by_alpha, size: 18, color: Theme.of(context).colorScheme.primary),
                                      const SizedBox(width: 8),
                                      Text(context.tr('Ordre alphabétique', 'Alphabetical order'), style: GoogleFonts.inter(fontSize: 13)),
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
                                tooltip: allPointed ? context.tr('Tout décocher', 'Uncheck all') : context.tr('Tout cocher', 'Check all'),
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      backgroundColor: Theme.of(context).colorScheme.surface,
                                      title: Text(
                                        allPointed ? context.tr('Tout décocher ?', 'Uncheck all?') : context.tr('Tout cocher ?', 'Check all?'),
                                        style: GoogleFonts.manrope(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 18,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                      content: Text(
                                        allPointed
                                            ? context.tr('Voulez-vous décocher la présence de tous les salariés actifs pour ce jour ?', 'Do you want to uncheck attendance for all active employees for this day?')
                                            : context.tr('Voulez-vous cocher la présence de tous les salariés actifs pour ce jour ?', 'Do you want to check attendance for all active employees for this day?'),
                                        style: GoogleFonts.inter(
                                          fontSize: 14,
                                          color: Theme.of(context).colorScheme.onSurface,
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
                                            context.tr('Confirmer', 'Confirm'),
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
                            _sortBy == 'alphabetical' 
                                ? context.tr('Triage: Ordre alphabétique', 'Sorting: Alphabetical') 
                                : context.tr('Triage: Non pointés en premier', 'Sorting: Unpointed first'),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                if (isPointed)
                  Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green, size: 13),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          context.tr('Présence Validée', 'Attendance Validated'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  )
                else if (hasConge)
                  Row(
                    children: [
                      const Icon(Icons.beach_access, color: Colors.blue, size: 13),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          context.tr('En Congé ($congeLabel)', 'On Leave ($congeLabel)'),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.blue,
                          ),
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
                      context.tr('Attente Vérification', 'Awaiting Verification'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                        context.tr('Note', 'Note'),
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
    final conge = appState.getCongeForSalarieOnDay(salarie.id, widget.day);
    final rawNote = appState.getNoteForDay(widget.day, salarie.id) ?? '';
    final noteController = TextEditingController(
      text: rawNote,
    );

    // Parse leave type and comment from note if it starts with known types
    String? parsedTypeLabel;
    String? parsedMotif;

    if (conge != null) {
      parsedTypeLabel = conge.estDemiJournee 
          ? '${_getCongeTypeLabel(context, conge.typeConge)} ${context.trStatic('(Demi-journée)', '(Half-day)')}' 
          : _getCongeTypeLabel(context, conge.typeConge);
      parsedMotif = conge.commentaire.isNotEmpty ? conge.commentaire : context.trStatic('Aucun commentaire', 'No comment');
    } else if (rawNote.isNotEmpty) {
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
        if (rawNote.startsWith(prefix)) {
          parsedTypeLabel = prefix;
          final remaining = rawNote.substring(prefix.length).trim();
          if (remaining.startsWith(':')) {
            parsedMotif = remaining.substring(1).trim();
          } else {
            parsedMotif = remaining;
          }
          if (parsedMotif.isEmpty) {
            parsedMotif = context.trStatic('Aucun commentaire', 'No comment');
          }
          break;
        }
      }
    }

    final isSeparatedView = conge != null || parsedTypeLabel != null;

    // Define accent colors and icons based on leave type to create clear visual identity
    Color accentColor = Theme.of(context).colorScheme.primary;
    Color containerBg = Theme.of(context).colorScheme.primary.withOpacity(0.04);
    Color borderColor = Theme.of(context).colorScheme.primary.withOpacity(0.15);
    IconData typeIcon = Icons.event_note_rounded;

    if (parsedTypeLabel != null) {
      final label = parsedTypeLabel.toLowerCase();
      if (label.contains('payé')) {
        accentColor = const Color(0xFF1E88E5); // Modern Blue
        containerBg = const Color(0xFFE3F2FD); // Light Blue tint
        borderColor = const Color(0xFF90CAF9);
        typeIcon = Icons.beach_access_rounded;
      } else if (label.contains('maladie') || label.contains('arrêt') || label.contains('malad')) {
        accentColor = const Color(0xFFE53935); // Modern Red
        containerBg = const Color(0xFFFFEBEE); // Light Red tint
        borderColor = const Color(0xFFEF9A9A);
        typeIcon = Icons.healing_rounded;
      } else if (label.contains('rtt')) {
        accentColor = const Color(0xFF8E24AA); // Modern Purple
        containerBg = const Color(0xFFF3E5F5); // Light Purple tint
        borderColor = const Color(0xFFCE93D8);
        typeIcon = Icons.timelapse_rounded;
      } else if (label.contains('exceptionnel')) {
        accentColor = const Color(0xFFD81B60); // Pink/Magenta
        containerBg = const Color(0xFFFCE4EC); // Light Pink tint
        borderColor = const Color(0xFFF48FB1);
        typeIcon = Icons.star_rounded;
      } else {
        accentColor = const Color(0xFF455A64); // Slate/Grey-Blue
        containerBg = const Color(0xFFECEFF1); // Light Slate tint
        borderColor = const Color(0xFFB0BEC5);
        typeIcon = Icons.event_busy_rounded;
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent, // Prevents Material 3 tinting overlay
        elevation: 16,
        title: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: accentColor.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSeparatedView ? typeIcon : Icons.edit_note_rounded,
                    color: accentColor,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        salarie.nomComplet,
                        style: GoogleFonts.manrope(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatDate(context, widget.day),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Divider(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.4), height: 1),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isSeparatedView) ...[
              Text(
                context.tr('TYPE DE CONGÉ / ABSENCE', 'LEAVE TYPE / ABSENCE'),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.8),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: containerBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: borderColor,
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withOpacity(0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(
                      typeIcon,
                      size: 20,
                      color: accentColor,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        parsedTypeLabel ?? '',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: accentColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Text(
                context.tr('MOTIF / COMMENTAIRE', 'REASON / COMMENT'),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.8),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 120),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.8),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 18,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        parsedMotif ?? '',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          height: 1.5,
                          fontWeight: FontWeight.w500,
                          color: (parsedMotif != null && parsedMotif != context.trStatic('Aucun commentaire', 'No comment'))
                              ? Theme.of(context).colorScheme.onSurface
                              : Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Text(
                context.tr('NOTE / COMMENTAIRE', 'NOTE / COMMENT'),
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.8),
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: noteController,
                  maxLines: 8,
                  decoration: InputDecoration(
                    hintText: context.tr('Écrire une note pour ce salarié...', 'Write a note for this employee...'),
                    hintStyle: GoogleFonts.inter(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant,
                        width: 1.2,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.8),
                        width: 1.2,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(
                        color: Theme.of(context).colorScheme.primary,
                        width: 1.5,
                      ),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ]
          ],
        ),
        actionsPadding: const EdgeInsets.only(bottom: 20, right: 20, left: 20),
        actions: [
          if (isSeparatedView) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                  shadowColor: accentColor.withOpacity(0.3),
                ),
                child: Text(
                  context.tr('Fermer', 'Close'),
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ] else ...[
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                        color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      context.tr('Annuler', 'Cancel'),
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Theme.of(context).colorScheme.outline,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      appState.setNote(widget.day, salarie.id, noteController.text);
                      Navigator.pop(ctx);
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                      shadowColor: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    ),
                    child: Text(
                      context.tr('Enregistrer', 'Save'),
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _getCongeTypeLabel(BuildContext context, String type) {
    switch (type) {
      case 'conge_paye':
        return context.trStatic('Congé Payé', 'Paid Leave');
      case 'maladie':
        return context.trStatic('Arrêt Maladie', 'Sick Leave');
      case 'rtt':
        return context.trStatic('RTT', 'RTT');
      case 'exceptionnel':
        return context.trStatic('Congé Exceptionnel', 'Special Leave');
      default:
        return context.trStatic('Autre Absence', 'Other Absence');
    }
  }

  String _formatDate(BuildContext context, DateTime day) {
    final state = Provider.of<AppState>(context, listen: false);
    final isEn = state.langue == 'English (EN)';
    final months = isEn
        ? [
            'January',
            'February',
            'March',
            'April',
            'May',
            'June',
            'July',
            'August',
            'September',
            'October',
            'November',
            'December',
          ]
        : [
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
    final weekdays = isEn
        ? [
            'Monday',
            'Tuesday',
            'Wednesday',
            'Thursday',
            'Friday',
            'Saturday',
            'Sunday',
          ]
        : [
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
