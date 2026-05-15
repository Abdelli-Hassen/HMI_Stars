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
}
