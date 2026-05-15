import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
                    bottomCard: _buildApprovalBadge(),
                  ),
                ),

                // ─── Right Form ───
                Expanded(
                  child: Container(
                    color: AppColors.surface,
                    padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 48),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          Text('Réinitialiser le mot de passe',
                              style: AppTextStyles.headlineMedium),
                          const SizedBox(height: 8),
                          Text(
                            'Veuillez choisir un nouveau mot de passe sécurisé pour votre compte.',
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.onSurfaceVariant),
                          ),
                          const SizedBox(height: 32),

                          // New Password
                          Text('NOUVEAU MOT DE PASSE',
                              style: AppTextStyles.labelSmall.copyWith(
                                  letterSpacing: 1.2,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.onSurfaceVariant)),
                          const SizedBox(height: 8),
                          TextField(
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
                          const SizedBox(height: 20),

                          // Security Requirements
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceContainerLow,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('EXIGENCES DE SÉCURITÉ',
                                    style: AppTextStyles.labelSmall.copyWith(
                                        letterSpacing: 1.2,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.onSurfaceVariant)),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _securityReq('8 caractères minimum', true),
                                    ),
                                    Expanded(
                                      child: _securityReq('Une majuscule', false),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _securityReq('Un chiffre', false),
                                    ),
                                    Expanded(
                                      child: _securityReq('Un caractère spécial', false),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 28),

                          // Submit
                          SizedBox(
                            width: double.infinity,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ElevatedButton(
                                onPressed: () => Navigator.pushReplacementNamed(
                                    context, AppRoutes.login),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 18),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                        'Enregistrer le nouveau mot de passe',
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
                          const SizedBox(height: 20),

                          // Footer
                          Divider(color: AppColors.surfaceContainer),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              MouseRegion(
                                cursor: SystemMouseCursors.click,
                                child: GestureDetector(
                                  onTap: () => Navigator.pop(context),
                                  child: Row(
                                    children: [
                                      const Icon(Icons.arrow_back,
                                          size: 16, color: AppColors.primary),
                                      const SizedBox(width: 4),
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
                              Row(
                                children: [
                                  const Icon(Icons.lock_outline,
                                      size: 14, color: AppColors.outline),
                                  const SizedBox(width: 4),
                                  Text('CHIFFREMENT SSL 256 BITS',
                                      style: AppTextStyles.labelSmall.copyWith(
                                          fontSize: 9,
                                          letterSpacing: 1.2,
                                          color: AppColors.outline)),
                                ],
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
                    Text('MENTIONS LÉGALES',
                        style: AppTextStyles.labelSmall.copyWith(
                            fontSize: 9,
                            letterSpacing: 1.2,
                            color: AppColors.outline)),
                    const SizedBox(width: 24),
                    Text('CONFIDENTIALITÉ',
                        style: AppTextStyles.labelSmall.copyWith(
                            fontSize: 9,
                            letterSpacing: 1.2,
                            color: AppColors.outline)),
                    const SizedBox(width: 24),
                    Text('SUPPORT',
                        style: AppTextStyles.labelSmall.copyWith(
                            fontSize: 9,
                            letterSpacing: 1.2,
                            color: AppColors.outline)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _securityReq(String text, bool met) {
    return Row(
      children: [
        Icon(
          met ? Icons.check_circle : Icons.circle_outlined,
          size: 16,
          color: met ? AppColors.success : AppColors.outline,
        ),
        const SizedBox(width: 6),
        Text(text,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.onSurfaceVariant,
            )),
      ],
    );
  }

  Widget _buildApprovalBadge() {
    return Container(
      padding: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
        ),
      ),
      child: Row(
        children: [
          // Avatars
          const SizedBox(
            width: 48,
            height: 28,
            child: Stack(
              children: [
                Positioned(
                  left: 0,
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: Color(0xFF334155),
                    child: Icon(Icons.person, size: 14, color: Colors.white54),
                  ),
                ),
                Positioned(
                  left: 18,
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: Color(0xFF475569),
                    child: Icon(Icons.person, size: 14, color: Colors.white54),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text('APPROUVÉ PAR +500 CABINETS',
              style: AppTextStyles.labelSmall.copyWith(
                  fontSize: 10,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.7))),
        ],
      ),
    );
  }
}
