import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/providers/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/top_notification_banner.dart';
import '../../core/utils/translation_extension.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _sent = false;
  bool _loading = false;
  bool _verifying = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _sendReset() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      TopNotificationBanner.show(
        context,
        context.trStatic('Veuillez saisir votre adresse e-mail.', 'Please enter your email address.'),
        isError: true,
      );
      return;
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      TopNotificationBanner.show(
        context,
        context.trStatic('Veuillez saisir une adresse e-mail valide.', 'Please enter a valid email address.'),
        isError: true,
      );
      return;
    }
    setState(() => _loading = true);
    try {
      await context.read<AppState>().resetPassword(_emailController.text.trim());
      if (mounted) setState(() { _loading = false; _sent = true; });
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        String msg = context.trStatic('Erreur lors de l\'envoi. Vérifiez l\'adresse e-mail.', 'Error sending. Check your email address.');
        if (e.toString().toLowerCase().contains('unknown verification email') || 
            e.toString().toLowerCase().contains('not found')) {
          msg = context.trStatic('Adresse e-mail inconnue ou non vérifiée.', 'Unknown or unverified email address.');
        } else if (e is Exception) {
          // Si on peut extraire le message de l'exception
          final str = e.toString();
          if (str.contains('message:')) {
            msg = str;
          }
        }
        TopNotificationBanner.show(
          context,
          msg,
          isError: true,
        );
      }
    }
  }

  Future<void> _verifyAndReset() async {
    final token = _otpController.text.trim();
    final newPassword = _passwordController.text.trim();
    if (token.length < 6) {
      TopNotificationBanner.show(
        context,
        context.trStatic('Veuillez saisir le code OTP à 6 chiffres.', 'Please enter the 6-digit OTP code.'),
        isError: true,
      );
      return;
    }
    if (newPassword.length < 8) {
      TopNotificationBanner.show(
        context,
        context.trStatic('Le nouveau mot de passe doit contenir au moins 8 caractères.', 'The new password must be at least 8 characters long.'),
        isError: true,
      );
      return;
    }
    setState(() => _verifying = true);
    try {
      final appState = context.read<AppState>();
      final email = _emailController.text.trim();
      final ok = await appState.verifyRecoveryOTP(email, token);
      if (!ok) {
        setState(() => _verifying = false);
        if (mounted) {
          TopNotificationBanner.show(
            context,
            context.trStatic('Code incorrect ou expiré.', 'Incorrect or expired code.'),
            isError: true,
          );
        }
        return;
      }
      await appState.updatePassword(newPassword);
      if (mounted) {
        setState(() => _verifying = false);
        TopNotificationBanner.show(
          context,
          context.trStatic('Mot de passe réinitialisé avec succès.', 'Password reset successfully.'),
          isError: false,
        );
        context.go('/connexion');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _verifying = false);
        TopNotificationBanner.show(
          context,
          'Erreur: ${e.toString()}',
          isError: true,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Theme.of(context).colorScheme.primary,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                context.tr('Mot de passe\noublié ?', 'Forgot\npassword?'),
                style: GoogleFonts.manrope(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.primary,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                context.tr('Entrez votre adresse e-mail institutionnelle. Nous vous enverrons un code OTP pour réinitialiser votre mot de passe.', 'Enter your institutional email address. We will send you an OTP code to reset your password.'),
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 32),
              if (!_sent) ...[
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('ADRESSE E-MAIL', 'EMAIL ADDRESS'),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.primary,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          hintText: 'nom@hmistars.com',
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _sendReset,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(
                              context,
                            ).colorScheme.tertiary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
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
                              : Text(
                                  context.tr('Envoyer le code', 'Send code'),
                                  style: GoogleFonts.manrope(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 24,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr('CODE DE CONFIRMATION (OTP)', 'CONFIRMATION CODE (OTP)'),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.primary,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 6,
                        ),
                        decoration: const InputDecoration(
                          hintText: '000000',
                          counterText: '',
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        context.tr('NOUVEAU MOT DE PASSE', 'NEW PASSWORD'),
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.primary,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: '••••••••',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword ? Icons.visibility_off : Icons.visibility,
                              size: 20,
                            ),
                            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _verifying ? null : _verifyAndReset,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Theme.of(context).colorScheme.tertiary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _verifying
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  context.tr('Réinitialiser le mot de passe', 'Reset password'),
                                  style: GoogleFonts.manrope(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
