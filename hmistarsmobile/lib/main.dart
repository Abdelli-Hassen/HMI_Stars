import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/config/supabase_config.dart';
import 'core/providers/app_state.dart';
import 'core/theme/app_theme.dart';
import 'features/router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  runApp(const HMIStarsApp());
}

class HMIStarsApp extends StatelessWidget {
  const HMIStarsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: const _HMIStarsAppContent(),
    );
  }
}

class _HMIStarsAppContent extends StatefulWidget {
  const _HMIStarsAppContent();

  @override
  State<_HMIStarsAppContent> createState() => _HMIStarsAppContentState();
}

class _HMIStarsAppContentState extends State<_HMIStarsAppContent> {
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    final appState = context.read<AppState>();
    _router = createAppRouter(appState);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.watch<AppState>().isDarkMode;
    return MaterialApp.router(
      title: 'HMI Stars Consulting',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      routerConfig: _router,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('fr', 'FR'), Locale('en', 'US')],
      locale: const Locale('fr', 'FR'),
    );
  }
}
