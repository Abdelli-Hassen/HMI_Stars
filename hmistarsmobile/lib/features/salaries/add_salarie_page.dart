import 'dart:io' as io;
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart' as fp;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/providers/app_state.dart';
import '../../core/models/models.dart';
import '../../core/widgets/mobile_file_previewer.dart';
import '../../core/widgets/top_notification_banner.dart';
import '../../core/widgets/salarie_avatar.dart';

class AddSalariePage extends StatefulWidget {
  final Salarie? salarie;
  final String? salarieId;
  final bool readOnly;
  const AddSalariePage({
    super.key,
    this.salarie,
    this.salarieId,
    this.readOnly = false,
  });

  @override
  State<AddSalariePage> createState() => _AddSalariePageState();
}

class _AddSalariePageState extends State<AddSalariePage> {
  final _formKey = GlobalKey<FormState>();
  String? _genre;
  String _typeContrat = 'CDI';
  DateTime? _dateNaissance;
  DateTime? _dateEmbauche;
  DateTime? _dateFinContrat;
  String? _avatarUrl;
  bool _isUploadingAvatar = false;

  // Controllers
  final _nomController = TextEditingController();
  final _prenomController = TextEditingController();
  final _nomNaissanceController = TextEditingController();
  final _nsecuController = TextEditingController();
  final _lieuNaissanceController = TextEditingController();
  final _nationaliteController = TextEditingController();
  final _adresseController = TextEditingController();
  final _telephoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _posteController = TextEditingController();
  final _cinController = TextEditingController();
  final _descriptionController = TextEditingController();

  // Documents joints
  bool _hasPieceIdentite = false;
  bool _hasCarteVitale = false;
  bool _hasJustificatifDomicile = false;
  bool _hasContratSigne = false;

  String? _initError;
  String? _initStackTrace;

  late final String _salarieId;
  bool _isLoadingSalarie = false;

