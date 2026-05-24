import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/app_state.dart';
import '../../core/models/models.dart';
import '../auth/login_page.dart';
import '../auth/forgot_password_page.dart';
import '../auth/selection_entreprise_page.dart';
import '../dashboard/dashboard_page.dart';
import '../pointage/pointage_page.dart';
import '../messagerie/messagerie_page.dart';
import '../salaries/salaries_page.dart';
import '../salaries/add_salarie_page.dart';
import '../avertissements/avertissements_page.dart';
import '../parametres/parametres_page.dart';
import '../conges/conges_page.dart';
import '../shell/main_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

GoRouter createAppRouter(AppState appState) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/connexion',
    redirect: (context, state) {
      final isAuthenticated = appState.isAuthenticated;
      final needsSelection = appState.needsCompanySelection;
      final location = state.matchedLocation;

      final isAuthRoute =
          location == '/connexion' || location == '/mot-de-passe-oublie';
      final isSelectionRoute = location == '/selection-entreprise';

      // Not logged in → always go to login
      if (!isAuthenticated && !isAuthRoute) return '/connexion';

      // Logged in but needs company selection → go to selector
      if (isAuthenticated && needsSelection && !isSelectionRoute) {
        return '/selection-entreprise';
      }

      // Logged in, company chosen, but still on auth/selection screen → go to dashboard
      if (isAuthenticated && !needsSelection && (isAuthRoute || isSelectionRoute)) {
        return '/tableau-de-bord';
      }

      return null;
    },
    refreshListenable: appState,
    routes: [
      // ─── Auth routes (no shell) ────────────────────────────────────────────
      GoRoute(
        path: '/connexion',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/mot-de-passe-oublie',
        builder: (context, state) => const ForgotPasswordPage(),
      ),

      // ─── Company selector (no shell) ──────────────────────────────────────
      GoRoute(
        path: '/selection-entreprise',
        builder: (context, state) => const SelectionEntreprisePage(),
      ),

      // ─── Full-screen routes (no bottom nav) ───────────────────────────────
      GoRoute(
        path: '/salaries/ajouter',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) => const AddSalariePage(),
      ),
      GoRoute(
        path: '/salaries/modifier',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (context, state) {
          Salarie? salarie;
          if (state.extra is Salarie) {
            salarie = state.extra as Salarie;
          } else if (state.extra is Map<String, dynamic>) {
            salarie = Salarie.fromJson(state.extra as Map<String, dynamic>);
          }
          return AddSalariePage(salarie: salarie);
        },
      ),

      // ─── Main shell with bottom nav ────────────────────────────────────────
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => MainShell(child: child),
        routes: [
          GoRoute(
            path: '/tableau-de-bord',
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: '/pointage',
            builder: (context, state) => const PointagePage(),
          ),
          GoRoute(
            path: '/messagerie',
            builder: (context, state) => const MessageriePage(),
          ),
          GoRoute(
            path: '/salaries',
            builder: (context, state) => const SalariesPage(),
          ),
          GoRoute(
            path: '/avertissements',
            builder: (context, state) => const AvertissementsPage(),
          ),
          GoRoute(
            path: '/parametres',
            builder: (context, state) => const ParametresPage(),
          ),
          GoRoute(
            path: '/conges',
            builder: (context, state) => const CongesPage(),
          ),
        ],
      ),
    ],
  );
}
