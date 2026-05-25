import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/salarie_service.dart';
import '../services/pointage_service.dart';
import '../services/message_service.dart';
import '../services/avertissement_service.dart';
import '../services/entreprise_service.dart';
import '../services/service_notification.dart';
import '../services/conge_service.dart';

class AppState extends ChangeNotifier with WidgetsBindingObserver {
  // ─── Services ────────────────────────────────────────────────────────────
  late final AuthService _authService;
  late final SalarieService _salarieService;
  late final PointageService _pointageService;
  late final MessageService _messageService;
  late final AvertissementService _avertissementService;
  late final EntrepriseService _entrepriseService;
  late final CongeService _congeService;

  // Abonnement Realtime pour les messages entrants de la plateforme
  StreamSubscription<List<Map<String, dynamic>>>? _abonnementMessages;

  AppState() {
    ServiceNotification().initialiser();
    
    final client = Supabase.instance.client;
    _authService = AuthService(client);
    _salarieService = SalarieService(client);
    _pointageService = PointageService(client);
    _messageService = MessageService(client);
    _avertissementService = AvertissementService(client);
    _entrepriseService = EntrepriseService(client);
    _congeService = CongeService(client);

    // Listen to Supabase auth changes so GoRouter can react
    _authService.onAuthStateChange.listen((authState) {
      final event = authState.event;
      if (event == AuthChangeEvent.signedIn) {
        _onSignedIn(authState.session);
      } else if (event == AuthChangeEvent.signedOut) {
        _onSignedOut();
      }
    });

    // If a session already exists (app restart), restore state
    final existing = Supabase.instance.client.auth.currentSession;
    if (existing != null) {
      _isAuthenticated = true;
      _onSignedIn(existing);
    }

    // Enregistrer l'observateur de cycle de vie
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _abonnementMessages?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('[AppState] App resumed, syncing messages and conges...');
      final eid = _entrepriseId;
      if (eid != null) {
        loadMessages();
        loadConges();
      }
    }
  }

  // ─── Auth ─────────────────────────────────────────────────────────────────
  bool _isAuthenticated = false;
  bool get isAuthenticated => _isAuthenticated;

  String? _entrepriseId;
  String? get entrepriseId => _entrepriseId;

  // ─── Multi-company selector ────────────────────────────────────────────────
  List<ClientParametres> _entreprisesDisponibles = [];
  List<ClientParametres> get entreprisesDisponibles => _entreprisesDisponibles;

  /// True when the user has multiple companies and hasn't chosen one yet.
  bool get needsCompanySelection =>
      _isAuthenticated && _entreprisesDisponibles.length > 1 && _entrepriseId == null;

  /// Called from the selector screen: loads the chosen company and clears the list.
  Future<void> selectEntreprise(ClientParametres choix) async {
    _entrepriseId = choix.id;
    _parametres = choix;
    _entreprisesDisponibles = []; // selection done
    notifyListeners();
    await Future.wait([
      loadSalaries(),
      loadMessages(),
      loadTemplates(),
      loadConges(),
    ]);
  }

  Future<String?> login(String email, String password) async {
    try {
      // S'assurer qu'aucune session persistante n'interfère avec la nouvelle connexion
      await _authService.signOut();
      
      final session = await _authService.signIn(email: email, password: password);
      if (session != null) {
        return null;
      }
      return 'Erreur de connexion inconnue.';
    } on AuthException catch (e) {
      // Traduire les erreurs courantes
      if (e.message.toLowerCase().contains('invalid login credentials')) {
        return 'Identifiants invalides ou e-mail non vérifié.';
      } else if (e.message.toLowerCase().contains('email not confirmed')) {
        return 'Adresse e-mail non confirmée.';
      }
      return e.message;
    } catch (e) {
      return e.toString();
    }
  }

  void logout() {
    _authService.signOut();
  }

  Future<void> resetPassword(String email) async {
    await _authService.resetPassword(email);
  }

  void _onSignedIn(Session? session) async {
    _isAuthenticated = true;
    notifyListeners();

    if (session != null) {
      await _loadEntreprise(session.user.id);
    }
  }

  void _onSignedOut() {
    _isAuthenticated = false;
    _entrepriseId = null;
    _entreprisesDisponibles = [];
    _salaries = [];
    _salariesArchives = [];
    _messages = [];
    _templates = [];
    _conges = [];
    _parametres = null;
    _pointagesCache = {};
    // Annuler l'abonnement temps réel
    _abonnementMessages?.cancel();
    _abonnementMessages = null;
    notifyListeners();
  }

  // ─── Theme ────────────────────────────────────────────────────────────────
  bool _isDarkMode = false;
  bool get isDarkMode => _isDarkMode;
  static bool isDarkStatic = false;

  void toggleDarkMode() {
    _isDarkMode = !_isDarkMode;
    isDarkStatic = _isDarkMode;
    notifyListeners();
  }

  // ─── Enterprise ──────────────────────────────────────────────────────────
  ClientParametres? _parametres;
  ClientParametres? get parametres => _parametres;

  bool _isLoadingParametres = false;
  bool get isLoadingParametres => _isLoadingParametres;

  Future<void> _loadEntreprise(String userId) async {
    try {
      final entreprises = await _entrepriseService.getEntreprisesForUser(userId);

      if (entreprises.isEmpty) return;

      final ids = entreprises.map((e) => e.id).toList();
      ServiceNotification().enregistrerJetonPourEntreprises(ids);

      if (entreprises.length == 1) {
        // Single company — load directly, no selector needed
        _entrepriseId = entreprises.first.id;
        _parametres = entreprises.first;
        _entreprisesDisponibles = [];
        notifyListeners();
        await Future.wait([
          loadSalaries(),
          loadMessages(),
          loadTemplates(),
          loadConges(),
        ]);
      } else {
        // Multiple companies — trigger the selector screen
        _entrepriseId = null;
        _parametres = null;
        _entreprisesDisponibles = entreprises;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[AppState] _loadEntreprise error: $e');
    }
  }

  Future<void> updateParametres(ClientParametres p) async {
    final updated = await _entrepriseService.updateEntreprise(p);
    _parametres = updated;
    
    if (_entreprisesDisponibles.isNotEmpty) {
      final index = _entreprisesDisponibles.indexWhere((e) => e.id == p.id);
      if (index != -1) {
        _entreprisesDisponibles[index] = updated;
      }
    }
    
    notifyListeners();
  }

  // ─── Salariés ─────────────────────────────────────────────────────────────
  List<Salarie> _salaries = [];
  List<Salarie> _salariesArchives = [];
  bool _isLoadingSalaries = false;

  List<Salarie> get salaries => _salaries;
  List<Salarie> get salariesArchives => _salariesArchives;
  bool get isLoadingSalaries => _isLoadingSalaries;

  Future<void> loadSalaries() async {
    final eid = _entrepriseId;
    if (eid == null) return;

    _isLoadingSalaries = true;
    notifyListeners();

    try {
      final results = await Future.wait([
        _salarieService.getSalaries(eid),
        _salarieService.getSalariesArchives(eid),
      ]);
      _salaries = results[0];
      _salariesArchives = results[1];
    } finally {
      _isLoadingSalaries = false;
      notifyListeners();
    }
  }

  Future<void> addSalarie(Salarie s) async {
    final created = await _salarieService.addSalarie(s);
    _salaries.add(created);
    notifyListeners();
  }

  Future<void> updateSalarie(Salarie updated) async {
    final saved = await _salarieService.updateSalarie(updated);
    final idx = _salaries.indexWhere((s) => s.id == saved.id);
    if (idx != -1) {
      _salaries[idx] = saved;
    } else {
      final aIdx = _salariesArchives.indexWhere((s) => s.id == saved.id);
      if (aIdx != -1) _salariesArchives[aIdx] = saved;
    }
    notifyListeners();
  }

  Future<String?> uploadSalarieAvatar(String salarieId, Uint8List fileBytes, String fileName) async {
    final publicUrl = await _salarieService.uploadSalarieAvatar(salarieId, fileBytes, fileName);
    if (publicUrl != null) {
      final idx = _salaries.indexWhere((s) => s.id == salarieId);
      if (idx != -1) {
        _salaries[idx] = _salaries[idx].copyWith(avatarUrl: publicUrl);
      } else {
        final aIdx = _salariesArchives.indexWhere((s) => s.id == salarieId);
        if (aIdx != -1) {
          _salariesArchives[aIdx] = _salariesArchives[aIdx].copyWith(avatarUrl: publicUrl);
        }
      }
      notifyListeners();
    }
    return publicUrl;
  }

  Future<void> archiverSalarie(String id) async {
    await _salarieService.archiveSalarie(id);
    final idx = _salaries.indexWhere((s) => s.id == id);
    if (idx != -1) {
      final s = _salaries.removeAt(idx);
      _salariesArchives.add(s.copyWith(isArchived: true));
    }
    notifyListeners();
  }

  Future<void> desarchiverSalarie(String id) async {
    await _salarieService.unarchiveSalarie(id);
    final idx = _salariesArchives.indexWhere((s) => s.id == id);
    if (idx != -1) {
      final s = _salariesArchives.removeAt(idx);
      _salaries.add(s.copyWith(isArchived: false));
    }
    notifyListeners();
  }

  Future<void> supprimerSalarie(String id) async {
    await _salarieService.deleteSalarie(id);
    _salaries.removeWhere((s) => s.id == id);
    _salariesArchives.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  // ─── Pointage ─────────────────────────────────────────────────────────────
  // Cache: "yyyy-MM" -> list of entries for that month
  Map<String, List<PointageEntree>> _pointagesCache = {};
  bool _isLoadingPointage = false;
  bool get isLoadingPointage => _isLoadingPointage;

  String _monthKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}';
  String _dateKey(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  List<Salarie> getSalariesForDay(DateTime day) => _salaries;

  Future<void> loadPointagesForMonth(DateTime month, {bool force = false}) async {
    final eid = _entrepriseId;
    if (eid == null) return;

    final key = _monthKey(month);
    if (!force && _pointagesCache.containsKey(key)) return; // already loaded

    _isLoadingPointage = true;
    notifyListeners();

    try {
      final entries = await _pointageService.getPointagesForMonth(
        eid,
        month.year,
        month.month,
      );
      _pointagesCache[key] = entries;
    } finally {
      _isLoadingPointage = false;
      notifyListeners();
    }
  }

  bool getPointageStatus(DateTime day, String salarieId) {
    final key = _monthKey(day);
    final dateStr = _dateKey(day);
    final entries = _pointagesCache[key] ?? [];
    return entries
        .any((e) => e.salarieId == salarieId && _dateKey(e.date) == dateStr && e.estPointe);
  }

  String getNoteForDay(DateTime day, String salarieId) {
    final key = _monthKey(day);
    final dateStr = _dateKey(day);
    final entries = _pointagesCache[key] ?? [];
    final match = entries.where(
        (e) => e.salarieId == salarieId && _dateKey(e.date) == dateStr);
    return match.isNotEmpty ? (match.first.note ?? '') : '';
  }

  Future<void> setPointage(DateTime day, String salarieId, bool value) async {
    final eid = _entrepriseId;
    if (eid == null) return;

    final entry = PointageEntree(
      salarieId: salarieId,
      entrepriseId: eid,
      date: day,
      estPointe: value,
      note: getNoteForDay(day, salarieId),
    );

    await _pointageService.upsertPointage(entry);

    // Update local cache
    final key = _monthKey(day);
    final dateStr = _dateKey(day);
    final list = _pointagesCache.putIfAbsent(key, () => []);
    final idx = list.indexWhere(
        (e) => e.salarieId == salarieId && _dateKey(e.date) == dateStr);
    if (idx != -1) {
      list[idx] = entry;
    } else {
      list.add(entry);
    }
    notifyListeners();
  }

  Future<void> setNote(DateTime day, String salarieId, String note) async {
    final eid = _entrepriseId;
    if (eid == null) return;

    final entry = PointageEntree(
      salarieId: salarieId,
      entrepriseId: eid,
      date: day,
      estPointe: getPointageStatus(day, salarieId),
      note: note,
    );

    await _pointageService.upsertPointage(entry);

    final key = _monthKey(day);
    final dateStr = _dateKey(day);
    final list = _pointagesCache.putIfAbsent(key, () => []);
    final idx = list.indexWhere(
        (e) => e.salarieId == salarieId && _dateKey(e.date) == dateStr);
    if (idx != -1) {
      list[idx] = entry;
    } else {
      list.add(entry);
    }
    notifyListeners();
  }

  bool isSalarieEnConge(String salarieId, DateTime day) {
    // 1. Check in conges list
    final target = DateTime(day.year, day.month, day.day);
    final inConges = _conges.any((c) {
      if (c.salarieId != salarieId) return false;
      final start = DateTime(c.dateDebut.year, c.dateDebut.month, c.dateDebut.day);
      final end = DateTime(c.dateFin.year, c.dateFin.month, c.dateFin.day);
      return (target.isAfter(start) || target.isAtSameMomentAs(start)) &&
             (target.isBefore(end) || target.isAtSameMomentAs(end));
    });
    if (inConges) return true;

    // 2. Check in pointages note
    final key = _monthKey(day);
    final dateStr = _dateKey(day);
    final entries = _pointagesCache[key] ?? [];
    final match = entries.where((e) => e.salarieId == salarieId && _dateKey(e.date) == dateStr);
    if (match.isNotEmpty) {
      final note = match.first.note ?? '';
      if (note.startsWith('Congé Payé') ||
          note.startsWith('Arrêt Maladie') ||
          note.startsWith('RTT') ||
          note.startsWith('Congé Exceptionnel') ||
          note.startsWith('Autre Absence') ||
          note.startsWith('Maladie') ||
          note.startsWith('Arrêt') ||
          note.startsWith('Conge')) {
        return true;
      }
    }
    return false;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String getCongeDescriptionForSalarie(String salarieId, DateTime day) {
    // 1. Check in conges list
    final target = DateTime(day.year, day.month, day.day);
    final matchConge = _conges.where((c) {
      if (c.salarieId != salarieId) return false;
      final start = DateTime(c.dateDebut.year, c.dateDebut.month, c.dateDebut.day);
      final end = DateTime(c.dateFin.year, c.dateFin.month, c.dateFin.day);
      return (target.isAfter(start) || target.isAtSameMomentAs(start)) &&
             (target.isBefore(end) || target.isAtSameMomentAs(end));
    });
    if (matchConge.isNotEmpty) {
      return _getTypeLabel(matchConge.first.typeConge);
    }

    // 2. Check in pointages note
    final key = _monthKey(day);
    final dateStr = _dateKey(day);
    final entries = _pointagesCache[key] ?? [];
    final match = entries.where((e) => e.salarieId == salarieId && _dateKey(e.date) == dateStr);
    if (match.isNotEmpty) {
      final note = match.first.note ?? '';
      if (note.startsWith('Congé Payé') ||
          note.startsWith('Arrêt Maladie') ||
          note.startsWith('RTT') ||
          note.startsWith('Congé Exceptionnel') ||
          note.startsWith('Autre Absence') ||
          note.startsWith('Maladie') ||
          note.startsWith('Arrêt') ||
          note.startsWith('Conge')) {
        final idx = note.indexOf(':');
        if (idx != -1) {
          return note.substring(0, idx).trim();
        }
        return note;
      }
    }
    return 'En Congé';
  }

  StatutJour getStatutJour(DateTime day) {
    if (_salaries.isEmpty) return StatutJour.absent;

    final key = _monthKey(day);
    final dateStr = _dateKey(day);
    final entries = (_pointagesCache[key] ?? [])
        .where((e) => _dateKey(e.date) == dateStr)
        .toList();

    int accountedCount = 0;
    for (final s in _salaries) {
      final isPointed = entries.any((e) => e.salarieId == s.id && e.estPointe);
      if (isPointed) {
        accountedCount++;
      } else {
        final onLeave = isSalarieEnConge(s.id, day);
        if (onLeave) {
          accountedCount++;
        }
      }
    }

    if (accountedCount == 0) return StatutJour.absent;
    if (accountedCount >= _salaries.length) return StatutJour.complet;
    return StatutJour.incomplet;
  }

  // ─── Messagerie ──────────────────────────────────────────────────────────
  List<Message> _messages = [];
  bool _isLoadingMessages = false;
  bool _hasMoreMessages = true;
  bool _isLoadingMoreMessages = false;
  static const int _messagePageSize = 20;

  bool get isLoadingMessages => _isLoadingMessages;
  bool get hasMoreMessages => _hasMoreMessages;
  bool get isLoadingMoreMessages => _isLoadingMoreMessages;

  List<Message> get messages => List.unmodifiable(_messages);

  List<Fichier> _fichiers = [];
  bool _isLoadingFichiers = false;

  List<Fichier> get fichiers => List.unmodifiable(_fichiers);
  bool get isLoadingFichiers => _isLoadingFichiers;

  Future<void> loadFichiers() async {
    final eid = _entrepriseId;
    if (eid == null) return;

    _isLoadingFichiers = true;
    notifyListeners();

    try {
      final fetched = await _messageService.getFichiers(eid);
      _fichiers = fetched;
    } catch (e) {
      debugPrint('[AppState] Error loading fichiers: $e');
    } finally {
      _isLoadingFichiers = false;
      notifyListeners();
    }
  }

  Future<void> loadMessages() async {
    final eid = _entrepriseId;
    if (eid == null) return;

    // Charger les fichiers en même temps
    loadFichiers();

    // Chargement silencieux si des messages sont déjà affichés
    final isFirstLoad = _messages.isEmpty;
    if (isFirstLoad) {
      _isLoadingMessages = true;
      _hasMoreMessages = true;
      notifyListeners();
    }

    try {
      final fetched = await _messageService.getMessages(eid, offset: 0, limit: _messagePageSize);
      _messages = fetched;
      _hasMoreMessages = fetched.length >= _messagePageSize;
      
      // Marquer comme lus
      _messageService.marquerMessagesCommeLus(eid);
    } finally {
      if (isFirstLoad) {
        _isLoadingMessages = false;
        notifyListeners();
      }
    }

    // Ouvrir l'abonnement Realtime pour la messagerie
    _abonnementMessages?.cancel();
    _abonnementMessages = _messageService.abonnerNouveauxMessages(
      eid,
      (messageEntrant) {
        final idx = _messages.indexWhere((m) => m.id == messageEntrant.id);
        if (idx != -1) {
          // Si le message existe déjà, mettre à jour son état de lecture
          if (_messages[idx].estLu != messageEntrant.estLu) {
            final updated = List<Message>.from(_messages);
            updated[idx] = updated[idx].copyWith(estLu: messageEntrant.estLu);
            _messages = updated;
            notifyListeners();
          }
        } else {
          // Rechercher s'il y a un message optimiste correspondant
          final idxOptimiste = _messages.indexWhere(
            (m) => m.id.startsWith('optimistic_') && m.contenu == messageEntrant.contenu
          );

          var msg = messageEntrant;
          if (!msg.estEnvoyePar) {
            msg = msg.copyWith(estLu: true);
            _messageService.marquerMessagesCommeLus(eid);
          }
          
          final updated = List<Message>.from(_messages);
          if (idxOptimiste != -1) {
            updated[idxOptimiste] = msg;
          } else {
            updated.add(msg);
          }
          updated.sort((a, b) => b.dateEnvoi.compareTo(a.dateEnvoi));
          _messages = updated;
          notifyListeners();
        }
      },
      onError: (err) {
        debugPrint('[AppState] Realtime subscription error, reconnecting in 5 seconds: $err');
        Future.delayed(const Duration(seconds: 5), () {
          if (_entrepriseId == eid) {
            loadMessages();
          }
        });
      },
    );
  }

  Future<void> loadMoreMessages() async {
    if (_isLoadingMoreMessages || !_hasMoreMessages) return;
    final eid = _entrepriseId;
    if (eid == null) return;

    _isLoadingMoreMessages = true;
    notifyListeners();

    try {
      final fetched = await _messageService.getMessages(
        eid,
        offset: _messages.length,
        limit: _messagePageSize,
      );
      _messages.addAll(fetched);
      _hasMoreMessages = fetched.length >= _messagePageSize;
    } catch (e) {
      debugPrint('[AppState] Error loading more messages: $e');
    } finally {
      _isLoadingMoreMessages = false;
      notifyListeners();
    }
  }

  Future<void> addMessage(Message msg) async {

    // Optimistic UI update
    final optimisticMessage = Message(
      id: 'optimistic_${DateTime.now().millisecondsSinceEpoch}',
      entrepriseId: msg.entrepriseId,
      contenu: msg.contenu,
      dateEnvoi: DateTime.now(),
      estEnvoyePar: msg.estEnvoyePar,
      fichierUrl: msg.fichierUrl,
      fichierNom: msg.fichierNom,
      typeDocument: msg.typeDocument,
      estFichier: msg.estFichier,
    );

    _messages = [optimisticMessage, ..._messages]
      ..sort((a, b) => b.dateEnvoi.compareTo(a.dateEnvoi));
    notifyListeners();

    try {
      Message saved;
      if (msg.estFichier) {
        final localPaths = msg.fichierUrl?.split(',') ?? [];
        final nomsFichiers = msg.fichierNom?.split(',') ?? [];
        
        if (localPaths.isEmpty || localPaths.first.isEmpty) {
          throw Exception('Local file paths are empty');
        }

        List<String> publicUrls = [];
        
        for (int i = 0; i < localPaths.length; i++) {
          final localPath = localPaths[i];
          final nomFichierOriginal = i < nomsFichiers.length ? nomsFichiers[i] : 'fichier';
          
          // 2. Upload file to Supabase Storage in an isolated subfolder
          final publicUrl = await _messageService.uploadFichier(msg.entrepriseId, nomFichierOriginal, localPath);

          // 3. Register in 'fichiers' table
          final typeDocValue = msg.typeDocument?.value ?? 'autre';
          await _messageService.enregistrerFichier(
            entrepriseId: msg.entrepriseId,
            nom: nomFichierOriginal,
            url: publicUrl,
            estEnvoyeParUser: true,
            typeDocument: typeDocValue,
          );
          
          publicUrls.add(publicUrl);
        }

        // 4. Build the final message object to insert in 'messages' table
        final msgToSend = Message(
          id: '',
          entrepriseId: msg.entrepriseId,
          contenu: nomsFichiers.length == 1 ? 'Fichier envoyé : ${nomsFichiers.first}' : '${nomsFichiers.length} fichiers envoyés',
          dateEnvoi: DateTime.now(),
          estEnvoyePar: true,
          fichierUrl: publicUrls.join(','),
          fichierNom: nomsFichiers.join(','),
          typeDocument: msg.typeDocument,
          estFichier: true,
        );
        saved = await _messageService.sendMessage(msgToSend);
      } else {
        saved = await _messageService.sendMessage(msg);
      }

      // Let the stream or this response replace it
      final idx = _messages.indexWhere((m) => m.id == optimisticMessage.id);
      if (idx != -1) {
        final updated = List<Message>.from(_messages);
        updated[idx] = saved;
        _messages = updated;
        notifyListeners();
      }
    } catch (e) {
      _messages.removeWhere((m) => m.id == optimisticMessage.id);
      notifyListeners();
      rethrow;
    }
  }

  String _sanitiserNomEntreprise(String nom) {
    String cleaned = nom.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    cleaned = cleaned.replaceAll(RegExp(r'_{2,}'), '_');
    cleaned = cleaned.trim().toLowerCase();
    if (cleaned.startsWith('_')) {
      cleaned = cleaned.substring(1);
    }
    if (cleaned.endsWith('_')) {
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }
    return cleaned.isEmpty ? 'entreprise' : cleaned;
  }

  // ─── Avertissements ───────────────────────────────────────────────────────
  List<TemplateAvertissement> _templates = [];
  bool _isLoadingTemplates = false;
  bool get isLoadingTemplates => _isLoadingTemplates;

  List<TemplateAvertissement> get templates => List.unmodifiable(_templates);

  Future<void> loadTemplates() async {
    final eid = _entrepriseId;
    if (eid == null) return;

    _isLoadingTemplates = true;
    notifyListeners();

    try {
      _templates = await _avertissementService.getTemplates(eid);
      // If no templates exist yet, seed the defaults
      if (_templates.isEmpty) {
        await _seedDefaultTemplates(eid);
        _templates = await _avertissementService.getTemplates(eid);
      }
    } finally {
      _isLoadingTemplates = false;
      notifyListeners();
    }
  }

  Future<void> updateTemplate(String id, String newContent) async {
    await _avertissementService.updateTemplate(id, newContent);
    final idx = _templates.indexWhere((t) => t.id == id);
    if (idx != -1) {
      final updated = List<TemplateAvertissement>.from(_templates);
      updated[idx] = updated[idx].copyWith(contenu: newContent);
      _templates = updated;
      notifyListeners();
    }
  }

  /// Seeds the 3 default templates on first use for this enterprise.
  Future<void> _seedDefaultTemplates(String entrepriseId) async {
    final defaults = [
      TemplateAvertissement(
        id: '',
        entrepriseId: entrepriseId,
        titre: "Fiche d'Avertissement",
        type: TypeAvertissement.ficheAvertissement,
        contenu: '''Objet : Avertissement

Madame / Monsieur [Nom Prénom],

Nous avons constaté les faits suivants : [description des faits].

Ces faits constituent une violation de [règle/procédure]. En conséquence, nous vous adressons le présent avertissement.

Nous vous demandons de remédier à cette situation dans les plus brefs délais.

Veuillez agréer, Madame/Monsieur, l\'expression de nos salutations distinguées.

La Direction''',
      ),
      TemplateAvertissement(
        id: '',
        entrepriseId: entrepriseId,
        titre: 'Convocation',
        type: TypeAvertissement.convocation,
        contenu: '''Objet : Convocation à un entretien

Madame / Monsieur [Nom Prénom],

Nous vous informons que vous êtes convoqué(e) à un entretien qui se tiendra le [date] à [heure] dans nos locaux situés [adresse].

Cet entretien a pour objet : [motif de l\'entretien].

Vous avez la possibilité de vous faire assister par une personne de votre choix appartenant au personnel de l\'entreprise.

Veuillez agréer, Madame/Monsieur, l\'expression de nos salutations distinguées.

La Direction''',
      ),
      TemplateAvertissement(
        id: '',
        entrepriseId: entrepriseId,
        titre: "Note d'Information",
        type: TypeAvertissement.information,
        contenu: '''Objet : Note d\'information

Madame / Monsieur [Nom Prénom],

Nous vous informons de [sujet de l\'information].

[Détails de l\'information]

Pour toute question, n\'hésitez pas à vous rapprocher de votre responsable hiérarchique.

Veuillez agréer, Madame/Monsieur, l\'expression de nos salutations distinguées.

La Direction''',
      ),
    ];

    for (final t in defaults) {
      await _avertissementService.addTemplate(t);
    }
  }

  // ─── Congés ───────────────────────────────────────────────────────────────
  List<Conge> _conges = [];
  bool _isLoadingConges = false;

  List<Conge> get conges => _conges;
  bool get isLoadingConges => _isLoadingConges;

  Future<void> loadConges() async {
    final eid = _entrepriseId;
    if (eid == null) return;

    _isLoadingConges = true;
    notifyListeners();

    try {
      _conges = await _congeService.getConges(eid);
    } catch (e) {
      debugPrint('[AppState] loadConges error: $e');
    } finally {
      _isLoadingConges = false;
      notifyListeners();
    }
  }

  Future<void> addConge(Conge conge) async {
    final created = await _congeService.createConge(conge);
    _conges.insert(0, created);
    
    try {
      await _generatePointagesForConge(created);
    } catch (e) {
      debugPrint('[AppState] Failed to auto-generate pointages: $e');
    }
    
    notifyListeners();
  }

  Future<void> updateConge(String id, Map<String, dynamic> updates) async {
    final idx = _conges.indexWhere((c) => c.id == id);
    if (idx != -1) {
      final oldConge = _conges[idx];

      // Delete old pointages
      try {
        await _deletePointagesForConge(oldConge);
      } catch (e) {
        debugPrint('[AppState] Failed to delete old pointages on update: $e');
      }

      // Update in db
      final updated = await _congeService.updateConge(id, updates);
      _conges[idx] = updated;
      
      try {
        await _generatePointagesForConge(updated);
      } catch (e) {
        debugPrint('[AppState] Failed to auto-generate pointages on update: $e');
      }
      
      notifyListeners();
    }
  }

  Future<void> deleteConge(String id) async {
    final idx = _conges.indexWhere((c) => c.id == id);
    if (idx != -1) {
      final conge = _conges[idx];
      
      await _congeService.deleteConge(id);
      _conges.removeAt(idx);
      
      try {
        await _deletePointagesForConge(conge);
      } catch (e) {
        debugPrint('[AppState] Failed to delete pointages for conge: $e');
      }
      
      notifyListeners();
    }
  }

  Future<void> _deletePointagesForConge(Conge conge) async {
    await _pointageService.deletePointagesInRange(
      conge.salarieId,
      conge.dateDebut,
      conge.dateFin,
    );

    // Update local cache
    final start = DateTime(conge.dateDebut.year, conge.dateDebut.month, conge.dateDebut.day);
    final end = DateTime(conge.dateFin.year, conge.dateFin.month, conge.dateFin.day);
    final daysCount = end.difference(start).inDays + 1;

    for (int i = 0; i < daysCount; i++) {
      final day = DateTime(start.year, start.month, start.day + i);
      final key = _monthKey(day);
      final dateStr = _dateKey(day);
      
      final list = _pointagesCache[key];
      if (list != null) {
        list.removeWhere(
          (e) => e.salarieId == conge.salarieId && _dateKey(e.date) == dateStr
        );
      }
    }
  }

  String _getTypeLabel(String type) {
    switch (type) {
      case 'conge_paye':
        return 'Congé Payé';
      case 'maladie':
        return 'Arrêt Maladie';
      case 'rtt':
        return 'RTT';
      case 'exceptionnel':
        return 'Congé Exceptionnel';
      default:
        return 'Autre Absence';
    }
  }

  Future<void> _generatePointagesForConge(Conge conge) async {
    final List<PointageEntree> entries = [];
    final start = DateTime(conge.dateDebut.year, conge.dateDebut.month, conge.dateDebut.day);
    final end = DateTime(conge.dateFin.year, conge.dateFin.month, conge.dateFin.day);
    final daysCount = end.difference(start).inDays + 1;

    for (int i = 0; i < daysCount; i++) {
      final day = DateTime(start.year, start.month, start.day + i);
      final label = _getTypeLabel(conge.typeConge);
      final note = conge.commentaire.trim().isNotEmpty
          ? '$label : ${conge.commentaire.trim()}'
          : label;

      final entry = PointageEntree(
        salarieId: conge.salarieId,
        entrepriseId: conge.entrepriseId,
        date: day,
        estPointe: false,
        note: note,
      );
      entries.add(entry);
    }

    if (entries.isEmpty) return;

    await _pointageService.upsertPointages(entries);

    // Update local cache
    for (final entry in entries) {
      final key = _monthKey(entry.date);
      final dateStr = _dateKey(entry.date);
      final list = _pointagesCache.putIfAbsent(key, () => []);
      final idx = list.indexWhere(
          (e) => e.salarieId == entry.salarieId && _dateKey(e.date) == dateStr);
      if (idx != -1) {
        list[idx] = entry;
      } else {
        list.add(entry);
      }
    }
  }
}
