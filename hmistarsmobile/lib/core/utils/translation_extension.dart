import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

extension TranslationExtension on BuildContext {
  /// Translates text reactively based on the user's saved preference in AppState.
  /// If the selected language is 'English (EN)', it returns the [en] translation.
  /// Otherwise, it defaults to the French [fr] text.
  String tr(String fr, String en) {
    try {
      final state = watch<AppState>();
      if (state.langue == 'English (EN)') {
        return en;
      }
    } catch (_) {}
    return fr;
  }

  /// Non-reactive translation helper for cases where active context watch is not permitted.
  String trStatic(String fr, String en) {
    try {
      final state = read<AppState>();
      if (state.langue == 'English (EN)') {
        return en;
      }
    } catch (_) {}
    return fr;
  }
}
