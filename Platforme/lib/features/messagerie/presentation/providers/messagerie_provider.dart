import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/services/platform_data_service.dart';
import '../../../../core/supabase_config.dart';
import '../../../entreprises/domain/models/entreprise.dart';

/// Un message de la messagerie plateforme.
class MessagePlateforme {
  final String id;
  final String entrepriseId;
  final String contenu;
  final DateTime dateEnvoi;
  final bool estEnvoyeParUser; // true = mobile, false = plateforme
  final bool estFichier;
  final String? fichierUrl;
  final String? fichierNom;
  final bool estLu;

  const MessagePlateforme({
    required this.id,
    required this.entrepriseId,
    required this.contenu,
    required this.dateEnvoi,
    required this.estEnvoyeParUser,
    this.estFichier = false,
    this.fichierUrl,
    this.fichierNom,
    this.estLu = false,
  });

  factory MessagePlateforme.fromJson(Map<String, dynamic> json) {
    final dateStr = json['date_envoi']?.toString() ?? DateTime.now().toIso8601String();
    
    DateTime parsedDate;
    try {
      parsedDate = dateStr.endsWith('Z') || dateStr.contains('+')
          ? DateTime.parse(dateStr)
          : DateTime.parse('${dateStr}Z');
    } catch (e) {
      debugPrint('[MessagePlateforme] Error parsing date: $dateStr - $e');
      parsedDate = DateTime.now();
    }
        
    return MessagePlateforme(
      id: json['id']?.toString() ?? 'unknown',
      entrepriseId: json['entreprise_id']?.toString() ?? '',
      contenu: json['contenu']?.toString() ?? '',
      dateEnvoi: parsedDate.toLocal(),
      estEnvoyeParUser: json['est_envoye_par_user'] as bool? ?? true,
      estFichier: json['est_fichier'] as bool? ?? false,
      fichierUrl: json['fichier_url'] as String?,
      fichierNom: json['fichier_nom'] as String?,
      estLu: json['est_lu'] as bool? ?? false,
    );
  }
}

/// Resume d'une conversation pour la barre laterale.
class ApercuConversation {
  final Entreprise entreprise;
  final String? dernierMessage;
  final DateTime? dateEnvoi;
  final bool estEnvoyeParUser;
  final bool aDesMessagesNonLus;

  const ApercuConversation({
    required this.entreprise,
    this.dernierMessage,
    this.dateEnvoi,
    this.estEnvoyeParUser = true,
    this.aDesMessagesNonLus = false,
  });

  ApercuConversation copyWith({
    String? dernierMessage,
    DateTime? dateEnvoi,
    bool? estEnvoyeParUser,
    bool? aDesMessagesNonLus,
  }) {
    return ApercuConversation(
      entreprise: entreprise,
      dernierMessage: dernierMessage ?? this.dernierMessage,
      dateEnvoi: dateEnvoi ?? this.dateEnvoi,
      estEnvoyeParUser: estEnvoyeParUser ?? this.estEnvoyeParUser,
      aDesMessagesNonLus: aDesMessagesNonLus ?? this.aDesMessagesNonLus,
    );
  }
}

/// Provider gerant la messagerie plateforme <-> application mobile.
class MessagerieProvider extends ChangeNotifier {
  final _dataService = PlatformDataService();
  final _supabase = Supabase.instance.client;

  // --- Etat ----------------------------------------------------------------
  List<ApercuConversation> _conversations = [];
  List<MessagePlateforme> _messagesActuels = [];
  String? _entrepriseSelectionneeId;
  bool _chargement = false;
  bool _envoi = false;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  bool _hasUnreadForSidebar = false;
  static const int _pageSize = 20;
  StreamSubscription<List<Map<String, dynamic>>>? _abonnementTempsReel;
  List<String> _favorisIds = [];

  // --- Getters -------------------------------------------------------------
  List<ApercuConversation> get conversations => _conversations;
  List<MessagePlateforme> get messagesActuels => _messagesActuels;
  String? get entrepriseSelectionneeId => _entrepriseSelectionneeId;
  bool get chargement => _chargement;
  bool get envoi => _envoi;
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;
  bool get hasUnreadForSidebar => _hasUnreadForSidebar;

  ApercuConversation? get conversationSelectionnee =>
      _conversations.where((c) => c.entreprise.id == _entrepriseSelectionneeId).isNotEmpty
          ? _conversations.firstWhere((c) => c.entreprise.id == _entrepriseSelectionneeId)
          : null;

  MessagerieProvider() {
    _chargerFavoris();
    _verifierNonLusInitial();
    _abonnerTempsReelGlobal();
  }

