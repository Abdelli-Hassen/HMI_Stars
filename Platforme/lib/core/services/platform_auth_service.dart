import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_config.dart';

/// Service d'authentification Supabase pour la plateforme admin.
class PlatformAuthService {
  final _client = SupabaseConfig.client;

  User? get currentUser => _client.auth.currentUser;
  Session? get currentSession => _client.auth.currentSession;
  bool get isSignedIn => currentUser != null;

  Stream<AuthState> get onAuthStateChange =>
      _client.auth.onAuthStateChange;

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      debugPrint('[Auth] signIn OK: ${response.user?.id}');
      return response;
    } catch (e) {
      debugPrint('[Auth] signIn error: $e');
      rethrow;
    }
  }

  /// Inscription d'un nouvel utilisateur plateforme.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    String? nom,
    String? telephone,
    String? cin,
    String? organisation,
  }) async {
    debugPrint('[Auth] signUp -> $email');

    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'nom': nom ?? email.split('@').first,
          'telephone': telephone ?? '',
          'cin': cin ?? '',
          'organisation': organisation ?? 'HMI Stars Consulting',
        },
      );
      debugPrint('[Auth] signUp OK -> user=${response.user?.id}');
      return response;
    } catch (e) {
      debugPrint('[Auth] signUp error: $e');
      rethrow;
    }
  }

  /// Re-sends the confirmation email for an unverified account.
  Future<void> resendConfirmationEmail(String email) async {
    debugPrint('[Auth] Resending confirmation to $email');
    await _client.auth.resend(type: OtpType.signup, email: email);
    debugPrint('[Auth] Confirmation email resent');
  }

  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
    debugPrint('[Auth] Signed out');
  }
}
