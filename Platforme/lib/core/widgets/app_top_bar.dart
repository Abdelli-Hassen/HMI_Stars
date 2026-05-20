import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../router/app_router.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/notification_provider.dart';
import '../../features/messagerie/presentation/providers/messagerie_provider.dart';
import '../../features/entreprises/presentation/providers/entreprise_provider.dart';

class AppTopBar extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final Widget? searchBar;
  final List<Widget>? tabs;

  const AppTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.searchBar,
    this.tabs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(
          bottom: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          // ─── Branding (Logo & Title) ───
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/logo.jpeg',
                    width: 70,
                    height: 36,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 70,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.business, size: 16, color: AppColors.primary),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.titleMedium.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 10,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Spacer(),

          // ─── Search Bar ───
          if (searchBar != null)
            searchBar!
          else
            _AnimatedSearchBar(),

          const SizedBox(width: 16),

          // ─── Dark Mode Toggle Icon ───
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, _) {
              return MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () => themeProvider.toggleTheme(!themeProvider.isDarkMode),
                  child: Container(
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(
                      themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                      size: 20,
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),

          // ─── Notification Bell ───
          const _NotificationBell(),

          if (actions != null) ...[
            const SizedBox(width: 4),
            ...actions!,
          ],

          const SizedBox(width: 16),

          // ─── User Avatar ───
          Consumer<AuthProvider>(
            builder: (context, auth, _) => Container(
              padding: const EdgeInsets.only(left: 16),
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.2))),
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(auth.userName, style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600)),
                      Text(auth.userRole, style: AppTextStyles.labelSmall.copyWith(fontSize: 10, color: AppColors.onSurfaceVariant)),
                    ],
                  ),
                  const SizedBox(width: 10),
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.surfaceContainerHigh,
                    child: const Icon(Icons.person, size: 18, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Notification Bell with Dropdown Panel
// ─────────────────────────────────────────────────────────
class _NotificationBell extends StatefulWidget {
  const _NotificationBell();

  @override
  State<_NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<_NotificationBell>
    with SingleTickerProviderStateMixin {
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  bool _isOpen = false;
  bool _hovered = false;

  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _overlayEntry = null;
    _animController.dispose();
    super.dispose();
  }

  void _togglePanel() {
    if (_isOpen) {
      _removeOverlay();
    } else {
      _showOverlay();
    }
  }

  void _showOverlay() {
    final provider = context.read<NotificationProvider>();
    final entrepriseProv = context.read<EntrepriseProvider>();
    final messagerieProv = context.read<MessagerieProvider>();

    _overlayEntry = OverlayEntry(builder: (context) {
      return Stack(
        children: [
          // Backdrop
          Positioned.fill(
            child: GestureDetector(
              onTap: _removeOverlay,
              behavior: HitTestBehavior.opaque,
              child: Container(color: Colors.transparent),
            ),
          ),
          // Panel
          Positioned(
            width: 380,
            child: CompositedTransformFollower(
              link: _layerLink,
              showWhenUnlinked: false,
              offset: const Offset(-340, 44),
              child: FadeTransition(
                opacity: _fadeAnim,
                child: ScaleTransition(
                  scale: _scaleAnim,
                  alignment: Alignment.topRight,
                  child: Material(
                    color: Colors.transparent,
                    child: MultiProvider(
                      providers: [
                        ChangeNotifierProvider.value(value: provider),
                        ChangeNotifierProvider.value(value: entrepriseProv),
                        ChangeNotifierProvider.value(value: messagerieProv),
                      ],
                      child: _NotificationPanel(
                        onClose: _removeOverlay,
                        onMarkAllRead: () {
                          provider.marquerToutCommeLu();
                          _overlayEntry?.markNeedsBuild();
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    });

    Overlay.of(context).insert(_overlayEntry!);
    _animController.forward(from: 0);
    setState(() => _isOpen = true);
  }

  void _removeOverlay() {
    _animController.reverse().then((_) {
      if (mounted) {
        _overlayEntry?.remove();
        _overlayEntry = null;
      }
    });
    if (mounted) setState(() => _isOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    final notifProvider = context.watch<NotificationProvider>();
    final unreadCount = notifProvider.notifications.where((n) => !n.estLu).length;

    return CompositedTransformTarget(
      link: _layerLink,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: GestureDetector(
          onTap: _togglePanel,
          child: Stack(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _isOpen
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : _hovered
                          ? AppColors.primary.withValues(alpha: 0.05)
                          : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  _isOpen ? Icons.notifications : Icons.notifications_outlined,
                  size: 20,
                  color: _isOpen || _hovered ? AppColors.primary : AppColors.onSurfaceVariant,
                ),
              ),
              if (unreadCount > 0)
                Positioned(
                  right: 6,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.surfaceContainerLowest, width: 1.5),
                    ),
                    child: Center(
                      child: Text(
                        '$unreadCount',
                        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Notification Panel
// ─────────────────────────────────────────────────────────
class _NotificationPanel extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback onMarkAllRead;

  const _NotificationPanel({required this.onClose, required this.onMarkAllRead});

  @override
  State<_NotificationPanel> createState() => _NotificationPanelState();
}

class _NotificationPanelState extends State<_NotificationPanel> {
  String _activeTab = 'Tous';

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final list = provider.notifications;

    final filtered = _activeTab == 'Tous'
        ? list
        : _activeTab == 'Urgents'
            ? list.where((n) => !n.estLu).toList()
            : list.where((n) => n.estLu).toList();

    final unreadCount = list.where((n) => !n.estLu).length;

    return Container(
      constraints: const BoxConstraints(maxHeight: 520),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.04),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ─── Header ───
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 16, 0),
            child: Row(
              children: [
                Text('Documents non vus', style: AppTextStyles.titleMedium),
                const SizedBox(width: 8),
                if (unreadCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$unreadCount',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
                const Spacer(),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: widget.onMarkAllRead,
                    child: Text(
                      'Tout marquer comme lu',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ─── Tabs ───
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: ['Tous', 'Urgents', 'Traités'].map((tab) {
                  final active = _activeTab == tab;
                  return Expanded(
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => setState(() => _activeTab = tab),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          decoration: BoxDecoration(
                            color: active ? AppColors.surfaceContainerLowest : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: active
                                ? [BoxShadow(color: AppColors.onSurface.withValues(alpha: 0.04), blurRadius: 4)]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              tab,
                              style: AppTextStyles.labelSmall.copyWith(
                                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                                color: active ? AppColors.primary : AppColors.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ─── Notification List ───
          Flexible(
            child: filtered.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.notifications_off_outlined, size: 40, color: AppColors.outline),
                        const SizedBox(height: 8),
                        Text('Aucun fichier non vu', style: AppTextStyles.bodySmall.copyWith(color: AppColors.outline)),
                      ],
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return _NotificationItem(
                        data: item,
                        onTap: () {
                          // 1. Mark as read
                          provider.marquerCommeLu(item.id);
                          // 2. Close overlay
                          widget.onClose();
                          // 3. Selection enterprise in MessagerieProvider
                          context.read<MessagerieProvider>().selectionnerEntreprise(item.entrepriseId);
                          // 4. Redirect to messagerie page
                          Navigator.pushReplacementNamed(context, AppRoutes.messagerie);
                        },
                      );
                    },
                  ),
          ),

          // ─── Footer ───
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.outlineVariant.withValues(alpha: 0.15))),
            ),
            child: Center(
              child: MouseRegion(
                cursor: SystemMouseCursors.click,
                child: GestureDetector(
                  onTap: () {
                    widget.onClose();
                    Navigator.pushReplacementNamed(context, AppRoutes.messagerie);
                  },
                  child: Text(
                    'Voir tous les documents',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Notification Item
// ─────────────────────────────────────────────────────────
class _NotificationItem extends StatefulWidget {
  final NotificationDocument data;
  final VoidCallback onTap;

  const _NotificationItem({required this.data, required this.onTap});

  @override
  State<_NotificationItem> createState() => _NotificationItemState();
}

class _NotificationItemState extends State<_NotificationItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final n = widget.data;
    
    // Map document type to icon and color
    IconData icon;
    Color iconColor;
    String docTitle;
    
    switch (n.typeDocument.toLowerCase()) {
      case 'fournisseur':
        icon = Icons.receipt_long;
        iconColor = const Color(0xFF2E7D32); // Green
        docTitle = 'Facture Fournisseur';
        break;
      case 'banque':
        icon = Icons.account_balance;
        iconColor = const Color(0xFF1565C0); // Blue
        docTitle = 'Relevé Bancaire';
        break;
      case 'chiffre_affaires':
        icon = Icons.monetization_on_outlined;
        iconColor = const Color(0xFFE65100); // Orange
        docTitle = 'Déclaration CA';
        break;
      case 'kbis':
        icon = Icons.business_center;
        iconColor = const Color(0xFFC62828); // Red
        docTitle = 'Extrait KBIS';
        break;
      case 'tva':
        icon = Icons.percent;
        iconColor = const Color(0xFF00695C); // Teal instead of purple (Purple Ban)
        docTitle = 'Déclaration TVA';
        break;
      case 'siret':
        icon = Icons.info_outline;
        iconColor = const Color(0xFF37474F); // Blue grey
        docTitle = 'Fiche SIRET';
        break;
      case 'rib':
        icon = Icons.credit_card;
        iconColor = const Color(0xFF283593); // Indigo
        docTitle = 'RIB';
        break;
      case 'statuts':
        icon = Icons.gavel;
        iconColor = const Color(0xFF4E342E); // Brown
        docTitle = 'Statuts';
        break;
      case 'media':
        icon = Icons.image;
        iconColor = const Color(0xFF0277BD); // Light blue
        docTitle = 'Fichier Média';
        break;
      default:
        icon = Icons.description_outlined;
        iconColor = const Color(0xFF1E88E5);
        docTitle = 'Nouveau Document';
    }

    final entreprises = context.watch<EntrepriseProvider>().entreprises;
    final ent = entreprises.where((e) => e.id == n.entrepriseId).isNotEmpty
        ? entreprises.firstWhere((e) => e.id == n.entrepriseId)
        : null;
    final entName = ent?.nom ?? 'Entreprise Inconnue';

    String relativeTime = formatRelativeTime(n.dateEnvoi);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _hovered
                ? AppColors.primary.withValues(alpha: 0.04)
                : !n.estLu
                    ? AppColors.primaryFixed.withValues(alpha: 0.15)
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 12),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            docTitle,
                            style: AppTextStyles.labelMedium.copyWith(
                              fontWeight: !n.estLu ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ),
                        if (!n.estLu) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.error.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text(
                              'NOUVEAU',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: AppColors.error,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Fichier : ${n.nomFichier} reçu de $entName.',
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 11,
                        color: AppColors.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      relativeTime,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 10,
                        color: AppColors.outline,
                      ),
                    ),
                  ],
                ),
              ),
              // Unread dot
              if (!n.estLu)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(top: 6, left: 6),
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

String formatRelativeTime(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inSeconds < 60) return 'À l\'instant';
  if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
  if (diff.inDays == 1) return 'Hier';
  return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}';
}


// ─────────────────────────────────────────────────────────
// Animated Search Bar
// ─────────────────────────────────────────────────────────
class _AnimatedSearchBar extends StatefulWidget {
  @override
  State<_AnimatedSearchBar> createState() => _AnimatedSearchBarState();
}

class _AnimatedSearchBarState extends State<_AnimatedSearchBar> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      width: _focused ? 280 : 220,
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        boxShadow: _focused
            ? [BoxShadow(color: AppColors.primary.withValues(alpha: 0.1), blurRadius: 8)]
            : null,
      ),
      child: TextField(
        onTap: () => setState(() => _focused = true),
        onSubmitted: (_) => setState(() => _focused = false),
        decoration: InputDecoration(
          hintText: 'Rechercher...',
          hintStyle: AppTextStyles.bodySmall.copyWith(color: AppColors.outline),
          prefixIcon: const Icon(Icons.search, size: 18, color: AppColors.outline),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
          isDense: true,
        ),
        style: AppTextStyles.bodySmall,
      ),
    );
  }
}
