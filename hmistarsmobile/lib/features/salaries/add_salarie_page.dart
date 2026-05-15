import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/providers/app_state.dart';
import '../../core/models/models.dart';
import '../../core/theme/app_theme.dart';

class AddSalariePage extends StatefulWidget {
  final Salarie? salarie;
  const AddSalariePage({super.key, this.salarie});

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
  bool _isSaving = false;

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

  // Documents joints
  bool _hasPieceIdentite = false;
  bool _hasCarteVitale = false;
  bool _hasJustificatifDomicile = false;
  bool _hasContratSigne = false;

  @override
  void initState() {
    super.initState();
    if (widget.salarie != null) {
      final s = widget.salarie!;
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
      _hasPieceIdentite = s.hasPieceIdentite;
      _hasCarteVitale = s.hasCarteVitale;
      _hasJustificatifDomicile = s.hasJustificatifDomicile;
      _hasContratSigne = s.hasContratSigne;
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
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final appState = context.read<AppState>();
    final entrepriseId = appState.entrepriseId ?? '';

    setState(() => _isSaving = true);

    try {
      final newSalarie = Salarie(
        id: widget.salarie?.id ?? '',
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
        hasPieceIdentite: _hasPieceIdentite,
        hasCarteVitale: _hasCarteVitale,
        hasJustificatifDomicile: _hasJustificatifDomicile,
        hasContratSigne: _hasContratSigne,
      );

      if (widget.salarie != null) {
        await appState.updateSalarie(newSalarie);
      } else {
        await appState.addSalarie(newSalarie);
      }

      if (mounted) {
        context.pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${newSalarie.nomComplet} enregistré avec succès'),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.salarie != null ? 'Modifier Salarié' : 'Nouveau Salarié',
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w800,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.close, color: Theme.of(context).colorScheme.primary),
          onPressed: () => context.pop(),
        ),
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: _save,
              child: Text(
                'Enregistrer',
                style: GoogleFonts.manrope(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.tertiary,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
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
                      onTap: () => setState(() => _genre = g),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 12,
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
                children: ['CDI', 'CDD', 'Apprentissage'].map((type) {
                  final isSelected = _typeContrat == type;
                  return GestureDetector(
                    onTap: () => setState(() => _typeContrat = type),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
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
              if (_typeContrat == 'CDD' || _typeContrat == 'Apprentissage') ...[
                const SizedBox(height: 16),
                _buildDateField(
                  'Date de Fin de Contrat',
                  _dateFinContrat,
                  (d) => setState(() => _dateFinContrat = d),
                ),
              ],
              const SizedBox(height: 8),
              _buildTextField(_posteController, 'Emploi / Poste'),
            ]),
            const SizedBox(height: 20),
            _buildSection('Pièces Jointes', [
              _buildFileUpload(
                'Pièce d\'identité',
                _hasPieceIdentite,
                (v) => setState(() => _hasPieceIdentite = v),
              ),
              _buildFileUpload(
                'Carte Vitale',
                _hasCarteVitale,
                (v) => setState(() => _hasCarteVitale = v),
              ),
              _buildFileUpload(
                'Justificatif de Domicile',
                _hasJustificatifDomicile,
                (v) => setState(() => _hasJustificatifDomicile = v),
              ),
              _buildFileUpload(
                'Contrat Signé',
                _hasContratSigne,
                (v) => setState(() => _hasContratSigne = v),
              ),
            ]),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      widget.salarie != null
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
        ),
      ),
    );
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
            validator: required
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
            onTap: () async {
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

  Widget _buildFileUpload(String label, bool value, Function(bool) onChanged) {
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
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Sélecteur de fichier simulé')),
              );
              Future.delayed(const Duration(milliseconds: 600), () {
                onChanged(true);
              });
            },
            icon: Icon(
              value ? Icons.check_circle : Icons.upload_file,
              color: value
                  ? Colors.green
                  : Theme.of(context).colorScheme.tertiary,
              size: 18,
            ),
            label: Text(
              value ? 'Ajouté' : 'Charger',
              style: GoogleFonts.inter(
                color: value
                    ? Colors.green
                    : Theme.of(context).colorScheme.tertiary,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color: value
                    ? Colors.green
                    : Theme.of(context).colorScheme.tertiary,
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
