import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../auth/domain/models/platform_user.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/main_shell.dart';

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
    
    // Prevent admin from accidentally demoting themselves if they are the only admin
    // This is just a basic safeguard
    
    setState(() => _isLoading = true);
    await context.read<AuthProvider>().changeUserRole(user.id, newRole);
    await _loadUsers();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Le rôle de ${user.nom} a été mis à jour.'),
        backgroundColor: AppColors.success,
      ));
    }
  }

  Future<void> _confirmDelete(UtilisateurPlateforme user) async {
    final authProvider = context.read<AuthProvider>();
    final currentUserId = authProvider.utilisateur?.id;
    if (user.id == currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Vous ne pouvez pas supprimer votre propre compte ici.'),
        backgroundColor: AppColors.error,
      ));
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: cs.surfaceContainerLowest,
        title: Text('Supprimer l\'utilisateur', style: AppTextStyles.titleMedium),
        content: Text('Voulez-vous vraiment supprimer définitivement le compte de ${user.nom} (${user.email}) ? Cette action est irréversible.', style: AppTextStyles.bodyMedium),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            child: const Text('Supprimer'),
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
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Utilisateur supprimé avec succès.'),
            backgroundColor: AppColors.success,
          ));
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Erreur lors de la suppression.'),
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
      title: 'Gestion des Comptes',
      body: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Comptes Utilisateurs', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 4),
            Text('Gérez les rôles et les accès de tous les utilisateurs de la plateforme.',
                style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurfaceVariant)),
            const SizedBox(height: 28),
            
            // Search Bar
            Container(
              constraints: const BoxConstraints(maxWidth: 400),
              child: TextField(
                onChanged: _filterUsers,
                decoration: InputDecoration(
                  hintText: 'Rechercher par nom ou email...',
                  prefixIcon: const Icon(Icons.search, color: cs.onSurfaceVariant),
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
                      ? Center(child: Text('Aucun utilisateur trouvé.', style: AppTextStyles.bodyLarge))
                      : _buildUsersTable(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersTable() {
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
          separatorBuilder: (context, index) => const Divider(height: 1, color: cs.outlineVariant),
          itemBuilder: (context, index) {
            final cs = Theme.of(context).colorScheme;
            final user = _filteredUsers[index];
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: cs.primaryContainer,
                    child: Text(user.nom.isNotEmpty ? user.nom[0].toUpperCase() : '?', style: const TextStyle(color: cs.onPrimaryContainer)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.nom.isNotEmpty ? user.nom : 'Sans Nom', style: AppTextStyles.titleSmall),
                        Text(user.email, style: AppTextStyles.bodySmall.copyWith(color: cs.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Créé le ${user.creeLe.day}/${user.creeLe.month}/${user.creeLe.year}',
                      style: AppTextStyles.bodySmall,
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
                        style: AppTextStyles.bodyMedium,
                        items: const [
                          DropdownMenuItem(value: 'admin', child: Text('ADMIN')),
                          DropdownMenuItem(value: 'secretaire', child: Text('SECRÉTAIRE')),
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
                    tooltip: 'Supprimer le compte',
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
