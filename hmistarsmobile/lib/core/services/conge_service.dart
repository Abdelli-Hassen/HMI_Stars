import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

/// Handles read/write operations for the `conges` (leaves) table.
class CongeService {
  final SupabaseClient _client;

  CongeService(this._client);

  /// Fetches all leave requests for a given enterprise.
  Future<List<Conge>> getConges(String entrepriseId) async {
    final data = await _client
        .from('conges')
        .select()
        .eq('entreprise_id', entrepriseId)
        .order('date_debut', ascending: false);

    return (data as List).map((e) => Conge.fromJson(e)).toList();
  }

  /// Inserts a new leave request.
  Future<Conge> createConge(Conge conge) async {
    final data = await _client
        .from('conges')
        .insert(conge.toJson())
        .select()
        .single();
    return Conge.fromJson(data);
  }

  /// Updates an existing leave request (e.g. status or notes).
  Future<Conge> updateConge(String id, Map<String, dynamic> updates) async {
    final data = await _client
        .from('conges')
        .update(updates)
        .eq('id', id)
        .select()
        .single();
    return Conge.fromJson(data);
  }

  /// Deletes a leave request.
  Future<void> deleteConge(String id) async {
    await _client.from('conges').delete().eq('id', id);
  }
}
