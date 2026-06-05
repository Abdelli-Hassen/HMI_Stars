import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/main_shell.dart';
import '../../../../core/widgets/staggered_column.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/utils/translation_extension.dart';
import '../../../auth/domain/models/platform_user.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  String _selectedLangue = 'Français (FR)';
  bool _uploadingAvatar = false;

  late TextEditingController _nomController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _cinController;

  UtilisateurPlateforme? _lastUser;

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _cinController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.watch<AuthProvider>();
    
    if (auth.utilisateur != null && auth.utilisateur != _lastUser) {
      _lastUser = auth.utilisateur;
      
      _nomController.text = auth.userName;
      _emailController.text = auth.userEmail;
      _phoneController.text = auth.userPhone;
      _cinController.text = auth.userCin;
      
      final prefs = auth.utilisateur!.preferences;
      _selectedLangue = prefs['langue'] ?? 'Français (FR)';
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _cinController.dispose();
    super.dispose();
  }

  void _sauvegarderProfil() {
    final auth = context.read<AuthProvider>();
    auth.updateUser(
      _nomController.text, 
      auth.userRole, // keep current role
      auth.userEmail, // email is read-only, keep current
      telephone: _phoneController.text,
      cin: _cinController.text,
    );
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(context.tr('Profil sauvegardé avec succès !', 'Profile saved successfully!')),
      backgroundColor: AppColors.success,
    ));
  }

  void _sauvegarderWorkspace() {
    final prefs = context.read<AuthProvider>().utilisateur?.preferences ?? {};
    prefs['langue'] = _selectedLangue;
    
    context.read<AuthProvider>().mettreAJourProfil(
      preferences: prefs,
    );
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(context.tr('Espace de travail mis à jour avec succès !', 'Workspace updated successfully!')),
      backgroundColor: AppColors.success,
    ));
  }

  Future<void> _modifierPhoto() async {
    final messenger = ScaffoldMessenger.of(context);
    final auth = context.read<AuthProvider>();
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.first;
      if (file.bytes == null || file.name.isEmpty) return;

      setState(() => _uploadingAvatar = true);

      final success = await auth.uploadAvatar(file.bytes!, file.name);

      if (!mounted) return;
      setState(() => _uploadingAvatar = false);

      messenger.showSnackBar(SnackBar(
        content: Text(success
            ? context.tr('Photo de profil mise à jour avec succès !', 'Profile picture updated successfully!')
            : context.tr('Erreur lors de la mise à jour de la photo.', 'Error updating picture.')),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ));
    } catch (e) {
      if (mounted) {
        setState(() => _uploadingAvatar = false);
        messenger.showSnackBar(SnackBar(
          content: Text(context.tr('Erreur lors de la sélection du fichier.', 'Error selecting file.')),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainShell(
      currentRoute: AppRoutes.settings,
      title: context.tr('Paramètres du Compte', 'Account Settings'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: StaggeredColumn(
          children: [
            Text(context.tr('Paramètres', 'Settings'), style: AppTextStyles.headlineMedium.copyWith(color: Theme.of(context).colorScheme.onSurface)),
            const SizedBox(height: 4),
            Text(context.tr('Gérez votre profil (Admin / Secrétaire), vos préférences et la sécurité de votre compte.', 'Manage your profile (Admin / Secretary), preferences, and account security.'),
                style: AppTextStyles.bodyMedium.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 28),

            // ─── Profile Row ───
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(child: _buildProfileSection()),
              const SizedBox(width: 16),
              Expanded(child: _buildWorkspaceSection()),
            ]),
            const SizedBox(height: 24),

            // ─── Security Section ───
            _buildSecuritySection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    final cs = Theme.of(context).colorScheme;
    final auth = context.watch<AuthProvider>();
    final avatarUrl = auth.userAvatarUrl;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withValues(alpha: 0.35)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(context.tr('PROFIL UTILISATEUR', 'USER PROFILE'), style: AppTextStyles.labelSmall.copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w700, color: cs.onSurfaceVariant)),
        const SizedBox(height: 20),
        Row(children: [
          Stack(
            children: [
              CircleAvatar(
                key: ValueKey(avatarUrl),
                radius: 32,
                backgroundColor: cs.surfaceContainerHigh,
                backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                    ? NetworkImage(avatarUrl)
                    : null,
                child: avatarUrl == null || avatarUrl.isEmpty
                    ? Icon(Icons.person, size: 32, color: cs.onSurfaceVariant)
                    : null,
              ),
              if (_uploadingAvatar)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black45,
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_nomController.text.isNotEmpty ? _nomController.text : context.tr('Utilisateur Actuel', 'Current User'), style: AppTextStyles.titleSmall.copyWith(color: cs.onSurface)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _uploadingAvatar ? null : _modifierPhoto,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(border: Border.all(color: cs.outline.withValues(alpha: 0.35)), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.camera_alt_outlined, size: 14, color: _uploadingAvatar ? cs.outline : cs.primary),
                    const SizedBox(width: 6),
                    Text(
                      _uploadingAvatar ? context.tr('ENVOI EN COURS...', 'UPLOADING...') : context.tr('MODIFIER LA PHOTO', 'CHANGE PHOTO'),
                      style: AppTextStyles.labelSmall.copyWith(letterSpacing: 0.8, fontWeight: FontWeight.w700, color: cs.onSurface),
                    ),
                  ],
                ),
              ),
            ),
          ]),
        ]),
        const SizedBox(height: 28),
        _textField(context.tr('Nom Complet', 'Full Name'), _nomController, Icons.person_outline),
        const SizedBox(height: 16),
        _disabledTextField(context.tr('Adresse E-mail', 'Email Address'), _emailController, Icons.email_outlined),
        const SizedBox(height: 16),
        _textField(context.tr('Téléphone', 'Phone'), _phoneController, Icons.phone_outlined),
        const SizedBox(height: 16),
        _textField(context.tr('N° Carte d\'Identité (CIN)', 'Identity Card Number (CIN)'), _cinController, Icons.badge_outlined),
        const SizedBox(height: 20),
        _saveButton(_sauvegarderProfil),
      ]),
    );
  }

  Widget _buildWorkspaceSection() {
    final cs = Theme.of(context).colorScheme;
    final themeProvider = context.watch<ThemeProvider>();
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withValues(alpha: 0.35)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(context.tr("ESPACE DE TRAVAIL", "WORKSPACE"), style: AppTextStyles.labelSmall.copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w700, color: cs.onSurfaceVariant)),
        const SizedBox(height: 20),
        _lockedTextField(context.tr("Organisation", "Organization"), 'HMI Stars Consulting', Icons.corporate_fare),
        const SizedBox(height: 16),
        _staticDropdownField(context.tr('Langue par défaut', 'Default Language'), _selectedLangue, ['Français (FR)', 'English (EN)'], (v) => setState(() => _selectedLangue = v!)),
        const SizedBox(height: 16),
        // Dark Mode Toggle
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cs.primary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    themeProvider.isDarkMode ? Icons.dark_mode : Icons.light_mode,
                    size: 20, 
                    color: cs.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.tr('Mode Sombre', 'Dark Mode'),
                      style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600, color: cs.onSurface),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      themeProvider.isDarkMode ? context.tr('Activé', 'Enabled') : context.tr('Désactivé', 'Disabled'),
                      style: AppTextStyles.bodySmall.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
            Switch(
              value: themeProvider.isDarkMode,
              onChanged: (val) => themeProvider.toggleTheme(val),
              activeThumbColor: cs.primary,
              activeTrackColor: cs.primary.withValues(alpha: 0.3),
              inactiveThumbColor: cs.outline,
              inactiveTrackColor: cs.surfaceContainerHigh,
            ),
          ],
        ),
        const SizedBox(height: 20),
        _saveButton(_sauvegarderWorkspace),
      ]),
    );
  }


  void _modifierMotDePasse() {
    bool obscureAncien = true;
    bool obscureNouveau = true;
    bool isLoading = false;
    final ancienCtrl = TextEditingController();
    final nouveauCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          final cs = Theme.of(context).colorScheme;
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            backgroundColor: cs.surfaceContainerLowest,
            titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
            contentPadding: const EdgeInsets.symmetric(horizontal: 24),
            actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: cs.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                  child: Icon(Icons.lock_reset, color: cs.primary),
                ),
                const SizedBox(width: 12),
                Text(context.tr('Modifier le mot de passe', 'Change Password'), style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold, color: cs.onSurface)),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(context.tr('Ancien mot de passe', 'Old Password'), style: AppTextStyles.labelMedium.copyWith(color: cs.onSurfaceVariant)),
                const SizedBox(height: 8),
                TextField(
                  controller: ancienCtrl,
                  decoration: InputDecoration(
                    hintText: '••••••••', 
                    isDense: true,
                    filled: true,
                    fillColor: cs.surfaceContainerLow,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.35))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.35))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.primary, width: 1.5)),
                    prefixIcon: Icon(Icons.password, size: 18, color: cs.outline),
                    suffixIcon: IconButton(
                      icon: Icon(obscureAncien ? Icons.visibility_off : Icons.visibility, size: 18, color: cs.outline),
                      onPressed: () => setStateDialog(() => obscureAncien = !obscureAncien),
                    ),
                  ), 
                  obscureText: obscureAncien,
                  style: TextStyle(color: cs.onSurface),
                ),
                const SizedBox(height: 20),
                Text(context.tr('Nouveau mot de passe', 'New Password'), style: AppTextStyles.labelMedium.copyWith(color: cs.onSurfaceVariant)),
                const SizedBox(height: 8),
                TextField(
                  controller: nouveauCtrl,
                  decoration: InputDecoration(
                    hintText: '••••••••', 
                    isDense: true,
                    filled: true,
                    fillColor: cs.surfaceContainerLow,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.35))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.outline.withValues(alpha: 0.35))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: cs.primary, width: 1.5)),
                    prefixIcon: Icon(Icons.lock_outline, size: 18, color: cs.outline),
                    suffixIcon: IconButton(
                      icon: Icon(obscureNouveau ? Icons.visibility_off : Icons.visibility, size: 18, color: cs.outline),
                      onPressed: () => setStateDialog(() => obscureNouveau = !obscureNouveau),
                    ),
                  ), 
                  obscureText: obscureNouveau,
                  style: TextStyle(color: cs.onSurface),
                ),
                const SizedBox(height: 12),
                Text(context.tr('Minimum 8 caractères, incluant des lettres et des chiffres.', 'Minimum 8 characters, including letters and numbers.'), style: AppTextStyles.bodySmall.copyWith(color: cs.onSurfaceVariant)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isLoading ? null : () => Navigator.pop(context), 
                style: TextButton.styleFrom(foregroundColor: cs.onSurfaceVariant),
                child: Text(context.tr('Annuler', 'Cancel'))
              ),
              ElevatedButton(
                onPressed: isLoading ? null : () async {
                  final nouveau = nouveauCtrl.text.trim();
                  if (nouveau.length < 8) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(context.tr('Le mot de passe doit contenir au moins 8 caractères.', 'Password must be at least 8 characters long.')),
                      backgroundColor: AppColors.error,
                    ));
                    return;
                  }
                  setStateDialog(() => isLoading = true);
                  try {
                    final auth = Provider.of<AuthProvider>(context, listen: false);
                    await auth.changePassword(nouveau);
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(context.tr('Mot de passe mis à jour avec succès.', 'Password updated successfully.')),
                        backgroundColor: AppColors.success,
                      ));
                    }
                  } catch (e) {
                    setStateDialog(() => isLoading = false);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text('${context.tr('Erreur: ', 'Error: ')}$e'),
                        backgroundColor: AppColors.error,
                      ));
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary, 
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: isLoading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(context.tr('Mettre à jour', 'Update')),
              ),
            ],
          );
        }
      )
    );
  }

  Widget _buildSecuritySection() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outline.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(context.tr('SÉCURITÉ', 'SECURITY'), style: AppTextStyles.labelSmall.copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w700, color: cs.onSurfaceVariant)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: cs.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.lock_outline, size: 20, color: cs.primary),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    context.tr('Mot de passe', 'Password'),
                    style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600, color: cs.onSurfaceVariant),
                  ),
                ],
              ),
              GestureDetector(
                onTap: _modifierMotDePasse,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: cs.outline.withValues(alpha: 0.35)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.lock_reset, size: 16, color: cs.primary),
                      const SizedBox(width: 8),
                      Text(context.tr('Modifier', 'Modify'), style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600, color: cs.onSurface)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _textField(String label, TextEditingController controller, IconData icon) {
    final cs = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller,
        style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurface),
        decoration: InputDecoration(
            isDense: true,
            prefixIcon: Icon(icon, size: 18, color: cs.outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            filled: true,
            fillColor: cs.surfaceContainerLow,
        ),
      ),
    ]);
  }

  Widget _disabledTextField(String label, TextEditingController controller, IconData icon) {
    final cs = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller,
        readOnly: true,
        enabled: false,
        style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurfaceVariant),
        decoration: InputDecoration(
            isDense: true,
            prefixIcon: Icon(icon, size: 18, color: cs.outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            filled: true,
            fillColor: cs.surfaceContainerLow,
        ),
      ),
    ]);
  }

  Widget _lockedTextField(String label, String value, IconData icon) {
    final cs = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
      const SizedBox(height: 6),
      TextFormField(
        initialValue: value,
        readOnly: true,
        style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurface),
        decoration: InputDecoration(
            isDense: true,
            prefixIcon: Icon(icon, size: 18, color: cs.outline),
            suffixIcon: Icon(Icons.lock_outline, size: 16, color: cs.outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            filled: true,
            fillColor: cs.surfaceContainerLow,
        ),
      ),
    ]);
  }

  Widget _staticDropdownField(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    final cs = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600, color: cs.onSurfaceVariant)),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(color: cs.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            dropdownColor: cs.surfaceContainerLowest,
            icon: Icon(Icons.keyboard_arrow_down, size: 18, color: cs.outline),
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item, style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurface)),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    ]);
  }

  Widget _saveButton(VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      child: Container(
        decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(12)),
        child: ElevatedButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.check, size: 18),
          label: Text(context.tr('Sauvegarder les Modifications', 'Save Changes')),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
        ),
      ),
    );
  }
}
