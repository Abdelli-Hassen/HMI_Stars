import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../domain/models/entreprise.dart';
import '../../domain/models/salarie.dart';
import '../../domain/models/document_entreprise.dart';
import '../../domain/models/note_entreprise.dart';
import '../../../../core/services/platform_data_service.dart';

enum LoadStatus { initial, loading, loaded, error }

class EntrepriseProvider extends ChangeNotifier {
  final _dataService = PlatformDataService();

  // ─── State ────────────────────────────────────────────────────────────────
  List<Entreprise> _entreprises = [];
  final Map<String, List<Salarie>> _salariesCache = {};
  final Map<String, List<DocumentEntreprise>> _documentsCache = {};
  final Map<String, List<NoteEntreprise>> _notesCache = {};
  List<NoteEntreprise> _allNotes = [];

  LoadStatus _status = LoadStatus.initial;
  String? _error;
  String _filtreActif = 'Toutes les entreprises';
  String _searchQuery = '';

  // ─── Getters ──────────────────────────────────────────────────────────────
  LoadStatus get status => _status;
  String? get error => _error;
  String get filtreActif => _filtreActif;
  String get searchQuery => _searchQuery;

  List<Entreprise> get entreprises => _entreprises;
  int get totalEntreprises => _entreprises.length;
  int get dossiersEnCours =>
      _entreprises.where((e) => e.statut == 'EN COURS').length;
  int get dossiersEnAttente =>
      _entreprises.where((e) => e.statut == 'ATTENTE DOCS').length;
  int get dossiersComplets =>
      _entreprises.where((e) => e.statut == 'COMPLET').length;

  List<Entreprise> get entreprisesFiltrees {
    var filtered = _entreprises;
    switch (_filtreActif) {
      case 'En cours de travail':
        filtered = filtered.where((e) => e.statut == 'EN COURS').toList();
        break;
      case 'En attente des besoins':
        filtered = filtered.where((e) => e.statut == 'ATTENTE DOCS').toList();
        break;
      case 'Travail complet':
        filtered = filtered.where((e) => e.statut == 'COMPLET').toList();
        break;
      case 'Archivées':
        filtered = filtered.where((e) => e.statut == 'ARCHIVÉ').toList();
        break;
      default:
        filtered = filtered.where((e) => e.statut != 'ARCHIVÉ').toList();
        break;
    }

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((e) => 
        e.nom.toLowerCase().contains(query) || 
        e.email.toLowerCase().contains(query) || 
        e.nomGerant.toLowerCase().contains(query)
      ).toList();
    }

