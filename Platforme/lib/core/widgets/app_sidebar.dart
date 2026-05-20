import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../router/app_router.dart';
import 'package:provider/provider.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/messagerie/presentation/providers/messagerie_provider.dart';

class SidebarItem {
  final IconData icon;
  final String label;
  final String route;

  const SidebarItem({
    required this.icon,
    required this.label,
    required this.route,
  });
}

class AppSidebar extends StatelessWidget {
  final String currentRoute;

  const AppSidebar({
    super.key,
    required this.currentRoute,
  });

  static const _baseNavItems = [
    SidebarItem(icon: Icons.dashboard_outlined, label: 'Tableau de bord', route: AppRoutes.dashboard),
    SidebarItem(icon: Icons.business, label: 'Entreprises', route: AppRoutes.entreprises),
    SidebarItem(icon: Icons.warning_amber_outlined, label: 'Urgents', route: AppRoutes.urgents),
    SidebarItem(icon: Icons.chat_bubble_outline, label: 'Messagerie', route: AppRoutes.messagerie),

    SidebarItem(icon: Icons.description_outlined, label: 'Documents RH', route: AppRoutes.documentsEntreprise),
    SidebarItem(icon: Icons.sticky_note_2_outlined, label: 'Notes & Rappels', route: AppRoutes.notesRappels),
    SidebarItem(icon: Icons.settings_outlined, label: 'Paramètres', route: AppRoutes.settings),
  ];

  @override
  Widget build(BuildContext context) {
    // Inject admin item if the user is admin
    final isAdmin = Provider.of<AuthProvider>(context).isAdmin;
    final navItems = List<SidebarItem>.from(_baseNavItems);
    if (isAdmin) {
      navItems.add(const SidebarItem(icon: Icons.people_outline, label: 'Comptes Admin', route: AppRoutes.gestionComptes));
    }

    return Container(
      width: 256,
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLow,
      ),
      child: Column(
        children: [
          // ─── Enterprise Logo & Name ───
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/logo.jpeg',
                    width: 90,
                    height: 48,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 90,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.business, size: 24, color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HMI Stars',
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                          color: const Color(0xFF1A3A7D),
                        ),
                      ),
                      Text(
                        'CONSULTING',
                        style: AppTextStyles.labelSmall.copyWith(
                          fontSize: 9,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w700,
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ─── Navigation Items ───
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ListView(
                children: navItems.map((item) {
                  final isActive = currentRoute == item.route;
                  
                  // Check unread condition if this is Messagerie item
                  bool hasUnread = false;
                  if (item.label == 'Messagerie') {
                    hasUnread = context.watch<MessagerieProvider>().hasUnreadForSidebar;
                  }

                  return _SidebarNavItem(
                    icon: item.icon,
                    label: item.label,
                    isActive: isActive,
                    hasUnread: hasUnread,
                    onTap: () {
                      if (currentRoute != item.route) {
                        if (item.route == AppRoutes.messagerie) {
                          context.read<MessagerieProvider>().clearSidebarUnread();
                        } else if (currentRoute == AppRoutes.messagerie) {
                          context.read<MessagerieProvider>().quitterMessagerie();
                        }
                        Navigator.pushReplacementNamed(context, item.route);
                      }
                    },
                  );
                }).toList(),
              ),
            ),
          ),

          // ─── Bottom section ───
          Container(
            padding: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              border: Border(
                  top: BorderSide(
                      color: AppColors.outlineVariant.withValues(alpha: 0.15))),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                children: [
                  _SidebarNavItem(
                    icon: Icons.help_outline,
                    label: 'Aide',
                    isActive: false,
                    onTap: () {},
                  ),
                  _SidebarNavItem(
                    icon: Icons.logout,
                    label: 'Déconnexion',
                    isActive: false,
                    isDestructive: true,
                    onTap: () {
                      if (currentRoute == AppRoutes.messagerie) {
                        context.read<MessagerieProvider>().quitterMessagerie();
                      }
                      Navigator.pushReplacementNamed(context, AppRoutes.login);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ─── Sidebar Navigation Item with hover slide animation ───

class _SidebarNavItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final bool isDestructive;
  final bool hasUnread;
  final VoidCallback onTap;

  const _SidebarNavItem({
    required this.icon,
    required this.label,
    required this.isActive,
    this.isDestructive = false,
    this.hasUnread = false,
    required this.onTap,
  });

  @override
  State<_SidebarNavItem> createState() => _SidebarNavItemState();
}

class _SidebarNavItemState extends State<_SidebarNavItem>
    with SingleTickerProviderStateMixin {
  bool _hovered = false;
  late AnimationController _slideController;
  late Animation<double> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: 0, end: 4).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isDestructive
        ? (_hovered ? AppColors.error : AppColors.onSurfaceVariant)
        : widget.isActive
            ? AppColors.primary
            : _hovered
                ? AppColors.onSurface
                : AppColors.onSurfaceVariant;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) {
        setState(() => _hovered = true);
        _slideController.forward();
      },
      onExit: (_) {
        setState(() => _hovered = false);
        _slideController.reverse();
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _slideAnimation,
          builder: (context, child) => Transform.translate(
            offset: Offset(_slideAnimation.value, 0),
            child: child,
          ),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            margin: const EdgeInsets.symmetric(vertical: 1),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: widget.isActive
                  ? AppColors.surfaceContainerLowest
                  : _hovered
                      ? AppColors.surfaceContainerLowest.withValues(alpha: 0.5)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              boxShadow: widget.isActive
                  ? [
                      BoxShadow(
                          color: AppColors.onSurface.withValues(alpha: 0.05),
                          blurRadius: 2)
                    ]
                  : null,
            ),
            child: Row(
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(widget.icon, size: 20, color: color),
                    if (widget.hasUnread)
                      Positioned(
                        right: -2,
                        top: -2,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.error,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    widget.label,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: color,
                      fontWeight:
                          widget.isActive ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
