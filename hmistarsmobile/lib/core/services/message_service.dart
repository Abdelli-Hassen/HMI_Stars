import 'dart:async';
import 'dart:io' as io;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

/// Gère les opérations de messagerie contre la table `messages`.
class MessageService {
  final SupabaseClient _client;

  MessageService(this._client);

  /// Récupère les messages d'une entreprise, avec pagination.
  Future<List<Message>> getMessages(String entrepriseId, {int? offset, int? limit}) async {
    var query = _client
        .from('messages')
        .select()
        .eq('entreprise_id', entrepriseId)
        .order('date_envoi', ascending: false);
    
    if (offset != null && limit != null) {
      query = query.range(offset, offset + limit - 1);
    } else if (limit != null) {
      query = query.limit(limit);
    }

    final data = await query;
    return (data as List).map((e) => Message.fromJson(e)).toList();
  }

  /// Insère un nouveau message et retourne la version avec ID/horodatage du serveur.
  Future<Message> sendMessage(Message message) async {
    final data = await _client
        .from('messages')
        .insert(message.toJson())
        .select()
        .single();
    return Message.fromJson(data);
  }

  String _sanitizeForStoragePath(String filename) {
    var result = filename
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[àâä]'), 'a')
        .replaceAll(RegExp(r'[ùûü]'), 'u')
        .replaceAll(RegExp(r'[îï]'), 'i')
        .replaceAll(RegExp(r'[ôö]'), 'o')
        .replaceAll(RegExp(r'[ç]'), 'c')
        .replaceAll(RegExp(r'[ÉÈÊË]'), 'E')
        .replaceAll(RegExp(r'[ÀÂÄ]'), 'A')
        .replaceAll(RegExp(r'[ÙÛÜ]'), 'U')
        .replaceAll(RegExp(r'[ÎÏ]'), 'I')
        .replaceAll(RegExp(r'[ÔÖ]'), 'O')
        .replaceAll(RegExp(r'[Ç]'), 'C');
    return result.replaceAll(RegExp(r'[^\x00-\x7F]'), '_');
  }

  /// Téléverse un fichier physique local sur Supabase Storage dans un dossier horodaté.
  Future<String> uploadFichier(String entrepriseId, String nomFichier, String localFilePath) async {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final nomSain = _sanitizeForStoragePath(nomFichier);
    final path = 'entreprises/$entrepriseId/$timestamp/$nomSain';
    final file = io.File(localFilePath);
    
    await _client.storage
        .from('documents')
        .upload(path, file);
        
    return _client.storage.from('documents').getPublicUrl(path);
  }

  /// Récupère le prochain numéro d'index de document pour une entreprise et un type de document donné.
  Future<int> getProchainNumeroFichier(String entrepriseId, String typeDocument) async {
    final typeDocLower = typeDocument.toLowerCase();
    
    final response = await _client
        .from('fichiers')
        .select('id')
        .eq('entreprise_id', entrepriseId)
        .eq('type_document', typeDocLower);
        
    final count = (response as List).length;
    return count + 1;
  }

  /// Enregistre le fichier dans la table 'fichiers'.
  Future<Map<String, dynamic>> enregistrerFichier({
    required String entrepriseId,
    required String nom,
    required String url,
    required bool estEnvoyeParUser,
    String? typeDocument,
  }) async {
    final data = await _client
        .from('fichiers')
        .insert({
          'entreprise_id': entrepriseId,
          'nom': nom,
          'url': url,
          'est_envoye_par_user': estEnvoyeParUser,
          'type_document': typeDocument?.toLowerCase(),
        })
        .select()
        .single();
    return data;
  }

  /// Ouvre un canal Supabase Realtime et appelle [onNouveauMessage]
  /// pour chaque message mis à jour ou nouveau dans la conversation.
  StreamSubscription<List<Map<String, dynamic>>> abonnerNouveauxMessages(
    String entrepriseId,
    void Function(Message message) onNouveauMessage, {
    void Function(Object error)? onError,
  }) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('entreprise_id', entrepriseId)
        .order('date_envoi')
        .listen(
      (rows) {
        for (final row in rows) {
          onNouveauMessage(Message.fromJson(row));
        }
      },
      onError: onError,
      cancelOnError: false,
    );
  }

  /// Marque tous les messages reçus de la plateforme comme lus pour l'entreprise.
  Future<void> marquerMessagesCommeLus(String entrepriseId) async {
    try {
      await _client
          .from('messages')
          .update({'est_lu': true})
          .eq('entreprise_id', entrepriseId)
          .eq('est_envoye_par_user', false)
          .eq('est_lu', false);
    } catch (_) {
      // Ignorer l'erreur silencieusement
    }
  }
}