  // --- Chargement ----------------------------------------------------------

  /// Vérifie rapidement s'il y a des messages non lus au démarrage.
  Future<void> _verifierNonLusInitial() async {
    try {
      final res = await _supabase
          .from('messages')
          .select('id')
          .eq('est_envoye_par_user', true)
          .eq('est_lu', false)
          .limit(1);
      if (res.isNotEmpty) {
        _hasUnreadForSidebar = true;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[MessagerieProvider] Erreur verifierNonLusInitial : $e');
    }
  }

  /// Charge la liste de toutes les entreprises avec leur dernier message.
  Future<void> chargerConversations(List<Entreprise> entreprises) async {
    _chargement = true;
    notifyListeners();

    try {
      final apercu = await _dataService.fetchApercuMessages();

      _conversations = entreprises.map((e) {
        final a = apercu[e.id];
        if (a == null) {
          return ApercuConversation(entreprise: e);
        }
        return ApercuConversation(
          entreprise: e,
          dernierMessage: a['dernier_message'] as String?,
          dateEnvoi: a['date_envoi'] != null
              ? (a['date_envoi'].toString().endsWith('Z') || a['date_envoi'].toString().contains('+')
                  ? DateTime.tryParse(a['date_envoi'] as String)?.toLocal()
                  : DateTime.tryParse('${a['date_envoi']}Z')?.toLocal())
              : null,
          estEnvoyeParUser: a['est_envoye_par_user'] as bool? ?? true,
          aDesMessagesNonLus: a['a_des_non_lus'] as bool? ?? false,
        );
      }).toList();

      // Trier : conversations avec messages en premier, par date decroissante
      _conversations.sort((a, b) {
        if (a.dateEnvoi == null && b.dateEnvoi == null) return 0;
        if (a.dateEnvoi == null) return 1;
        if (b.dateEnvoi == null) return -1;
        return b.dateEnvoi!.compareTo(a.dateEnvoi!);
      });
    } catch (_) {
      _conversations = entreprises
          .map((e) => ApercuConversation(entreprise: e))
          .toList();
    }

    _chargement = false;
    // Recalculer l'état global unread
    _hasUnreadForSidebar = _conversations.any((c) => c.aDesMessagesNonLus && c.entreprise.id != _entrepriseSelectionneeId);
    notifyListeners();

    // S'abonner aux messages de TOUTES les entreprises pour la sidebar
    _abonnerTempsReelGlobal();
  }

  void _abonnerTempsReelGlobal() {
    _abonnementTempsReel?.cancel();
    _abonnementTempsReel = _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .order('date_envoi')
        .listen((rows) {
      if (rows.isEmpty) return;

      bool aChangeGlobal = false;

      for (final row in rows) {
        final eid = row['entreprise_id'] as String;
        final isFromClient = row['est_envoye_par_user'] as bool? ?? true;
        String content = row['contenu'] as String? ?? '';
        final estLu = row['est_lu'] as bool? ?? false;
        final estFichier = row['est_fichier'] as bool? ?? false;
        final fichierNom = row['fichier_nom'] as String?;

        if (estFichier && content.trim().isEmpty) {
          content = fichierNom ?? "Pièce jointe";
        }

        // 1. Mettre à jour l'aperçu dans la sidebar
        final dateString = row['date_envoi']?.toString() ?? '';
        DateTime parsedDate;
        try {
          parsedDate = dateString.endsWith('Z') || dateString.contains('+')
              ? DateTime.parse(dateString)
              : DateTime.parse('${dateString}Z');
          parsedDate = parsedDate.toLocal();
        } catch (_) {
          parsedDate = DateTime.now();
        }

        final updated = _mettreAJourApercuDirect(eid, content, parsedDate, isFromClient, estLu);
        if (updated) aChangeGlobal = true;

        if (isFromClient && !estLu && eid != _entrepriseSelectionneeId) {
          _hasUnreadForSidebar = true;
          aChangeGlobal = true;
        }

        // 2. Si c'est l'entreprise actuellement ouverte, mettre à jour le chat
        if (eid == _entrepriseSelectionneeId) {
          final m = MessagePlateforme.fromJson(row);
          final exists = _messagesActuels.any((existing) => existing.id == m.id);
          if (!exists) {
            final indexOptimiste = _messagesActuels.indexWhere(
              (existing) => existing.id.startsWith('optimistic_') && existing.contenu == m.contenu
            );
            if (indexOptimiste != -1) {
              _messagesActuels[indexOptimiste] = m;
            } else {
              _messagesActuels.insert(0, m); // Insert at top for reverse list
            }
            _messagesActuels.sort((a, b) => b.dateEnvoi.compareTo(a.dateEnvoi));
            aChangeGlobal = true;

            // Marquer comme lu dans la DB si c'est le client qui envoie
            if (isFromClient && !estLu) {
              _dataService.marquerMessagesCommeLus(eid).catchError((e) {
                debugPrint('[MessagerieProvider] Erreur marquage lu temps réel : $e');
              });
            }
          }
        }
      }

      if (aChangeGlobal) {
        notifyListeners();
      }
    }, onError: (error) {
      debugPrint('[MessagerieProvider] Erreur de connexion temps réel (flux global) : $error');
    });
  }

  bool _mettreAJourApercuDirect(String eid, String contenu, DateTime date, bool estUser, bool estLu) {
    final idx = _conversations.indexWhere((c) => c.entreprise.id == eid);
    if (idx == -1) return false;

    final oldConv = _conversations[idx];
    if (oldConv.dateEnvoi != null && date.isBefore(oldConv.dateEnvoi!)) {
      return false;
    }

    // Déterminer si on doit marquer comme non lu
    bool aDesNonLus = oldConv.aDesMessagesNonLus;
    // Si envoyé par client ET pas encore lu ET pas l'entreprise courante
    if (estUser && !estLu && eid != _entrepriseSelectionneeId) {
      aDesNonLus = true;
    }

    _conversations[idx] = oldConv.copyWith(
      dernierMessage: contenu,
      dateEnvoi: date,
      estEnvoyeParUser: estUser,
      aDesMessagesNonLus: aDesNonLus,
    );

    // Re-trier
    _conversations.sort((a, b) {
      if (a.dateEnvoi == null && b.dateEnvoi == null) return 0;
      if (a.dateEnvoi == null) return 1;
      if (b.dateEnvoi == null) return -1;
      return b.dateEnvoi!.compareTo(a.dateEnvoi!);
    });

    return true;
  }

  /// Selectionne une entreprise et charge ses messages.
  Future<void> selectionnerEntreprise(String entrepriseId) async {
    if (_entrepriseSelectionneeId == entrepriseId) return;

    _entrepriseSelectionneeId = entrepriseId;
    
    // Marquer localement comme lu immédiatement
    final idx = _conversations.indexWhere((c) => c.entreprise.id == entrepriseId);
    if (idx != -1 && _conversations[idx].aDesMessagesNonLus) {
      _conversations[idx] = _conversations[idx].copyWith(aDesMessagesNonLus: false);
    }

    // Recalculer l'état unread de la sidebar
    _hasUnreadForSidebar = _conversations.any((c) => c.aDesMessagesNonLus && c.entreprise.id != entrepriseId);

    _messagesActuels = [];
    _hasMore = true;
    _isLoadingMore = false;
    notifyListeners();

    // Marquer comme lu dans la DB (async)
    _dataService.marquerMessagesCommeLus(entrepriseId).catchError((e) {
      debugPrint('[MessagerieProvider] Erreur marquage lu : $e');
    });

    // Charger l'historique
    await _chargerHistorique(entrepriseId);
  }

  Future<void> _chargerHistorique(String entrepriseId) async {
    try {
      final rows = await _dataService.fetchMessagesForEntreprise(
        entrepriseId,
        offset: 0,
        limit: _pageSize,
      );
      _messagesActuels = rows.map(MessagePlateforme.fromJson).toList()
        ..sort((a, b) {
          final cmp = b.dateEnvoi.compareTo(a.dateEnvoi);
          if (cmp != 0) return cmp;
          return b.id.compareTo(a.id);
        });
      _hasMore = rows.length >= _pageSize;
      notifyListeners();
    } catch (e) {
      debugPrint('[MessagerieProvider] Error loading history: $e');
    }
  }

  /// Charge le bloc suivant de messages (Lazy Loading).
  Future<void> chargerPlusDeMessages() async {
    if (_isLoadingMore || !_hasMore || _entrepriseSelectionneeId == null) return;

    _isLoadingMore = true;
    notifyListeners();

    try {
      final rows = await _dataService.fetchMessagesForEntreprise(
        _entrepriseSelectionneeId!,
        offset: _messagesActuels.length,
        limit: _pageSize,
      );

      final nouveauxMessages = rows.map(MessagePlateforme.fromJson).toList();
      _messagesActuels.addAll(nouveauxMessages);
      _hasMore = rows.length >= _pageSize;
    } catch (e) {
      debugPrint('[MessagerieProvider] Error loading more: $e');
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // --- Envoi ---------------------------------------------------------------

  /// Envoie un message depuis la plateforme vers l'entreprise selectionnee.
  Future<void> envoyerMessage(String contenu) async {
    final eid = _entrepriseSelectionneeId;
    if (eid == null || contenu.trim().isEmpty) return;

    final texte = contenu.trim();

    // Optimistic UI update
    final optimisticMessage = MessagePlateforme(
      id: 'optimistic_${DateTime.now().millisecondsSinceEpoch}',
      entrepriseId: eid,
      contenu: texte,
      dateEnvoi: DateTime.now(),
      estEnvoyeParUser: false, // La plateforme envoie
    );

    _messagesActuels.insert(0, optimisticMessage);
    _envoi = true;
    notifyListeners();

    try {
      final res = await _dataService.envoyerMessagePlateforme(
        entrepriseId: eid,
        contenu: texte,
      );
      final realMessage = MessagePlateforme.fromJson(res);
      final index = _messagesActuels.indexWhere((m) => m.id == optimisticMessage.id);
      if (index != -1) {
        _messagesActuels[index] = realMessage;
      }
    } catch (_) {
      _messagesActuels.removeWhere((m) => m.id == optimisticMessage.id);
    } finally {
      _envoi = false;
      notifyListeners();
    }
  }

  // --- Actions de Navigation / Sidebar ------------------------------------

  /// Désactive le témoin global sur la barre latérale.
  void clearSidebarUnread() {
    if (_hasUnreadForSidebar) {
      _hasUnreadForSidebar = false;
      notifyListeners();
    }
  }

  /// Réinitialise l'entreprise sélectionnée quand on quitte la messagerie.
  void quitterMessagerie() {
    _entrepriseSelectionneeId = null;
    _messagesActuels = [];
    notifyListeners();
  }

  // --- Favoris et Envoi Fichiers -------------------------------------------

  Future<void> _chargerFavoris() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _favorisIds = prefs.getStringList('entreprises_favorites') ?? [];
      notifyListeners();
    } catch (e) {
      debugPrint('[MessagerieProvider] Erreur chargement favoris : $e');
    }
  }

  bool estFavori(String id) => _favorisIds.contains(id);

  Future<void> toggleFavori(String id) async {
    if (_favorisIds.contains(id)) {
      _favorisIds.remove(id);
    } else {
      _favorisIds.add(id);
    }
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('entreprises_favorites', _favorisIds);
    } catch (e) {
      debugPrint('[MessagerieProvider] Erreur sauvegarde favoris : $e');
    }
  }