    return filtered;
  }

  List<Salarie> get salaries =>
      _salariesCache.values.expand((s) => s).toList();

  // ─── Init / Fetch ─────────────────────────────────────────────────────────

  Future<void> fetchEntreprises({bool force = false}) async {
    if (!force && _entreprises.isNotEmpty) {
      _status = LoadStatus.loaded;
      notifyListeners();
      return;
    }
    _status = LoadStatus.loading;
    _error = null;
    notifyListeners();
    try {
      _entreprises = await _dataService.fetchEntreprises();
      _status = LoadStatus.loaded;
    } catch (e) {
      _status = LoadStatus.error;
      _error = e.toString();
    }
    notifyListeners();
  }

  // ─── Salaries ─────────────────────────────────────────────────────────────

  List<Salarie> salariesPourEntreprise(String entrepriseId) =>
      (_salariesCache[entrepriseId] ?? [])
          .where((s) => s.estActif)
          .toList();

  List<Salarie> archivesPourEntreprise(String entrepriseId) =>
      (_salariesCache[entrepriseId] ?? [])
          .where((s) => !s.estActif)
          .toList();

  Future<void> fetchSalariesForEntreprise(String entrepriseId, {bool force = false}) async {
    if (!force && _salariesCache.containsKey(entrepriseId)) return;
    try {
      final list = await _dataService.fetchSalariesForEntreprise(entrepriseId);
      _salariesCache[entrepriseId] = list;
      notifyListeners();
    } catch (_) {}
  }

  Future<Salarie> ajouterSalarie(Salarie salarie) async {
    final created = await _dataService.createSalarie(salarie);
    final list = _salariesCache[salarie.entrepriseId] ?? [];
    _salariesCache[salarie.entrepriseId] = [...list, created];
    notifyListeners();
    return created;
  }

  Future<Salarie> modifierSalarie(Salarie salarie) async {
    final updated = await _dataService.updateSalarie(salarie);
    final list = _salariesCache[salarie.entrepriseId] ?? [];
    final index = list.indexWhere((s) => s.id == salarie.id);
    if (index != -1) {
      list[index] = updated;
      _salariesCache[salarie.entrepriseId] = [...list];
    } else {
      await fetchSalariesForEntreprise(salarie.entrepriseId, force: true);
    }
    notifyListeners();
    return updated;
  }

  Future<String?> uploadSalarieAvatar(String salarieId, Uint8List fileBytes, String fileName, String entrepriseId) async {
    final url = await _dataService.uploadSalarieAvatar(salarieId, fileBytes, fileName);
    if (url != null) {
      final list = _salariesCache[entrepriseId] ?? [];
      final index = list.indexWhere((s) => s.id == salarieId);
      if (index != -1) {
        list[index] = list[index].copyWith(avatarUrl: url);
        _salariesCache[entrepriseId] = [...list];
        notifyListeners();
      }
    }
    return url;
  }

  Future<void> archiverSalarie(String id, String entrepriseId) async {
    await _dataService.archiveSalarie(id);
    await fetchSalariesForEntreprise(entrepriseId, force: true);
  }

  Future<void> desarchiverSalarie(String id, String entrepriseId) async {
    await _dataService.unarchiveSalarie(id);
    await fetchSalariesForEntreprise(entrepriseId, force: true);
  }

  Future<void> supprimerArchive(String id, String entrepriseId) async {
    await _dataService.deleteSalarie(id);
    _salariesCache[entrepriseId]?.removeWhere((s) => s.id == id);
    notifyListeners();
  }

  // ─── Documents ────────────────────────────────────────────────────────────

  List<DocumentEntreprise> documentsPourEntreprise(String entrepriseId) =>
      _documentsCache[entrepriseId] ?? [];

  Future<void> fetchDocumentsForEntreprise(String entrepriseId, {bool force = false}) async {
    if (!force && _documentsCache.containsKey(entrepriseId)) return;
    try {
      final list = entrepriseId == 'all'
          ? await _dataService.fetchAllDocuments()
          : await _dataService.fetchDocumentsForEntreprise(entrepriseId);
      _documentsCache[entrepriseId] = list;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> supprimerDocument(DocumentEntreprise doc, String entrepriseId) async {
    try {
      await _dataService.deleteDocument(doc.id, url: doc.url);
      _documentsCache[entrepriseId]?.removeWhere((d) => d.id == doc.id || d.url == doc.url);
      notifyListeners();
    } catch (_) {}
  }

  // ─── Notes ────────────────────────────────────────────────────────────────

  List<NoteEntreprise> notesPourEntreprise(String entrepriseId) =>
      (_notesCache[entrepriseId] ?? [])
          .toList();

  List<NoteEntreprise> get allNotes => _allNotes;

  Future<void> fetchNotesForEntreprise(String entrepriseId, {bool force = false}) async {
    if (!force && _notesCache.containsKey(entrepriseId)) return;
    try {
      final list = await _dataService.fetchNotesForEntreprise(entrepriseId);
      _notesCache[entrepriseId] = list;
      notifyListeners();
    } catch (_) {}
  }

  Future<void> fetchAllNotes() async {
    try {
      _allNotes = await _dataService.fetchAllNotes();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> ajouterNote(NoteEntreprise note) async {
    final created = await _dataService.createNote(note);
    final list = _notesCache[note.entrepriseId] ?? [];
    _notesCache[note.entrepriseId] = [created, ...list];
    // Also update the global list
    _allNotes = [created, ..._allNotes];
    notifyListeners();
  }

  Future<void> updateNote(NoteEntreprise note) async {
    final updated = await _dataService.updateNote(note);
    // Update in cache
    final list = _notesCache[note.entrepriseId];
    if (list != null) {
      final idx = list.indexWhere((n) => n.id == updated.id);
      if (idx != -1) list[idx] = updated;
    }
    // Update in global list
    final gIdx = _allNotes.indexWhere((n) => n.id == updated.id);
    if (gIdx != -1) _allNotes[gIdx] = updated;
    notifyListeners();
  }

  Future<void> supprimerNote(String id, String entrepriseId) async {
    await _dataService.deleteNote(id);
    _notesCache[entrepriseId]?.removeWhere((n) => n.id == id);
    _allNotes.removeWhere((n) => n.id == id);
    notifyListeners();
  }

  // ─── Entreprise CRUD ──────────────────────────────────────────────────────

  Future<void> ajouterEntreprise(Entreprise entreprise) async {
    final created = await _dataService.createEntreprise(entreprise);
    _entreprises = [created, ..._entreprises];
    notifyListeners();
  }

  Future<void> updateEntreprise(Entreprise entreprise) async {
    final updated = await _dataService.updateEntreprise(entreprise);
    final idx = _entreprises.indexWhere((e) => e.id == updated.id);
    if (idx != -1) {
      _entreprises = [..._entreprises]..[idx] = updated;
      notifyListeners();
    }
  }

  Future<bool> uploadEntrepriseLogo(String entrepriseId, List<int> fileBytes, String fileName) async {
    final url = await _dataService.uploadEntrepriseLogo(entrepriseId, Uint8List.fromList(fileBytes), fileName);
    if (url != null) {
      final idx = _entreprises.indexWhere((e) => e.id == entrepriseId);
      if (idx != -1) {
        _entreprises = [..._entreprises]..[idx] = _entreprises[idx].copyWith(logoUrl: url);
        notifyListeners();
      }
      return true;
    }
    return false;
  }

  // ─── Filters ──────────────────────────────────────────────────────────────

  void setFiltre(String filtre) {
    _filtreActif = filtre;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }
}
