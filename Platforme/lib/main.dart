import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
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
import 'features/auth/presentation/pages/reset_password_page.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.implicit,
    ),
  );

  runApp(const HmiStarsApp());
}

class HmiStarsApp extends StatelessWidget {
  const HmiStarsApp({super.key});

  String _getInitialRoute(AuthProvider auth) {
    if (kIsWeb) {
      final uri = Uri.base;
      if (uri.queryParameters.containsKey('code') ||
          uri.fragment.contains('type=recovery') ||
          uri.queryParameters['type'] == 'recovery') {
        return AppRoutes.resetPassword;
      }
    }
    return auth.isAuthenticated ? AppRoutes.dashboard : AppRoutes.login;
  }

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
            navigatorKey: AppRoutes.navigatorKey,
            title: 'HMI Stars',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: themeProvider.themeMode,
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('fr', 'FR'),
              Locale('en', 'US'),
            ],
            initialRoute: _getInitialRoute(auth),
            routes: AppRoutes.routes,
            onGenerateRoute: (settings) {
              final routeName = settings.name ?? '';
              debugPrint('[AppRouter] onGenerateRoute settings name: $routeName');
              if (routeName.startsWith('/reset-password') || routeName.contains('reset-password')) {
                return MaterialPageRoute(
                  settings: settings,
                  builder: (_) => const ResetPasswordPage(),
                );
              }
              return MaterialPageRoute(
                settings: settings,
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

