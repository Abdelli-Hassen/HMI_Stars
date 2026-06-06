import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/providers/theme_provider.dart';
import '../../../../core/utils/translation_extension.dart';
import '../widgets/auth_hero_panel.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  bool _obscure1 = true;
  bool _obscure2 = true;
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (password.isEmpty) {
      setState(() => _errorMessage = context.tr(
          "Veuillez entrer un nouveau mot de passe.",
          "Please enter a new password."));
      return;
    }

    if (password.length < 8) {
      setState(() => _errorMessage = context.tr(
          "Le mot de passe doit contenir au moins 8 caractères.",
          "Password must contain at least 8 characters."));
      return;
    }

    if (password != confirmPassword) {
      setState(() => _errorMessage = context.tr(
          "Les mots de passe ne correspondent pas.",
          "Passwords do not match."));
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final auth = context.read<AuthProvider>();
      await auth.changePassword(password);

      if (!mounted) return;

      showDialog(
        barrierDismissible: false,
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(context.tr('Succès', 'Success')),
          content: Text(context.tr(
              'Votre mot de passe a été modifié avec succès. Vous pouvez maintenant vous connecter.',
              'Your password has been successfully modified. You can now log in.')),
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
    } on AuthException catch (e) {
      String msg = e.message;
      if (msg.toLowerCase().contains('session missing') ||
          msg.toLowerCase().contains('invalid token') ||
          msg.toLowerCase().contains('expired')) {
        msg = context.tr(
          "Lien expiré ou invalide. Veuillez demander un nouveau lien de réinitialisation.",
          "Expired or invalid link. Please request a new reset link.",
        );
      }
      setState(() => _errorMessage = msg);
    } catch (e) {
      setState(() => _errorMessage = context.tr(
          "Une erreur est survenue lors de la réinitialisation.",
          "An error occurred during reset."));
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
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
                      "L'architecture de votre excellence financière.",
                      "The architecture of your financial excellence.",
                    ),
                    subHeadline: context.tr(
                      "Sécurisez votre accès à l'outil de gestion RH et financière le plus précis du marché français.",
                      "Secure your access to the most accurate HR and financial management tool in the French market.",
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
                            context.tr('Réinitialiser le mot de passe',
                                'Reset Password'),
                            style: AppTextStyles.headlineLarge.copyWith(fontSize: 30, color: cs.onSurface),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            context.tr(
                              'Veuillez choisir un nouveau mot de passe sécurisé pour votre compte.',
                              'Please choose a new secure password for your account.',
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
                                  Icon(Icons.error_outline,
                                      color: AppColors.error, size: 20),
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



                          // New Password
                          Text(
                            context.tr('NOUVEAU MOT DE PASSE', 'NEW PASSWORD'),
                            style: AppTextStyles.labelSmall.copyWith(
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscure1,
                            decoration: InputDecoration(
                              hintText: '••••••••',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscure1
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 20,
                                  color: cs.outline,
                                ),
                                onPressed: () =>
                                    setState(() => _obscure1 = !_obscure1),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Confirm Password
                          Text(
                            context.tr('CONFIRMER LE MOT DE PASSE',
                                'CONFIRM PASSWORD'),
                            style: AppTextStyles.labelSmall.copyWith(
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w700,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _confirmPasswordController,
                            obscureText: _obscure2,
                            decoration: InputDecoration(
                              hintText: '••••••••',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscure2
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 20,
                                  color: cs.outline,
                                ),
                                onPressed: () =>
                                    setState(() => _obscure2 = !_obscure2),
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
                                onPressed: _loading ? null : _updatePassword,
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
                                                'Mettre à jour le mot de passe',
                                                'Update Password'),
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

                          const SizedBox(height: 24),
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
