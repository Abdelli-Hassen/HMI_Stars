import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/utils/translation_extension.dart';
import '../../../../core/utils/toast_utils.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_hero_panel.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cinController = TextEditingController();
  bool _acceptTerms = false;
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _cinController.dispose();
    super.dispose();
  }

  Future<void> _signUp() async {
    if (!_acceptTerms) return;
    
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = context.tr("Les mots de passe ne correspondent pas.", "Passwords do not match."));
      return;
    }
    
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _errorMessage = context.tr("Email et mot de passe requis.", "Email and password are required."));
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final auth = context.read<AuthProvider>();
    final success = await auth.signUp(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      nom: _nameController.text.trim(),
      telephone: _phoneController.text.trim(),
      cin: _cinController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (success) {
      if (auth.isAuthenticated) {
        Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
      } else {
        ToastUtils.show(
          context,
          context.tr(
            "Inscription réussie. Veuillez vérifier votre e-mail.",
            "Registration successful. Please check your email.",
          ),
        );
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    } else {
      setState(() {
        _errorMessage = auth.errorMessage ?? context.tr("Erreur lors de l'inscription.", "Error during registration.");
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final auth = Provider.of<AuthProvider>(context);
    return Scaffold(
      backgroundColor: cs.surface,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200, maxHeight: 900),
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cs.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: cs.onSurface.withValues(alpha: 0.06),
                blurRadius: 24,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Row(
              children: [
                // ─── Hero Panel ───
                Expanded(
                  child: AuthHeroPanel(
                    headline: context.tr(
                      "HMI Stars Consulting\nVotre partenaire de réussite.",
                      "HMI Stars Consulting\nYour partner in success.",
                    ),
                    subHeadline: context.tr(
                      "Cabinet de conseil expert en gestion, création d'entreprise et accompagnement social. Transformez vos ambitions en réussites durables.",
                      "Expert consulting firm in management, business creation, and social support. Transform your ambitions into sustainable success.",
                    ),
                  ),
                ),

                // ─── Sign Up Form ───
                Expanded(
                  child: Container(
                    color: cs.surfaceContainerLowest,
                    padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 48),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(context.tr('Créer un compte', 'Create an account'),
                              style: AppTextStyles.headlineLarge.copyWith(fontSize: 30, color: cs.onSurface)),
                          const SizedBox(height: 6),
                          Text(
                            context.tr('Démarrez votre transformation digitale aujourd\'hui.', 'Start your digital transformation today.'),
                            style: AppTextStyles.bodyMedium.copyWith(color: cs.onSurfaceVariant),
                          ),
                          const SizedBox(height: 32),

                          if (_errorMessage != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 24),
                              decoration: BoxDecoration(
                                color: AppColors.error.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.error_outline, color: AppColors.error, size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(_errorMessage!, style: TextStyle(color: AppColors.error))),
                                ],
                              ),
                            ),

                          // Name
                          _buildLabel(context.tr('Nom Complet', 'Full Name')),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.person_outline, size: 20, color: cs.outline),
                              hintText: 'Jean Dupont',
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Phone
                          _buildLabel(context.tr('Numéro de Téléphone', 'Phone Number')),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.phone_outlined, size: 20, color: cs.outline),
                              hintText: '+33 6 12 34 56 78',
                            ),
                          ),
                          const SizedBox(height: 18),

                          // CIN (Carte d'Identité Nationale)
                          _buildLabel(context.tr('N° Carte d\'Identité Nationale', 'National ID Number')),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _cinController,
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.badge_outlined, size: 20, color: cs.outline),
                              hintText: 'AB123456',
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Email
                          _buildLabel(context.tr('Adresse Email', 'Email Address')),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.email_outlined, size: 20, color: cs.outline),
                              hintText: 'jean.dupont@entreprise.fr',
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Password Row
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildLabel(context.tr('Mot de passe', 'Password')),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: _passwordController,
                                      obscureText: true,
                                      decoration: InputDecoration(
                                        prefixIcon: Icon(Icons.lock_outline, size: 20, color: cs.outline),
                                        hintText: '••••••••',
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
                                    _buildLabel(context.tr('Confirmation', 'Confirm Password')),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: _confirmPasswordController,
                                      obscureText: true,
                                      decoration: InputDecoration(
                                        prefixIcon: Icon(Icons.lock_reset, size: 20, color: cs.outline),
                                        hintText: '••••••••',
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // Terms
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                width: 18,
                                height: 18,
                                child: Checkbox(
                                  value: _acceptTerms,
                                  onChanged: (v) => setState(() => _acceptTerms = v ?? false),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: cs.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    children: [
                                      TextSpan(text: context.tr("J'accepte les ", "I accept the ")),
                                      TextSpan(
                                        text: context.tr("Conditions Générales d'Utilisation", "Terms and Conditions"),
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: cs.primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      TextSpan(text: context.tr(' et la politique de confidentialité.', ' and the privacy policy.')),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Submit
                          SizedBox(
                            width: double.infinity,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              decoration: BoxDecoration(
                                gradient: _acceptTerms ? cs.primaryGradient : null,
                                color: _acceptTerms ? null : cs.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: _acceptTerms
                                    ? [
                                        BoxShadow(
                                          color: cs.primary.withValues(alpha: 0.2),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : [],
                              ),
                              child: ElevatedButton(
                                onPressed: _acceptTerms && !_loading ? _signUp : null,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                ),
                                child: _loading 
                                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                    : Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(context.tr("S'inscrire", 'Sign Up'),
                                              style: GoogleFonts.manrope(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w700,
                                                color: Colors.white,
                                              )),
                                          const SizedBox(width: 8),
                                          const Icon(Icons.arrow_forward, size: 18, color: Colors.white),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Already have account
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(context.tr('Déjà un compte ? ', 'Already have an account? '),
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: cs.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    )),
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: () => Navigator.pushNamed(context, AppRoutes.login),
                                    child: Text(context.tr('Se connecter', 'Sign In'),
                                        style: AppTextStyles.labelMedium.copyWith(
                                          color: cs.primary,
                                          fontWeight: FontWeight.w700,
                                        )),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Support / Language footer (inside form block)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _FooterLink(
                                icon: Icons.language,
                                text: auth.tempLanguage == 'English (EN)' ? 'Français (FR)' : 'English (EN)',
                                onTap: () {
                                  auth.setTempLanguage(
                                    auth.tempLanguage == 'English (EN)'
                                        ? 'Français (FR)'
                                        : 'English (EN)',
                                  );
                                },
                              ),
                              const SizedBox(width: 24),
                              _FooterLink(
                                icon: themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                                text: themeProvider.isDarkMode
                                    ? context.tr('Mode Jour ?', 'Light Mode ?')
                                    : context.tr('Mode Nuit ?', 'Night Mode ?'),
                                onTap: () {
                                  themeProvider.toggleTheme(!themeProvider.isDarkMode);
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
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

  Widget _buildLabel(String text) {
    final cs = Theme.of(context).colorScheme;
    return Text(
      text,
      style: AppTextStyles.labelMedium.copyWith(
        fontWeight: FontWeight.w600,
        color: cs.onSurfaceVariant,
      ),
    );
  }
}

class _FooterLink extends StatefulWidget {
  final IconData icon;
  final String text;
  final VoidCallback? onTap;

  const _FooterLink({required this.icon, required this.text, this.onTap});

  @override
  State<_FooterLink> createState() => _FooterLinkState();
}

class _FooterLinkState extends State<_FooterLink> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: widget.onTap,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.icon,
              size: 14,
              color: _hovered ? cs.onSurface : cs.outline,
            ),
            const SizedBox(width: 4),
            Text(
              widget.text,
              style: AppTextStyles.labelSmall.copyWith(
                color: _hovered ? cs.onSurface : cs.outline,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
