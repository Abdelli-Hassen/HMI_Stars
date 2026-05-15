import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

/// Handles all Supabase authentication operations.
class AuthService {
  final SupabaseClient _client;

  AuthService(this._client);

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get onAuthStateChange =>
      _client.auth.onAuthStateChange;

  /// Signs the user in with email and password.
  /// Returns the Supabase [Session] on success.
  Future<Session?> signIn({
    required String email,
    required String password,
  }) async {
    final response = await _client.auth.signInWithPassword(
      email: email,
      password: password,
    );
    return response.session;
  }

  /// Signs the user out and clears the session.
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  /// Sends a password reset email.
  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }
}
