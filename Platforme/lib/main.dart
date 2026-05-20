import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/supabase_config.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/providers/theme_provider.dart';
import 'core/providers/notification_provider.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/dashboard/presentation/pages/dashboard_page.dart';
import 'features/entreprises/presentation/providers/entreprise_provider.dart';
import 'features/dashboard/presentation/providers/dashboard_provider.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/messagerie/presentation/providers/messagerie_provider.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(const HmiStarsApp());
}

class HmiStarsApp extends StatelessWidget {
  const HmiStarsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => EntrepriseProvider()),
        ChangeNotifierProvider(create: (_) => MessagerieProvider()),
        ChangeNotifierProxyProvider<EntrepriseProvider, NotificationProvider>(
          create: (ctx) => NotificationProvider(ctx.read<EntrepriseProvider>()),
          update: (ctx, entrepriseProvider, previous) =>
              previous ?? NotificationProvider(entrepriseProvider),
        ),
        ChangeNotifierProxyProvider<EntrepriseProvider, DashboardProvider>(
          create: (ctx) => DashboardProvider(
            ctx.read<EntrepriseProvider>(),
          ),
          update: (ctx, entrepriseProvider, previous) =>
              DashboardProvider(entrepriseProvider),
        ),
      ],
      child: Consumer2<AuthProvider, ThemeProvider>(
        builder: (context, auth, themeProvider, _) {
          return MaterialApp(
            title: 'HMI Stars',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            initialRoute: auth.isAuthenticated
                ? AppRoutes.dashboard
                : AppRoutes.login,
            routes: AppRoutes.routes,
            onGenerateRoute: (settings) {
              // Handle "/" or any deep-link route not in the table
              return MaterialPageRoute(
                builder: (_) => auth.isAuthenticated
                    ? const DashboardPage()
                    : const LoginPage(),
              );
            },
            onUnknownRoute: (settings) {
              return MaterialPageRoute(
                builder: (_) => const LoginPage(),
              );
            },
          );
        },
      ),
    );
  }
}
