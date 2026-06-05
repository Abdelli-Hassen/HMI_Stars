import 'package:flutter/material.dart';
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
