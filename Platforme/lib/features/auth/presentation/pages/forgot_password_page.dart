import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/utils/translation_extension.dart';
import '../widgets/auth_hero_panel.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (_emailController.text.isEmpty) {
      setState(() => _errorMessage = context.tr(
          "Veuillez entrer votre adresse e-mail.",
          "Please enter your email address."));
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    final auth = context.read<AuthProvider>();
    auth.clearError();
    await auth.resetPassword(_emailController.text.trim());

    if (!mounted) return;
    setState(() => _loading = false);

    if (auth.errorMessage != null) {
      setState(() => _errorMessage = auth.errorMessage);
    } else {
      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(context.tr(
              'Vérification d\'email requise', 'Email Verification Required')),
          content: Text(context.tr(
              'Un lien de réinitialisation a été envoyé. Veuillez vérifier votre boîte de réception et cliquer sur le lien avant de vous connecter.',
              'A reset link has been sent. Please check your inbox and click the link before logging in.')),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
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
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Row(
              children: [
                // ─── Left Hero ───
                Expanded(
                  child: AuthHeroPanel(
                    headline: context.tr(
                      "La rigueur financière est l'architecte de la pérennité.",
                      "Financial rigor is the architect of sustainability.",
                    ),
                    subHeadline: context.tr(
                      "— Vision Expertise\nPARTENAIRE DES LEADERS FRANÇAIS",
                      "— Vision Expertise\nPARTNER OF FRENCH LEADERS",
                    ),
                  ),
                ),

                // ─── Right Form ───
                Expanded(
                  child: Container(
                    color: cs.surfaceContainerLowest,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 64,
                      vertical: 48,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            context.tr('Mot de passe oublié ?', 'Forgot Password?'),
                            style: AppTextStyles.headlineLarge.copyWith(fontSize: 30),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            context.tr(
                              'Entrez votre adresse e-mail pour recevoir un lien de réinitialisation.',
                              'Enter your email address to receive a reset link.',
                            ),
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 36),

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
                                  Expanded(
                                    child: Text(
                                      _errorMessage!,
                                      style: TextStyle(color: AppColors.error),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          Text(
                            context.tr(
                              'ADRESSE E-MAIL PROFESSIONNELLE',
                              'PROFESSIONAL EMAIL ADDRESS',
                            ),
                            style: AppTextStyles.labelSmall.copyWith(
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.email_outlined,
                                  size: 20, color: cs.outline),
                              hintText: context.tr(
                                'nom@entreprise.fr',
                                'name@company.com',
                              ),
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Submit Button
                          SizedBox(
                            width: double.infinity,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: cs.primaryGradient,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: cs.primary.withValues(alpha: 0.2),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _loading ? null : _resetPassword,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 18),
                                ),
                                child: _loading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            context.tr(
                                                'Envoyer le lien', 'Send Link'),
                                            style: GoogleFonts.manrope(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(Icons.arrow_forward,
                                              size: 18, color: Colors.white),
                                        ],
                                      ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 28),
                          Divider(color: cs.surfaceContainer),
                          const SizedBox(height: 16),

                          // Back to login
                          Center(
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.chevron_left,
                                        size: 18, color: cs.primary),
                                    Text(
                                      context.tr(
                                        'Retour à la connexion',
                                        'Back to Login',
                                      ),
                                      style: AppTextStyles.labelMedium.copyWith(
                                        color: cs.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 36),

                          // Support / Language footer (inside form block)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _FooterLink(
                                icon: Icons.language,
                                text: auth.tempLanguage == 'English (EN)'
                                    ? 'Français (FR)'
                                    : 'English (EN)',
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
                                icon: themeProvider.isDarkMode
                                    ? Icons.light_mode
                                    : Icons.dark_mode,
                                text: themeProvider.isDarkMode
                                    ? context.tr('Mode Jour ?', 'Light Mode ?')
                                    : context.tr('Mode Nuit ?', 'Night Mode ?'),
                                onTap: () {
                                  themeProvider.toggleTheme(
                                      !themeProvider.isDarkMode);
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
