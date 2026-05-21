import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/main_shell.dart';
import '../../../../core/widgets/staggered_column.dart';
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
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Profil sauvegardé avec succès !'),
      backgroundColor: AppColors.success,
    ));
  }

  void _sauvegarderWorkspace() {
    final prefs = context.read<AuthProvider>().utilisateur?.preferences ?? {};
    prefs['langue'] = _selectedLangue;
    
    context.read<AuthProvider>().mettreAJourProfil(
      preferences: prefs,
    );
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Espace de travail mis à jour avec succès !'),
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
            ? 'Photo de profil mise à jour avec succès !'
            : 'Erreur lors de la mise à jour de la photo.'),
        backgroundColor: success ? AppColors.success : AppColors.error,
      ));
    } catch (e) {
      if (mounted) {
        setState(() => _uploadingAvatar = false);
        messenger.showSnackBar(const SnackBar(
          content: Text('Erreur lors de la sélection du fichier.'),
          backgroundColor: AppColors.error,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MainShell(
      currentRoute: AppRoutes.settings,
      title: 'Paramètres du Compte',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: StaggeredColumn(
          children: [
            Text('Paramètres', style: AppTextStyles.headlineMedium),
            const SizedBox(height: 4),
            Text('Gérez votre profil (Admin / Secrétaire), vos préférences et la sécurité de votre compte.',
                style: AppTextStyles.bodyMedium.copyWith(color: AppColors.onSurfaceVariant)),
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
    final auth = context.watch<AuthProvider>();
    final avatarUrl = auth.userAvatarUrl;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('PROFIL UTILISATEUR', style: AppTextStyles.labelSmall.copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w700)),
        const SizedBox(height: 20),
        Row(children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.surfaceContainerHigh,
                backgroundImage: avatarUrl != null && avatarUrl.isNotEmpty
                    ? NetworkImage(avatarUrl)
                    : null,
                child: avatarUrl == null || avatarUrl.isEmpty
                    ? const Icon(Icons.person, size: 32, color: AppColors.onSurfaceVariant)
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
            Text(_nomController.text.isNotEmpty ? _nomController.text : 'Utilisateur Actuel', style: AppTextStyles.titleSmall),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _uploadingAvatar ? null : _modifierPhoto,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(border: Border.all(color: AppColors.outlineVariant), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.camera_alt_outlined, size: 14, color: _uploadingAvatar ? AppColors.outline : AppColors.primary),
                    const SizedBox(width: 6),
                    Text(
                      _uploadingAvatar ? 'ENVOI EN COURS...' : 'MODIFIER LA PHOTO',
                      style: AppTextStyles.labelSmall.copyWith(letterSpacing: 0.8, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
          ]),
        ]),
        const SizedBox(height: 28),
        _textField('Nom Complet', _nomController, Icons.person_outline),
        const SizedBox(height: 16),
        _disabledTextField('Adresse E-mail', _emailController, Icons.email_outlined),
        const SizedBox(height: 16),
        _textField('Téléphone', _phoneController, Icons.phone_outlined),
        const SizedBox(height: 16),
        _textField('N° Carte d\'Identité (CIN)', _cinController, Icons.badge_outlined),
        const SizedBox(height: 20),
        _saveButton(_sauvegarderProfil),
      ]),
    );
  }

  Widget _buildWorkspaceSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("ESPACE DE TRAVAIL", style: AppTextStyles.labelSmall.copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w700)),
        const SizedBox(height: 20),
        _lockedTextField("Organisation", 'HMI Stars Consulting', Icons.corporate_fare),
        const SizedBox(height: 16),
        _staticDropdownField('Langue par défaut', _selectedLangue, ['Français (FR)', 'English (EN)'], (v) => setState(() => _selectedLangue = v!)),
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
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          backgroundColor: AppColors.surfaceContainerLowest,
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24),
          actionsPadding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: AppColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.lock_reset, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Text('Modifier le mot de passe', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ancien mot de passe', style: AppTextStyles.labelMedium.copyWith(color: AppColors.onSurfaceVariant)),
              const SizedBox(height: 8),
              TextField(
                controller: ancienCtrl,
                decoration: InputDecoration(
                  hintText: '••••••••', 
                  isDense: true,
                  filled: true,
                  fillColor: AppColors.surfaceContainerLow,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.password, size: 18, color: AppColors.outline),
                  suffixIcon: IconButton(
                    icon: Icon(obscureAncien ? Icons.visibility_off : Icons.visibility, size: 18, color: AppColors.outline),
                    onPressed: () => setStateDialog(() => obscureAncien = !obscureAncien),
                  ),
                ), 
                obscureText: obscureAncien,
              ),
              const SizedBox(height: 20),
              Text('Nouveau mot de passe', style: AppTextStyles.labelMedium.copyWith(color: AppColors.onSurfaceVariant)),
              const SizedBox(height: 8),
              TextField(
                controller: nouveauCtrl,
                decoration: InputDecoration(
                  hintText: '••••••••', 
                  isDense: true,
                  filled: true,
                  fillColor: AppColors.surfaceContainerLow,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  prefixIcon: const Icon(Icons.lock_outline, size: 18, color: AppColors.outline),
                  suffixIcon: IconButton(
                    icon: Icon(obscureNouveau ? Icons.visibility_off : Icons.visibility, size: 18, color: AppColors.outline),
                    onPressed: () => setStateDialog(() => obscureNouveau = !obscureNouveau),
                  ),
                ), 
                obscureText: obscureNouveau,
              ),
              const SizedBox(height: 12),
              Text('Minimum 8 caractères, incluant des lettres et des chiffres.', style: AppTextStyles.bodySmall.copyWith(color: AppColors.onSurfaceVariant)),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(context), 
              style: TextButton.styleFrom(foregroundColor: AppColors.onSurfaceVariant),
              child: const Text('Annuler')
            ),
            ElevatedButton(
              onPressed: isLoading ? null : () async {
                final nouveau = nouveauCtrl.text.trim();
                if (nouveau.length < 8) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Le mot de passe doit contenir au moins 8 caractères.'),
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
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Mot de passe mis à jour avec succès.'),
                      backgroundColor: AppColors.success,
                    ));
                  }
                } catch (e) {
                  setStateDialog(() => isLoading = false);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Erreur: $e'),
                      backgroundColor: AppColors.error,
                    ));
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary, 
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: isLoading
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Mettre à jour'),
            ),
          ],
        )
      )
    );
  }

  Widget _buildSecuritySection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('SÉCURITÉ', style: AppTextStyles.labelSmall.copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.lock_outline, size: 20, color: AppColors.primary),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Mot de passe',
                    style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
              GestureDetector(
                onTap: _modifierMotDePasse,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.outlineVariant),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_reset, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text('Modifier', style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600)),
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
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant)),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller,
        style: AppTextStyles.bodyMedium,
        decoration: InputDecoration(
            isDense: true,
            prefixIcon: Icon(icon, size: 18, color: AppColors.outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            filled: true,
            fillColor: AppColors.surfaceContainerLow,
        ),
      ),
    ]);
  }

  Widget _disabledTextField(String label, TextEditingController controller, IconData icon) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant)),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller,
        readOnly: true,
        enabled: false,
        style: AppTextStyles.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
        decoration: InputDecoration(
            isDense: true,
            prefixIcon: Icon(icon, size: 18, color: AppColors.outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            filled: true,
            fillColor: AppColors.surfaceContainerLow,
        ),
      ),
    ]);
  }

  Widget _lockedTextField(String label, String value, IconData icon) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant)),
      const SizedBox(height: 6),
      TextFormField(
        initialValue: value,
        readOnly: true,
        style: AppTextStyles.bodyMedium,
        decoration: InputDecoration(
            isDense: true,
            prefixIcon: Icon(icon, size: 18, color: AppColors.outline),
            suffixIcon: const Icon(Icons.lock_outline, size: 16, color: AppColors.outline),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            filled: true,
            fillColor: AppColors.surfaceContainerLow,
        ),
      ),
    ]);
  }

  Widget _staticDropdownField(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600, color: AppColors.onSurfaceVariant)),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        decoration: BoxDecoration(color: AppColors.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.outline),
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item, style: AppTextStyles.bodyMedium),
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
          label: const Text('Sauvegarder les Modifications'),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
        ),
      ),
    );
  }
}
