import 'package:flutter/material.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/sign_up_page.dart';
import '../../features/auth/presentation/pages/forgot_password_page.dart';
import '../../features/auth/presentation/pages/reset_password_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/entreprises/presentation/pages/entreprises_page.dart';
import '../../features/urgents/presentation/pages/urgents_page.dart';
import '../../features/messagerie/presentation/pages/messagerie_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/entreprise_details/presentation/pages/entreprise_details_page.dart';
import '../../features/entreprise_details/presentation/pages/documents_entreprise_page.dart';
import '../../features/entreprise_details/presentation/pages/notes_rappels_page.dart';
import '../../features/entreprise_details/presentation/pages/details_calculs_page.dart';

import '../../features/settings/presentation/pages/gestion_comptes_page.dart';

class AppRoutes {
  AppRoutes._();

  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static const String login = '/login';
  static const String signUp = '/sign-up';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String dashboard = '/dashboard';
  static const String entreprises = '/entreprises';
  static const String urgents = '/urgents';
  static const String messagerie = '/messagerie';
  static const String settings = '/settings';
  static const String gestionComptes = '/gestion-comptes';
  static const String entrepriseDetails = '/entreprise/details';
  static const String documentsEntreprise = '/entreprise/documents';
  static const String notesRappels = '/notes-rappels';
  static const String detailsCalculs = '/entreprise/details-calculs';

  static Map<String, WidgetBuilder> get routes => {
        login: (_) => const LoginPage(),
        signUp: (_) => const SignUpPage(),
        forgotPassword: (_) => const ForgotPasswordPage(),
        resetPassword: (_) => const ResetPasswordPage(),
        dashboard: (_) => const DashboardPage(),
        entreprises: (_) => const EntreprisesPage(),
        urgents: (_) => const UrgentsPage(),
        messagerie: (_) => const MessageriePage(),
        settings: (_) => const SettingsPage(),
        gestionComptes: (_) => const GestionComptesPage(),
        entrepriseDetails: (_) => const EntrepriseDetailsPage(),
        documentsEntreprise: (_) => const DocumentsEntreprisePage(),
        notesRappels: (_) => const NotesRappelsPage(),
        detailsCalculs: (_) => const DetailsCalculsPage(),
      };
}
