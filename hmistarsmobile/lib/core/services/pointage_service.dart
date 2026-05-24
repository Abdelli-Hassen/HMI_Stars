import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

/// Handles read/write operations for the `pointages` table.
class PointageService {
  final SupabaseClient _client;

  PointageService(this._client);

  /// Fetches all pointage entries for a given enterprise and month.
  Future<List<PointageEntree>> getPointagesForMonth(
    String entrepriseId,
    int year,
    int month,
  ) async {
    final firstDay = '$year-${month.toString().padLeft(2, '0')}-01';
    final lastDay = month < 12
        ? '$year-${(month + 1).toString().padLeft(2, '0')}-01'
        : '${year + 1}-01-01';

    final data = await _client
        .from('pointages')
        .select()
        .eq('entreprise_id', entrepriseId)
        .gte('date', firstDay)
        .lt('date', lastDay);

    return (data as List).map((e) => PointageEntree.fromJson(e)).toList();
  }

  /// Upserts (insert or update) a pointage entry.
  /// Uses ON CONFLICT on (salarie_id, date) to handle duplicates.
  Future<void> upsertPointage(PointageEntree entry) async {
    await _client.from('pointages').upsert(
      entry.toJson(),
      onConflict: 'salarie_id,date',
    );
  }

  /// Upserts multiple pointage entries in a single call.
  Future<void> upsertPointages(List<PointageEntree> entries) async {
    if (entries.isEmpty) return;
    await _client.from('pointages').upsert(
      entries.map((e) => e.toJson()).toList(),
      onConflict: 'salarie_id,date',
    );
  }

  /// Deletes pointages for a salarie within a date range.
  Future<void> deletePointagesInRange(
    String salarieId,
    DateTime start,
    DateTime end,
  ) async {
    final startStr = start.toIso8601String().split('T').first;
    final endStr = end.toIso8601String().split('T').first;

    await _client
        .from('pointages')
        .delete()
        .eq('salarie_id', salarieId)
        .gte('date', startStr)
        .lte('date', endStr);
  }
}
