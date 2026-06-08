import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/providers/app_state.dart';
import '../../core/models/models.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/salarie_avatar.dart';
import '../../core/utils/translation_extension.dart';

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
    final isEn = appState.langue == 'English (EN)';
    final weekdays = isEn 
        ? ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday']
        : ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    final months = isEn
        ? ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December']
        : ['Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'];
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
                    context.tr('Bonjour, ${params?.nomGerant ?? 'Admin'} !', 'Hello, ${params?.nomGerant ?? 'Admin'}!'),
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

                  // --- Action Cards ---
                  _buildActionCards(context, appState,
                    nonPointes: nonPointes,
                    absencesIndefinies: absencesIndefinies.length,
                    templatesDisponibles: templatesDisponibles,
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
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: _kpiCard(
            context,
            title: context.tr('Effectif', 'Staff'),
            value: '$totalSalaries',
            subtitle: context.tr('Salariés actifs', 'Active employees'),
            icon: Icons.group_rounded,
            accentColor: cs.tertiary,
            onTap: () => context.go('/salaries'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _kpiCard(
            context,
            title: context.tr('Non pointés', 'Unpointed'),
            value: '$nonPointes',
            subtitle: nonPointes == 0 
                ? context.tr('Tout le monde pointé ✓', 'Everyone pointed ✓') 
                : context.tr('À pointer aujourd\'hui', 'To point today'),
            icon: Icons.edit_note_rounded,
            accentColor: nonPointes == 0 ? cs.tertiary : cs.error,
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

  // ─── Fixed Action Cards ────────────────────────────────────────────────────

  Widget _buildActionCards(
    BuildContext context,
    AppState appState, {
    required int nonPointes,
    required int absencesIndefinies,
    required int templatesDisponibles,
  }) {
    final cs = Theme.of(context).colorScheme;

    final items = [
      // 1. Attendance
      _ActionItem(
        icon: Icons.edit_note_rounded,
        iconBg: nonPointes == 0 ? cs.tertiaryContainer : cs.errorContainer,
        iconColor: nonPointes == 0 ? cs.onTertiaryContainer : cs.onErrorContainer,
        title: context.tr('Pointage du jour', 'Daily Attendance'),
        badge: nonPointes == 0 ? '✓' : '$nonPointes',
        badgeBg: nonPointes == 0 ? cs.tertiaryContainer : cs.errorContainer,
        badgeColor: nonPointes == 0 ? cs.onTertiaryContainer : cs.onErrorContainer,
        desc: nonPointes == 0
            ? context.tr('Pointage complet — aucune action requise.', 'Attendance complete — no action required.')
            : context.tr(
                'Effectuez le pointage maintenant ! $nonPointes salarié${nonPointes > 1 ? 's' : ''} n\'${nonPointes > 1 ? 'ont' : 'a'} pas encore été pointé${nonPointes > 1 ? 's' : ''}.',
                'Perform the attendance check now! $nonPointes employee${nonPointes > 1 ? 's' : ''} ${nonPointes > 1 ? 'have' : 'has'} not been pointed yet.',
              ),
        route: '/pointage',
      ),
      // 2. Undefined absences
      _ActionItem(
        icon: Icons.help_center_outlined,
        iconBg: absencesIndefinies == 0 ? cs.tertiaryContainer : cs.errorContainer,
        iconColor: absencesIndefinies == 0 ? cs.onTertiaryContainer : cs.onErrorContainer,
        title: context.tr('Absences indéfinies', 'Undefined Absences'),
        badge: '$absencesIndefinies',
        badgeBg: absencesIndefinies == 0 ? cs.tertiaryContainer : cs.errorContainer,
        badgeColor: absencesIndefinies == 0 ? cs.onTertiaryContainer : cs.onErrorContainer,
        desc: absencesIndefinies == 0
            ? context.tr('Toutes les absences sont classées — rien à faire.', 'All absences are classified — nothing to do.')
            : context.tr(
                'Classifiez les absences maintenant ! $absencesIndefinies absence${absencesIndefinies > 1 ? 's' : ''} de type « Autre » doivent être précisées au plus vite.',
                'Classify the absences now! $absencesIndefinies absence${absencesIndefinies > 1 ? 's' : ''} of type "Other" must be specified as soon as possible.',
              ),
        route: '/conges',
      ),
      // 3. Warnings
      _ActionItem(
        icon: Icons.warning_amber_rounded,
        iconBg: cs.tertiaryContainer,
        iconColor: cs.onTertiaryContainer,
        title: context.tr('Avertissements', 'Warnings'),
        badge: '$templatesDisponibles',
        badgeBg: cs.tertiaryContainer,
        badgeColor: cs.onTertiaryContainer,
        desc: templatesDisponibles == 0
            ? context.tr('Aucun modèle d\'avertissement disponible.', 'No warning templates available.')
            : context.tr(
                'N\'oubliez pas d\'envoyer les avertissements ! $templatesDisponibles modèle${templatesDisponibles > 1 ? 's' : ''} ${templatesDisponibles > 1 ? 'sont prêts' : 'est prêt'} à être envoyé${templatesDisponibles > 1 ? 's' : ''}.',
                'Don\'t forget to send warnings! $templatesDisponibles template${templatesDisponibles > 1 ? 's are' : ' is'} ready to be sent.',
              ),
        route: '/avertissements',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('RAPPELS', 'REMINDERS'),
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: cs.tertiary,
            letterSpacing: 1.4,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: cs.tertiaryContainer, width: 1.5),
          ),
          child: Column(
            children: [
              for (int i = 0; i < items.length; i++) ...[
                _actionTile(context, items[i]),
                if (i < items.length - 1)
                  Divider(height: 1, indent: 66, color: cs.outlineVariant),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _actionTile(BuildContext context, _ActionItem item) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () => context.go(item.route),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: item.iconBg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(item.icon, color: item.iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.desc,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: item.badgeBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                item.badge,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: item.badgeColor,
                ),
              ),
            ),
          ],
        ),
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
              context.tr('DEMANDES EN ATTENTE', 'PENDING REQUESTS'),
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
                context.tr('Voir tout', 'See all'),
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
        id: '', entrepriseId: '', nom: context.trStatic('Inconnu', 'Unknown'), prenom: '',
        nomDeNaissance: '', typeContrat: 'CDI',
      ),
    );

    // Type label
    final typeLabels = {
      'conge_paye': context.tr('Congé Payé', 'Paid Leave'),
      'maladie': context.tr('Arrêt Maladie', 'Sick Leave'),
      'rtt': context.tr('RTT', 'RTT'),
      'exceptionnel': context.tr('Congé Exceptionnel', 'Special Leave'),
      'autre': context.tr('Autre Absence', 'Other Absence'),
    };
    final typeLabel = typeLabels[conge.typeConge] ?? context.tr('Absence', 'Absence');

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
                    context.tr(
                      '$typeLabel · Du ${conge.dateDebut.day}/${conge.dateDebut.month} au ${conge.dateFin.day}/${conge.dateFin.month}',
                      '$typeLabel · From ${conge.dateDebut.day}/${conge.dateDebut.month} to ${conge.dateFin.day}/${conge.dateFin.month}',
                    ),
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
                context.tr('En attente', 'Pending'),
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

class _ActionItem {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String desc;
  final String badge;
  final Color badgeBg;
  final Color badgeColor;
  final String route;

  const _ActionItem({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.desc,
    required this.badge,
    required this.badgeBg,
    required this.badgeColor,
    required this.route,
  });
}

