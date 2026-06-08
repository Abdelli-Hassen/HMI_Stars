import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/app_state.dart';
import '../../core/models/models.dart';
import '../../core/widgets/app_header.dart';
import 'widgets/employee_day_list.dart';

class PointagePage extends StatefulWidget {
  const PointagePage({super.key});

  @override
  State<PointagePage> createState() => _PointagePageState();
}

class _PointagePageState extends State<PointagePage> {
  bool _isBlockView = true;
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    // Load pointages for the current month and conges from Supabase
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final appState = context.read<AppState>();
      appState.loadPointagesForMonth(DateTime.now(), force: true);
      appState.loadConges();
    });
  }

  Color _dayColor(StatutJour statut) {
    switch (statut) {
      case StatutJour.complet:
        return Colors.green;
      case StatutJour.incomplet:
        return Colors.orange;
      case StatutJour.absent:
        return Colors.red;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          AppHeader.sliver(
            context: context,
            actions: [
              IconButton(
                icon: Icon(
                  Icons.calendar_month_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                tooltip: 'Choisir mois/année',
                onPressed: () async {
                  final appState = context.read<AppState>();
                  final picked = await _showMonthYearPicker(context, _focusedDay);
                  if (picked != null) {
                    setState(() {
                      _focusedDay = picked;
                      _selectedDay = picked;
                    });
                    appState.loadPointagesForMonth(picked, force: true);
                  }
                },
              ),
              IconButton(
                icon: Icon(
                  Icons.beach_access_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                tooltip: 'Gestion des congés',
                onPressed: () => context.go('/conges'),
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Pointage',
                              style: GoogleFonts.manrope(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: Theme.of(context).colorScheme.primary,
                                letterSpacing: -0.5,
                              ),
                            ),
                            Text(
                              'Gestion des présences journalières',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // View toggle
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            _buildViewToggle(Icons.grid_view, 'Block', true),
                            _buildViewToggle(
                              Icons.format_list_bulleted,
                              'Liste',
                              false,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Legend
                  Row(
                    children: [
                      _buildLegend(Colors.green, 'Complet'),
                      const SizedBox(width: 16),
                      _buildLegend(Colors.orange, 'Incomplet'),
                      const SizedBox(width: 16),
                      _buildLegend(Colors.red, 'Absent'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Calendar
                  _isBlockView
                      ? _buildBlockCalendar(appState)
                      : _buildListCalendar(appState),
                  const SizedBox(height: 20),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggle(IconData icon, String label, bool isBlock) {
    final isActive = _isBlockView == isBlock;
    return GestureDetector(
      onTap: () => setState(() => _isBlockView = isBlock),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? Theme.of(context).colorScheme.surfaceContainerLowest
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildBlockCalendar(AppState appState) {
    final startYear = appState.parametres?.dateCreation?.year ?? 2025;
    return TableCalendar(
      firstDay: DateTime.utc(startYear, 1, 1),
      lastDay: DateTime.now().add(const Duration(days: 365)),
      focusedDay: _focusedDay,
      selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selectedDay = selectedDay;
          _focusedDay = focusedDay;
        });
        
        // Ensure data is loaded
        final appState = context.read<AppState>();
        appState.loadPointagesForMonth(selectedDay);
        
        _showDayDetails(context, selectedDay, appState);
      },
      onPageChanged: (focusedDay) {
        setState(() => _focusedDay = focusedDay);
        // Load the newly visible month's pointages and conges
        final appState = context.read<AppState>();
        appState.loadPointagesForMonth(focusedDay, force: true);
        appState.loadConges();
      },
      calendarStyle: CalendarStyle(
        outsideDaysVisible: false,
        todayDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.tertiary.withOpacity(0.2),
          shape: BoxShape.circle,
        ),
        todayTextStyle: TextStyle(
          color: Theme.of(context).colorScheme.tertiary,
          fontWeight: FontWeight.w800,
        ),
        selectedDecoration: BoxDecoration(
          color: Theme.of(context).colorScheme.tertiary,
          shape: BoxShape.circle,
        ),
        selectedTextStyle: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
        defaultTextStyle: TextStyle(
          color: Theme.of(context).colorScheme.primary,
        ),
        weekendTextStyle: TextStyle(
          color: Theme.of(context).colorScheme.secondary,
        ),
      ),
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, date, events) {
          final isFuture = date.isAfter(DateTime.now()) && !isSameDay(date, DateTime.now());
          if (isFuture) {
            // Check if any employee is on leave on this day
            bool anyOnLeave = false;
            for (final s in appState.salaries) {
              if (appState.isSalarieEnConge(s.id, date)) {
                anyOnLeave = true;
                break;
              }
            }
            if (!anyOnLeave) return const SizedBox.shrink();
          }

          final statut = appState.getStatutJour(date);
          return Positioned(
            bottom: 2,
            child: Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: _dayColor(statut),
                shape: BoxShape.circle,
              ),
            ),
          );
        },
      ),
      headerStyle: HeaderStyle(
        formatButtonVisible: false,
        titleTextStyle: GoogleFonts.manrope(
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary,
          fontSize: 16,
        ),
        leftChevronIcon: Icon(
          Icons.chevron_left,
          color: Theme.of(context).colorScheme.primary,
        ),
        rightChevronIcon: Icon(
          Icons.chevron_right,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  Widget _buildListCalendar(AppState appState) {
    final now = DateTime.now();
    final year = _focusedDay.year;
    final month = _focusedDay.month;
    
    // Dernier jour du mois visé
    final lastDayOfMonth = DateTime(year, month + 1, 0);
    final totalDays = lastDayOfMonth.day;
    
    final List<DateTime> days = [];
    for (int i = 1; i <= totalDays; i++) {
      final day = DateTime(year, month, i);
      final isFuture = day.isAfter(now) && !isSameDay(day, now);
      if (!isFuture) {
        days.add(day);
      } else {
        // If it's a future day, only add it if at least one employee is on leave
        bool anyOnLeave = false;
        for (final s in appState.salaries) {
          if (appState.isSalarieEnConge(s.id, day)) {
            anyOnLeave = true;
            break;
          }
        }
        if (anyOnLeave) {
          days.add(day);
        }
      }
    }

    if (days.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 40),
          child: Column(
            children: [
              Icon(
                Icons.calendar_today_outlined,
                size: 48,
                color: Theme.of(context).colorScheme.outline.withOpacity(0.5),
              ),
              const SizedBox(height: 12),
              Text(
                'Aucun jour à afficher pour ce mois',
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: days.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, idx) {
        final day = days[idx];
        final statut = appState.getStatutJour(day);
        final color = _dayColor(statut);
        return GestureDetector(
          onTap: () => _showDayDetails(context, day, appState),
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _formatDay(day),
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _statutLabel(statut),
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        Icon(
                          Icons.chevron_right,
                          color: Theme.of(context).colorScheme.outline,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }


  void _showDayDetails(BuildContext context, DateTime day, AppState appState) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EmployeeDayList(day: day),
    );
  }

  String _formatDay(DateTime day) {
    const months = [
      'Jan',
      'Fév',
      'Mar',
      'Avr',
      'Mai',
      'Jun',
      'Jul',
      'Aoû',
      'Sep',
      'Oct',
      'Nov',
      'Déc',
    ];
    const weekdays = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
    return '${weekdays[day.weekday - 1]} ${day.day} ${months[day.month - 1]} ${day.year}';
  }

  String _statutLabel(StatutJour statut) {
    switch (statut) {
      case StatutJour.complet:
        return 'Pointage complet';
      case StatutJour.incomplet:
        return 'Pointage incomplet';
      case StatutJour.absent:
        return 'Aucun pointage';
    }
  }

  Future<DateTime?> _showMonthYearPicker(BuildContext context, DateTime initialDate) async {
    int selectedYear = initialDate.year;
    int selectedMonth = initialDate.month;
    
    final appState = context.read<AppState>();
    final int startYear = appState.parametres?.dateCreation?.year ?? 2025;
    final int currentYear = DateTime.now().year;
    final int endYear = currentYear;
    final int range = (endYear - startYear + 1).clamp(1, 50);
    
    final List<int> years = List.generate(range, (index) => startYear + index);
    final List<String> months = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];

    return showDialog<DateTime>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final cs = Theme.of(context).colorScheme;
            return AlertDialog(
              title: const Text('Sélectionner mois / année'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Year Selection dropdown
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Année :', style: TextStyle(fontWeight: FontWeight.bold)),
                      DropdownButton<int>(
                        value: selectedYear,
                        dropdownColor: cs.surfaceContainerHighest,
                        items: years.map((y) => DropdownMenuItem(
                          value: y,
                          child: Text(y.toString()),
                        )).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setStateDialog(() => selectedYear = val);
                          }
                        },
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  // Month selection grid
                  SizedBox(
                    width: 320,
                    height: 200,
                    child: GridView.builder(
                      shrinkWrap: true,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 2.2,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                      ),
                      itemCount: 12,
                      itemBuilder: (context, index) {
                        final monthNum = index + 1;
                        final isSelected = selectedMonth == monthNum;
                        return InkWell(
                          onTap: () {
                            setStateDialog(() => selectedMonth = monthNum);
                          },
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isSelected ? cs.primary : cs.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? cs.primary : cs.outlineVariant,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              months[index],
                              style: TextStyle(
                                color: isSelected ? cs.onPrimary : cs.onSurface,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(DateTime(selectedYear, selectedMonth, 1));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: cs.primary,
                    foregroundColor: cs.onPrimary,
                  ),
                  child: const Text('OK'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