  /// Envoie un message avec un fichier attaché.
  Future<void> envoyerMessageAvecFichier({
    required String nomFichier,
    required List<int> octets,
    String contenu = '',
  }) async {
    final eid = _entrepriseSelectionneeId;
    if (eid == null) return;

    _envoi = true;
    notifyListeners();

    try {
      // 1. Upload vers Supabase Storage
      final path = 'messages/${DateTime.now().millisecondsSinceEpoch}_$nomFichier';
      await SupabaseConfig.adminClient.storage.from('documents').uploadBinary(
        path,
        Uint8List.fromList(octets),
      );

      final urlFichier = SupabaseConfig.adminClient.storage.from('documents').getPublicUrl(path);

      // Détecter le type_document
      String typeDoc = 'autre';
      final ext = nomFichier.toLowerCase();
      if (ext.endsWith('.png') ||
          ext.endsWith('.jpg') ||
          ext.endsWith('.jpeg') ||
          ext.endsWith('.webp') ||
          ext.endsWith('.gif')) {
        typeDoc = 'media';
      }

      // 2. Insérer le message
      await _dataService.envoyerMessagePlateformeFichier(
        entrepriseId: eid,
        contenu: contenu,
        fichierUrl: urlFichier,
        fichierNom: nomFichier,
        typeDocument: typeDoc,
      );

      // 3. Enregistrer également dans la table fichiers
      await _dataService.enregistrerFichier(
        entrepriseId: eid,
        nom: nomFichier,
        url: urlFichier,
        estEnvoyeParUser: false,
        typeDocument: typeDoc,
      );
    } catch (e) {
      debugPrint('[MessagerieProvider] Erreur envoi fichier : $e');
      rethrow;
    } finally {
      _envoi = false;
      notifyListeners();
    }
  }

  // --- Nettoyage -----------------------------------------------------------

  @override
  void dispose() {
    _abonnementTempsReel?.cancel();
    super.dispose();
  }
}
