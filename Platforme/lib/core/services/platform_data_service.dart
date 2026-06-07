import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../supabase_config.dart';
import '../../features/entreprises/domain/models/entreprise.dart';
import '../../features/entreprises/domain/models/salarie.dart';
import '../../features/entreprises/domain/models/document_entreprise.dart';
import '../../features/entreprises/domain/models/note_entreprise.dart';
import '../../features/entreprises/domain/models/template_avertissement.dart';
import '../../features/urgents/domain/models/tache_urgente.dart';
import '../../features/auth/domain/models/platform_user.dart';

/// Service de données Supabase pour la plateforme admin.
/// Utilise adminClient (clé service_role) pour contourner les politiques RLS.
class PlatformDataService {
  final _client = SupabaseConfig.adminClient;

  // ─── UTILISATEURS PLATEFORME ───────────────────────────────────────────────

  Future<UtilisateurPlateforme?> recupererUtilisateur(String userId) async {
    try {
      final data = await _client
          .from('utilisateurs_plateforme')
          .select()
          .eq('id', userId)
          .maybeSingle();
      if (data == null) return null;
      return UtilisateurPlateforme.fromJson(data);
    } catch (e) {
      debugPrint('[DataService] Error fetching user: $e');
      return null;
    }
  }

  Future<UtilisateurPlateforme> mettreAJourUtilisateur(UtilisateurPlateforme user) async {
    final data = await _client
        .from('utilisateurs_plateforme')
        .update(user.toJson())
        .eq('id', user.id)
        .select()
        .single();
    return UtilisateurPlateforme.fromJson(data);
  }

