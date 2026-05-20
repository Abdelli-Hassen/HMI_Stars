import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Service gérant les notifications push (FCM) avec une approche robuste 
/// (ne crashe pas si google-services.json est manquant).
class ServiceNotification {
  static final ServiceNotification _instance = ServiceNotification._interne();
  factory ServiceNotification() => _instance;
  ServiceNotification._interne();

  bool _estInitialise = false;
  String? _jetonFcm;
  List<String> _dernieresEntreprisesIds = [];

  /// Initialise Firebase et demande les permissions.
  Future<void> initialiser() async {
    if (_estInitialise) return;
    
    try {
      await Firebase.initializeApp();
      _estInitialise = true;
      debugPrint('[Notification] Firebase initialisé avec succès.');

      final messaging = FirebaseMessaging.instance;
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        debugPrint('[Notification] Permissions accordées.');
        
        _jetonFcm = await messaging.getToken();
        debugPrint('[Notification] Jeton FCM obtenu : $_jetonFcm');

        messaging.onTokenRefresh.listen((nouveauJeton) {
          _jetonFcm = nouveauJeton;
          if (_dernieresEntreprisesIds.isNotEmpty) {
            enregistrerJetonPourEntreprises(_dernieresEntreprisesIds);
          }
        });

      } else {
        debugPrint('[Notification] Permissions refusées.');
      }
    } catch (e) {
      // Attrapé si google-services.json est manquant
      debugPrint('[Notification] Firebase non configuré (google-services.json manquant).');
      _estInitialise = false;
    }
  }

  /// Sauvegarde le jeton FCM de l'entreprise connectée dans Supabase
  Future<void> enregistrerJetonPourEntreprises(List<String> entreprisesIds) async {
    if (!_estInitialise || _jetonFcm == null || entreprisesIds.isEmpty) return;
    _dernieresEntreprisesIds = entreprisesIds;

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
}
