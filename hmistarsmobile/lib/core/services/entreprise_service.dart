import 'dart:io';
import 'package:flutter/foundation.dart';
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

    try {
      // Check if the user is a platform admin/secretary
      final userCheck = await _client
          .from('utilisateurs_plateforme')
          .select('role')
          .eq('id', userId)
          .maybeSingle();

      if (userCheck != null) {
        // Platform user: load all enterprises
        final data = await _client
            .from('entreprises')
            .select()
            .order('raison_sociale', ascending: true);

        return (data as List)
            .map((row) => ClientParametres.fromJson(row as Map<String, dynamic>))
            .toList();
      }
    } catch (e) {
      debugPrint('[EntrepriseService] Check platform user error: $e');
    }

    // Default: load company by email (regular client)
    final List<String> emailsToCheck = [email];
    if (email.endsWith('@gmail.com')) {
      emailsToCheck.add(email.replaceAll('@gmail.com', '@mail.com'));
    } else if (email.endsWith('@mail.com')) {
      emailsToCheck.add(email.replaceAll('@mail.com', '@gmail.com'));
    }

    final data = await _client
        .from('entreprises')
        .select()
        .inFilter('email', emailsToCheck)
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

  /// Updates the enterprise settings record and returns the final ClientParametres.
  Future<ClientParametres> updateEntreprise(ClientParametres params) async {
    String? logoUrl = params.logoUrl;

    if (logoUrl != null && logoUrl.isNotEmpty && !logoUrl.startsWith('http')) {
      // It's a local file path, upload it to Supabase Storage first.
      try {
        final file = File(logoUrl);
        if (await file.exists()) {
          final ext = logoUrl.split('.').last.toLowerCase();
          final storagePath = 'logos/${params.id}.$ext';

          // Upload to bucket 'avatars' (which is public)
          await _client.storage.from('avatars').upload(
            storagePath,
            file,
            fileOptions: const FileOptions(upsert: true, contentType: 'image/*'),
          );

          // Get public URL with cache-busting
          final baseUrl = _client.storage.from('avatars').getPublicUrl(storagePath);
          logoUrl = '$baseUrl?t=${DateTime.now().millisecondsSinceEpoch}';
        }
      } catch (e) {
        debugPrint('[EntrepriseService] Error uploading logo: $e');
        rethrow;
      }
    }

    final updatedParams = params.copyWith(logoUrl: logoUrl);
    final payload = updatedParams.toJson();

    debugPrint('[EntrepriseService] Payload before update (to JSON): $payload');
    if (payload.containsKey('name')) {
      debugPrint('[EntrepriseService] WARNING: Payload contains unauthorized "name" key. Removing it.');
    }
    payload.remove('name');
    debugPrint('[EntrepriseService] Sanitized payload: $payload');

    final response = await _client
        .from('entreprises')
        .update(payload)
        .eq('id', params.id)
        .select()
        .single();

    return ClientParametres.fromJson(response);
  }
}

