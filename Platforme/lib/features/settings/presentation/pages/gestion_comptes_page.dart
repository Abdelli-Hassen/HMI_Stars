import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/models/platform_user.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/main_shell.dart';
import '../../../../core/utils/translation_extension.dart';
import '../../../../core/utils/toast_utils.dart';
import '../../../messagerie/presentation/providers/messagerie_provider.dart';

class GestionComptesPage extends StatefulWidget {
  const GestionComptesPage({super.key});

  @override
  State<GestionComptesPage> createState() => _GestionComptesPageState();
}

class _GestionComptesPageState extends State<GestionComptesPage> {
  List<UtilisateurPlateforme> _allUsers = [];
  List<UtilisateurPlateforme> _filteredUsers = [];
  bool _isLoading = true;
  AuthProvider? _authProvider;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _authProvider = context.read<AuthProvider>();
        _authProvider!.addListener(_onAuthChanged);
        _loadUsers();
      }
    });
  }

  void _onAuthChanged() {
    if (_allUsers.isEmpty && _authProvider != null && _authProvider!.isAuthenticated) {
      _loadUsers();
    }
  }

  @override
  void dispose() {
    _authProvider?.removeListener(_onAuthChanged);
    super.dispose();
  }

  Future<void> _loadUsers() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    final users = await context.read<AuthProvider>().fetchAllUsers();
    if (!mounted) return;
    setState(() {
      _allUsers = users;
      _filteredUsers = users;
      _isLoading = false;
    });
  }

  void _filterUsers(String query) {
    setState(() {
      _filteredUsers = _allUsers.where((user) {
        final nomMatch = user.nom.toLowerCase().contains(query.toLowerCase());
        final emailMatch = user.email.toLowerCase().contains(query.toLowerCase());
        return nomMatch || emailMatch;
      }).toList();
    });
  }

  Future<void> _changeRole(UtilisateurPlateforme user, String newRole) async {
    if (user.role == newRole) return;
    
    setState(() => _isLoading = true);
    await context.read<AuthProvider>().changeUserRole(user.id, newRole);
    if (!mounted) return;
    await _loadUsers();
    
    if (mounted) {
      ToastUtils.show(
        context,
        context.tr(
          'Le rôle de ${user.nom} a été mis à jour.',
          'The role of ${user.nom} has been updated.',
        ),
        isError: false,
      );
    }
  }

  Future<void> _confirmDelete(UtilisateurPlateforme user) async {
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.utilisateur?.id;
    if (user.id == currentUserId) {
      ToastUtils.show(
        context,
        context.tr(
          'Vous ne pouvez pas supprimer votre propre compte ici.',
          'You cannot delete your own account here.',
        ),
        isError: true,
      );
      return;
    }

    final cs = Theme.of(context).colorScheme;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: cs.surfaceContainerLowest,
        title: Text(
          context.tr('Supprimer l\'utilisateur', 'Delete User'),
          style: AppTextStyles.titleMedium.copyWith(color: cs.onSurface),
        ),
        content: Text(
          context.tr(
            'Voulez-vous vraiment supprimer définitivement le compte de ${user.nom} (${user.email}) ? Cette action est irréversible.',
            'Are you sure you want to permanently delete the account of ${user.nom} (${user.email})? This action is irreversible.',
          ),
          style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('Annuler', 'Cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: Text(context.tr('Supprimer', 'Delete')),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      setState(() => _isLoading = true);
      try {
        await authProvider.deleteUser(user.id);
        if (!mounted) return;
        await _loadUsers();
        if (mounted) {
          ToastUtils.show(
            context,
            context.tr('Utilisateur supprimé avec succès.', 'User deleted successfully.'),
            isError: false,
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ToastUtils.show(
            context,
            context.tr('Erreur lors de la suppression.', 'Error during deletion.'),
            isError: true,
          );
        }
      }
    }
  }

  Future<void> _impersonateUser(UtilisateurPlateforme user) async {
    final authProvider = context.read<AuthProvider>();
    
    if (user.id == authProvider.utilisateur?.id) {
      ToastUtils.show(
        context,
        context.tr(
          'Vous êtes déjà connecté à ce compte.',
          'You are already logged into this account.',
        ),
        isError: false, // shows as normal notification/warning status in custom toast
      );
      return;
    }

    final cs = Theme.of(context).colorScheme;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: cs.surfaceContainerLowest,
        title: Text(
          context.tr('Accéder au compte', 'Access Account'),
          style: AppTextStyles.titleMedium.copyWith(color: cs.onSurface),
        ),
        content: Text(
          context.tr(
            'Voulez-vous ouvrir la session de ${user.nom} sans mot de passe ? Un e-mail de notification d\'accès sera envoyé à l\'utilisateur.',
            'Do you want to open the session of ${user.nom} without a password? A notification access email will be sent to the user.',
          ),
          style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurfaceVariant),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.tr('Annuler', 'Cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: cs.primary, foregroundColor: Colors.white),
            child: Text(context.tr('Ouvrir', 'Open')),
          ),
        ],
      ),
    );

    if (confirm == true) {
      if (!mounted) return;
      try {
        authProvider.impersonateUser(user);
        Provider.of<MessagerieProvider>(context, listen: false).setOverrideUserId(user.id);
        
        ToastUtils.show(
          context,
          context.tr(
            'Session ouverte en tant que ${user.nom}. Email de notification envoyé.',
            'Session opened as ${user.nom}. Notification email sent.',
          ),
          isError: false,
        );
        
        Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
      } catch (e) {
        if (mounted) {
          ToastUtils.show(
            context,
            '${context.tr('Erreur: ', 'Error: ')}$e',
            isError: true,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return MainShell(
      currentRoute: AppRoutes.gestionComptes,
      title: context.tr('Gestion des Comptes', 'Account Management'),
      body: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(context.tr('Comptes Utilisateurs', 'User Accounts'), style: AppTextStyles.headlineMedium.copyWith(color: cs.onSurface)),
            const SizedBox(height: 4),
            Text(
              context.tr(
                'Gérez les rôles et les accès de tous les utilisateurs de la plateforme.',
                'Manage roles and access for all platform users.',
              ),
              style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurfaceVariant),
            ),
            const SizedBox(height: 28),
            
            // Search Bar
            Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: TextField(
                onChanged: _filterUsers,
                style: TextStyle(color: cs.onSurface),
                decoration: InputDecoration(
                  hintText: context.tr('Rechercher par nom ou email...', 'Search by name or email...'),
                  prefixIcon: Icon(Icons.search, color: cs.onSurfaceVariant),
                  filled: true,
                  fillColor: cs.surfaceContainerLowest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Users Table
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _filteredUsers.isEmpty
                      ? Center(child: Text(context.tr('Aucun utilisateur trouvé.', 'No user found.'), style: AppTextStyles.bodyLarge.copyWith(color: cs.onSurface)))
                      : _buildUsersTable(cs),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersTable(ColorScheme cs) {
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: ListView.separated(
          itemCount: _filteredUsers.length,
          separatorBuilder: (context, index) => Divider(height: 1, color: cs.outlineVariant),
          itemBuilder: (context, index) {
            final user = _filteredUsers[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                   CircleAvatar(
                    backgroundColor: cs.primaryContainer,
                    backgroundImage: (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                        ? NetworkImage(user.avatarUrl!)
                        : null,
                    child: (user.avatarUrl == null || user.avatarUrl!.isEmpty)
                        ? Text(
                            user.nom.isNotEmpty ? user.nom[0].toUpperCase() : '?',
                            style: const TextStyle(color: Colors.white),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          children: [
                            Text(
                              user.nom.isNotEmpty ? user.nom : context.tr('Sans Nom', 'No Name'),
                              style: AppTextStyles.titleSmall.copyWith(color: cs.onSurface),
                            ),
                            if (!user.emailConfirme)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.amber.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(color: Colors.amber.withValues(alpha: 0.5)),
                                ),
                                child: Text(
                                  context.tr('Non vérifié', 'Unverified'),
                                  style: TextStyle(
                                    color: Colors.amber[800] ?? Colors.amber,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        Text(user.email, style: AppTextStyles.bodySmall.copyWith(color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Text(
                      context.tr(
                        'Créé le ${user.creeLe.day}/${user.creeLe.month}/${user.creeLe.year}',
                        'Created on ${user.creeLe.day}/${user.creeLe.month}/${user.creeLe.year}',
                      ),
                      style: AppTextStyles.bodySmall.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ),
                  // Approval Status Switch
                  Tooltip(
                    message: user.estApprouve 
                        ? context.tr('Compte actif / approuvé', 'Active / approved account') 
                        : context.tr('Compte suspendu / en attente', 'Suspended / pending account'),
                    child: Switch(
                      value: user.estApprouve,
                      activeThumbColor: AppColors.success,
                      activeTrackColor: AppColors.success.withValues(alpha: 0.2),
                      onChanged: user.id == context.read<AuthProvider>().utilisateur?.id 
                          ? null // Cannot disable approval for yourself
                          : (val) async {
                              final auth = context.read<AuthProvider>();
                              setState(() => _isLoading = true);
                              await auth.toggleUserApproval(user.id, val);
                              await _loadUsers();
                              if (!mounted) return;
                              ToastUtils.show(
                                context,
                                val 
                                    ? context.tr('Compte approuvé avec succès.', 'Account approved successfully.')
                                    : context.tr('Compte suspendu.', 'Account suspended.'),
                                isError: !val,
                              );
                            },
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Role Dropdown
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: (user.role == 'admin' || user.role == 'secretaire') ? user.role : 'secretaire',
                        icon: const Icon(Icons.arrow_drop_down, size: 20),
                        dropdownColor: cs.surfaceContainerLowest,
                        style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurface),
                        items: [
                          DropdownMenuItem(value: 'admin', child: Text(context.tr('ADMIN', 'ADMIN'))),
                          DropdownMenuItem(value: 'secretaire', child: Text(context.tr('SECRÉTAIRE', 'SECRETARY'))),
                        ],
                        onChanged: (newRole) {
                          if (newRole != null) _changeRole(user, newRole);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Confirm Email Action (if not verified)
                  if (!user.emailConfirme) ...[
                    IconButton(
                      icon: const Icon(Icons.mark_email_read_outlined, color: AppColors.success),
                      tooltip: context.tr('Confirmer l\'e-mail manuellement', 'Confirm email manually'),
                      onPressed: () async {
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (context) => AlertDialog(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            backgroundColor: cs.surfaceContainerLowest,
                            title: Text(
                              context.tr('Confirmer le compte', 'Verify Account'),
                              style: AppTextStyles.titleMedium.copyWith(color: cs.onSurface),
                            ),
                            content: Text(
                              context.tr(
                                'Voulez-vous confirmer manuellement l\'adresse e-mail de ${user.nom} (${user.email}) ?',
                                'Do you want to manually verify the email address of ${user.nom} (${user.email})?',
                              ),
                              style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurfaceVariant),
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context, false),
                                child: Text(context.tr('Annuler', 'Cancel')),
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.pop(context, true),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.success,
                                  foregroundColor: Colors.white,
                                ),
                                child: Text(context.tr('Confirmer', 'Verify')),
                              ),
                            ],
                          ),
                        );

                        if (confirm == true) {
                          if (!mounted) return;
                          setState(() => _isLoading = true);
                          try {
                            await context.read<AuthProvider>().confirmUserEmail(user.id);
                            await _loadUsers();
                            if (mounted) {
                              ToastUtils.show(
                                context,
                                context.tr(
                                  'E-mail de ${user.nom} confirmé avec succès.',
                                  'Email of ${user.nom} successfully confirmed.',
                                ),
                                isError: false,
                              );
                            }
                          } catch (e) {
                            if (mounted) {
                              setState(() => _isLoading = false);
                              ToastUtils.show(
                                context,
                                context.tr(
                                  'Erreur lors de la confirmation.',
                                  'Error confirming email.',
                                ),
                                isError: true,
                              );
                            }
                          }
                        }
                      },
                    ),
                  ],
                  // Impersonate Action
                  IconButton(
                    icon: Icon(Icons.login_rounded, color: cs.primary),
                    tooltip: context.tr('Accéder au compte', 'Access account'),
                    onPressed: () => _impersonateUser(user),
                  ),
                  const SizedBox(width: 8),
                  // Delete Action
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: AppColors.error),
                    tooltip: context.tr('Supprimer le compte', 'Delete account'),
                    onPressed: () => _confirmDelete(user),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
