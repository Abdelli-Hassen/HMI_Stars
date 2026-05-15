import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/router/app_router.dart';
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
      setState(() => _errorMessage = "Veuillez entrer votre adresse e-mail.");
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
        builder: (context) => AlertDialog(
          title: const Text('Vérification d\'email requise'),
          content: const Text('Un lien de réinitialisation a été envoyé. Veuillez vérifier votre boîte de réception et cliquer sur le lien avant de vous connecter.'),
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
                    headline:
                        '"La rigueur financière est l\'architecte de la pérennité."',
                    subHeadline: '— Vision Expertise\nPARTENAIRE DES LEADERS FRANÇAIS',
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
                            Text('Mot de passe oublié ?',
                                style: AppTextStyles.headlineMedium),
                            const SizedBox(height: 8),
                            Text(
                              'Entrez votre adresse e-mail pour recevoir un lien de réinitialisation.',
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

                            Text(
                              'ADRESSE E-MAIL PROFESSIONNELLE',
                              style: AppTextStyles.labelSmall.copyWith(
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(height: 8),
                            TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(
                                prefixIcon: Icon(Icons.email_outlined,
                                    size: 20, color: AppColors.outline),
                                hintText: 'nom@entreprise.fr',
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
                                  onPressed: _loading ? null : _resetPassword,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    shadowColor: Colors.transparent,
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 18),
                                  ),
                                  child: _loading
                                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                      : Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Text('Envoyer le lien',
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

                            const SizedBox(height: 28),

                            // Divider
                            Divider(color: AppColors.surfaceContainer),
                            const SizedBox(height: 16),

                            // Back to login
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

                            const SizedBox(height: 20),

                            // Footer links
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('SUPPORT',
                                    style: AppTextStyles.labelSmall.copyWith(
                                        fontSize: 9,
                                        letterSpacing: 1.5,
                                        color: AppColors.outline)),
                                const SizedBox(width: 16),
                                Text('•',
                                    style: AppTextStyles.labelSmall
                                        .copyWith(color: AppColors.outline)),
                                const SizedBox(width: 16),
                                Text('CONFIDENTIALITÉ',
                                    style: AppTextStyles.labelSmall.copyWith(
                                        fontSize: 9,
                                        letterSpacing: 1.5,
                                        color: AppColors.outline)),
                              ],
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
                Text(
                  '© 2026 HMI STARS. TOUS DROITS RÉSERVÉS.',
                  style: AppTextStyles.labelSmall.copyWith(
                    fontSize: 9,
                    letterSpacing: 1.2,
                    color: AppColors.outline,
                  ),
                ),
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
