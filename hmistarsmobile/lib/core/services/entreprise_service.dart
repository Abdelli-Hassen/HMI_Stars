import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

/// Handles enterprise data: fetching the user's enterprise and updating settings.
class EntrepriseService {
  final SupabaseClient _client;

  EntrepriseService(this._client);

  /// Returns ALL enterprises linked to the authenticated user's email.
  /// Used to detect multi-company accounts and show the company selector.
  Future<List<ClientParametres>> getEntreprisesForUser(String userId) async {
    final email = _client.auth.currentUser?.email;
    if (email == null) return [];

    final data = await _client
        .from('entreprises')
        .select()
        .eq('email', email)
        .order('raison_sociale', ascending: true);

    return (data as List)
        .map((row) => ClientParametres.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  /// Returns the first enterprise linked to the current authenticated user.
  /// Used when the user has only one company (no selector needed).
  Future<ClientParametres?> getEntrepriseForUser(String userId) async {
    final entreprises = await getEntreprisesForUser(userId);
    return entreprises.isEmpty ? null : entreprises.first;
  }

  /// Fetches the enterprise ID for the current user (for use in queries).
  Future<String?> getEntrepriseId(String userId) async {
    final params = await getEntrepriseForUser(userId);
    return params?.id;
  }

  /// Updates the enterprise settings record.
  Future<void> updateEntreprise(ClientParametres params) async {
    await _client
        .from('entreprises')
        .update(params.toJson())
        .eq('id', params.id);
  }
}
