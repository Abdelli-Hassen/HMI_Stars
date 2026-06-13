import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/messagerie/presentation/providers/messagerie_provider.dart';
import '../utils/translation_extension.dart';
import 'app_sidebar.dart';
import 'app_top_bar.dart';

class MainShell extends StatelessWidget {
  final String currentRoute;
  final String title;
  final String? subtitle;
  final Widget body;
  final String sidebarVariant; // kept for API compat but ignored
  final List<Widget>? topBarActions;
  final List<Widget>? topBarTabs;

  const MainShell({
    super.key,
    required this.currentRoute,
    required this.title,
    required this.body,
    this.subtitle,
    this.sidebarVariant = 'main',
    this.topBarActions,
    this.topBarTabs,
  });

  Widget _buildImpersonationBanner(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isImpersonating) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;
    return Container(
      color: cs.errorContainer,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(Icons.admin_panel_settings_rounded, color: cs.onErrorContainer, size: 20),
              const SizedBox(width: 8),
              Text(
                '${context.tr("Mode impersonation actif : connecté en tant que", "Impersonation mode active: logged in as")} ${auth.userName} (${auth.libelleRole})',
                style: TextStyle(
                  color: cs.onErrorContainer,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          ElevatedButton.icon(
            onPressed: () {
              auth.stopImpersonating();
              Provider.of<MessagerieProvider>(context, listen: false).setOverrideUserId(null);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: cs.error,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.exit_to_app_rounded, size: 16),
            label: Text(
              context.tr('Quitter', 'Exit'),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: cs.surface,
      body: Row(
        children: [
          // ─── Sidebar (always the same) ───
          AppSidebar(currentRoute: currentRoute),

          // ─── Main Content Area ───
          Expanded(
            child: Column(
              children: [
                _buildImpersonationBanner(context),
                AppTopBar(
                  title: title,
                  subtitle: subtitle,
                  actions: topBarActions,
                  tabs: topBarTabs,
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 900),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: CurvedAnimation(
                          parent: animation,
                          curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
                        ),
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.03),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          )),
                          child: child,
                        ),
                      );
                    },
                    child: Container(
                      key: ValueKey(currentRoute),
                      color: cs.surface,
                      child: body,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
