import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  String _selectedDevice = 'EUR (€)';
  String _selectedTimezone = 'Paris (GMT+1)';
  String _selectedLangue = 'Français (FR)';
  bool _emailNewDocs = true;
  bool _emailAlertes = true;
  bool _emailConnexions = false;
  bool _emailSupport = true;

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
      _selectedDevice = prefs['devise'] ?? 'EUR (€)';
      _selectedTimezone = prefs['timezone'] ?? 'Paris (GMT+1)';
      _selectedLangue = prefs['langue'] ?? 'Français (FR)';
      _emailNewDocs = prefs['emailNewDocs'] ?? true;
      _emailAlertes = prefs['emailAlertes'] ?? true;
      _emailConnexions = prefs['emailConnexions'] ?? false;
      _emailSupport = prefs['emailSupport'] ?? true;
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
      _emailController.text,
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
    prefs['devise'] = _selectedDevice;
    prefs['timezone'] = _selectedTimezone;
    prefs['langue'] = _selectedLangue;
    prefs['emailNewDocs'] = _emailNewDocs;
    prefs['emailAlertes'] = _emailAlertes;
    prefs['emailConnexions'] = _emailConnexions;
    prefs['emailSupport'] = _emailSupport;
    
    context.read<AuthProvider>().mettreAJourProfil(
      preferences: prefs,
    );
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Espace de travail mis à jour avec succès !'),
      backgroundColor: AppColors.success,
    ));
  }

  void _modifierPhoto() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Fonctionnalité en cours de développement.'),
    ));
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
            const SizedBox(height: 24),

            // ─── Notifications Section ───
            _buildNotificationsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: AppColors.primary, width: 3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('PROFIL UTILISATEUR', style: AppTextStyles.labelSmall.copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w700)),
        const SizedBox(height: 20),
        Row(children: [
          CircleAvatar(radius: 32, backgroundColor: AppColors.surfaceContainerHigh, child: const Icon(Icons.person, size: 32, color: AppColors.onSurfaceVariant)),
          const SizedBox(width: 16),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_nomController.text.isNotEmpty ? _nomController.text : 'Utilisateur Actuel', style: AppTextStyles.titleSmall),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _modifierPhoto,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(border: Border.all(color: AppColors.outlineVariant), borderRadius: BorderRadius.circular(8)),
                child: Text('MODIFIER LA PHOTO', style: AppTextStyles.labelSmall.copyWith(letterSpacing: 0.8, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ]),
        const SizedBox(height: 28),
        _textField('Nom Complet', _nomController, Icons.person_outline),
        const SizedBox(height: 16),
        _textField('Adresse E-mail', _emailController, Icons.email_outlined),
        const SizedBox(height: 16),

        const SizedBox(height: 16),
        _textField('Téléphone', _phoneController, Icons.phone_outlined),
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
        _textField('N° Carte d\'Identité (CIN)', _cinController, Icons.badge_outlined),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _staticDropdownField('Devise', _selectedDevice, ['EUR (€)', 'USD (\$)'], (v) => setState(() => _selectedDevice = v!))),
          const SizedBox(width: 12),
          Expanded(child: _staticDropdownField('Fuseau horaire', _selectedTimezone, ['Paris (GMT+1)', 'London (GMT)', 'New York (GMT-5)'], (v) => setState(() => _selectedTimezone = v!))),
        ]),
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
              onPressed: () => Navigator.pop(context), 
              style: TextButton.styleFrom(foregroundColor: AppColors.onSurfaceVariant),
              child: const Text('Annuler')
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mot de passe mis à jour.'), backgroundColor: AppColors.success));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary, 
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Mettre à jour'),
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
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.shield_outlined, size: 18, color: AppColors.primary),
          const SizedBox(width: 8),
          Text('SÉCURITÉ & ACCÈS', style: AppTextStyles.labelSmall.copyWith(letterSpacing: 1.2, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 20),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Mot de passe', style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('Dernière modification il y a 30 jours', style: AppTextStyles.bodySmall),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _modifierMotDePasse,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(border: Border.all(color: AppColors.outlineVariant), borderRadius: BorderRadius.circular(8)),
              child: Text('Modifier le mot de passe', style: AppTextStyles.labelMedium.copyWith(fontWeight: FontWeight.w600)),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _buildNotificationsSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: AppColors.surfaceContainerLowest, borderRadius: BorderRadius.circular(16)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.secondary.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.notifications_outlined, color: AppColors.secondary, size: 20)),
          const SizedBox(width: 16),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Préférences de Notification', style: AppTextStyles.titleMedium.copyWith(fontWeight: FontWeight.w700)),
            Text('Gérez les notifications par email.', style: AppTextStyles.bodySmall.copyWith(color: AppColors.onSurfaceVariant)),
          ])),
        ]),
        const SizedBox(height: 24),
        Row(children: [
          Expanded(flex: 3, child: Text('Type de Notification', style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w700, color: AppColors.onSurfaceVariant, letterSpacing: 1.1))),
          Expanded(child: Center(child: Text('Email', style: AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w700, color: AppColors.onSurfaceVariant, letterSpacing: 1.1)))),
        ]),
        const SizedBox(height: 12),
        const Divider(),
        _notifRow('Nouveaux Documents', _emailNewDocs, (v) => setState(() => _emailNewDocs = v)),
        const Divider(),
        _notifRow('Alertes de Paie', _emailAlertes, (v) => setState(() => _emailAlertes = v)),
        const Divider(),
        _notifRow('Nouvelles Connexions', _emailConnexions, (v) => setState(() => _emailConnexions = v)),
        const Divider(),
        _notifRow('Mises à jour Support', _emailSupport, (v) => setState(() => _emailSupport = v)),
        const SizedBox(height: 20),
        _saveButton(_sauvegarderWorkspace),
      ]),
    );
  }

  Widget _notifRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(children: [
        Expanded(flex: 3, child: Text(label, style: AppTextStyles.bodyMedium)),
        Expanded(child: Center(child: _toggle(value, onChanged))),
      ]),
    );
  }

  Widget _toggle(bool active, ValueChanged<bool> onChanged) {
    return GestureDetector(
      onTap: () => onChanged(!active),
      child: Container(
        width: 40, height: 22,
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(11),
        ),
        child: Align(
          alignment: active ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 18, height: 18, margin: const EdgeInsets.symmetric(horizontal: 2),
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
          ),
        ),
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
