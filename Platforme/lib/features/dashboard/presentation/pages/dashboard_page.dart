import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../features/entreprises/presentation/providers/entreprise_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/main_shell.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _barAnim;
  late Animation<double> _donutAnim;
  late Animation<double> _fadeAnim;
  late Animation<double> _kpiAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    _kpiAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOutCubic),
    );
    _barAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.15, 0.65, curve: Curves.easeOutCubic),
    );
    _donutAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.25, 0.75, curve: Curves.easeOutCubic),
    );
    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
    );

    _controller.forward();

    // Charger les données initiales (entreprises, stats, etc.)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<EntrepriseProvider>().fetchEntreprises();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MainShell(
      currentRoute: AppRoutes.dashboard,
      title: 'HMI Stars - Tableau de Bord RH',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header ───
            FadeTransition(
              opacity: _kpiAnim,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, -0.2), end: Offset.zero).animate(_kpiAnim),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tableau de Bord RH', style: AppTextStyles.headlineMedium),
                    const SizedBox(height: 4),
                    Text('Bienvenue, voici un aperçu de votre gestion actuelle.',
                        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.onSurfaceVariant)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

          // ─── KPI Cards (animated counter) ───
          Consumer<EntrepriseProvider>(
            builder: (context, entrepriseProvider, child) {
              return AnimatedBuilder(
                animation: _kpiAnim,
                builder: (context, _) {
                  final t = _kpiAnim.value;
                  return Opacity(
                    opacity: t,
                    child: Transform.translate(
                      offset: Offset(0, 20 * (1 - t)),
                      child: Row(
                        children: [
                          _KpiCard(
                            icon: Icons.business, iconColor: AppColors.primary,
                            value: (entrepriseProvider.totalEntreprises * t).round().toString(), label: 'Total Entreprises',
                            badge: "Portefeuille", badgeColor: AppColors.success,
                          ),
                          const SizedBox(width: 16),
                          _KpiCard(
                            icon: Icons.work_history, iconColor: AppColors.warning,
                            value: (entrepriseProvider.dossiersEnCours * t).round().toString(), label: 'En Cours',
                            badge: "Aujourd'hui", badgeColor: AppColors.primary,
                          ),
                          const SizedBox(width: 16),
                          _KpiCard(
                            icon: Icons.hourglass_empty, iconColor: AppColors.primary,
                            value: (entrepriseProvider.dossiersEnAttente * t).round().toString(), label: 'En Attente',
                            badge: 'Documents', badgeColor: AppColors.primary,
                          ),
                          const SizedBox(width: 16),
                          _KpiCard(
                            icon: Icons.check_circle_outline, iconColor: AppColors.success,
                            value: (entrepriseProvider.entreprises.where((e) => e.statut == 'COMPLET').length * t).round().toString(), label: 'Dossiers Complets',
                            badge: 'Historique', badgeColor: AppColors.success,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          const SizedBox(height: 24),

          // ─── Charts Row (animated) ───
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bar Chart
              Expanded(
                flex: 2,
                child: AnimatedBuilder(
                  animation: _barAnim,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _barAnim.value.clamp(0.0, 1.0),
                      child: Transform.translate(
                        offset: Offset(0, 30 * (1 - _barAnim.value)),
                        child: _buildBarChartCard(_barAnim.value, context),
                      ),
                    );
                  },
                ),
              ),
                const SizedBox(width: 16),
                // Donut Chart
                Expanded(
                  child: AnimatedBuilder(
                    animation: _donutAnim,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _donutAnim.value.clamp(0.0, 1.0),
                        child: Transform.translate(
                          offset: Offset(0, 30 * (1 - _donutAnim.value)),
                          child: _buildDonutChartCard(_donutAnim.value),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // ─── Actions & Calendar ───
            FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(_fadeAnim),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 2, child: _buildActionsCard()),
                    const SizedBox(width: 16),
                    Expanded(child: _buildCalendarCard()),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChartCard(double animProgress, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Statistiques RH', style: AppTextStyles.titleMedium),
              Container(
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    _chartToggle('Mensuel', true),
                    _chartToggle('Annuel', false),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 30,
                barGroups: [
                  _makeBarGroup(0, 22 * animProgress, 18 * animProgress),
                  _makeBarGroup(1, 15 * animProgress, 20 * animProgress),
                  _makeBarGroup(2, 25 * animProgress, 22 * animProgress),
                  _makeBarGroup(3, 18 * animProgress, 16 * animProgress),
                  _makeBarGroup(4, 20 * animProgress, 24 * animProgress),
                  _makeBarGroup(5, 28 * animProgress, 20 * animProgress),
                ],
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        rod.toY.round().toString(),
                        AppTextStyles.labelSmall.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                      );
                    },
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const labels = ['JAN', 'FEV', 'MAR', 'AVR', 'MAI', 'JUIN'];
                        if (value.toInt() >= labels.length) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(labels[value.toInt()],
                              style: AppTextStyles.labelSmall.copyWith(fontSize: 10)),
                        );
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
              ),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _chartLegend(AppColors.primary, 'Nouveaux Recrutements'),
              const SizedBox(width: 24),
              _chartLegend(AppColors.surfaceContainerHigh, 'Objectifs Atteints'),
            ],
          ),
        ],
      ),
    );
  }

  BarChartGroupData _makeBarGroup(int x, double v1, double v2) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(toY: v1, color: AppColors.primary, width: 12, borderRadius: BorderRadius.circular(4)),
        BarChartRodData(toY: v2, color: AppColors.surfaceContainerHigh, width: 12, borderRadius: BorderRadius.circular(4)),
      ],
    );
  }

  Widget _chartToggle(String label, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: active ? AppColors.surfaceContainerLowest : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label,
          style: AppTextStyles.labelMedium.copyWith(
            color: active ? AppColors.onSurface : AppColors.onSurfaceVariant,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
          )),
    );
  }

  Widget _chartLegend(Color color, String text) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(text, style: AppTextStyles.bodySmall),
      ],
    );
  }

  Widget _buildDonutChartCard(double animProgress) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Répartition RH', style: AppTextStyles.titleMedium),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: Stack(
              alignment: Alignment.center,
              children: [
                PieChart(
                  PieChartData(
                    sections: [
                      PieChartSectionData(
                        value: 65 * animProgress,
                        color: AppColors.primary,
                        radius: 24,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        value: 25 * animProgress,
                        color: AppColors.surfaceContainerHigh,
                        radius: 24,
                        showTitle: false,
                      ),
                      PieChartSectionData(
                        value: 10 * animProgress,
                        color: AppColors.tertiary,
                        radius: 24,
                        showTitle: false,
                      ),
                      if (animProgress < 1.0)
                        PieChartSectionData(
                          value: 100 * (1 - animProgress),
                          color: AppColors.surfaceContainerLow,
                          radius: 24,
                          showTitle: false,
                        ),
                    ],
                    centerSpaceRadius: 50,
                    sectionsSpace: 2,
                    startDegreeOffset: -90,
                  ),
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOutCubic,
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TweenAnimationBuilder<int>(
                      tween: IntTween(begin: 0, end: 150),
                      duration: const Duration(milliseconds: 1500),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) => Text(
                        '$value',
                        style: AppTextStyles.headlineMedium,
                      ),
                    ),
                    Text('TOTAL', style: AppTextStyles.labelSmall.copyWith(letterSpacing: 1)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _donutLegend(AppColors.primary, 'CDI', '65%'),
          const SizedBox(height: 8),
          _donutLegend(AppColors.surfaceContainerHigh, 'CDD / Stage', '25%'),
          const SizedBox(height: 8),
          _donutLegend(AppColors.tertiary, 'Freelance', '10%'),
        ],
      ),
    );
  }

  Widget _donutLegend(Color color, String label, String pct) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.onSurface)),
        const Spacer(),
        Text(pct, style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }

  Widget _buildActionsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Actions & Notifications', style: AppTextStyles.titleMedium),
              Text('Voir tout',
                  style: AppTextStyles.labelMedium.copyWith(color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 20),
          _actionItem(
            Icons.warning_amber_rounded, AppColors.error,
            'Vérification de la Paie',
            'Validation finale nécessaire pour le mois de Juin.',
            badge: 'URGENT', badgeColor: AppColors.error,
          ),
          const SizedBox(height: 16),
          _actionItem(
            Icons.assignment_outlined, AppColors.primary,
            "Validation d'Entretien",
            'Candidat : Marc Lefebvre - Développeur Senior.',
            badge: 'Valider', badgeColor: AppColors.primary,
          ),
          const SizedBox(height: 16),
          _actionItem(
            Icons.calendar_today, AppColors.onSurfaceVariant,
            'Planning Annuel',
            "Mise à jour du calendrier des congés d'été.",
            badge: 'IL Y A 2H', badgeColor: AppColors.outline,
            hasBadgeBg: false,
          ),
        ],
      ),
    );
  }

  Widget _actionItem(IconData icon, Color iconColor, String title, String subtitle,
      {String? badge, Color? badgeColor, bool hasBadgeBg = true}) {
    return Row(
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTextStyles.labelLarge),
              Text(subtitle, style: AppTextStyles.bodySmall),
            ],
          ),
        ),
        if (badge != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: hasBadgeBg ? badgeColor : Colors.transparent,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(badge,
                style: AppTextStyles.labelSmall.copyWith(
                  color: hasBadgeBg ? Colors.white : badgeColor,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                )),
          ),
      ],
    );
  }

  Widget _buildCalendarCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Calendrier', style: AppTextStyles.titleMedium),
              Row(
                children: [
                  Icon(Icons.chevron_left, size: 18, color: AppColors.outline),
                  const SizedBox(width: 8),
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 18),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: Text('Juin 2026',
                style: AppTextStyles.labelLarge.copyWith(color: AppColors.primary)),
          ),
          const SizedBox(height: 12),

          // Day Headers
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: ['L', 'M', 'M', 'J', 'V', 'S', 'D']
                .map((d) => SizedBox(
                      width: 30,
                      child: Center(
                          child: Text(d,
                              style: AppTextStyles.labelSmall.copyWith(
                                fontWeight: FontWeight.w600,
                              ))),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),

          // Week rows
          _buildWeekRow([27, 28, 29, 30, 1, 2, 3], grayed: [27, 28, 29, 30]),
          _buildWeekRow([4, 5, 6, 7, 8, 9, 10], highlighted: [5]),
          _buildWeekRow([11, 12, 13, 14, 15, 16, 17], accent: [12]),

          const SizedBox(height: 16),

          // Events
          _calEvent(AppColors.primary, 'Réunion d\'équipe - 14:00'),
          const SizedBox(height: 8),
          _calEvent(AppColors.error, 'Clôture des congés - 17:00'),
        ],
      ),
    );
  }

  Widget _buildWeekRow(List<int> days,
      {List<int> grayed = const [],
      List<int> highlighted = const [],
      List<int> accent = const []}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: days
            .map((d) => Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(
                    color: highlighted.contains(d)
                        ? AppColors.primary
                        : accent.contains(d)
                            ? AppColors.error
                            : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text('$d',
                        style: AppTextStyles.bodySmall.copyWith(
                          fontSize: 12,
                          color: highlighted.contains(d) || accent.contains(d)
                              ? Colors.white
                              : grayed.contains(d)
                                  ? AppColors.outline
                                  : AppColors.onSurface,
                          fontWeight: highlighted.contains(d)
                              ? FontWeight.w700
                              : FontWeight.w400,
                        )),
                  ),
                ))
            .toList(),
      ),
    );
  }

  Widget _calEvent(Color color, String text) {
    return Row(
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: AppTextStyles.bodySmall.copyWith(color: AppColors.onSurface))),
      ],
    );
  }
}

class _KpiCard extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final String badge;
  final Color badgeColor;

  const _KpiCard({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    required this.badge,
    required this.badgeColor,
  });

  @override
  State<_KpiCard> createState() => _KpiCardState();
}

class _KpiCardState extends State<_KpiCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.all(20),
          transform: Matrix4.translationValues(0.0, _hovered ? -4.0 : 0.0, 0.0),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border(
              left: BorderSide(color: AppColors.primary, width: 3),
            ),
            boxShadow: _hovered
                ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.08), blurRadius: 16, offset: const Offset(0, 8))]
                : [],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _hovered
                          ? widget.iconColor.withValues(alpha: 0.15)
                          : widget.iconColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(widget.icon, color: widget.iconColor, size: 22),
                  ),
                  Text(widget.badge,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: widget.badgeColor,
                        fontWeight: FontWeight.w600,
                      )),
                ],
              ),
              const SizedBox(height: 12),
              Text(widget.value, style: AppTextStyles.headlineMedium),
              const SizedBox(height: 2),
              Text(widget.label, style: AppTextStyles.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
