import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/main_shell.dart';
import '../../../../core/widgets/staggered_column.dart';

class DetailsCalculsPage extends StatelessWidget {
  const DetailsCalculsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MainShell(
      currentRoute: AppRoutes.entreprises,
      title: 'Détails des Calculs',
      sidebarVariant: 'employee',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: StaggeredColumn(
          children: [
            // Header
            Row(children: [
              MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.arrow_back, size: 18, color: AppColors.onSurfaceVariant),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Détails des Calculs de Congés', style: AppTextStyles.headlineMedium),
                Text('Jean Dupont — Exercice 2026',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.onSurfaceVariant)),
              ]),
            ]),
            const SizedBox(height: 28),

            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // ─── Left: Calc sections ───
              Expanded(flex: 2, child: Column(children: [
                // CP Section
                _calcSection(
                  'CONGÉS PAYÉS (CP)',
                  [
                    _calcRow('Droits acquis N', '25 jours', AppColors.primary),
                    _calcRow('Report N-1', '3 jours', AppColors.primary),
                    _calcRow('Congés pris', '-10 jours', AppColors.error),
                    _calcRow('Solde restant', '18 jours', AppColors.success, bold: true),
                  ],
                ),
                const SizedBox(height: 16),

                // Movement Table
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(16)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('MOUVEMENTS DE CONGÉS', style: AppTextStyles.labelSmall.copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                      decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(8)),
                      child: Row(children: [
                        SizedBox(width: 100, child: Text('DATE', style: _hdr())),
                        Expanded(child: Text('TYPE', style: _hdr())),
                        SizedBox(width: 80, child: Text('JOURS', textAlign: TextAlign.center, style: _hdr())),
                        SizedBox(width: 80, child: Text('SOLDE', textAlign: TextAlign.center, style: _hdr())),
                      ]),
                    ),
                    _movRow('01 Jan', 'Acquisition', '+2.08', '27.08'),
                    _movRow('01 Fév', 'Acquisition', '+2.08', '29.16'),
                    _movRow('15 Mar', 'Congé Maladie', '-2', '27.16'),
                    _movRow('01 Avr', 'Acquisition', '+2.08', '29.24'),
                    _movRow('22 Mai', 'RTT posé', '-1', '28.24'),
                    _movRow('01 Juin', 'Congé Payé', '-10', '18.24'),
                  ]),
                ),
                const SizedBox(height: 16),

                // RTT Section
                _calcSection(
                  'RÉDUCTION DU TEMPS DE TRAVAIL (RTT)',
                  [
                    _calcRow('Droits annuels', '10 jours', AppColors.primary),
                    _calcRow('RTT pris', '-4 jours', AppColors.error),
                    _calcRow('Solde restant', '6 jours', AppColors.success, bold: true),
                  ],
                ),
              ])),
              const SizedBox(width: 16),

              // ─── Right sidebar ───
              Expanded(child: Column(children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('RÉSUMÉ GLOBAL', style: AppTextStyles.labelSmall.copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 20),
                    _globalRow('CP Restants', '18 j', AppColors.primary),
                    const SizedBox(height: 12),
                    _globalRow('RTT Restants', '6 j', AppColors.primaryContainer),
                    const SizedBox(height: 12),
                    _globalRow('Maladie utilisés', '2 j', AppColors.error),
                    const SizedBox(height: 12),
                    Divider(color: AppColors.outlineVariant.withValues(alpha: 0.15)),
                    const SizedBox(height: 8),
                    _globalRow('Total disponible', '24 j', AppColors.success),
                  ]),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(16)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('MÉTHODE DE CALCUL', style: AppTextStyles.labelSmall.copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 16),
                    _methodItem('Acquisition', '2.08 j/mois (25j/an)'),
                    _methodItem('Période', '1 Juin N-1 → 31 Mai N'),
                    _methodItem('Convention', 'SYNTEC – IDCC 1486'),
                    _methodItem('Report max', '5 jours N-1'),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity, padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(10)),
                      child: Row(children: [
                        Icon(Icons.info_outline, size: 14, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Expanded(child: Text('Calculs conformes aux articles L.3141 du Code du Travail',
                            style: AppTextStyles.bodySmall.copyWith(fontSize: 10))),
                      ]),
                    ),
                  ]),
                ),
              ])),
            ]),
          ],
        ),
      ),
    );
  }

  TextStyle _hdr() => AppTextStyles.labelSmall.copyWith(letterSpacing: 0.8, fontWeight: FontWeight.w700);

  Widget _calcSection(String title, List<Widget> items) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: AppTextStyles.labelSmall.copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w700)),
        const SizedBox(height: 16),
        ...items,
      ]),
    );
  }

  Widget _calcRow(String label, String value, Color color, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.onSurfaceVariant)),
        Text(value, style: (bold ? AppTextStyles.titleSmall : AppTextStyles.labelMedium).copyWith(fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }

  Widget _movRow(String date, String type, String days, String balance) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.1)))),
      child: Row(children: [
        SizedBox(width: 100, child: Text(date, style: AppTextStyles.bodySmall.copyWith(color: AppColors.onSurface))),
        Expanded(child: Text(type, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w500, color: AppColors.onSurface))),
        SizedBox(width: 80, child: Text(days, textAlign: TextAlign.center, style: AppTextStyles.labelMedium.copyWith(
          fontWeight: FontWeight.w700,
          color: days.startsWith('+') ? AppColors.success : days.startsWith('-') ? AppColors.error : AppColors.onSurface,
        ))),
        SizedBox(width: 80, child: Text(balance, textAlign: TextAlign.center, style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600))),
      ]),
    );
  }

  Widget _globalRow(String label, String value, Color color) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: AppTextStyles.bodySmall.copyWith(fontWeight: FontWeight.w500, color: AppColors.onSurface)),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
        child: Text(value, style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w700, color: color)),
      ),
    ]);
  }

  Widget _methodItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Container(width: 4, height: 4, decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600)),
          Text(value, style: AppTextStyles.bodySmall.copyWith(fontSize: 11)),
        ])),
      ]),
    );
  }
}
