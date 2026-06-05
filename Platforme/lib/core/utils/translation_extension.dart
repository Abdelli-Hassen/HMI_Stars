import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

extension TranslationExtension on BuildContext {
  /// Translates text reactively based on the user's saved preference in AuthProvider.
  /// If the selected language is 'English (EN)', it returns the [en] translation.
  /// Otherwise, it defaults to the French [fr] text.
  String tr(String fr, String en) {
    try {
      final auth = watch<AuthProvider>();
      final lang = auth.utilisateur?.preferences['langue'] ?? auth.tempLanguage;
      if (lang == 'English (EN)') {
        return en;
      }
    } catch (_) {
      try {
        final auth = read<AuthProvider>();
        final lang = auth.utilisateur?.preferences['langue'] ?? auth.tempLanguage;
        if (lang == 'English (EN)') {
          return en;
        }
      } catch (_) {}
    }
    return fr;
  }

  /// Non-reactive translation helper for cases where active context watch is not permitted (e.g. during layout/init).
  String trStatic(String fr, String en) {
    try {
      final auth = read<AuthProvider>();
      final lang = auth.utilisateur?.preferences['langue'] ?? auth.tempLanguage;
      if (lang == 'English (EN)') {
        return en;
      }
    } catch (_) {}
    return fr;
  }
}

