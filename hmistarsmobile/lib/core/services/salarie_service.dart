import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

/// Handles CRUD operations for the `salaries` table.
class SalarieService {
  final SupabaseClient _client;

  SalarieService(this._client);

  /// Fetches all active (non-archived) salariés for the given enterprise.
  Future<List<Salarie>> getSalaries(String entrepriseId) async {
    final data = await _client
        .from('salaries')
        .select()
        .eq('entreprise_id', entrepriseId)
        .eq('est_archive', false)
        .order('nom', ascending: true);
    return (data as List).map((e) => Salarie.fromJson(e)).toList();
  }

  /// Fetches only archived salariés for the given enterprise.
  Future<List<Salarie>> getSalariesArchives(String entrepriseId) async {
    final data = await _client
        .from('salaries')
        .select()
        .eq('entreprise_id', entrepriseId)
        .eq('est_archive', true)
        .order('nom', ascending: true);
    return (data as List).map((e) => Salarie.fromJson(e)).toList();
  }

  /// Inserts a new salarié and returns it with the generated ID.
  Future<Salarie> addSalarie(Salarie salarie) async {
    final data = await _client
        .from('salaries')
        .insert(salarie.toJson())
        .select()
        .single();
    return Salarie.fromJson(data);
  }

  /// Updates an existing salarié (matched by ID).
  Future<Salarie> updateSalarie(Salarie salarie) async {
    final data = await _client
        .from('salaries')
        .update(salarie.toJson())
        .eq('id', salarie.id)
        .select()
        .single();
    return Salarie.fromJson(data);
  }

  /// Archives a salarié (soft delete).
  Future<void> archiveSalarie(String id) async {
    await _client
        .from('salaries')
        .update({'est_archive': true})
        .eq('id', id);
  }

  /// Restores an archived salarié.
  Future<void> unarchiveSalarie(String id) async {
    await _client
        .from('salaries')
        .update({'est_archive': false})
        .eq('id', id);
  }

  /// Permanently deletes a salarié.
  Future<void> deleteSalarie(String id) async {
    await _client
        .from('salaries')
        .delete()
        .eq('id', id);
  }

  /// Uploads a salarie avatar to Supabase Storage and returns the public URL.
  Future<String?> uploadSalarieAvatar(String salarieId, Uint8List fileBytes, String fileName) async {
    try {
      final ext = fileName.split('.').last.toLowerCase();
      // Bucket: 'avatars', path: 'avatars/$salarieId.$ext' to align with Admin/PlatformDataService pattern
      final storagePath = 'avatars/$salarieId.$ext';

      await _client.storage.from('avatars').uploadBinary(
        storagePath,
        fileBytes,
        fileOptions: FileOptions(
          upsert: true,
          contentType: 'image/$ext',
        ),
      );

      final baseUrl = _client.storage.from('avatars').getPublicUrl(storagePath);
      final publicUrl = '$baseUrl?t=${DateTime.now().millisecondsSinceEpoch}';

      // Update the database if the salarie exists
      await _client
          .from('salaries')
          .update({'avatar_url': publicUrl})
          .eq('id', salarieId);

      return publicUrl;
    } catch (e) {
      logError('Error uploading avatar: $e');
      return null;
    }
  }

  void logError(String message) {
    // Basic print logging
    print('[SalarieService] $message');
  }
}
