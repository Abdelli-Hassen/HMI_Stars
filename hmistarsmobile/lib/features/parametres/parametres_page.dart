import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/app_state.dart';
import '../../core/models/models.dart';

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
  bool _loaded = false;

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
    super.dispose();
  }

  Future<void> _pickLogoFromDevice() async {
    // image_picker not included — show a snackbar for now
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Upload de logo à venir dans une prochaine version')),
    );
  }

  Future<void> _save() async {
    final appState = context.read<AppState>();
    final existingId = appState.parametres?.id ?? '';
    final existingLogoUrl = appState.parametres?.logoUrl;
    final logoUrlToSave = _localLogoFile != null
        ? _localLogoFile!.path
        : existingLogoUrl;

    try {
      await appState.updateParametres(
        ClientParametres(
          id: existingId,
          raisonSociale: _raisonSocialeController.text.trim(),
          siret: _siretController.text.trim(),
          telephone: _telephoneController.text.trim().isEmpty
              ? null
              : _telephoneController.text.trim(),
          email: _emailController.text.trim().isEmpty
              ? null
              : _emailController.text.trim(),
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
          logoUrl: logoUrlToSave,
        ),
      );
      if (mounted) {
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
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            floating: true,
            snap: true,
            title: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/logo.jpeg',
                    width: 70,
                    height: 36,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'HMI Stars Consulting',
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).colorScheme.primary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Configuration',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.tertiary,
                      letterSpacing: 1.5,
                    ),
                  ),
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
                  _buildInfoCard(p),
                  const SizedBox(height: 20),
                  _buildAppearanceSection(context, appState, isDark),
                  const SizedBox(height: 20),
                  _buildEditSection(),
                  const SizedBox(height: 20),
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

  Widget _buildInfoCard(ClientParametres p) {
    // Determine logo widget
    Widget logoWidget;
    if (_localLogoFile != null) {
      logoWidget = ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.file(
          _localLogoFile!,
          width: 56,
          height: 56,
          fit: BoxFit.contain,
        ),
      );
    } else if (p.logoUrl != null && p.logoUrl!.startsWith('http')) {
      logoWidget = ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          p.logoUrl!,
          width: 56,
          height: 56,
          fit: BoxFit.contain,
        ),
      );
    } else {
      logoWidget = Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(Icons.business, color: Colors.white, size: 28),
      );
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primaryContainer,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Tappable logo — pick from gallery
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
                        child: Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 12,
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
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Client HMI Stars',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white60,
                      ),
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: _pickLogoFromDevice,
                      child: Text(
                        'Changer la photo',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.tertiary,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          decorationColor: Theme.of(
                            context,
                          ).colorScheme.tertiary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildInfoRow(Icons.numbers, 'SIRET', p.siret),
          if (p.telephone != null)
            _buildInfoRow(Icons.phone, 'Téléphone', p.telephone!),
          if (p.email != null) _buildInfoRow(Icons.email, 'Email', p.email!),
          if (p.adresse != null)
            _buildInfoRow(Icons.location_on, 'Adresse', p.adresse!),
          if (p.tvaIntracommunautaire != null)
            _buildInfoRow(
              Icons.account_balance,
              'TVA Intra.',
              p.tvaIntracommunautaire!,
            ),
          if (p.formeJuridique != null)
            _buildInfoRow(Icons.gavel, 'Forme Juridique', p.formeJuridique!),
          if (p.capitalSocial != null)
            _buildInfoRow(
              Icons.monetization_on,
              'Capital Social',
              '${p.capitalSocial!} €',
            ),
          if (p.codeAPE != null)
            _buildInfoRow(Icons.category, 'Code APE', p.codeAPE!),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: Colors.white54, size: 16),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 9,
                  color: Colors.white54,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
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
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Apparence',
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2A2F3A)
                      : Theme.of(
                          context,
                        ).colorScheme.primaryContainer.withOpacity(0.12),
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
                activeColor: const Color(0xFFEAC249),
                activeTrackColor: const Color(0xFF574400),
                inactiveThumbColor: Theme.of(context).colorScheme.primary,
                inactiveTrackColor: Theme.of(
                  context,
                ).colorScheme.outlineVariant,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEditSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Modifier mes informations',
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 20),
          _buildField(
            _raisonSocialeController,
            'Raison Sociale',
            Icons.business_outlined,
          ),
          _buildField(
            _siretController,
            'SIRET',
            Icons.numbers,
            keyboardType: TextInputType.number,
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
          _buildField(
            _tvaController,
            'TVA Intracommunautaire',
            Icons.account_balance_outlined,
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
          _buildField(_codeAPEController, 'Code APE', Icons.category_outlined),
          const SizedBox(height: 8),
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

  Widget _buildDangerZone(BuildContext context, AppState appState) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.error.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Zone Danger',
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w700,
              fontSize: 16,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
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
          ),
        ],
      ),
    );
  }
}
