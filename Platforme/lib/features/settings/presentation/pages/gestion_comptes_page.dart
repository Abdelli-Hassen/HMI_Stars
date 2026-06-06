import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/models/platform_user.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/main_shell.dart';
import '../../../../core/utils/translation_extension.dart';

class GestionComptesPage extends StatefulWidget {
  const GestionComptesPage({super.key});

  @override
  State<GestionComptesPage> createState() => _GestionComptesPageState();
}

class _GestionComptesPageState extends State<GestionComptesPage> {
  List<UtilisateurPlateforme> _allUsers = [];
  List<UtilisateurPlateforme> _filteredUsers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    final users = await context.read<AuthProvider>().fetchAllUsers();
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
    await _loadUsers();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(context.tr(
          'Le rôle de ${user.nom} a été mis à jour.',
          'The role of ${user.nom} has been updated.',
        )),
        backgroundColor: AppColors.success,
      ));
    }
  }

  Future<void> _confirmDelete(UtilisateurPlateforme user) async {
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.utilisateur?.id;
    if (user.id == currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(context.tr(
          'Vous ne pouvez pas supprimer votre propre compte ici.',
          'You cannot delete your own account here.',
        )),
        backgroundColor: AppColors.error,
      ));
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
      setState(() => _isLoading = true);
      try {
        await authProvider.deleteUser(user.id);
        await _loadUsers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(context.tr('Utilisateur supprimé avec succès.', 'User deleted successfully.')),
            backgroundColor: AppColors.success,
          ));
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(context.tr('Erreur lors de la suppression.', 'Error during deletion.')),
            backgroundColor: AppColors.error,
          ));
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
                    child: Text(user.nom.isNotEmpty ? user.nom[0].toUpperCase() : '?', style: TextStyle(color: cs.onPrimaryContainer)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.nom.isNotEmpty ? user.nom : context.tr('Sans Nom', 'No Name'), style: AppTextStyles.titleSmall.copyWith(color: cs.onSurface)),
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
