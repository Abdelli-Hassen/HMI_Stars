import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class AppHeader {
  static Widget _buildLogo(BuildContext context, {String? logoUrl}) {
    return Image.asset(
      'assets/images/logo.jpeg',
      width: 70,
      height: 36,
      fit: BoxFit.contain,
    );
  }

  static SliverAppBar sliver({
    required BuildContext context,
    String? logoUrl,
    List<Widget>? actions,
    PreferredSizeWidget? bottom,
    bool floating = true,
    bool snap = true,
    bool pinned = false,
  }) {
    return SliverAppBar(
      floating: floating,
      snap: snap,
      pinned: pinned,
      backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.9),
      title: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _buildLogo(context, logoUrl: logoUrl),
          ),
          const SizedBox(width: 10),
          Text(
            'HMI Stars',
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
      actions: actions,
      bottom: bottom,
    );
  }

  static AppBar standard({
    required BuildContext context,
    String? logoUrl,
    List<Widget>? actions,
    PreferredSizeWidget? bottom,
    Widget? leading,
    bool automaticallyImplyLeading = true,
    double elevation = 0,
  }) {
    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: elevation,
      leading: leading,
      automaticallyImplyLeading: automaticallyImplyLeading,
      title: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: _buildLogo(context, logoUrl: logoUrl),
          ),
          const SizedBox(width: 10),
          Text(
            'HMI Stars',
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.primary,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
      actions: actions,
      bottom: bottom,
    );
  }
}
