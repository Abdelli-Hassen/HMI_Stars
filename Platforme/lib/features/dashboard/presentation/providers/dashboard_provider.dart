import 'package:flutter/material.dart';
import '../../../entreprises/presentation/providers/entreprise_provider.dart';

class DashboardProvider extends ChangeNotifier {
  final EntrepriseProvider _entrepriseProvider;

  DashboardProvider(this._entrepriseProvider);

  int get totalEntreprises => _entrepriseProvider.totalEntreprises;
  int get dossiersEnCours => _entrepriseProvider.dossiersEnCours;
  int get dossiersEnAttente => _entrepriseProvider.dossiersEnAttente;
  int get totalSalaries => _entrepriseProvider.salaries.length;

  // Placeholder until a revenue model is added
  double get revenusHebdomadaires => 0;
}
