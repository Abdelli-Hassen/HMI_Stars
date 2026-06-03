import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/router/app_router.dart';
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
      setState(() => _errorMessage = "Veuillez entrer un nouveau mot de passe.");
      return;
    }

    if (password.length < 8) {
      setState(() => _errorMessage = "Le mot de passe doit contenir au moins 8 caractères.");
      return;
    }

    if (password != confirmPassword) {
      setState(() => _errorMessage = "Les mots de passe ne correspondent pas.");
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
        builder: (context) => AlertDialog(
          title: const Text('Succès'),
          content: const Text('Votre mot de passe a été modifié avec succès. Vous pouvez maintenant vous connecter.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, AppRoutes.login);
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() => _errorMessage = "Une erreur est survenue lors de la réinitialisation.");
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(
            child: Row(
              children: [
                // ─── Left Hero ───
                Expanded(
                  child: AuthHeroPanel(
                    headline: "L'architecture de votre excellence financière.",
                    subHeadline:
                        "Sécurisez votre accès à l'outil de gestion RH et financière le plus précis du marché français.",
                  ),
                ),

                // ─── Right Form ───
                Expanded(
                  child: Container(
                    color: AppColors.surface,
                    child: Center(
                      child: Container(
                        constraints: const BoxConstraints(maxWidth: 420),
                        padding: const EdgeInsets.all(48),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(16),
                          border: Border(
                            left: BorderSide(
                              color: AppColors.primary,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Réinitialiser le mot de passe',
                                style: AppTextStyles.headlineMedium),
                            const SizedBox(height: 8),
                            Text(
                              'Veuillez choisir un nouveau mot de passe sécurisé pour votre compte.',
                              style: AppTextStyles.bodyMedium
                                  .copyWith(color: AppColors.onSurfaceVariant),
                            ),
                            const SizedBox(height: 28),

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

                            // New Password
                            Text('NOUVEAU MOT DE PASSE',
                                style: AppTextStyles.labelSmall.copyWith(
                                    letterSpacing: 1.2,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.onSurfaceVariant)),
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
                                      color: AppColors.outline),
                                  onPressed: () =>
                                      setState(() => _obscure1 = !_obscure1),
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Confirm Password
                            Text('CONFIRMER LE MOT DE PASSE',
                                style: AppTextStyles.labelSmall.copyWith(
                                    letterSpacing: 1.2,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.onSurfaceVariant)),
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
                                      color: AppColors.outline),
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
                                  gradient: AppColors.primaryGradient,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ElevatedButton(
                                  onPressed: _loading ? null : _updatePassword,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 18),
                                  ),
                                  child: _loading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2),
                                        )
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text(
                                                'Mettre à jour le mot de passe',
                                                style: GoogleFonts.manrope(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w700,
                                                  color: Colors.white,
                                                )),
                                            const SizedBox(width: 8),
                                            const Icon(Icons.arrow_forward,
                                                size: 18, color: Colors.white),
                                          ],
                                        ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Footer
                            Divider(color: AppColors.surfaceContainer),
                            const SizedBox(height: 16),
                            Center(
                              child: MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.chevron_left,
                                          size: 18, color: AppColors.primary),
                                      Text('Retour à la connexion',
                                          style: AppTextStyles.labelMedium
                                              .copyWith(
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w600,
                                          )),
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
                ),
              ],
            ),
          ),

          // ─── Bottom Footer ───
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            color: AppColors.surfaceContainerLowest,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('© 2026 HMI STARS. TOUS DROITS RÉSERVÉS.',
                    style: AppTextStyles.labelSmall.copyWith(
                        fontSize: 9,
                        letterSpacing: 1.2,
                        color: AppColors.outline)),
                Row(
                  children: [
                    _footerLink('MENTIONS LÉGALES'),
                    const SizedBox(width: 24),
                    _footerLink('CONFIDENTIALITÉ'),
                    const SizedBox(width: 24),
                    _footerLink('SUPPORT'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _footerLink(String text) {
    return Text(
      text,
      style: AppTextStyles.labelSmall.copyWith(
        fontSize: 9,
        letterSpacing: 1.2,
        color: AppColors.outline,
      ),
    );
  }
}
