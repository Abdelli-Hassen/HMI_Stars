import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/providers/app_state.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';

class SelectionEntreprisePage extends StatefulWidget {
  const SelectionEntreprisePage({super.key});

  @override
  State<SelectionEntreprisePage> createState() =>
      _SelectionEntreprisePageState();
}

class _SelectionEntreprisePageState extends State<SelectionEntreprisePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String? _selectingId;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _choisir(AppState state, ClientParametres e) async {
    if (_selectingId != null) return;
    setState(() => _selectingId = e.id);
    await state.selectEntreprise(e);
    // GoRouter will auto-redirect once needsCompanySelection = false
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final entreprises = state.entreprisesDisponibles;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF15191E) : AppColors.surface;
    final cardColor = isDark ? const Color(0xFF1C2128) : Colors.white;
    final goldColor = isDark ? const Color(0xFFF2D574) : AppColors.tertiary;
    final textPrimary = isDark ? const Color(0xFFF0F2F5) : AppColors.primary;
    final textSecondary =
        isDark ? const Color(0xFFC5CBD3) : AppColors.onSurfaceVariant;

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 48),

              // ─── Header ───────────────────────────────────────────────────
              _FadeSlide(
                controller: _controller,
                delay: 0.0,
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: goldColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.business_rounded,
                          color: goldColor, size: 22),
                    ),
                    const SizedBox(width: 14),
                    Text(
                      'HMI Stars',
                      style: GoogleFonts.manrope(
                        color: goldColor,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 40),

              _FadeSlide(
                controller: _controller,
                delay: 0.1,
                child: Text(
                  'Choisissez\nvotre entreprise',
                  style: GoogleFonts.manrope(
                    color: textPrimary,
                    fontWeight: FontWeight.w800,
                    fontSize: 28,
                    height: 1.2,
                    letterSpacing: -0.5,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              _FadeSlide(
                controller: _controller,
                delay: 0.15,
                child: Text(
                  'Votre compte est lié à ${entreprises.length} entreprises.\nSélectionnez celle que vous souhaitez gérer.',
                  style: GoogleFonts.inter(
                    color: textSecondary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 36),

              // ─── Company cards ────────────────────────────────────────────
              Expanded(
                child: ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  itemCount: entreprises.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final e = entreprises[index];
                    final isSelecting = _selectingId == e.id;
                    final isDisabled =
                        _selectingId != null && _selectingId != e.id;
                    final delay = 0.2 + index * 0.07;

                    return _FadeSlide(
                      controller: _controller,
                      delay: delay.clamp(0.0, 0.7),
                      child: _EntrepriseCard(
                        entreprise: e,
                        isSelecting: isSelecting,
                        isDisabled: isDisabled,
                        cardColor: cardColor,
                        goldColor: goldColor,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                        isDark: isDark,
                        onTap: () => _choisir(context.read<AppState>(), e),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 24),

              // ─── Logout ───────────────────────────────────────────────────
              _FadeSlide(
                controller: _controller,
                delay: 0.5,
                child: Center(
                  child: TextButton.icon(
                    onPressed: _selectingId != null
                        ? null
                        : () => context.read<AppState>().logout(),
                    icon: Icon(Icons.logout_rounded,
                        size: 16, color: textSecondary),
                    label: Text(
                      'Se déconnecter',
                      style: GoogleFonts.inter(
                        color: textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Company card widget ────────────────────────────────────────────────────

class _EntrepriseCard extends StatefulWidget {
  final ClientParametres entreprise;
  final bool isSelecting;
  final bool isDisabled;
  final Color cardColor;
  final Color goldColor;
  final Color textPrimary;
  final Color textSecondary;
  final bool isDark;
  final VoidCallback onTap;

  const _EntrepriseCard({
    required this.entreprise,
    required this.isSelecting,
    required this.isDisabled,
    required this.cardColor,
    required this.goldColor,
    required this.textPrimary,
    required this.textSecondary,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<_EntrepriseCard> createState() => _EntrepriseCardState();
}

class _EntrepriseCardState extends State<_EntrepriseCard> {
  bool _hovered = false;

  String get _initials {
    final words = widget.entreprise.raisonSociale.trim().split(' ');
    if (words.isEmpty) return '?';
    if (words.length == 1) return words[0][0].toUpperCase();
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final opacity = widget.isDisabled ? 0.45 : 1.0;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: opacity,
      child: GestureDetector(
        onTap: widget.isDisabled ? null : widget.onTap,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: widget.isSelecting
                  ? widget.goldColor.withOpacity(widget.isDark ? 0.15 : 0.08)
                  : _hovered
                      ? widget.cardColor
                          .withOpacity(widget.isDark ? 0.95 : 0.97)
                      : widget.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.isSelecting
                    ? widget.goldColor
                    : _hovered
                        ? widget.goldColor.withOpacity(0.4)
                        : (widget.isDark
                            ? const Color(0xFF2D3540)
                            : AppColors.outlineVariant),
                width: widget.isSelecting ? 2 : 1,
              ),
              boxShadow: _hovered || widget.isSelecting
                  ? [
                      BoxShadow(
                        color: widget.goldColor.withOpacity(0.12),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      )
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      )
                    ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  // Logo / initials avatar
                  _buildAvatar(),

                  const SizedBox(width: 16),

                  // Company info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.entreprise.raisonSociale,
                          style: GoogleFonts.manrope(
                            color: widget.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.entreprise.siret.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            'SIRET: ${widget.entreprise.siret}',
                            style: GoogleFonts.inter(
                              color: widget.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                        if (widget.entreprise.formeJuridique != null &&
                            widget.entreprise.formeJuridique!.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            widget.entreprise.formeJuridique!,
                            style: GoogleFonts.inter(
                              color: widget.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Arrow or loading indicator
                  if (widget.isSelecting)
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor:
                            AlwaysStoppedAnimation(widget.goldColor),
                      ),
                    )
                  else
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 15,
                      color: widget.isDisabled
                          ? widget.textSecondary.withOpacity(0.3)
                          : widget.goldColor,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final logoUrl = widget.entreprise.logoUrl;

    if (logoUrl != null && logoUrl.isNotEmpty && !logoUrl.contains('dicebear.com')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          logoUrl,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _initialsAvatar(),
        ),
      );
    }
    return _initialsAvatar();
  }

  Widget _initialsAvatar() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            widget.goldColor.withOpacity(0.8),
            widget.goldColor,
          ],
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      alignment: Alignment.center,
      child: Text(
        _initials,
        style: GoogleFonts.manrope(
          color: widget.isDark
              ? const Color(0xFF3D2F00)
              : AppColors.onTertiary,
          fontWeight: FontWeight.w800,
          fontSize: 16,
        ),
      ),
    );
  }
}

// ─── Staggered fade+slide animation helper ─────────────────────────────────

class _FadeSlide extends StatelessWidget {
  final AnimationController controller;
  final double delay;
  final Widget child;

  const _FadeSlide({
    required this.controller,
    required this.delay,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final start = delay;
    final end = (delay + 0.4).clamp(0.0, 1.0);

    final fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(start, end, curve: Curves.easeOut),
      ),
    );
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: controller,
        curve: Interval(start, end, curve: Curves.easeOut),
      ),
    );

    return FadeTransition(
      opacity: fade,
      child: SlideTransition(position: slide, child: child),
    );
  }
}