  Future<List<UtilisateurPlateforme>> recupererTousUtilisateurs() async {
    final data = await _client
        .from('utilisateurs_plateforme')
        .select()
        .order('cree_le', ascending: true);
    return (data as List)
        .map((row) => UtilisateurPlateforme.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> supprimerUtilisateurAuth(String uid) async {
    try {
      await _client.auth.admin.deleteUser(uid);
    } catch (e) {
      debugPrint('[DataService] Error deleting user: $e');
      rethrow;
    }
  }

  // ─── ENTREPRISES ──────────────────────────────────────────────────────────

  Future<List<Entreprise>> fetchEntreprises() async {
    final data = await _client
        .from('entreprises')
        .select()
        .order('cree_le', ascending: false);
    return (data as List)
        .map((row) => Entreprise.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<Entreprise> createEntreprise(Entreprise entreprise) async {
    // 1. Créer ou réutiliser l'utilisateur Supabase Auth
    // Si l'email existe déjà, on réutilise le compte (un gérant peut avoir plusieurs entreprises)
    if (entreprise.email.isNotEmpty && entreprise.motDePasse.isNotEmpty) {
      try {
        await SupabaseConfig.adminClient.auth.admin.createUser(
          AdminUserAttributes(
            email: entreprise.email,
            password: entreprise.motDePasse,
            emailConfirm: true,
            userMetadata: {'user_type': 'client'},
          ),
        );
        debugPrint('[DataService] Auth user created for ${entreprise.email}');
      } catch (e) {
        final msg = e.toString();
        if (msg.contains('email_exists') || msg.contains('already been registered')) {
          // L'email existe déjà dans Auth — pas de problème,
          // l'entreprise sera quand même créée avec son propre UUID.
          debugPrint('[DataService] Auth user already exists for ${entreprise.email} — continuing');
        } else {
          // Erreur inattendue — on logue mais on ne bloque pas la création
          debugPrint('[DataService] Auth user creation failed: $e');
        }
      }
    }

    // 2. Insérer l'entreprise — l'id UUID est généré automatiquement par Supabase
    final data = await _client
        .from('entreprises')
        .insert(entreprise.toJson())
        .select()
        .single();
    return Entreprise.fromJson(data);
  }

  Future<Entreprise> updateEntreprise(Entreprise entreprise) async {
    // 1. Récupérer l'ancien email de l'entreprise avant la mise à jour
    String? oldEmail;
    try {
      final existing = await _client
          .from('entreprises')
          .select('email')
          .eq('id', entreprise.id)
          .maybeSingle();
      if (existing != null) {
        oldEmail = existing['email'] as String?;
      }
    } catch (e) {
      debugPrint('[DataService] Error fetching old email before update: $e');
    }

    // 2. Mettre à jour l'utilisateur dans Supabase Auth si le mot de passe est modifié
    // ou si l'email a changé.
    if (entreprise.motDePasse.isNotEmpty ||
        (oldEmail != null && oldEmail.toLowerCase() != entreprise.email.toLowerCase())) {
      try {
        final users = await _client.auth.admin.listUsers();
        final emailToFind = oldEmail ?? entreprise.email;
        
        final user = users.firstWhere(
          (u) => u.email?.toLowerCase() == emailToFind.toLowerCase(),
          orElse: () => users.firstWhere(
            (u) => u.email?.toLowerCase() == entreprise.email.toLowerCase(),
          ),
        );

        final attributes = AdminUserAttributes(
          password: entreprise.motDePasse.isNotEmpty ? entreprise.motDePasse : null,
          email: (oldEmail != null && oldEmail.toLowerCase() != entreprise.email.toLowerCase())
              ? entreprise.email
              : null,
        );

        await _client.auth.admin.updateUserById(
          user.id,
          attributes: attributes,
        );
        debugPrint('[DataService] Auth user updated successfully for ${entreprise.email}');
      } catch (e) {
        debugPrint('[DataService] Failed to update auth credentials: $e');
        // Fallback : Si l'utilisateur n'existe pas encore dans Auth, on le crée
        if (entreprise.motDePasse.isNotEmpty) {
          try {
            await _client.auth.admin.createUser(
              AdminUserAttributes(
                email: entreprise.email,
                password: entreprise.motDePasse,
                emailConfirm: true,
                userMetadata: {'user_type': 'client'},
              ),
            );
            debugPrint('[DataService] Fallback: Auth user created for ${entreprise.email}');
          } catch (err) {
            debugPrint('[DataService] Fallback: Failed to create Auth user: $err');
          }
        }
      }
    }

    // 3. Mettre à jour l'entreprise dans la table 'entreprises'
    final data = await _client
        .from('entreprises')
        .update(entreprise.toJson())
        .eq('id', entreprise.id)
        .select()
        .single();
    return Entreprise.fromJson(data);
  }

  Future<void> archiveEntreprise(String id) async {
    await _client
        .from('entreprises')
        .update({'statut': 'ARCHIVÉ'})
        .eq('id', id);
  }

  // ─── SALARIÉS ─────────────────────────────────────────────────────────────

  Future<List<Salarie>> fetchSalariesForEntreprise(
      String entrepriseId) async {
    final data = await _client
        .from('salaries')
        .select()
        .eq('entreprise_id', entrepriseId)
        .order('nom', ascending: true);
    return (data as List)
        .map((row) => Salarie.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<Salarie> createSalarie(Salarie salarie) async {
    final data = await _client
        .from('salaries')
        .insert(salarie.toJson())
        .select()
        .single();
    return Salarie.fromJson(data);
  }

  Future<Salarie> updateSalarie(Salarie salarie) async {
    final data = await _client
        .from('salaries')
        .update(salarie.toJson())
        .eq('id', salarie.id)
        .select()
        .single();
    return Salarie.fromJson(data);
  }

  Future<void> archiveSalarie(String id) async {
    await _client
        .from('salaries')
        .update({'est_archive': true})
        .eq('id', id);
  }

  Future<void> unarchiveSalarie(String id) async {
    await _client
        .from('salaries')
        .update({'est_archive': false})
        .eq('id', id);
  }

  Future<void> deleteSalarie(String id) async {
    await _client.from('salaries').delete().eq('id', id);
  }

  // ─── DOCUMENTS ────────────────────────────────────────────────────────────

  /// Les documents sont stockés comme messages de type fichier ou enregistrés dans la table fichiers.
  Future<List<DocumentEntreprise>> fetchDocumentsForEntreprise(
      String entrepriseId) async {
    final data = await _client
        .from('entreprise_documents_view')
        .select()
        .eq('entreprise_id', entrepriseId)
        .order('cree_le', ascending: false);
    return (data as List)
        .map((row) =>
            DocumentEntreprise.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<DocumentEntreprise>> fetchAllDocuments() async {
    final data = await _client
        .from('entreprise_documents_view')
        .select()
        .order('cree_le', ascending: false);
    return (data as List)
        .map((row) =>
            DocumentEntreprise.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<DocumentEntreprise>> fetchDocumentsForEntreprisePaginated(
      String entrepriseId, int offset, int limit) async {
    final data = await _client
        .from('entreprise_documents_view')
        .select()
        .eq('entreprise_id', entrepriseId)
        .order('cree_le', ascending: false)
        .range(offset, offset + limit - 1);
    return (data as List)
        .map((row) =>
            DocumentEntreprise.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<void> deleteDocument(String id, {String? url}) async {
    final List<Future> deletes = [
      _client.from('messages').delete().eq('id', id),
      _client.from('fichiers').delete().eq('id', id),
    ];
    if (url != null && url.isNotEmpty) {
      deletes.add(_client.from('messages').delete().eq('fichier_url', url));
      deletes.add(_client.from('fichiers').delete().eq('url', url));
    }
    await Future.wait(deletes);
  }

  // ─── NOTES / RAPPELS ─────────────────────────────────────────────────────

  Future<List<NoteEntreprise>> fetchNotesForEntreprise(
      String entrepriseId) async {
    final data = await _client
        .from('notes_entreprises')
        .select()
        .eq('entreprise_id', entrepriseId)
        .order('cree_le', ascending: false);
    return (data as List)
        .map((row) => NoteEntreprise.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<NoteEntreprise> createNote(NoteEntreprise note) async {
    final data = await _client
        .from('notes_entreprises')
        .insert(note.toJson())
        .select()
        .single();
    return NoteEntreprise.fromJson(data);
  }

  Future<NoteEntreprise> updateNote(NoteEntreprise note) async {
    final data = await _client
        .from('notes_entreprises')
        .update(note.toJson())
        .eq('id', note.id)
        .select()
        .single();
    return NoteEntreprise.fromJson(data);
  }

  Future<void> deleteNote(String id) async {
    await _client.from('notes_entreprises').delete().eq('id', id);
  }

  /// Récupérer toutes les notes de toutes les entreprises (page globale).
  Future<List<NoteEntreprise>> fetchAllNotes() async {
    final data = await _client
        .from('notes_entreprises')
        .select()
        .order('cree_le', ascending: false);
    return (data as List)
        .map((row) => NoteEntreprise.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  // ─── TÂCHES URGENTES ──────────────────────────────────────────────────────

  Future<List<TacheUrgente>> fetchTachesUrgentes() async {
    final data = await _client
        .from('taches_urgentes')
        .select()
        .order('date_echeance', ascending: true);
    return (data as List)
        .map((row) => TacheUrgente.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<TacheUrgente>> fetchTachesForEntreprise(
      String entrepriseId) async {
    final data = await _client
        .from('taches_urgentes')
        .select()
        .eq('entreprise_id', entrepriseId)
        .order('date_echeance', ascending: true);
    return (data as List)
        .map((row) => TacheUrgente.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<TacheUrgente> createTacheUrgente(TacheUrgente tache) async {
    final data = await _client
        .from('taches_urgentes')
        .insert(tache.toJson())
        .select()
        .single();
    return TacheUrgente.fromJson(data);
  }

  Future<TacheUrgente> updateTacheUrgente(TacheUrgente tache) async {
    final data = await _client
        .from('taches_urgentes')
        .update(tache.toJson())
        .eq('id', tache.id)
        .select()
        .single();
    return TacheUrgente.fromJson(data);
  }

  Future<void> basculerTacheAccomplie(String id, bool accomplie) async {
    await _client
        .from('taches_urgentes')
        .update({'accomplie': accomplie})
        .eq('id', id);
  }

  Future<void> supprimerTacheUrgente(String id) async {
    await _client.from('taches_urgentes').delete().eq('id', id);
  }

  // ─── MODÈLES D'AVERTISSEMENTS ────────────────────────────────────────────

  Future<List<ModeleAvertissement>> fetchModeles() async {
    final data = await _client
        .from('modeles_avertissements')
        .select()
        .order('cree_le', ascending: false);
    return (data as List)
        .map((row) =>
            ModeleAvertissement.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<List<ModeleAvertissement>> fetchModelesForEntreprise(
      String entrepriseId) async {
    final data = await _client
        .from('modeles_avertissements')
        .select()
        .or('entreprise_id.is.null,entreprise_id.eq.$entrepriseId')
        .order('cree_le', ascending: false);
    return (data as List)
        .map((row) =>
            ModeleAvertissement.fromJson(row as Map<String, dynamic>))
        .toList();
  }

  Future<ModeleAvertissement> createModele(
      ModeleAvertissement modele) async {
    final data = await _client
        .from('modeles_avertissements')
        .insert(modele.toJson())
        .select()
        .single();
    return ModeleAvertissement.fromJson(data);
  }

  Future<ModeleAvertissement> updateModele(
      ModeleAvertissement modele) async {
    final data = await _client
        .from('modeles_avertissements')
        .update(modele.toJson())
        .eq('id', modele.id)
        .select()
        .single();
    return ModeleAvertissement.fromJson(data);
  }

  Future<void> supprimerModele(String id) async {
    await _client.from('modeles_avertissements').delete().eq('id', id);
  }

  // ─── MESSAGERIE ────────────────────────────────────────────────────────────

  /// Récupère les messages d'une conversation entreprise, avec pagination.
  Future<List<Map<String, dynamic>>> fetchMessagesForEntreprise(
      String entrepriseId, {int? offset, int? limit}) async {
    var query = _client
        .from('messages')
        .select('*, est_lu')
        .eq('entreprise_id', entrepriseId)
        .order('date_envoi', ascending: false);

    if (offset != null && limit != null) {
      query = query.range(offset, offset + limit - 1);
    } else if (limit != null) {
      query = query.limit(limit);
    }

    final data = await query;
    return List<Map<String, dynamic>>.from(data as List);
  }

  /// Marque tous les messages d'une entreprise comme lus.
  Future<void> marquerMessagesCommeLus(String entrepriseId) async {
    await _client
        .from('messages')
        .update({'est_lu': true})
        .eq('entreprise_id', entrepriseId)
        .eq('est_envoye_par_user', true)
        .eq('est_lu', false);
  }

  /// Envoie un message depuis la plateforme (est_envoye_par_user = false).
  Future<Map<String, dynamic>> envoyerMessagePlateforme({
    required String entrepriseId,
    required String contenu,
  }) async {
    final data = await _client
        .from('messages')
        .insert({
          'entreprise_id': entrepriseId,
          'contenu': contenu,
          'est_envoye_par_user': false,
          'est_fichier': false,
        })
        .select()
        .single();
    return Map<String, dynamic>.from(data as Map);
  }

  /// Envoie un message de type fichier depuis la plateforme (est_envoye_par_user = false).
  Future<Map<String, dynamic>> envoyerMessagePlateformeFichier({
    required String entrepriseId,
    required String contenu,
    required String fichierUrl,
    required String fichierNom,
    String? typeDocument,
  }) async {
    final data = await _client
        .from('messages')
        .insert({
          'entreprise_id': entrepriseId,
          'contenu': contenu,
          'est_envoye_par_user': false,
          'est_fichier': true,
          'fichier_url': fichierUrl,
          'fichier_nom': fichierNom,
          'type_document': typeDocument,
        })
        .select()
        .single();
    return Map<String, dynamic>.from(data as Map);
  }

  /// Récupère le dernier message + nombre de messages non lus pour chaque entreprise.
  /// Utilisé pour peupler la barre latérale de la messagerie.
  Future<Map<String, Map<String, dynamic>>> fetchApercuMessages({String? myUid}) async {
    final data = await _client
        .from('messages')
        .select('entreprise_id, contenu, date_envoi, est_envoye_par_user, est_lu, est_fichier, fichier_nom')
        .order('date_envoi', ascending: false);

    final List<Map<String, dynamic>> rows = List<Map<String, dynamic>>.from(data as List);
    
    // Tri manuel de sécurité en Dart pour s'assurer du DESC
    rows.sort((a, b) {
      final dateA = DateTime.tryParse(a['date_envoi']?.toString() ?? '') ?? DateTime(0);
      final dateB = DateTime.tryParse(b['date_envoi']?.toString() ?? '') ?? DateTime(0);
      return dateB.compareTo(dateA);
    });

    final Map<String, Map<String, dynamic>> apercu = {};
    for (final row in rows) {
      final rawContenu = row['contenu'] as String? ?? '';
      final match = RegExp(r'<!--contact:([a-zA-Z0-9\-]+)-->').firstMatch(rawContenu);
      final contactId = match?.group(1);
      final cleanContenu = rawContenu.replaceAll(RegExp(r'<!--contact:[a-zA-Z0-9\-]+-->'), '');

      if (myUid != null && contactId != null && contactId != myUid) {
        continue; // Skip messages for other contacts
      }

      final eid = row['entreprise_id'] as String;
      final estDeUser = row['est_envoye_par_user'] as bool;
      final estLu = row['est_lu'] as bool? ?? false;

      if (!apercu.containsKey(eid)) {
        String content = cleanContenu;
        final estFichier = row['est_fichier'] as bool? ?? false;
        final fichierNom = row['fichier_nom'] as String?;
        if (estFichier && content.trim().isEmpty) {
          content = fichierNom ?? "Pièce jointe";
        }

        apercu[eid] = {
          'dernier_message': content,
          'date_envoi': row['date_envoi'] as String,
          'est_envoye_par_user': estDeUser,
          'a_des_non_lus': false, // Initialisation
        };
      }
      
      // Si un message du client n'est pas lu, on marque la conversation comme "non lue"
      if (estDeUser && !estLu) {
        apercu[eid]!['a_des_non_lus'] = true;
      }
    }
    return apercu;
  }

  /// Enregistre un fichier partagé dans la table fichiers.
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
    return Map<String, dynamic>.from(data as Map);
  }
  /// Upload un avatar utilisateur dans Supabase Storage et met à jour le profil.
  Future<String?> uploadAvatar(String userId, Uint8List fileBytes, String fileName) async {
    try {
      final ext = fileName.split('.').last.toLowerCase();
      final storagePath = 'avatars/$userId.$ext';

      // Upload vers le bucket 'avatars'
      await _client.storage.from('avatars').uploadBinary(
        storagePath,
        fileBytes,
        fileOptions: FileOptions(upsert: true, contentType: 'image/$ext'),
      );

      // Récupérer l'URL publique avec cache-busting
      final baseUrl = _client.storage.from('avatars').getPublicUrl(storagePath);
      final publicUrl = '$baseUrl?t=${DateTime.now().millisecondsSinceEpoch}';

      // Mettre à jour le profil utilisateur
      await _client
          .from('utilisateurs_plateforme')
          .update({'avatar_url': publicUrl})
          .eq('id', userId);

      return publicUrl;
    } catch (e) {
      debugPrint('[DataService] Error uploading avatar: $e');
      return null;
    }
  }

  /// Upload un avatar de salarié dans Supabase Storage et met à jour son profil.
  Future<String?> uploadSalarieAvatar(String salarieId, Uint8List fileBytes, String fileName) async {
    try {
      final ext = fileName.split('.').last.toLowerCase();
      final storagePath = 'avatars/$salarieId.$ext';

      // Upload vers le bucket 'avatars'
      await _client.storage.from('avatars').uploadBinary(
        storagePath,
        fileBytes,
        fileOptions: FileOptions(upsert: true, contentType: 'image/$ext'),
      );

      // Récupérer l'URL publique avec cache-busting
      final baseUrl = _client.storage.from('avatars').getPublicUrl(storagePath);
      final publicUrl = '$baseUrl?t=${DateTime.now().millisecondsSinceEpoch}';

      // Mettre à jour le salarié
      await _client
          .from('salaries')
          .update({'avatar_url': publicUrl})
          .eq('id', salarieId);

      return publicUrl;
    } catch (e) {
      debugPrint('[DataService] Error uploading salarie avatar: $e');
      return null;
    }
  }

  /// Upload un logo d'entreprise dans Supabase Storage et met à jour l'entreprise.
  Future<String?> uploadEntrepriseLogo(String entrepriseId, Uint8List fileBytes, String fileName) async {
    try {
      final ext = fileName.split('.').last.toLowerCase();
      final storagePath = 'logos/$entrepriseId.$ext';

      // Upload vers le bucket 'avatars' (qui est public)
      await _client.storage.from('avatars').uploadBinary(
        storagePath,
        fileBytes,
        fileOptions: FileOptions(upsert: true, contentType: 'image/$ext'),
      );

      // Récupérer l'URL publique avec cache-busting
      final baseUrl = _client.storage.from('avatars').getPublicUrl(storagePath);
      final publicUrl = '$baseUrl?t=${DateTime.now().millisecondsSinceEpoch}';

      // Mettre à jour l'entreprise
      await _client
          .from('entreprises')
          .update({'logo_url': publicUrl})
          .eq('id', entrepriseId);

      return publicUrl;
    } catch (e) {
      debugPrint('[DataService] Error uploading logo: $e');
      return null;
    }
  }

  /// Récupère les pointages d'un salarié pour un mois et une année donnés.
  Future<List<Map<String, dynamic>>> fetchPointagesForSalarieAndMonth(
      String salarieId, int year, int month) async {
    final firstDay = '$year-${month.toString().padLeft(2, '0')}-01';
    final nextMonth = month == 12 ? 1 : month + 1;
    final nextYear = month == 12 ? year + 1 : year;
    final lastDay = '$nextYear-${nextMonth.toString().padLeft(2, '0')}-01';

    try {
      final data = await _client
          .from('pointages')
          .select()
          .eq('salarie_id', salarieId)
          .gte('date', firstDay)
          .lt('date', lastDay)
          .order('date', ascending: true);
      return List<Map<String, dynamic>>.from(data as List);
    } catch (e) {
      debugPrint('[DataService] Error fetching pointages: $e');
      return [];
    }
  }
}
