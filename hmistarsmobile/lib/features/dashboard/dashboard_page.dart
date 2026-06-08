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
    final params = appState.parametres;

    final today = DateTime.now();
    final todayKey = DateTime(today.year, today.month, today.day);

    // --- Real metrics derived from live state ---

    // Count employees on approved leave today
    final congesApprouvesAujourd = appState.conges.where((c) {
      final start = DateTime(c.dateDebut.year, c.dateDebut.month, c.dateDebut.day);
      final end = DateTime(c.dateFin.year, c.dateFin.month, c.dateFin.day);
      return c.statut == 'approuve' &&
          (start.isBefore(todayKey) || start.isAtSameMomentAs(todayKey)) &&
          (end.isAfter(todayKey) || end.isAtSameMomentAs(todayKey));
    }).length;

    // Count employees who have NOT been pointed today and are not on approved leave
    final nonPointes = appState.salaries.where((s) {
      final pointed = appState.getPointageStatus(todayKey, s.id);
      final enConge = appState.isSalarieEnConge(s.id, todayKey);
      return !pointed && !enConge;
    }).length;

    // Pending leave requests
    final congesEnAttente = appState.conges.where((c) => c.statut == 'en_attente').toList();

    // Absences with undefined/unclassified type ('autre') - excludes fully-day approved
    final absencesIndefinies = appState.conges.where((c) =>
        c.typeConge == 'autre' && c.statut != 'refuse').toList();

    // Unread messages from platform
    final messagesNonLus = appState.messages.where((m) => !m.estEnvoyePar && !m.estLu).length;

    // Warning templates ready to send
    final templatesDisponibles = appState.templates.length;

    // Day of week greeting
    final weekdays = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    final months = ['Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'];
    final dateStr = '${weekdays[today.weekday - 1]} ${today.day} ${months[today.month - 1]}';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          AppHeader.sliver(context: context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // --- Greeting header ---
                  Text(
                    dateStr,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.outline,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Bonjour, ${params?.nomGerant ?? 'Admin'} 👋',
                    style: GoogleFonts.manrope(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.primary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- KPI Cards ---
                  _buildKPIGrid(context,
                    totalSalaries: appState.salaries.length,
                    nonPointes: nonPointes,
                  ),
                  const SizedBox(height: 24),

                  // --- Smart Reminders Section ---
                  _buildReminders(context,
                    nonPointes: nonPointes,
                    congesEnAttente: congesEnAttente.length,
                    absencesIndefinies: absencesIndefinies.length,
                    messagesNonLus: messagesNonLus,
                    templatesDisponibles: templatesDisponibles,
                    today: today,
                  ),
                  const SizedBox(height: 24),

                  // --- Pending Leave Requests ---
                  if (congesEnAttente.isNotEmpty)
                    _buildPendingLeaveSection(context, appState, congesEnAttente),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── KPI Grid ─────────────────────────────────────────────────────────────

  Widget _buildKPIGrid(
    BuildContext context, {
    required int totalSalaries,
    required int nonPointes,
  }) {
    return Row(
      children: [
        Expanded(
          child: _kpiCard(
            context,
            title: 'Effectif',
            value: '$totalSalaries',
            subtitle: 'Salariés actifs',
            icon: Icons.group_rounded,
            accentColor: const Color(0xFF1E88E5),
            onTap: () => context.go('/salaries'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _kpiCard(
            context,
            title: 'Non pointés',
            value: '$nonPointes',
            subtitle: nonPointes == 0 ? 'Tout le monde pointé ✓' : 'À pointer aujourd\'hui',
            icon: Icons.edit_note_rounded,
            accentColor: nonPointes == 0
                ? const Color(0xFF43A047)
                : nonPointes == 1
                    ? const Color(0xFFFB8C00)
                    : const Color(0xFFE53935),
            onTap: () => context.go('/pointage'),
          ),
        ),
      ],
    );
  }

  Widget _kpiCard(
    BuildContext context, {
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    VoidCallback? onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withOpacity(0.5), width: 1),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.manrope(
              fontSize: 30,
              fontWeight: FontWeight.w800,
              color: accentColor,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: cs.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: card);
    }
    return card;
  }

  // ─── Smart Reminders ──────────────────────────────────────────────────────

  Widget _buildReminders(
    BuildContext context, {
    required int nonPointes,
    required int congesEnAttente,
    required int absencesIndefinies,
    required int messagesNonLus,
    required int templatesDisponibles,
    required DateTime today,
  }) {
    final cs = Theme.of(context).colorScheme;
    final isWeekday = today.weekday <= 5;

    // Build list of contextual reminder items
    final List<_ReminderData> reminders = [];

    // 1. Attendance reminder (only on weekdays)
    if (isWeekday && nonPointes > 0) {
      reminders.add(_ReminderData(
        icon: Icons.touch_app_rounded,
        color: const Color(0xFF1E88E5),
        title: 'Pointage du jour à faire',
        desc: '$nonPointes salarié${nonPointes > 1 ? 's' : ''} non pointé${nonPointes > 1 ? 's' : ''} aujourd\'hui.',
        route: '/pointage',
        urgent: nonPointes > 2,
      ));
    }

    // 2. Pending leave requests
    if (congesEnAttente > 0) {
      reminders.add(_ReminderData(
        icon: Icons.pending_actions_rounded,
        color: const Color(0xFFFB8C00),
        title: 'Demandes de congé en attente',
        desc: '$congesEnAttente demande${congesEnAttente > 1 ? 's' : ''} à valider ou refuser.',
        route: '/conges',
        urgent: congesEnAttente > 3,
      ));
    }

    // 3. Undefined absences reminder
    if (absencesIndefinies > 0) {
      reminders.add(_ReminderData(
        icon: Icons.help_outline_rounded,
        color: const Color(0xFF8E24AA),
        title: 'Absences non classifiées',
        desc: '$absencesIndefinies absence${absencesIndefinies > 1 ? 's' : ''} de type "Autre" à préciser.',
        route: '/conges',
        urgent: false,
      ));
    }

    // 4. Warning templates available to send
    if (templatesDisponibles > 0) {
      reminders.add(_ReminderData(
        icon: Icons.warning_amber_rounded,
        color: const Color(0xFFE53935),
        title: 'Avertissements disponibles',
        desc: '$templatesDisponibles modèle${templatesDisponibles > 1 ? 's' : ''} prêt${templatesDisponibles > 1 ? 's' : ''} à envoyer.',
        route: '/avertissements',
        urgent: false,
      ));
    }

    // 5. Unread messages
    if (messagesNonLus > 0) {
      reminders.add(_ReminderData(
        icon: Icons.mark_chat_unread_rounded,
        color: const Color(0xFF00897B),
        title: 'Nouveaux messages',
        desc: '$messagesNonLus message${messagesNonLus > 1 ? 's' : ''} non lu${messagesNonLus > 1 ? 's' : ''} de la plateforme.',
        route: '/messagerie',
        urgent: false,
      ));
    }

    if (reminders.isEmpty) {
      return _buildAllClearCard(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'À FAIRE AUJOURD\'HUI',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: cs.onSurfaceVariant.withOpacity(0.8),
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cs.outlineVariant.withOpacity(0.5), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              for (int i = 0; i < reminders.length; i++) ...[
                _reminderTile(context, reminders[i]),
                if (i < reminders.length - 1)
                  Divider(
                    height: 1,
                    indent: 64,
                    color: cs.outlineVariant.withOpacity(0.4),
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _reminderTile(BuildContext context, _ReminderData data) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => context.go(data.route),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: data.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(data.icon, color: data.color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          data.title,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            color: cs.onSurface,
                          ),
                        ),
                      ),
                      if (data.urgent)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE53935).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'URGENT',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFE53935),
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    data.desc,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.arrow_forward_ios_rounded, size: 13, color: cs.outline),
          ],
        ),
      ),
    );
  }

  Widget _buildAllClearCard(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF43A047).withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF43A047).withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF43A047).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle_rounded, color: Color(0xFF43A047), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tout est à jour !',
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF43A047),
                  ),
                ),
                Text(
                  'Aucune action requise pour le moment.',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─── Pending Leave Requests ───────────────────────────────────────────────

  Widget _buildPendingLeaveSection(
    BuildContext context,
    AppState appState,
    List congesEnAttente,
  ) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'DEMANDES EN ATTENTE',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: cs.onSurfaceVariant.withOpacity(0.8),
                letterSpacing: 1.2,
              ),
            ),
            GestureDetector(
              onTap: () => context.go('/conges'),
              child: Text(
                'Voir tout',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: cs.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cs.outlineVariant.withOpacity(0.5), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              for (int i = 0; i < congesEnAttente.take(3).length; i++) ...[
                _buildLeaveRequestTile(context, appState, congesEnAttente[i]),
                if (i < congesEnAttente.take(3).length - 1)
                  Divider(
                    height: 1,
                    indent: 64,
                    color: cs.outlineVariant.withOpacity(0.4),
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildLeaveRequestTile(BuildContext context, AppState appState, dynamic conge) {
    final cs = Theme.of(context).colorScheme;
    final salarie = appState.salaries.firstWhere(
      (s) => s.id == conge.salarieId,
      orElse: () => Salarie(
        id: '', entrepriseId: '', nom: 'Inconnu', prenom: '',
        nomDeNaissance: '', typeContrat: 'CDI',
      ),
    );

    // Type label
    final typeLabels = {
      'conge_paye': 'Congé Payé',
      'maladie': 'Arrêt Maladie',
      'rtt': 'RTT',
      'exceptionnel': 'Congé Exceptionnel',
      'autre': 'Autre Absence',
    };
    final typeLabel = typeLabels[conge.typeConge] ?? 'Absence';

    return InkWell(
      onTap: () => context.go('/conges'),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            SalarieAvatar(
              radius: 20,
              avatarUrl: salarie.avatarUrl,
              initials: salarie.prenom.isNotEmpty
                  ? salarie.prenom[0].toUpperCase()
                  : (salarie.nom.isNotEmpty ? salarie.nom[0].toUpperCase() : '?'),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${salarie.prenom} ${salarie.nom}',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$typeLabel · Du ${conge.dateDebut.day}/${conge.dateDebut.month} au ${conge.dateFin.day}/${conge.dateFin.month}',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFB8C00).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'En attente',
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFFFB8C00),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReminderData {
  final IconData icon;
  final Color color;
  final String title;
  final String desc;
  final String route;
  final bool urgent;

  const _ReminderData({
    required this.icon,
    required this.color,
    required this.title,
    required this.desc,
    required this.route,
    required this.urgent,
  });
}
