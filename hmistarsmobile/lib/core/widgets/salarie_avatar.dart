import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class SalarieAvatar extends StatelessWidget {
  final String? avatarUrl;
  final String initials;
  final double radius;
  final Color? backgroundColor;
  final TextStyle? textStyle;
  final double iconSize;

  const SalarieAvatar({
    super.key,
    this.avatarUrl,
    required this.initials,
    this.radius = 24,
    this.backgroundColor,
    this.textStyle,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSvg = avatarUrl != null && (avatarUrl!.contains('.svg') || avatarUrl!.contains('/svg'));
    final hasAvatar = avatarUrl != null && avatarUrl!.isNotEmpty && !avatarUrl!.contains('dicebear.com');

    final defaultBgColor = backgroundColor ?? theme.colorScheme.primaryContainer.withOpacity(0.3);

    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
          width: 1.5,
        ),
      ),
      child: CircleAvatar(
        radius: radius - 1.5,
        backgroundColor: defaultBgColor,
        backgroundImage: hasAvatar && !isSvg ? NetworkImage(avatarUrl!) : null,
        child: hasAvatar && isSvg
            ? ClipOval(
                child: SvgPicture.network(
                  avatarUrl!,
                  width: (radius - 1.5) * 2,
                  height: (radius - 1.5) * 2,
                  fit: BoxFit.cover,
                  placeholderBuilder: (BuildContext context) => SizedBox(
                    width: (radius - 1.5) * 2,
                    height: (radius - 1.5) * 2,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            : (!hasAvatar
                ? (initials.isNotEmpty
                    ? Text(
                        initials,
                        style: textStyle ??
                            GoogleFonts.manrope(
                              fontWeight: FontWeight.w800,
                              fontSize: (radius - 1.5) * 0.7,
                              color: theme.colorScheme.primary,
                            ),
                      )
                    : Icon(
                        Icons.person,
                        size: iconSize,
                        color: theme.colorScheme.primary,
                      ))
                : null),
      ),
    );
  }
}
