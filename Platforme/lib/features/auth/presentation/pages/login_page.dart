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

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) return;

    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    final success = await auth.signIn(
      email: email,
      password: password,
      rememberMe: _rememberMe,
    );
    if (!mounted) return;
    setState(() => _loading = false);

    if (success) {
      Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
    } else if (auth.emailNonConfirme) {
      ToastUtils.show(
        context,
        context.tr(
          "Votre adresse e-mail n'a pas encore été confirmée. Veuillez vérifier votre boîte de réception et cliquer sur le lien de confirmation.",
          "Your email address has not been confirmed yet. Please check your inbox and click the confirmation link.",
        ),
        isError: true,
      );
    }
  }


  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final themeProvider = Provider.of<ThemeProvider>(context);
    final auth = Provider.of<AuthProvider>(context);

    if (auth.status == AuthStatus.initial) {
      return Scaffold(
        backgroundColor: cs.surface,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (auth.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
      });
      return Scaffold(
        backgroundColor: cs.surface,
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

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
                // ─── Left: Hero Panel ───
                Expanded(
                  child: AuthHeroPanel(
                    headline: context.tr(
                      "HMI Stars Consulting\nL'expertise à votre service.",
                      "HMI Stars Consulting\nExpertise at your service.",
                    ),
                    subHeadline: context.tr(
                      "Cabinet de conseil spécialisé en gestion, création d'entreprise et accompagnement social. Accédez à votre espace dédié pour un pilotage optimal de votre activité.",
                      "Consulting firm specialized in management, business creation, and social support. Access your dedicated space for optimal management of your activity.",
                    ),
                  ),
                ),

                // ─── Right: Login Form ───
                Expanded(
                  child: Container(
                    color: cs.surfaceContainerLowest,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 64,
                      vertical: 48,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('Espace Client', 'Client Space'),
                          style:
                              AppTextStyles.headlineLarge.copyWith(fontSize: 30, color: cs.onSurface),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          context.tr(
                            'Veuillez saisir vos identifiants pour accéder.',
                            'Please enter your credentials for access.',
                          ),
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 36),

                        // ─── Email ───
                        Text(
                          context.tr(
                            'Adresse e-mail',
                            'Email address',
                          ),
                          style: AppTextStyles.labelMedium.copyWith(
                            fontWeight: FontWeight.w600,
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
                        const SizedBox(height: 20),

                        // ─── Password ───
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              context.tr('Mot de passe', 'Password'),
                              style: AppTextStyles.labelMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                            MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () => Navigator.pushNamed(
                                    context, AppRoutes.forgotPassword),
                                child: Text(
                                  context.tr(
                                    'Mot de passe oublié ?',
                                    'Forgot password?',
                                  ),
                                  style: AppTextStyles.labelSmall.copyWith(
                                    color: cs.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          onSubmitted: (_) => _signIn(),
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.lock_outline,
                                size: 20, color: cs.outline),
                            hintText: '••••••••••••',
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                size: 20,
                                color: cs.outline,
                              ),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        // ─── Error message ───
                        Consumer<AuthProvider>(
                          builder: (context, auth, child) {
                            if (auth.errorMessage == null) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: Text(
                                auth.errorMessage!,
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            );
                          },
                        ),

                        // ─── Remember Me ───
                        Row(
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: Checkbox(
                                value: _rememberMe,
                                onChanged: (v) =>
                                    setState(() => _rememberMe = v ?? false),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              context.tr(
                                'Rester connecté sur cet appareil',
                                'Keep me signed in on this device',
                              ),
                              style: AppTextStyles.bodySmall.copyWith(
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // ─── Submit Button ───
                        SizedBox(
                          width: double.infinity,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: cs.primaryGradient,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      cs.primary.withValues(alpha: 0.2),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _loading ? null : _signIn,
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
                                          context.tr('Se connecter', 'Sign In'),
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

                        const SizedBox(height: 36),

                        // ─── Footer ───
                        Container(
                          padding: const EdgeInsets.only(top: 24),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(
                                color: cs.surfaceContainer,
                              ),
                            ),
                          ),
                          child: Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  context.tr('Nouveau sur HMI Stars ?', 'New to HMI Stars?'),
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: cs.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                MouseRegion(
                                  cursor: SystemMouseCursors.click,
                                  child: GestureDetector(
                                    onTap: () => Navigator.pushNamed(
                                        context, AppRoutes.signUp),
                                    child: Text(
                                      context.tr('Créer un compte', 'Create an account'),
                                      style:
                                          AppTextStyles.labelMedium.copyWith(
                                        color: cs.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ─── Support / Language / Theme Switcher ───
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
