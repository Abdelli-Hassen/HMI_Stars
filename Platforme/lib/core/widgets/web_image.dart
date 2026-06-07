import 'package:flutter/material.dart';
import 'web_image_stub.dart' if (dart.library.html) 'web_image_web.dart' as loader;

class WebImage extends StatelessWidget {
  final String url;
  final BoxFit fit;

  const WebImage({super.key, required this.url, this.fit = BoxFit.contain});

  @override
  Widget build(BuildContext context) {
    return loader.createWebImage(url, fit: fit);
  }
}
