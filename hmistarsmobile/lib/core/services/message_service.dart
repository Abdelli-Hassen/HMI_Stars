import 'dart:async';
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

  /// Ouvre un canal Supabase Realtime et appelle [onNouveauMessage]
  /// à chaque nouveau message reçu de la plateforme (est_envoye_par_user = false).
  StreamSubscription<List<Map<String, dynamic>>> abonnerNouveauxMessages(
    String entrepriseId,
    void Function(Message message) onNouveauMessage,
  ) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('entreprise_id', entrepriseId)
        .order('date_envoi')
        .listen((rows) {
      // Le stream retourne TOUS les messages à chaque changement.
      // On ne traite que les messages entrants de la plateforme
      // (est_envoye_par_user = false) pour les pousser dans l'état.
      // L'AppState se charge de la déduplication par ID.
      for (final row in rows) {
        if (row['est_envoye_par_user'] == false) {
          onNouveauMessage(Message.fromJson(row));
        }
      }
    });
  }
}
