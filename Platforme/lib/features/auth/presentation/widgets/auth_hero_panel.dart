import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_colors.dart';


import '../../../../core/utils/translation_extension.dart';

/// Reusable left-side hero panel for all authentication screens.
class AuthHeroPanel extends StatelessWidget {
  final String headline;
  final String? subHeadline;
  final Widget? bottomCard;

  const AuthHeroPanel({
    super.key,
    required this.headline,
    this.subHeadline,
    this.bottomCard,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF003D9B),
            Color(0xFF0052CC),
            Color(0xFF0A1628),
          ],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // ─── Decorative blurred circles ───
          Positioned(
            top: -80,
            left: -80,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            right: -100,
            child: Container(
              width: 350,
              height: 350,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryContainer.withValues(alpha: 0.1),
              ),
            ),
          ),

          // ─── Content ───
          Padding(
            padding: const EdgeInsets.all(48),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // ─── Logo ───
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/logo.jpeg',
                    width: 100,
                    fit: BoxFit.contain,
                  ),
                ),

                // ─── Headline ───
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      headline,
                      style: GoogleFonts.manrope(
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.15,
                      ),
                    ),
                    if (subHeadline != null) ...[
                      const SizedBox(height: 20),
                      Text(
                        subHeadline!,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withValues(alpha: 0.7),
                          height: 1.6,
                        ),
                      ),
                    ],
                    if (bottomCard != null) ...[
                      const SizedBox(height: 32),
                      bottomCard!,
                    ],
                  ],
                ),

                // ─── Footer ───
                Text(
                  context.tr(
                    '© 2026 HMI Stars Consulting. Tous droits réservés.',
                    '© 2026 HMI Stars Consulting. All rights reserved.',
                  ),
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Trust badge card shown on the login page hero.
class TrustBadgeCard extends StatelessWidget {
  const TrustBadgeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(
                  Icons.verified,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('Certifié Sécurité Bancaire', 'Certified Bank Security'),
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    context.tr('Chiffrement de bout en bout AES-256', 'End-to-end encryption AES-256'),
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('ACCOMPAGNEMENT ANNUEL', 'ANNUAL SUPPORT'),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.5),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '+500',
                        style: GoogleFonts.manrope(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        context.tr('Entreprises', 'Companies'),
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF93C5FD),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Icon(
                Icons.business_center,
                color: const Color(0xFF60A5FA),
                size: 24,
              ),
            ],
          ),
        ],
      ),
    );
  }
}