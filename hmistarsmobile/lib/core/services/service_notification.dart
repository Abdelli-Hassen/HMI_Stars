import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:path_provider/path_provider.dart';
import '../../features/router/app_router.dart';

/// Service gérant les notifications push (FCM) avec une approche robuste 
/// (ne crashe pas si google-services.json est manquant).
class ServiceNotification {
  static final ServiceNotification _instance = ServiceNotification._interne();
  factory ServiceNotification() => _instance;
  ServiceNotification._interne();

  bool _estInitialise = false;
  String? _jetonFcm;
  List<String> _dernieresEntreprisesIds = [];

  String? get jetonFcm => _jetonFcm;
  bool get estInitialise => _estInitialise;

  /// Vérifie si c'est le premier lancement de l'application depuis son installation
  Future<bool> _estPremierLancementApresInstallation() async {
    try {
      final dossier = await getApplicationDocumentsDirectory();
      final fichier = File('${dossier.path}/.fcm_initialise_v1');
      if (await fichier.exists()) {
        return false;
      }
      await fichier.create(recursive: true);
      return true;
    } catch (e) {
      debugPrint('[Notification] Erreur lors de la détection du premier lancement : $e');
      return true; // En cas d'erreur, on suppose que c'est le premier lancement par sécurité
    }
  }