  String _generateUuid() {
    final random = math.Random.secure();
    final values = List<int>.generate(16, (i) => random.nextInt(256));
    values[6] = (values[6] & 0x0f) | 0x40; // version 4
    values[8] = (values[8] & 0x3f) | 0x80; // variant
    final hex = values.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20, 32)}';
  }

  Map<String, String> _fileUrls = {};
  bool _loadingFiles = false;

  Future<void> _loadDocuments() async {
    setState(() => _loadingFiles = true);
    try {
      final client = Supabase.instance.client;
      final list = await client.storage
          .from('documents')
          .list(path: 'salaries/$_salarieId');

      final Map<String, String> urls = {};
      for (final f in list) {
        final parts = f.name.split('.');
        if (parts.isNotEmpty) {
          final key = parts.first;
          final path = 'salaries/$_salarieId/${f.name}';
          final url = client.storage
              .from('documents')
              .getPublicUrl(path);
          urls[key] = url;
        }
      }
      if (mounted) {
        setState(() {
          _fileUrls = urls;
          _loadingFiles = false;
        });
      }
    } catch (e) {
      debugPrint('Error listing documents in mobile: $e');
      if (mounted) {
        setState(() => _loadingFiles = false);
      }
    }
  }

  void _initializeFields(Salarie s) {
    _nomController.text = s.nom;
    _prenomController.text = s.prenom;
    _nomNaissanceController.text = s.nomDeNaissance;
    _genre = s.genre;
    _nsecuController.text = s.numeroSecuriteSociale ?? '';
    _dateNaissance = s.dateNaissance;
    _lieuNaissanceController.text = s.lieuNaissance ?? '';
    _nationaliteController.text = s.nationalite ?? '';
    _adresseController.text = s.adressePostale ?? '';
    _telephoneController.text = s.telephone ?? '';
    _emailController.text = s.email ?? '';
    _dateEmbauche = s.dateEmbauche;
    _typeContrat = s.typeContrat;
    _dateFinContrat = s.dateFinContrat;
    _posteController.text = s.emploiPoste ?? '';
    _cinController.text = s.cin;
    _descriptionController.text = s.description;
    _hasPieceIdentite = s.hasPieceIdentite;
    _hasCarteVitale = s.hasCarteVitale;
    _hasJustificatifDomicile = s.hasJustificatifDomicile;
    _hasContratSigne = s.hasContratSigne;
  }

  Future<void> _loadSalarieFromStateOrDb() async {
    setState(() => _isLoadingSalarie = true);
    try {
      final appState = context.read<AppState>();
      Salarie? sal;
      try {
        sal = appState.salaries.firstWhere(
          (s) => s.id == _salarieId,
          orElse: () => appState.salariesArchives.firstWhere(
            (s) => s.id == _salarieId,
          ),
        );
      } catch (_) {
        sal = null;
      }

      if (sal != null) {
        if (mounted) {
          setState(() {
            _avatarUrl = sal!.avatarUrl;
            _initializeFields(sal);
            _isLoadingSalarie = false;
          });
          _loadDocuments();
        }
      } else {
        await appState.loadSalaries();
        try {
          sal = appState.salaries.firstWhere(
            (s) => s.id == _salarieId,
            orElse: () => appState.salariesArchives.firstWhere(
              (s) => s.id == _salarieId,
            ),
          );
        } catch (_) {
          sal = null;
        }
        if (mounted) {
          setState(() {
            if (sal != null) {
              _avatarUrl = sal.avatarUrl;
              _initializeFields(sal);
            }
            _isLoadingSalarie = false;
          });
          if (sal != null) {
            _loadDocuments();
          }
        }
      }
    } catch (e) {
      debugPrint("Error loading salarie by id: $e");
      if (mounted) {
        setState(() => _isLoadingSalarie = false);
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _salarieId = widget.salarie?.id ?? widget.salarieId ?? _generateUuid();
    _avatarUrl = widget.salarie?.avatarUrl;
    
    try {
      if (widget.salarie != null) {
        _loadDocuments();
        _initializeFields(widget.salarie!);
      } else if (widget.salarieId != null) {
        _loadSalarieFromStateOrDb();
      }
    } catch (e, stack) {
      debugPrint("FATAL ERROR IN AddSalariePage initState: $e");
      debugPrint(stack.toString());
      _initError = e.toString();
      _initStackTrace = stack.toString();
    }
  }

  @override
  void didUpdateWidget(covariant AddSalariePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.salarie != oldWidget.salarie && widget.salarie != null) {
      _avatarUrl = widget.salarie!.avatarUrl;
      _initializeFields(widget.salarie!);
    }
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _nomNaissanceController.dispose();
    _nsecuController.dispose();
    _lieuNaissanceController.dispose();
    _nationaliteController.dispose();
    _adresseController.dispose();
    _telephoneController.dispose();
    _emailController.dispose();
    _posteController.dispose();
    _cinController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final appState = context.read<AppState>();
    final entrepriseId = appState.entrepriseId ?? '';

    final newSalarie = Salarie(
      id: _salarieId,
      entrepriseId: entrepriseId,
      nom: _nomController.text.trim(),
      prenom: _prenomController.text.trim(),
      nomDeNaissance: _nomNaissanceController.text.trim().isEmpty
          ? _nomController.text.trim()
          : _nomNaissanceController.text.trim(),
      genre: _genre,
      numeroSecuriteSociale: _nsecuController.text.trim().isEmpty
          ? null
          : _nsecuController.text.trim(),
      dateNaissance: _dateNaissance,
      lieuNaissance: _lieuNaissanceController.text.trim().isEmpty
          ? null
          : _lieuNaissanceController.text.trim(),
      nationalite: _nationaliteController.text.trim().isEmpty
          ? null
          : _nationaliteController.text.trim(),
      adressePostale: _adresseController.text.trim().isEmpty
          ? null
          : _adresseController.text.trim(),
      telephone: _telephoneController.text.trim().isEmpty
          ? null
          : _telephoneController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      dateEmbauche: _dateEmbauche,
      typeContrat: _typeContrat,
      dateFinContrat: _dateFinContrat,
      emploiPoste: _posteController.text.trim().isEmpty
          ? null
          : _posteController.text.trim(),
      cin: _cinController.text.trim(),
      description: _descriptionController.text.trim(),
      avatarUrl: _avatarUrl,
      hasPieceIdentite: _hasPieceIdentite,
      hasCarteVitale: _hasCarteVitale,
      hasJustificatifDomicile: _hasJustificatifDomicile,
      hasContratSigne: _hasContratSigne,
    );

    final isEditing = widget.salarie != null || widget.salarieId != null;
    if (isEditing) {
      appState.updateSalarie(newSalarie).catchError((e) {
        debugPrint('[AddSalariePage] Error updating employee: $e');
      });
    } else {
      appState.addSalarie(newSalarie).catchError((e) {
        debugPrint('[AddSalariePage] Error adding employee: $e');
      });
    }

    TopNotificationBanner.show(
      context,
      '${newSalarie.nomComplet} enregistré avec succès',
      isError: false,
    );
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    if (_initError != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Erreur Initialisation',
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w800,
              color: Colors.red,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.red),
            onPressed: () => context.pop(),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Une erreur est survenue lors de l\'initialisation des données.',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 16),
                ),
                const SizedBox(height: 16),
                Text('Erreur : $_initError', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Stacktrace :\n$_initStackTrace', style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
              ],
            ),
          ),
        ),
      );
    }

    if (_isLoadingSalarie) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.readOnly ? 'Profil Salarié' : 'Chargement...',
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.close, color: Theme.of(context).colorScheme.primary),
            onPressed: () => context.pop(),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    try {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            widget.readOnly
                ? 'Profil Salarié'
                : ((widget.salarie != null || widget.salarieId != null) ? 'Modifier Salarié' : 'Nouveau Salarié'),
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w800,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.close, color: Theme.of(context).colorScheme.primary),
            onPressed: () => context.pop(),
          ),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildAvatarHeader(),
              const SizedBox(height: 24),
              _buildSection('Informations Personnelles', [
                // Genre
                _buildLabel('Genre'),
                const SizedBox(height: 8),
                Row(
                  children: ['M', 'F'].map((g) {
                    final isSelected = _genre == g;
                    return Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: widget.readOnly ? null : () => setState(() => _genre = g),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(
                                    context,
                                  ).colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? Theme.of(context).colorScheme.primary
                                  : Theme.of(context).colorScheme.outlineVariant,
                            ),
                          ),
                          child: Text(
                            g == 'M' ? 'Masculin' : 'Féminin',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                _buildTextField(_nomController, 'Nom *', required: true),
                _buildTextField(_prenomController, 'Prénom *', required: true),
                _buildTextField(_nomNaissanceController, 'Nom de Naissance'),
                _buildTextField(
                  _nsecuController,
                  'Numéro de Sécurité Sociale',
                  keyboardType: TextInputType.number,
                ),
                _buildDateField(
                  'Date de Naissance',
                  _dateNaissance,
                  (d) => setState(() => _dateNaissance = d),
                ),
                _buildTextField(_lieuNaissanceController, 'Lieu de Naissance'),
                _buildTextField(_nationaliteController, 'Nationalité'),
                _buildTextField(_cinController, 'CIN (Carte d\'Identité)'),
              ]),
              const SizedBox(height: 20),
              _buildSection('Coordonnées', [
                _buildTextField(_adresseController, 'Adresse Postale'),
                _buildTextField(
                  _telephoneController,
                  'Téléphone',
                  keyboardType: TextInputType.phone,
                ),
                _buildTextField(
                  _emailController,
                  'Email',
                  keyboardType: TextInputType.emailAddress,
                ),
              ]),
              const SizedBox(height: 20),
              _buildSection('Informations Contractuelles', [
                _buildDateField(
                  'Date d\'Embauche',
                  _dateEmbauche,
                  (d) => setState(() => _dateEmbauche = d),
                ),
                const SizedBox(height: 8),
                _buildLabel('Type de Contrat'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['CDI', 'CDD', 'Apprentissage', 'Stage'].map((type) {
                    final isSelected = _typeContrat == type;
                    return GestureDetector(
                      onTap: widget.readOnly ? null : () => setState(() => _typeContrat = type),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).colorScheme.tertiary
                              : Theme.of(context).colorScheme.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          type,
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            color: isSelected
                                ? Colors.white
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (_typeContrat == 'CDD' || _typeContrat == 'Apprentissage' || _typeContrat == 'Stage') ...[
                  const SizedBox(height: 16),
                  _buildDateField(
                    'Date de Fin de Contrat',
                    _dateFinContrat,
                    (d) => setState(() => _dateFinContrat = d),
                  ),
                ],
                const SizedBox(height: 8),
                _buildTextField(_posteController, 'Emploi / Poste'),
                _buildTextField(
                  _descriptionController,
                  'Notes / Description',
                  maxLines: 3,
                ),
              ]),
              const SizedBox(height: 20),
              _buildSection('Pièces Jointes', [
                if (_loadingFiles) ...[
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: LinearProgressIndicator(),
                  ),
                ],
                _buildFileUpload(
                  'Pièce d\'identité',
                  _hasPieceIdentite,
                  'piece_identite',
                  (v) => setState(() => _hasPieceIdentite = v),
                ),
                _buildFileUpload(
                  'Carte Vitale',
                  _hasCarteVitale,
                  'carte_vitale',
                  (v) => setState(() => _hasCarteVitale = v),
                ),
                _buildFileUpload(
                  'Justificatif de Domicile',
                  _hasJustificatifDomicile,
                  'justificatif_domicile',
                  (v) => setState(() => _hasJustificatifDomicile = v),
                ),
                _buildFileUpload(
                  'Contrat Signé',
                  _hasContratSigne,
                  'contrat_signe',
                  (v) => setState(() => _hasContratSigne = v),
                ),
              ]),
              const SizedBox(height: 32),
              if (!widget.readOnly) ...[
                ElevatedButton(
                  onPressed: _isUploadingAvatar ? null : _save,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    (widget.salarie != null || widget.salarieId != null)
                        ? 'Mettre à jour le Salarié'
                        : 'Enregistrer le Salarié',
                    style: GoogleFonts.manrope(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ],
          ),
        ),
      );
    } catch (e, stack) {
      debugPrint("FATAL ERROR IN AddSalariePage build: $e");
      debugPrint(stack.toString());
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Erreur Rendu',
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w800,
              color: Colors.red,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.red),
            onPressed: () => context.pop(),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Une erreur est survenue lors du rendu de la page.',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red, fontSize: 16),
                ),
                const SizedBox(height: 16),
                Text('Erreur : $e', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Stacktrace :\n$stack', style: const TextStyle(fontSize: 12, fontFamily: 'monospace')),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: GoogleFonts.manrope(
              fontWeight: FontWeight.w800,
              fontSize: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String label, {
    TextInputType? keyboardType,
    bool required = false,
    int? maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel(label),
          const SizedBox(height: 6),
          TextFormField(
            controller: ctrl,
            keyboardType: keyboardType,
            maxLines: maxLines,
            readOnly: widget.readOnly,
            validator: required && !widget.readOnly
                ? (v) => v == null || v.isEmpty ? 'Champ requis' : null
                : null,
            decoration: InputDecoration(hintText: label),
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(
    String label,
    DateTime? value,
    Function(DateTime) onPick,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildLabel(label),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: widget.readOnly
                ? null
                : () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: value ?? DateTime(1990),
                      firstDate: DateTime(1900),
                      lastDate: DateTime(2100),
                      locale: const Locale('fr', 'FR'),
                    );
                    if (picked != null) onPick(picked);
                  },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 18,
                    color: Theme.of(context).colorScheme.outline,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    value != null
                        ? DateFormat('dd/MM/yyyy').format(value)
                        : 'JJ/MM/AAAA',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: value != null
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context).colorScheme.outlineVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _downloadOrViewFile(String label, String? url) async {
    if (url == null || url.isEmpty) {
      TopNotificationBanner.show(
        context,
        'Aucun lien disponible pour ce fichier.',
        isError: true,
      );
      return;
    }
    MobileFilePreviewer.show(context, url, label);
  }

  Future<void> _pickAndUploadFile(String label, String docType, Function(bool) onChanged) async {
    try {
      final result = await fp.FilePicker.pickFiles(type: fp.FileType.any);
      if (result == null || result.files.isEmpty) return;
      
      final file = result.files.first;
      final localPath = file.path;
      if (localPath == null) return;
 
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
 
      final appState = context.read<AppState>();
      final entrepriseId = appState.entrepriseId ?? '';
      final client = Supabase.instance.client;
      final ext = file.extension ?? 'bin';
      
      final fileName = '$docType.$ext';
      final storagePath = 'salaries/$_salarieId/$fileName';
 
      final fileObject = io.File(localPath);
      await client.storage.from('documents').upload(
        storagePath,
        fileObject,
        fileOptions: const FileOptions(upsert: true),
      );
 
      final publicUrl = client.storage.from('documents').getPublicUrl(storagePath);
 
      // Save to 'public.fichiers' table
      final salarieNom = '${_prenomController.text.trim()} ${_nomController.text.trim()}';
 
      await client.from('fichiers').insert({
        'entreprise_id': entrepriseId,
        'nom': '$label - ${salarieNom.trim().isEmpty ? 'Nouveau Salarié' : salarieNom.trim()}',
        'url': publicUrl,
        'est_envoye_par_user': true,
        'type_document': 'autre',
      });
 
      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading dialog
 
      TopNotificationBanner.show(
        context,
        'Fichier "$fileName" téléversé avec succès',
        isError: false,
      );
 
      setState(() {
        _fileUrls[docType] = publicUrl;
      });

      onChanged(true);
    } catch (e) {
      debugPrint('[AddSalariePage] Upload error: $e');
      if (!mounted) return;
      Navigator.pop(context); // Dismiss loading dialog
      TopNotificationBanner.show(
        context,
        'Erreur lors du téléversement : $e',
        isError: true,
      );
    }
  }
 
  Widget _buildFileUpload(String label, bool value, String docType, Function(bool) onChanged) {
    final fileUrl = _fileUrls[docType];
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),

          OutlinedButton.icon(
            onPressed: widget.readOnly
                ? (value && fileUrl != null ? () => _downloadOrViewFile(label, fileUrl) : null)
                : () => _pickAndUploadFile(label, docType, onChanged),
            icon: Icon(
              widget.readOnly
                  ? (value ? Icons.file_present : Icons.block)
                  : (value ? Icons.check_circle : Icons.upload_file),
              color: value
                  ? Colors.green
                  : (widget.readOnly ? Colors.grey : Theme.of(context).colorScheme.tertiary),
              size: 18,
            ),
            label: Text(
              widget.readOnly
                  ? (value ? 'Visualiser' : 'Non fourni')
                  : (value ? 'Modifié' : 'Charger'),
              style: GoogleFonts.inter(
                color: value
                    ? Colors.green
                    : (widget.readOnly ? Colors.grey : Theme.of(context).colorScheme.tertiary),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(120, 48),
              side: BorderSide(
                color: value
                    ? Colors.green
                    : (widget.readOnly ? Colors.grey : Theme.of(context).colorScheme.tertiary),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarHeader() {
    final prenom = _prenomController.text.trim();
    final nom = _nomController.text.trim();
    final initials = '${prenom.isNotEmpty ? prenom[0] : ''}${nom.isNotEmpty ? nom[0] : ''}'.toUpperCase();
    final hasInitials = initials.isNotEmpty;
    final hasAvatar = _avatarUrl != null && _avatarUrl!.isNotEmpty;
    
    VoidCallback? handleTap;
    if (_isUploadingAvatar) {
      handleTap = null;
    } else if (hasAvatar) {
      handleTap = () {
        MobileFilePreviewer.show(context, _avatarUrl!, "Photo de profil");
      };
    } else {
      handleTap = widget.readOnly ? null : _pickAndUploadAvatar;
    }

    return Center(
      child: GestureDetector(
        onTap: handleTap,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  width: 4,
                ),
              ),
              child: SalarieAvatar(
                avatarUrl: _avatarUrl,
                initials: initials,
                radius: 60,
                backgroundColor: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.4),
                textStyle: GoogleFonts.manrope(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.primary,
                ),
                iconSize: 56,
              ),
            ),
            if (_isUploadingAvatar)
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.black38,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              ),
            if (!widget.readOnly && !_isUploadingAvatar)
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: _pickAndUploadAvatar,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.edit,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadAvatar() async {
    final appState = context.read<AppState>();
    final theme = Theme.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final ImageSource? source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'Modifier la photo de profil',
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: Text('Choisir dans la galerie', style: GoogleFonts.inter()),
                onTap: () => Navigator.pop(context, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: Text('Prendre une photo', style: GoogleFonts.inter()),
                onTap: () => Navigator.pop(context, ImageSource.camera),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );

    if (source == null) return;

    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() => _isUploadingAvatar = true);

      final Uint8List bytes = await pickedFile.readAsBytes();
      
      final publicUrl = await appState.uploadSalarieAvatar(
        _salarieId,
        bytes,
        pickedFile.name,
      );

      if (publicUrl != null) {
        setState(() {
          _avatarUrl = publicUrl;
        });
        if (mounted) {
          TopNotificationBanner.show(
            context,
            'Photo de profil mise à jour avec succès',
            isError: false,
          );
        }
      } else {
        if (mounted) {
          TopNotificationBanner.show(
            context,
            'Erreur lors de la mise à jour de la photo de profil',
            isError: true,
          );
        }
      }
    } catch (e) {
      debugPrint('[AddSalariePage] Error picking/uploading avatar: $e');
      if (mounted) {
        TopNotificationBanner.show(
          context,
          'Erreur : $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingAvatar = false);
      }
    }
  }

  Widget _buildLabel(String text) {
    return Text(
      text.replaceAll(' *', '').toUpperCase(),
      style: GoogleFonts.inter(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.primary,
        letterSpacing: 1.2,
      ),
    );
  }
}
