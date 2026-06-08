import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/providers/app_state.dart';
import '../../core/models/models.dart';
import '../../core/widgets/app_header.dart';


class ParametresPage extends StatefulWidget {
  const ParametresPage({super.key});

  @override
  State<ParametresPage> createState() => _ParametresPageState();
}

class _ParametresPageState extends State<ParametresPage> {
  final _raisonSocialeController = TextEditingController();
  final _siretController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _adresseController = TextEditingController();
  final _tvaController = TextEditingController();
  final _formeJuridiqueController = TextEditingController();
  final _capitalSocialController = TextEditingController();
  final _codeAPEController = TextEditingController();
  final _nomGerantController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _sirenController = TextEditingController();
  final _rcsController = TextEditingController();
  bool _loaded = false;
  DateTime? _dateCreation;

  // Local image file picked from device
  File? _localLogoFile;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      final p = context.read<AppState>().parametres;
      if (p == null) return; // Not loaded yet from Supabase
      _raisonSocialeController.text = p.raisonSociale;
      _siretController.text = p.siret;
      _telephoneController.text = p.telephone ?? '';
      _emailController.text = p.email ?? '';
      _adresseController.text = p.adresse ?? '';
      _tvaController.text = p.tvaIntracommunautaire ?? '';
      _formeJuridiqueController.text = p.formeJuridique ?? '';
      _capitalSocialController.text = p.capitalSocial ?? '';
      _codeAPEController.text = p.codeAPE ?? '';
      _nomGerantController.text = p.nomGerant ?? '';
      _descriptionController.text = p.description ?? '';
      _sirenController.text = p.nSiren ?? '';
      _rcsController.text = p.nRcs ?? '';
      _dateCreation = p.dateCreation;
      if (p.logoUrl != null &&
          p.logoUrl!.isNotEmpty &&
          !p.logoUrl!.startsWith('http')) {
        _localLogoFile = File(p.logoUrl!);
      }
      _loaded = true;
    }
  }

  @override
  void dispose() {
    _raisonSocialeController.dispose();
    _siretController.dispose();
    _telephoneController.dispose();
    _emailController.dispose();
    _adresseController.dispose();
    _tvaController.dispose();
    _formeJuridiqueController.dispose();
    _capitalSocialController.dispose();
    _codeAPEController.dispose();
    _nomGerantController.dispose();
    _descriptionController.dispose();
    _sirenController.dispose();
    _rcsController.dispose();
    super.dispose();
  }

  Future<void> _pickLogoFromDevice() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (image != null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
                SizedBox(width: 16),
                Text('Mise à jour du logo...'),
              ],
            ),
            duration: Duration(minutes: 1),
          ),
        );

        final appState = context.read<AppState>();
        final currentParams = appState.parametres;
        if (currentParams != null) {
          await appState.updateParametres(
            currentParams.copyWith(logoUrl: image.path),
          );

          if (mounted) {
            setState(() {
              _localLogoFile = null;
              _loaded = false;
            });
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Logo mis à jour avec succès !'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  Future<void> _save() async {
    final appState = context.read<AppState>();
    final existingId = appState.parametres?.id ?? '';
    final existingLogoUrl = appState.parametres?.logoUrl;
    final logoUrlToSave = _localLogoFile != null
        ? _localLogoFile!.path
        : existingLogoUrl;

    final raisonSocialeVal = _raisonSocialeController.text.trim();
    final nomGerantVal = _nomGerantController.text.trim();
    final emailVal = _emailController.text.trim();
    final siretVal = _siretController.text.trim();
    final sirenVal = _sirenController.text.trim();
    final telephoneVal = _telephoneController.text.trim();
    final adresseVal = _adresseController.text.trim();
    final tvaVal = _tvaController.text.trim();
    final formeJuridiqueVal = _formeJuridiqueController.text.trim();
    final capitalSocialVal = _capitalSocialController.text.trim();
    final codeApeVal = _codeAPEController.text.trim();
    final rcsVal = _rcsController.text.trim();

    if (raisonSocialeVal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La Raison Sociale est requise'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (nomGerantVal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le nom du gérant est requis'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (emailVal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('L\'adresse email est requise'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(emailVal)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez saisir une adresse e-mail valide.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (telephoneVal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le numéro de téléphone est requis'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!RegExp(r'^[+0-9\s-]{9,15}$').hasMatch(telephoneVal)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le numéro de téléphone saisi est invalide.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (siretVal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le numéro SIRET est requis'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!RegExp(r'^\d{14}$').hasMatch(siretVal)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le numéro SIRET doit comporter exactement 14 chiffres.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (sirenVal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le numéro SIREN est requis'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!RegExp(r'^\d{9}$').hasMatch(sirenVal)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le numéro SIREN doit comporter exactement 9 chiffres.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (adresseVal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('L\'adresse est requise'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (tvaVal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le numéro de TVA est requis'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (formeJuridiqueVal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La forme juridique est requise'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (capitalSocialVal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le capital social est requis'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (codeApeVal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le code APE est requis'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (rcsVal.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Le numéro RCS est requis'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await appState.updateParametres(
        ClientParametres(
          id: existingId,
          raisonSociale: raisonSocialeVal,
          siret: _siretController.text.trim(),
          telephone: _telephoneController.text.trim().isEmpty
              ? null
              : _telephoneController.text.trim(),
          email: emailVal,
          adresse: _adresseController.text.trim().isEmpty
              ? null
              : _adresseController.text.trim(),
          tvaIntracommunautaire: _tvaController.text.trim().isEmpty
              ? null
              : _tvaController.text.trim(),
          formeJuridique: _formeJuridiqueController.text.trim().isEmpty
              ? null
              : _formeJuridiqueController.text.trim(),
          capitalSocial: _capitalSocialController.text.trim().isEmpty
              ? null
              : _capitalSocialController.text.trim(),
          codeAPE: _codeAPEController.text.trim().isEmpty
              ? null
              : _codeAPEController.text.trim(),
          nomGerant: nomGerantVal,
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          nSiren: _sirenController.text.trim().isEmpty
              ? null
              : _sirenController.text.trim(),
          nRcs: _rcsController.text.trim().isEmpty
              ? null
              : _rcsController.text.trim(),
          logoUrl: logoUrlToSave,
          dateCreation: _dateCreation,
        ),
      );
      if (mounted) {
        setState(() {
          _localLogoFile = null;
          _loaded = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Paramètres enregistrés'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final p = appState.parametres;
    final isDark = appState.isDarkMode;

    // Show loading while enterprise data is being fetched
    if (p == null) {
      return Scaffold(
        body: Center(
          child: appState.isLoadingParametres
              ? const CircularProgressIndicator()
              : Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 60, color: Colors.orange),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune entreprise associée',
                        style: GoogleFonts.manrope(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Votre compte (${Supabase.instance.client.auth.currentUser?.email}) n\'est rattaché à aucune entreprise active dans la base de données.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => appState.logout(),
                        icon: const Icon(Icons.logout),
                        label: const Text('Se déconnecter'),
                      ),
                    ],
                  ),
                ),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          AppHeader.sliver(context: context),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Paramètres',
                    style: GoogleFonts.manrope(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.primary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Profil de l\'entreprise'),
                  _buildCompanyHeader(p),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Apparence'),
                  _buildAppearanceSection(context, appState, isDark),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Modifier les informations'),
                  _buildEditSection(),
                  const SizedBox(height: 24),
                  _buildDangerZone(context, appState),
                  const SizedBox(height: 120),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        title,
        style: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.8),
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _buildCompanyHeader(ClientParametres p) {
    Widget logoWidget;
    if (_localLogoFile != null) {
      logoWidget = ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(
          _localLogoFile!,
          width: 64,
          height: 64,
          fit: BoxFit.contain,
        ),
      );
    } else if (p.logoUrl != null && p.logoUrl!.startsWith('http') && !p.logoUrl!.contains('dicebear.com')) {
      logoWidget = ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          p.logoUrl!,
          key: ValueKey(p.logoUrl),
          width: 64,
          height: 64,
          fit: BoxFit.contain,
        ),
      );
    } else {
      logoWidget = Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          Icons.business,
          color: Theme.of(context).colorScheme.primary,
          size: 32,
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _pickLogoFromDevice,
            child: Stack(
              children: [
                logoWidget,
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.tertiary,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: const Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: 10,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.raisonSociale,
                  style: GoogleFonts.manrope(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                Text(
                  'Client HMI Stars',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: _pickLogoFromDevice,
                  child: Text(
                    'Changer le logo',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.tertiary,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor: Theme.of(context).colorScheme.tertiary,
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

  Widget _buildAppearanceSection(
    BuildContext context,
    AppState appState,
    bool isDark,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2A2F3A)
                      : Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isDark ? Icons.dark_mode : Icons.light_mode,
                  color: isDark
                      ? const Color(0xFFEAC249)
                      : Theme.of(context).colorScheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isDark ? 'Mode Sombre' : 'Mode Clair',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      isDark
                          ? 'Interface en thème sombre'
                          : 'Interface en thème clair',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: isDark,
                onChanged: (_) => appState.toggleDarkMode(),
                activeThumbColor: const Color(0xFFEAC249),
                activeTrackColor: const Color(0xFF574400),
                inactiveThumbColor: Theme.of(context).colorScheme.primary,
                inactiveTrackColor: Theme.of(
                  context,
                ).colorScheme.outlineVariant,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.translate,
                  color: Theme.of(context).colorScheme.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Langue',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Sélectionner la langue de l\'application',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              DropdownButton<String>(
                value: appState.langue,
                items: const [
                  DropdownMenuItem(value: 'Français (FR)', child: Text('Français (FR)')),
                  DropdownMenuItem(value: 'English (EN)', child: Text('English (EN)')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    appState.setLangue(val);
                  }
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEditSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Informations Générales
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSubSectionHeader('Informations Générales'),
              const SizedBox(height: 16),
              _buildField(
                _raisonSocialeController,
                'Raison Sociale',
                Icons.business_outlined,
              ),
              _buildDatePickerField(
                'Date de création d\'entreprise',
                Icons.calendar_today_outlined,
                _dateCreation,
                (date) => setState(() => _dateCreation = date),
              ),
              _buildField(
                _nomGerantController,
                'Nom du Gérant',
                Icons.person_outline,
              ),
              _buildField(
                _descriptionController,
                'Activité / Description',
                Icons.description_outlined,
              ),
              _buildField(
                _telephoneController,
                'Téléphone',
                Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              _buildField(
                _emailController,
                'Email',
                Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),
              _buildField(
                _adresseController,
                'Adresse',
                Icons.location_on_outlined,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // 2. Informations Juridiques
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSubSectionHeader('Informations Juridiques'),
              const SizedBox(height: 16),
              _buildField(
                _sirenController,
                'SIREN',
                Icons.pin_outlined,
                keyboardType: TextInputType.number,
              ),
              _buildField(
                _siretController,
                'SIRET',
                Icons.numbers,
                keyboardType: TextInputType.number,
              ),
              _buildField(
                _formeJuridiqueController,
                'Forme Juridique',
                Icons.gavel_outlined,
              ),
              _buildField(
                _capitalSocialController,
                'Capital Social (€)',
                Icons.monetization_on_outlined,
                keyboardType: TextInputType.number,
              ),
              _buildField(
                _tvaController,
                'TVA Intracommunautaire',
                Icons.account_balance_outlined,
              ),
              _buildField(
                _rcsController,
                'RCS',
                Icons.receipt_long_outlined,
              ),
              _buildField(_codeAPEController, 'Code APE', Icons.category_outlined),
            ],
          ),
        ),
        const SizedBox(height: 20),
        // 3. Save Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _save,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              'Enregistrer les modifications',
              style: GoogleFonts.manrope(fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubSectionHeader(String title) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.manrope(
        fontSize: 12,
        fontWeight: FontWeight.w800,
        color: Theme.of(context).colorScheme.secondary,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(
            icon,
            size: 20,
            color: Theme.of(context).colorScheme.outline,
          ),
          labelStyle: GoogleFonts.inter(
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildDatePickerField(
    String label,
    IconData icon,
    DateTime? selectedDate,
    Function(DateTime) onDateSelected,
  ) {
    final dateStr = selectedDate != null
        ? "${selectedDate.day.toString().padLeft(2, '0')}/${selectedDate.month.toString().padLeft(2, '0')}/${selectedDate.year}"
        : "";

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context,
            initialDate: selectedDate ?? DateTime.now(),
            firstDate: DateTime(1900),
            lastDate: DateTime.now(),
          );
          if (picked != null) {
            onDateSelected(picked);
          }
        },
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(
              icon,
              size: 20,
              color: Theme.of(context).colorScheme.outline,
            ),
            labelStyle: GoogleFonts.inter(
              fontSize: 13,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          child: Text(
            dateStr.isEmpty ? 'Sélectionner une date' : dateStr,
            style: GoogleFonts.inter(
              fontSize: 15,
              color: dateStr.isEmpty
                  ? Theme.of(context).colorScheme.outline
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDangerZone(BuildContext context, AppState appState) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          appState.logout();
          context.go('/connexion');
        },
        icon: Icon(
          Icons.logout,
          color: Theme.of(context).colorScheme.error,
        ),
        label: Text(
          'Se déconnecter',
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.error,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Theme.of(context).colorScheme.error),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }}