  /// Initialise Firebase et demande les permissions.
  Future<void> initialiser() async {
    if (_estInitialise) return;
    
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      _estInitialise = true;
      debugPrint('[Notification] Firebase initialisé avec succès.');

      final messaging = FirebaseMessaging.instance;
      
      // Demander les permissions de notification
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      
      debugPrint('[Notification] Statut d\'autorisation des permissions : ${settings.authorizationStatus}');

      // Supprimer le jeton obsolète lors du tout premier lancement après installation pour éviter les jetons invalides d'Auto Backup
      if (await _estPremierLancementApresInstallation()) {
        debugPrint('[Notification] Premier lancement détecté. Nettoyage du jeton FCM potentiellement obsolète...');
        try {
          await messaging.deleteToken();
        } catch (e) {
          debugPrint('[Notification] Impossible de supprimer le jeton obsolète : $e');
        }
      }

      // Toujours tenter d'obtenir le jeton FCM, car cela ne dépend pas de l'autorisation de notification
      try {
        _jetonFcm = await messaging.getToken();
        debugPrint('[Notification] Jeton FCM obtenu : $_jetonFcm');
        if (_jetonFcm != null && _dernieresEntreprisesIds.isNotEmpty) {
          enregistrerJetonPourEntreprises(_dernieresEntreprisesIds);
        }
      } catch (e) {
        debugPrint('[Notification] Erreur lors de l\'obtention du jeton FCM : $e');
      }

      // Écouter les rafraîchissements du jeton
      messaging.onTokenRefresh.listen((nouveauJeton) {
        _jetonFcm = nouveauJeton;
        debugPrint('[Notification] Jeton FCM rafraîchi : $_jetonFcm');
        if (_dernieresEntreprisesIds.isNotEmpty) {
          enregistrerJetonPourEntreprises(_dernieresEntreprisesIds);
        }
      });

      // Écouter les messages au premier plan
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[Notification] Message reçu au premier plan : ${message.messageId}');
        _afficherNotificationEnPremierPlan(message);
      });
    } catch (e) {
      // Attrapé si google-services.json est manquant
      debugPrint('[Notification] Firebase non configuré (google-services.json manquant) ou erreur : $e');
      _estInitialise = false;
    }
  }

  /// Sauvegarde le jeton FCM de l'entreprise connectée dans Supabase
  Future<void> enregistrerJetonPourEntreprises(List<String> entreprisesIds) async {
    if (entreprisesIds.isEmpty) return;
    _dernieresEntreprisesIds = entreprisesIds;

    if (!_estInitialise) {
      debugPrint('[Notification] Enregistrement différé (non initialisé).');
      return;
    }

    // Récupérer le jeton à la volée si nécessaire
    if (_jetonFcm == null) {
      debugPrint('[Notification] Jeton FCM manquant lors de l\'enregistrement, tentative de récupération...');
      try {
        _jetonFcm = await FirebaseMessaging.instance.getToken();
        debugPrint('[Notification] Jeton récupéré à la volée : $_jetonFcm');
      } catch (e) {
        debugPrint('[Notification] Échec de la récupération du jeton à la volée : $e');
      }
    }

    if (_jetonFcm == null) {
      debugPrint('[Notification] Enregistrement abandonné : jeton FCM toujours null.');
      return;
    }

    try {
      final supabase = Supabase.instance.client;
      for (final id in entreprisesIds) {
        await supabase
            .from('entreprises')
            .update({'jeton_notification': _jetonFcm})
            .eq('id', id);
      }
      debugPrint('[Notification] Jeton sauvegardé dans Supabase pour ${entreprisesIds.length} entreprises.');
    } catch (e) {
      debugPrint('[Notification] Erreur lors de la sauvegarde du jeton : $e');
    }
  }

  /// Obtient le jeton FCM actuel et le sauvegarde dans Supabase pour les entreprises spécifiées.
  Future<void> synchroniserJeton(List<String> entreprisesIds) async {
    if (!_estInitialise) {
      await initialiser();
    }
    
    final messaging = FirebaseMessaging.instance;
    try {
      _jetonFcm = await messaging.getToken();
      debugPrint('[Notification] Jeton FCM obtenu pour synchronisation : $_jetonFcm');
      if (_jetonFcm != null && entreprisesIds.isNotEmpty) {
        await enregistrerJetonPourEntreprises(entreprisesIds);
      }
    } catch (e) {
      debugPrint('[Notification] Erreur lors de la synchronisation du jeton : $e');
      rethrow;
    }
  }

  /// Supprime le jeton actuel et force la génération d'un nouveau jeton FCM, puis le sauvegarde.
  Future<void> forcerNouveauJeton(List<String> entreprisesIds) async {
    if (!_estInitialise) {
      await initialiser();
    }

    final messaging = FirebaseMessaging.instance;
    try {
      await messaging.deleteToken();
      _jetonFcm = await messaging.getToken();
      debugPrint('[Notification] Nouveau jeton FCM obtenu après forçage : $_jetonFcm');
      if (_jetonFcm != null && entreprisesIds.isNotEmpty) {
        await enregistrerJetonPourEntreprises(entreprisesIds);
      }
    } catch (e) {
      debugPrint('[Notification] Erreur lors du forçage du nouveau jeton : $e');
      rethrow;
    }
  }

  /// Affiche un toast personnalisé haut de gamme lorsque l'application est au premier plan
  void _afficherNotificationEnPremierPlan(RemoteMessage message) {
    final title = message.notification?.title ?? 'Notification';
    final body = message.notification?.body ?? '';
    
    final context = rootNavigatorKey.currentContext;
    if (context == null) return;

    final overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) {
        return Positioned(
          top: MediaQuery.of(context).padding.top + 12,
          left: 16,
          right: 16,
          child: SafeArea(
            top: false,
            child: Material(
              color: Colors.transparent,
              child: _InAppNotificationBanner(
                title: title,
                body: body,
                onDismiss: () {
                  if (overlayEntry.mounted) {
                    overlayEntry.remove();
                  }
                },
                onTap: () {
                  if (overlayEntry.mounted) {
                    overlayEntry.remove();
                  }
                  // Rediriger vers la messagerie
                  rootNavigatorKey.currentState?.context.go('/messagerie');
                },
              ),
            ),
          ),
        );
      },
    );

    overlayState.insert(overlayEntry);

    // Supprimer automatiquement après 4 secondes
    Timer(const Duration(seconds: 4), () {
      if (overlayEntry.mounted) {
        overlayEntry.remove();
      }
    });
  }
}

/// Widget d'affichage haut de gamme de la notification en premier plan
class _InAppNotificationBanner extends StatelessWidget {
  final String title;
  final String body;
  final VoidCallback onDismiss;
  final VoidCallback onTap;

  const _InAppNotificationBanner({
    required this.title,
    required this.body,
    required this.onDismiss,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Dismissible(
      key: UniqueKey(),
      direction: DismissDirection.horizontal,
      onDismissed: (_) => onDismiss(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F242C) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: isDark ? const Color(0xFF323537) : const Color(0xFFEDEEEF),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Icon with gold accent background
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE08B).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_active_outlined,
                  color: Color(0xFFEAC249),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              
              // Text Content
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF001E40),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      body,
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFFC5CBD3) : const Color(0xFF4C616C),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Close Button
              IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  color: isDark ? const Color(0xFF8D95A1) : const Color(0xFF737780),
                  size: 18,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: onDismiss,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
