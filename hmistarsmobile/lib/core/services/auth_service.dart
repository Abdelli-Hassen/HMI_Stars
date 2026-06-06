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

  Future<void> resetPassword(String email) async {
    await _client.auth.resetPasswordForEmail(email);
  }

  Future<void> updatePassword(String newPassword) async {
    await _client.auth.updateUser(UserAttributes(password: newPassword));
  }

  Future<AuthResponse> verifyRecoveryOTP(String email, String token) async {
    return await _client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.recovery,
    );
  }

  Future<AuthResponse> verifySignupOTP(String email, String token) async {
    return await _client.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.signup,
    );
  }
}
