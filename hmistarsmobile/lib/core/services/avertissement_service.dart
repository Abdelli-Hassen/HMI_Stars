import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

/// Handles CRUD for the `modeles_avertissements` table.
class AvertissementService {
  final SupabaseClient _client;

  AvertissementService(this._client);

  /// Fetches global templates (entreprise_id IS NULL) plus
  /// templates belonging to the given enterprise.
  Future<List<TemplateAvertissement>> getTemplates(
      String entrepriseId) async {
    // Supabase doesn't support OR filters natively in the simple API,
    // so we use two queries and merge them.
    final globalData = await _client
        .from('modeles_avertissements')
        .select()
        .isFilter('entreprise_id', null);

    final enterpriseData = await _client
        .from('modeles_avertissements')
        .select()
        .eq('entreprise_id', entrepriseId);

    final combined = [
      ...(globalData as List),
      ...(enterpriseData as List),
    ];
    return combined.map((e) => TemplateAvertissement.fromJson(e)).toList();
  }

  /// Inserts a new avertissement template for the given enterprise.
  Future<TemplateAvertissement> addTemplate(
      TemplateAvertissement template) async {
    final data = await _client
        .from('modeles_avertissements')
        .insert(template.toJson())
        .select()
        .single();
    return TemplateAvertissement.fromJson(data);
  }

  /// Updates the content of an existing template.
  Future<void> updateTemplate(String id, String newContenu) async {
    await _client
        .from('modeles_avertissements')
        .update({'contenu': newContenu})
        .eq('id', id);
  }

  /// Deletes a template by ID.
  Future<void> deleteTemplate(String id) async {
    await _client.from('modeles_avertissements').delete().eq('id', id);
  }
}
