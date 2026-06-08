import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

Widget createWebImage(String url, {BoxFit fit = BoxFit.contain}) {
  final isSvg = url.toLowerCase().contains('.svg') ||
      url.toLowerCase().contains('/svg');
  if (isSvg) {
    return SvgPicture.network(
      url,
      fit: fit,
      placeholderBuilder: (BuildContext context) => const Center(
        child: CircularProgressIndicator(),
      ),
      errorBuilder: (context, error, stackTrace) => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.broken_image, size: 64, color: Colors.white54),
          const SizedBox(height: 16),
          const Text(
            'Impossible de charger l\'image',
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
  return Image.network(
    url,
    fit: fit,
    errorBuilder: (context, error, stackTrace) => Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.broken_image, size: 64, color: Colors.white54),
        const SizedBox(height: 16),
        const Text(
          'Impossible de charger l\'image',
          style: TextStyle(color: Colors.white70),
        ),
      ],
    ),
  );
}
