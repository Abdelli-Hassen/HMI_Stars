import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/router/app_router.dart';
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
      setState(() => _errorMessage = "Les mots de passe ne correspondent pas.");
      return;
    }
    
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _errorMessage = "Email et mot de passe requis.");
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
        // Confirm email was off, logged in automatically
        Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
      } else {
        // Confirm email is ON, session is null, redirect to login
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(auth.errorMessage ?? "Inscription réussie. Veuillez vérifier votre e-mail."),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 5),
          ),
        );
        Navigator.pushReplacementNamed(context, AppRoutes.login);
      }
    } else {
      setState(() {
        _errorMessage = auth.errorMessage ?? "Erreur lors de l'inscription.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 1200, maxHeight: 900),
          margin: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.onSurface.withValues(alpha: 0.06),
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
                    headline: "HMI Stars Consulting\nVotre partenaire de réussite.",
                    subHeadline:
                        "Cabinet de conseil expert en gestion, création d'entreprise et accompagnement social. Transformez vos ambitions en réussites durables.",
                    bottomCard: const TestimonialCard(),
                  ),
                ),

                // ─── Sign Up Form ───
                Expanded(
                  child: Container(
                    color: AppColors.surfaceContainerLowest,
                    padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 48),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Créer un compte',
                              style: AppTextStyles.headlineLarge.copyWith(fontSize: 30)),
                          const SizedBox(height: 6),
                          Text(
                            'Démarrez votre transformation digitale aujourd\'hui.',
                            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.onSurfaceVariant),
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
                          _buildLabel('Nom Complet'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.person_outline, size: 20, color: AppColors.outline),
                              hintText: 'Jean Dupont',
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Phone
                          _buildLabel('Numéro de Téléphone'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.phone_outlined, size: 20, color: AppColors.outline),
                              hintText: '+33 6 12 34 56 78',
                            ),
                          ),
                          const SizedBox(height: 18),

                          // CIN (Carte d'Identité Nationale)
                          _buildLabel('N° Carte d\'Identité Nationale'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _cinController,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.badge_outlined, size: 20, color: AppColors.outline),
                              hintText: 'AB123456',
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Email
                          _buildLabel('Adresse Email'),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              prefixIcon: Icon(Icons.email_outlined, size: 20, color: AppColors.outline),
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
                                    _buildLabel('Mot de passe'),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: _passwordController,
                                      obscureText: true,
                                      decoration: const InputDecoration(
                                        prefixIcon: Icon(Icons.lock_outline, size: 20, color: AppColors.outline),
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
                                    _buildLabel('Confirmation'),
                                    const SizedBox(height: 8),
                                    TextField(
                                      controller: _confirmPasswordController,
                                      obscureText: true,
                                      decoration: const InputDecoration(
                                        prefixIcon: Icon(Icons.lock_reset, size: 20, color: AppColors.outline),
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
                                      color: AppColors.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    children: [
                                      const TextSpan(text: "J'accepte les "),
                                      TextSpan(
                                        text: "Conditions Générales d'Utilisation",
                                        style: AppTextStyles.bodySmall.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const TextSpan(text: ' et la politique de confidentialité.'),
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
                                gradient: _acceptTerms ? AppColors.primaryGradient : null,
                                color: _acceptTerms ? null : AppColors.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: _acceptTerms
                                    ? [
                                        BoxShadow(
                                          color: AppColors.primary.withValues(alpha: 0.2),
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ]
                                    : [],
                              ),
                                child: ElevatedButton(
                                  onPressed: _acceptTerms && !_loading
                                      ? _signUp
                                      : null,
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
                                    Text('S\'inscrire',
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
                                Text('Déjà un compte ? ',
                                    style: AppTextStyles.bodySmall.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                      fontWeight: FontWeight.w500,
                                    )),
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: () => Navigator.pushNamed(context, AppRoutes.login),
                                    child: Text('Se connecter',
                                        style: AppTextStyles.labelMedium.copyWith(
                                          color: AppColors.primary,
                                          fontWeight: FontWeight.w700,
                                        )),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Footer
                          Container(
                            padding: const EdgeInsets.only(top: 20),
                            decoration: BoxDecoration(
                              border: Border(top: BorderSide(color: AppColors.surfaceContainer)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '© 2026 HMI STARS SAS',
                                  style: AppTextStyles.labelSmall.copyWith(
                                    fontSize: 9,
                                    letterSpacing: 1.5,
                                    color: AppColors.outline,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text('AIDE', style: AppTextStyles.labelSmall.copyWith(fontSize: 9, letterSpacing: 1.5, color: AppColors.outline)),
                                    const SizedBox(width: 16),
                                    Text('CONFIDENTIALITÉ', style: AppTextStyles.labelSmall.copyWith(fontSize: 9, letterSpacing: 1.5, color: AppColors.outline)),
                                  ],
                                ),
                              ],
                            ),
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
    return Text(
      text,
      style: AppTextStyles.labelMedium.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColors.onSurfaceVariant,
      ),
    );
  }
}
