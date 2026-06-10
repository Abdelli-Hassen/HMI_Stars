import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/providers/app_state.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/top_notification_banner.dart';
import '../../core/utils/translation_extension.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    final appState = context.read<AppState>();
    final errorMessage = await appState.login(
      _emailController.text.trim(),
      _passwordController.text,
    );
    if (mounted) {
      setState(() => _isLoading = false);
      if (errorMessage == null) {
        context.go('/tableau-de-bord');
      } else if (errorMessage == 'email_not_confirmed') {
        _showOtpDialog(_emailController.text.trim());
      } else {
        TopNotificationBanner.show(
          context,
          errorMessage,
          isError: true,
        );
      }
    }
  }

  void _showOtpDialog(String email) {
    final otpController = TextEditingController();
    bool isVerifying = false;
    bool isResending = false;
    int resendCooldown = 0;

    // Auto-resend the OTP when the dialog first opens
    final appState = context.read<AppState>();
    appState.resendConfirmationOTP(email).catchError((_) {});

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setStateDialog) {
          // Start cooldown timer helper
          void startCooldown() {
            resendCooldown = 60;
            Future.doWhile(() async {
              await Future.delayed(const Duration(seconds: 1));
              if (!dialogContext.mounted) return false;
              setStateDialog(() => resendCooldown--);
              return resendCooldown > 0;
            });
          }

          // Kick off cooldown on first build
          if (resendCooldown == 0 && !isResending) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (dialogContext.mounted) startCooldown();
            });
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(context.tr('Confirmation de Compte', 'Account Confirmation')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '${context.tr('Saisissez le code de confirmation à 6 chiffres envoyé à', 'Enter the 6-digit confirmation code sent to')} $email',
                  style: GoogleFonts.inter(fontSize: 14),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: otpController,
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
                const SizedBox(height: 12),
                // Resend OTP button with cooldown
                TextButton.icon(
                  onPressed: (resendCooldown > 0 || isResending)
                      ? null
                      : () async {
                          setStateDialog(() => isResending = true);
                          try {
                            await appState.resendConfirmationOTP(email);
                            if (dialogContext.mounted) {
                              setStateDialog(() => isResending = false);
                              startCooldown();
                              TopNotificationBanner.show(
                                context,
                                context.trStatic(
                                  'Code renvoyé avec succès !',
                                  'Code resent successfully!',
                                ),
                                isError: false,
                              );
                            }
                          } catch (e) {
                            if (dialogContext.mounted) {
                              setStateDialog(() => isResending = false);
                              TopNotificationBanner.show(
                                context,
                                context.trStatic(
                                  'Impossible de renvoyer le code.',
                                  'Unable to resend the code.',
                                ),
                                isError: true,
                              );
                            }
                          }
                        },
                  icon: isResending
                      ? const SizedBox(
                          height: 14,
                          width: 14,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.refresh, size: 18),
                  label: Text(
                    resendCooldown > 0
                        ? '${context.tr('Renvoyer dans', 'Resend in')} ${resendCooldown}s'
                        : context.tr('Renvoyer le code', 'Resend code'),
                    style: GoogleFonts.inter(fontSize: 13),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: isVerifying ? null : () => Navigator.pop(dialogContext),
                child: Text(context.tr('Annuler', 'Cancel')),
              ),
              ElevatedButton(
                onPressed: isVerifying ? null : () async {
                  final token = otpController.text.trim();
                  if (token.length < 6) return;

                  setStateDialog(() => isVerifying = true);
                  try {
                    final ok = await appState.verifySignupOTP(email, token);
                    if (mounted) {
                      Navigator.pop(dialogContext);
                      if (ok) {
                        TopNotificationBanner.show(
                          context,
                          context.trStatic('Compte confirmé avec succès !', 'Account confirmed successfully!'),
                          isError: false,
                        );
                        context.go('/tableau-de-bord');
                      } else {
                        TopNotificationBanner.show(
                          context,
                          context.trStatic('Code incorrect ou expiré.', 'Incorrect or expired code.'),
                          isError: true,
                        );
                      }
                    }
                  } catch (e) {
                    setStateDialog(() => isVerifying = false);
                    if (mounted) {
                      TopNotificationBanner.show(
                        context,
                        'Erreur: ${e.toString()}',
                        isError: true,
                      );
                    }
                  }
                },
                child: isVerifying
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(context.tr('Valider', 'Validate')),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Decorative background blurs
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            right: 20,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Theme.of(context).colorScheme.tertiary.withOpacity(0.05),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 32),
                  // Brand Header
                  _buildBrandHeader(),
                  const SizedBox(height: 40),
                  // Headline
                  Text(
                    'HMI Stars Consulting',
                    style: GoogleFonts.manrope(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.primary,
                      height: 1.15,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    context.tr('Cabinet de conseil spécialisé en gestion, création d\'entreprise et accompagnement social.', 'Consulting firm specializing in management, business creation, and social support.'),
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Login Card
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Email
                          _buildLabel(context.tr('Adresse e-mail', 'E-mail adress')),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: const InputDecoration(
                              hintText: 'nom@hmistars.com',
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return context.trStatic('Email requis', 'Email required');
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v.trim())) {
                                return context.trStatic('Veuillez saisir un e-mail valide', 'Please enter a valid e-mail');
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),
                          // Password
                          _buildLabel(context.tr('Mot de Passe', 'Password')),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              hintText: '••••••••',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: Theme.of(context).colorScheme.outline,
                                  size: 20,
                                ),
                                onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword,
                                ),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return context.trStatic('Mot de passe requis', 'Password required');
                              if (v.trim().length < 6) {
                                return context.trStatic('Au moins 6 caractères requis', 'At least 6 characters required');
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          // Forgot Password
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () => context.push('/mot-de-passe-oublie'),
                              child: Text(
                                context.tr('Mot de passe oublié ?', 'Forgot password?'),
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.tertiary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Login Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.tertiary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  vertical: 18,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: _isLoading
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
                                          context.tr('Se connecter', 'Login'),
                                          style: GoogleFonts.manrope(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 16,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Icon(Icons.arrow_forward, size: 18),
                                      ],
                                    ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Footer in card
                          Divider(
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  final appState = context.read<AppState>();
                                  if (appState.langue == 'English (EN)') {
                                    appState.setLangue('Français (FR)');
                                  } else {
                                    appState.setLangue('English (EN)');
                                  }
                                },
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.language,
                                      size: 18,
                                      color: Theme.of(context).colorScheme.outline,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      context.watch<AppState>().langue == 'English (EN)'
                                          ? 'Français'
                                          : 'English',
                                      style: GoogleFonts.inter(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: Theme.of(context).colorScheme.outline,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () => context.read<AppState>().toggleDarkMode(),
                                child: Text(
                                  context.watch<AppState>().isDarkMode
                                      ? context.tr('Mode clair', 'Light Mode')
                                      : context.tr('Mode nuit', 'Night Mode'),
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: Theme.of(context).colorScheme.outline,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Info box
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: Text(
                            context.tr('AVIS', 'NOTICE'),
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Theme.of(context).colorScheme.tertiary,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            context.tr('L\'accès est strictement réservé au personnel autorisé. Toute tentative de connexion non autorisée fera l\'objet d\'un audit de sécurité.', 'Access is strictly reserved for authorized personnel. Any unauthorized connection attempt will be subject to a security audit.'),
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: Text(
                      '© 2026 HMI Stars Consulting',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.outline,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandHeader() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.asset(
        'assets/images/logo.jpeg',
        width: 100,
        fit: BoxFit.contain,
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.primary,
        letterSpacing: 1.2,
      ),
    );
  }
}
