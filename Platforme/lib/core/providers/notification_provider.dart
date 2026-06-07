import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../features/entreprises/presentation/providers/entreprise_provider.dart';
import '../supabase_config.dart';

/// Représente un document de notification extrait des messages Supabase.
class NotificationDocument {
  final String id;
  final String entrepriseId;
  final String nomFichier;
  final String urlFichier;
  final String typeDocument;
  final DateTime dateEnvoi;
  final bool estLu;

  NotificationDocument({
    required this.id,
    required this.entrepriseId,
    required this.nomFichier,
    required this.urlFichier,
    required this.typeDocument,
    required this.dateEnvoi,
    required this.estLu,
  });

  /// Construit un objet à partir du JSON retourné par Supabase.
  factory NotificationDocument.fromJson(Map<String, dynamic> json) {
    final dateStr = json['date_envoi']?.toString() ?? DateTime.now().toIso8601String();
    DateTime parsedDate;
    try {
      parsedDate = dateStr.endsWith('Z') || dateStr.contains('+')
          ? DateTime.parse(dateStr)
          : DateTime.parse('${dateStr}Z');
    } catch (_) {
      parsedDate = DateTime.now();
    }

    return NotificationDocument(
      id: json['id']?.toString() ?? '',
      entrepriseId: json['entreprise_id']?.toString() ?? '',
      nomFichier: json['fichier_nom']?.toString() ?? 'Document',
      urlFichier: json['fichier_url']?.toString() ?? '',
      typeDocument: json['type_document']?.toString() ?? 'autre',
      dateEnvoi: parsedDate.toLocal(),
      estLu: json['est_lu'] as bool? ?? false,
    );
  }
}

/// Gère l'état global et l'écoute en temps réel des documents reçus des clients.
class NotificationProvider extends ChangeNotifier {
  final EntrepriseProvider entrepriseProvider;
  final clientSupabase = SupabaseConfig.adminClient;

  List<NotificationDocument> notifications = [];
  bool chargement = false;
  StreamSubscription<List<Map<String, dynamic>>>? abonnementTempsReel;
  bool _disposed = false;

  NotificationProvider(this.entrepriseProvider) {
    chargerNotifications();
    initialiserAbonnement();
  }

  @override
  void dispose() {
    _disposed = true;
    abonnementTempsReel?.cancel();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_disposed) {
      super.notifyListeners();
    }
  }

  /// Charge les 50 derniers documents reçus depuis Supabase.
  Future<void> chargerNotifications() async {
    chargement = true;
    notifyListeners();

    try {
      final reponse = await clientSupabase
          .from('messages')
          .select()
          .eq('est_fichier', true)
          .eq('est_envoye_par_user', true)
          .order('date_envoi', ascending: false)
          .limit(50);

      final liste = reponse as List;
      notifications = liste
          .map((item) => NotificationDocument.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[NotificationProvider] Erreur chargement initial : $e');
    }

    chargement = false;
    notifyListeners();
  }

  /// Initialise le flux en temps réel Supabase pour écouter les nouveaux messages.
  void initialiserAbonnement() {
    abonnementTempsReel?.cancel();
    abonnementTempsReel = clientSupabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('date_envoi')
        .listen((lignes) {
      if (lignes.isEmpty) return;

      bool changement = false;
      for (final ligne in lignes) {
        final estFichier = ligne['est_fichier'] as bool? ?? false;
        final estUser = ligne['est_envoye_par_user'] as bool? ?? true;

        if (estFichier && estUser) {
          final doc = NotificationDocument.fromJson(ligne);
          final index = notifications.indexWhere((n) => n.id == doc.id);

          if (index == -1) {
            // Ajouter en haut et maintenir la limite de 50
            notifications.insert(0, doc);
            if (notifications.length > 50) {
              notifications.removeLast();
            }
            changement = true;
          } else if (notifications[index].estLu != doc.estLu) {
            notifications[index] = doc;
            changement = true;
          }
        }
      }

      if (changement) {
        notifications.sort((a, b) => b.dateEnvoi.compareTo(a.dateEnvoi));
        notifyListeners();
      }
    }, onError: (error) {
      debugPrint('[NotificationProvider] Erreur de connexion temps réel (notifications) : $error. Reconnexion dans 5 secondes...');
      Future.delayed(const Duration(seconds: 5), () {
        initialiserAbonnement();
      });
    });
  }

  /// Marque un document comme lu dans Supabase et met à jour l'état local.
  Future<void> marquerCommeLu(String messageId) async {
    try {
      await clientSupabase
          .from('messages')
          .update({'est_lu': true})
          .eq('id', messageId);

      final index = notifications.indexWhere((n) => n.id == messageId);
      if (index != -1) {
        notifications[index] = NotificationDocument(
          id: notifications[index].id,
          entrepriseId: notifications[index].entrepriseId,
          nomFichier: notifications[index].nomFichier,
          urlFichier: notifications[index].urlFichier,
          typeDocument: notifications[index].typeDocument,
          dateEnvoi: notifications[index].dateEnvoi,
          estLu: true,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[NotificationProvider] Erreur marquage lu : $e');
    }
  }

  /// Marque tous les documents clients non lus comme lus.
  Future<void> marquerToutCommeLu() async {
    try {
      await clientSupabase
          .from('messages')
          .update({'est_lu': true})
          .eq('est_envoye_par_user', true)
          .eq('est_fichier', true)
          .eq('est_lu', false);

      notifications = notifications.map((n) {
        return NotificationDocument(
          id: n.id,
          entrepriseId: n.entrepriseId,
          nomFichier: n.nomFichier,
          urlFichier: n.urlFichier,
          typeDocument: n.typeDocument,
          dateEnvoi: n.dateEnvoi,
          estLu: true,
        );
      }).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('[NotificationProvider] Erreur marquage tout lu : $e');
    }
  }

  /// Retourne la liste des documents non lus.
  List<NotificationDocument> get documentsNonLus =>
      notifications.where((n) => !n.estLu).toList();

  /// Retourne la liste des documents urgents non lus (tout document non lu selon les réponses utilisateur).
  List<NotificationDocument> get documentsUrgentsNonLus =>
      notifications.where((n) => !n.estLu).toList();

  /// Retourne la liste des documents déjà traités (lus).
  List<NotificationDocument> get documentsTraites =>
      notifications.where((n) => n.estLu).toList();

  /// Résout le nom commercial de l'entreprise à partir de son ID.
  String obtenirNomEntreprise(String entrepriseId) {
    try {
      final entreprise = entrepriseProvider.entreprises.firstWhere(
        (e) => e.id == entrepriseId,
      );
      return entreprise.nom;
    } catch (_) {
      return 'Entreprise Client';
    }
  }
}
