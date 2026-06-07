import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/providers/app_state.dart';
import '../../core/models/models.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/salarie_avatar.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final salariesActifs = appState.salaries.length;
    final params = appState.parametres;

    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);
    final congesAujourdhui = appState.conges.where((c) {
      final start = DateTime(c.dateDebut.year, c.dateDebut.month, c.dateDebut.day);
      final end = DateTime(c.dateFin.year, c.dateFin.month, c.dateFin.day);
      return (c.statut == 'approuve') &&
          (start.isBefore(todayKey) || start.isAtSameMomentAs(todayKey)) &&
          (end.isAfter(todayKey) || end.isAtSameMomentAs(todayKey));
    }).length;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Top App Bar
          AppHeader.sliver(context: context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    'TABLEAU DE BORD DIRIGEANT',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.tertiary,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Bonjour, ${params?.nomGerant ?? 'Admin'}',
                    style: GoogleFonts.manrope(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.primary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Aperçu global de l\'activité, des présences, et des urgences institutionnelles pour aujourd\'hui.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Key Metrics Map
                  _buildKPISection(context, salariesActifs, congesAujourdhui),
                  const SizedBox(height: 24),

                  // Notifications & Alerts
                  _buildRecentAlerts(context),
                  const SizedBox(height: 24),

                  // Leave Management
                  _buildLeaveManagementSection(context),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKPISection(BuildContext context, int salariesActifs, int congesAujourdhui) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildKPICard(
                context,
                title: 'Effectif',
                value: '$salariesActifs',
                icon: Icons.people_outline,
                color: Colors.blue,
                subtitle: 'Salariés actifs',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildKPICard(
                context,
                title: 'Présences',
                value:
                    '${salariesActifs > 2 ? salariesActifs - 2 : salariesActifs}',
                icon: Icons.how_to_reg,
                color: Colors.green,
                subtitle: 'Confirmées',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildKPICard(
                context,
                title: 'Absences',
                value: '$congesAujourdhui',
                icon: Icons.person_off_outlined,
                color: Colors.redAccent,
                subtitle: 'Aujourd\'hui',
                onTap: () => context.go('/conges'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildKPICard(
                context,
                title: 'Avertissements',
                value: '1',
                icon: Icons.warning_amber_rounded,
                color: Colors.orange,
                subtitle: 'En attente',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKPICard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.primary,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    }
    return card;
  }

  Widget _buildRecentAlerts(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RAPPORTS',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.error,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Alertes et urgences',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: Theme.of(context).colorScheme.surfaceContainerHigh,
          ),
          Container(
            color: Theme.of(context).colorScheme.surfaceContainerLowest,
            child: Column(
              children: [
                _buildAlertItem(
                  'Absence non justifiée',
                  '2 salariés n\'ont pas pointé aujourd\'hui.',
                  Icons.person_off,
                  Colors.redAccent,
                  context,
                ),
                Divider(height: 1, indent: 64),
                _buildAlertItem(
                  'Nouveau Message entrant',
                  'Client ABC a envoyé des documents.',
                  Icons.message_outlined,
                  Theme.of(context).colorScheme.tertiary,
                  context,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertItem(
    String title,
    String desc,
    IconData icon,
    Color color,
    BuildContext context,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Text(
                  desc,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveManagementSection(BuildContext context) {
    final appState = context.watch<AppState>();
    final pendingLeaves = appState.conges.where((c) => c.statut == 'en_attente').toList();
    final approvedLeaves = appState.conges.where((c) => c.statut == 'approuve').toList();

    final cs = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CONGÉS',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: cs.primary,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Gestion des Congés',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: cs.primary,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () => context.go('/conges'),
                  child: Row(
                    children: [
                      Text(
                        'Voir tout',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: cs.primary,
                        ),
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 12),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            color: cs.surfaceContainerHigh,
          ),
          Container(
            padding: const EdgeInsets.all(20),
            color: cs.surfaceContainerLowest,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildLeaveMiniStat(
                        context,
                        title: 'En attente',
                        count: pendingLeaves.length,
                        color: Colors.orange,
                        icon: Icons.hourglass_empty,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildLeaveMiniStat(
                        context,
                        title: 'Approuvés',
                        count: approvedLeaves.length,
                        color: Colors.green,
                        icon: Icons.check_circle_outline,
                      ),
                    ),
                  ],
                ),
                if (pendingLeaves.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Demandes récentes en attente',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...pendingLeaves.take(2).map((conge) {
                    final salarie = appState.salaries.firstWhere(
                      (s) => s.id == conge.salarieId,
                      orElse: () => Salarie(id: '', entrepriseId: '', nom: 'Inconnu', prenom: '', nomDeNaissance: '', typeContrat: 'CDI'),
                    );
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          SalarieAvatar(
                            radius: 14,
                            avatarUrl: salarie.avatarUrl,
                            initials: salarie.prenom.isNotEmpty
                                ? salarie.prenom[0].toUpperCase()
                                : (salarie.nom.isNotEmpty ? salarie.nom[0].toUpperCase() : '?'),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${salarie.prenom} ${salarie.nom}',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  'Du ${conge.dateDebut.day}/${conge.dateDebut.month} au ${conge.dateFin.day}/${conge.dateFin.month}',
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.arrow_forward_ios, size: 14),
                            onPressed: () => context.go('/conges'),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeaveMiniStat(
    BuildContext context, {
    required String title,
    required int count,
    required Color color,
    required IconData icon,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: cs.outlineVariant.withOpacity(0.5),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$count',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: cs.onSurface,
                ),
              ),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
