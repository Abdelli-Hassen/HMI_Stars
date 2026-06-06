import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../features/entreprises/presentation/providers/entreprise_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/main_shell.dart';
import '../../../../core/utils/translation_extension.dart';
import '../../../../core/supabase_config.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _kpiAnim;

  // Real-time dynamic stats
  int _realSalariesCount = 0;
  List<Map<String, dynamic>> _activeCompaniesStats = [];
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _kpiAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.35, curve: Curves.easeOutCubic),
    );
    _fadeAnim = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOutCubic),
    );

    _controller.forward();

    // Load initial data and real-time stats
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final ep = context.read<EntrepriseProvider>();
      ep.fetchEntreprises();
      ep.fetchAllNotes();
      _loadRealTimeStats();
    });
  }

  Future<void> _loadRealTimeStats() async {
    if (!mounted) return;
    setState(() => _loadingStats = true);

    try {
      final client = SupabaseConfig.adminClient;

      // 1. Fetch real total salaries count directly from database
      final salariesRes = await client.from('salaries').select('id');
      final totalSalaries = (salariesRes as List).length;

      // 2. Fetch all companies to compute activity
      final empresasRes = await client
          .from('entreprises')
          .select('id, raison_sociale, statut');
      final empresas = empresasRes as List;

      // 3. Fetch all messages and files to count them in memory (optimizes N-query loop to 2 queries)
      final messagesRes = await client.from('messages').select('entreprise_id');
      final filesRes = await client.from('fichiers').select('entreprise_id');

      final messagesList = messagesRes as List;
      final filesList = filesRes as List;

      final Map<String, int> messageCounts = {};
      final Map<String, int> fileCounts = {};

      for (var msg in messagesList) {
        final id = msg['entreprise_id'] as String?;
        if (id != null) {
          messageCounts[id] = (messageCounts[id] ?? 0) + 1;
        }
      }

      for (var file in filesList) {
        final id = file['entreprise_id'] as String?;
        if (id != null) {
          fileCounts[id] = (fileCounts[id] ?? 0) + 1;
        }
      }

      List<Map<String, dynamic>> stats = [];

      for (var emp in empresas) {
        final empId = emp['id'] as String;
        final name = emp['raison_sociale'] as String? ?? '';
        final statusText = emp['statut'] as String? ?? 'EN COURS';

        final msgCount = messageCounts[empId] ?? 0;
        final docCount = fileCounts[empId] ?? 0;
        final totalActivity = msgCount + docCount;

        stats.add({
          'id': empId,
          'name': name,
          'status': statusText,
          'msgCount': msgCount,
          'docCount': docCount,
          'activity': totalActivity,
        });
      }

      // Sort companies by activity score descending
      stats.sort((a, b) => (b['activity'] as int).compareTo(a['activity'] as int));

      if (mounted) {
        setState(() {
          _realSalariesCount = totalSalaries;
          _activeCompaniesStats = stats.take(5).toList();
          _loadingStats = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading real-time dashboard stats: $e');
      if (mounted) {
        setState(() => _loadingStats = false);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return MainShell(
      currentRoute: AppRoutes.dashboard,
      title: context.tr('HMI Stars - Tableau de Bord', 'HMI Stars - Dashboard'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Header ───
            FadeTransition(
              opacity: _kpiAnim,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, -0.1), end: Offset.zero).animate(_kpiAnim),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('Tableau de Bord RH', 'HR Dashboard'),
                          style: AppTextStyles.headlineMedium.copyWith(
                            color: cs.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // ─── KPI Cards Row ───
            Consumer<EntrepriseProvider>(
              builder: (context, entrepriseProvider, child) {
                return AnimatedBuilder(
                  animation: _kpiAnim,
                  builder: (context, _) {
                    final t = _kpiAnim.value;
                    final urgentAlertsCount = entrepriseProvider.allNotes.where((n) => n.estRappel).length;

                    // Display database dynamic counts or mockup values as fallback
                    final displayCompanies = _loadingStats ? '...' : (entrepriseProvider.totalEntreprises * t).round().toString();
                    final displaySalaries = _loadingStats ? '...' : (_realSalariesCount * t).round().toString();

                    return Opacity(
                      opacity: t,
                      child: Transform.translate(
                        offset: Offset(0, 15 * (1 - t)),
                        child: Row(
                          children: [
                            _KpiCard(
                              icon: Icons.business_outlined,
                              iconColor: cs.primary,
                              value: displayCompanies,
                              label: context.tr('ENTREPRISES CLIENTES', 'CLIENT COMPANIES'),
                              badge: context.tr('Totale des entreprises', 'Total Companies'),
                              badgeColor: cs.primary,
                            ),
                            const SizedBox(width: 16),
                            _KpiCard(
                              icon: Icons.people_outline,
                              iconColor: AppColors.success,
                              value: displaySalaries,
                              label: context.tr('SALARIÉS GÉRÉS', 'EMPLOYEES MANAGED'),
                              badge: context.tr('Effectif total', 'Total employees'),
                              badgeColor: AppColors.success,
                            ),
                            const SizedBox(width: 16),
                            _KpiCard(
                              icon: Icons.notifications_none_outlined,
                              iconColor: cs.primary,
                              value: (urgentAlertsCount * t).round().toString(),
                              label: context.tr('RAPPELS & ACTIONS URGENTES', 'REMINDERS & URGENT ACTIONS'),
                              badge: context.tr('Alertes actives', 'Active alerts'),
                              badgeColor: cs.primary,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 28),

            // ─── Bottom Sections Columns ───
            FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(_fadeAnim),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left: Top Active Companies
                    Expanded(
                      flex: 2,
                      child: _buildActiveCompaniesCard(),
                    ),
                    const SizedBox(width: 20),
                    // Right: Approaching Deadlines
                    Expanded(
                      child: _buildDeadlinesCard(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveCompaniesCard() {
    final cs = Theme.of(context).colorScheme;

    if (_loadingStats) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outline.withValues(alpha: 0.35)),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    // Determine the highest activity score for progress bar scaling
    final int highestActivity = _activeCompaniesStats.isNotEmpty 
        ? _activeCompaniesStats.first['activity'] as int 
        : 1;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.star_border, color: cs.primary, size: 22),
              const SizedBox(width: 10),
              Text(
                context.tr('Entreprises les Plus Actives', 'Top Active Companies'),
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Text(
              context.tr(
                'Classées par volume d\'échanges de messages et de fichiers importés sur la plateforme.',
                'Ranked by the volume of message exchanges and files uploaded on the platform.',
              ),
              style: AppTextStyles.bodySmall.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 20),
          if (_activeCompaniesStats.isEmpty)
            // Empty state view
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  context.tr('Aucune entreprise active pour le moment.', 'No active companies at the moment.'),
                  style: AppTextStyles.bodyMedium.copyWith(color: cs.outline),
                ),
              ),
            )
          else
            ..._activeCompaniesStats.map((item) {
              final String name = item['name'] as String;
              final int msg = item['msgCount'] as int;
              final int doc = item['docCount'] as int;
              final String status = item['status'] as String;
              final int activity = item['activity'] as int;

              // Calculate progress normalized against highest activity company
              final double progress = highestActivity > 0 
                  ? (activity / highestActivity).clamp(0.2, 1.0) 
                  : 0.5;

              Color progressColor = cs.primary;
              if (status == 'COMPLET') {
                progressColor = AppColors.success;
              }

              return _ActiveCompanyItem(
                name: name,
                stats: context.tr('$msg messages • $doc doc(s)', '$msg messages • $doc doc(s)'),
                status: status,
                progress: progress,
                progressColor: progressColor,
              );
            }),
        ],
      ),
    );
  }
  Widget _buildDeadlinesCard() {
    final cs = Theme.of(context).colorScheme;
    final entrepriseProvider = context.watch<EntrepriseProvider>();
    final notes = entrepriseProvider.allNotes
        .where((n) => n.estRappel && n.dateRappel != null)
        .toList();
    notes.sort((a, b) => a.dateRappel!.compareTo(b.dateRappel!));
    final closestNotes = notes.take(3).toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.access_time, color: cs.primary, size: 22),
              const SizedBox(width: 10),
              Text(
                context.tr('Échéances Proches', 'Approaching Deadlines'),
                style: AppTextStyles.titleMedium.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 32),
            child: Text(
              context.tr('Rappels critiques à traiter en priorité.', 'Critical reminders to process first.'),
              style: AppTextStyles.bodySmall.copyWith(color: cs.onSurfaceVariant),
            ),
          ),
          const SizedBox(height: 20),
          if (closestNotes.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Text(
                  context.tr('Aucune échéance à venir pour le moment.', 'No upcoming deadlines at the moment.'),
                  style: AppTextStyles.bodyMedium.copyWith(color: cs.outline),
                ),
              ),
            )
          else
            ...closestNotes.map((note) => _DeadlineItem(
                  title: note.titre,
                  description: note.contenu,
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.urgents,
                      arguments: note.id,
                    );
                  },
                )),
        ],
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: cs.outline.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    value,
                    style: AppTextStyles.displaySmall.copyWith(
                      color: cs.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 32,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    badge,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: badgeColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActiveCompanyItem extends StatelessWidget {
  final String name;
  final String stats;
  final String status;
  final double progress;
  final Color progressColor;

  const _ActiveCompanyItem({
    required this.name,
    required this.stats,
    required this.status,
    required this.progress,
    required this.progressColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                name,
                style: AppTextStyles.titleSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    stats,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: cs.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: progressColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: progressColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      status,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: progressColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 9,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(2),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: cs.outlineVariant.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeadlineItem extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback? onTap;

  const _DeadlineItem({
    required this.title,
    required this.description,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.notifications_none_outlined,
                    color: cs.primary,
                    size: 16,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: AppTextStyles.labelLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: cs.onSurfaceVariant,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
