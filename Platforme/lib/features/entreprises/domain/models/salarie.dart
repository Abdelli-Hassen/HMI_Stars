class Salarie {
  final String id;
  final String entrepriseId;
  final String genre; // 'M' ou 'F'
  final String nom;
  final String prenom;
  final String nomNaissance;
  final String cin;
  final String numeroSecuriteSociale;
  final DateTime? dateNaissance;
  final String lieuNaissance;
  final String nationalite;
  final String adressePostale;
  final String telephone;
  final String email;
  final DateTime? dateEmbauche;
  final String typeContrat; // 'CDI', 'CDD', 'Apprentissage', 'Stage'
  final DateTime? dateFinContrat;
  final String emploiPoste;

  // Indicateurs de pièces jointes
  final bool aPieceIdentite;
  final bool aCarteVitale;
  final bool aJustificatifDomicile;
  final bool aContratSigne;

  final String? avatarUrl;
  final bool estActif; // true = en poste, false = archivé

  Salarie({
    required this.id,
    required this.entrepriseId,
    this.genre = '',
    required this.nom,
    required this.prenom,
    this.nomNaissance = '',
    this.cin = '',
    this.numeroSecuriteSociale = '',
    this.dateNaissance,
    this.lieuNaissance = '',
    this.nationalite = '',
    this.adressePostale = '',
    this.telephone = '',
    this.email = '',
    this.dateEmbauche,
    required this.typeContrat,
    this.dateFinContrat,
    this.emploiPoste = '',
    this.aPieceIdentite = false,
    this.aCarteVitale = false,
    this.aJustificatifDomicile = false,
    this.aContratSigne = false,
    this.avatarUrl,
    this.estActif = true,
  });

  String get nomComplet => '$prenom $nom'.trim();

  factory Salarie.fromJson(Map<String, dynamic> json) {
    return Salarie(
      id: json['id'] as String,
      entrepriseId: json['entreprise_id'] as String,
      genre: json['genre'] as String? ?? '',
      nom: json['nom'] as String? ?? '',
      prenom: json['prenom'] as String? ?? '',
      nomNaissance: json['nom_de_naissance'] as String? ?? '',
      cin: '',
      numeroSecuriteSociale: json['numero_securite_sociale'] as String? ?? '',
      dateNaissance: json['date_naissance'] != null
          ? DateTime.tryParse(json['date_naissance'] as String)
          : null,
      lieuNaissance: json['lieu_naissance'] as String? ?? '',
      nationalite: json['nationalite'] as String? ?? '',
      adressePostale: json['adresse_postale'] as String? ?? '',
      telephone: json['telephone'] as String? ?? '',
      email: json['email'] as String? ?? '',
      dateEmbauche: json['date_embauche'] != null
          ? DateTime.tryParse(json['date_embauche'] as String)
          : null,
      typeContrat: json['type_contrat'] as String? ?? 'CDI',
      dateFinContrat: json['date_fin_contrat'] != null
          ? DateTime.tryParse(json['date_fin_contrat'] as String)
          : null,
      emploiPoste: json['emploi_poste'] as String? ?? '',
      aPieceIdentite: json['a_piece_identite'] as bool? ?? false,
      aCarteVitale: json['a_carte_vitale'] as bool? ?? false,
      aJustificatifDomicile: json['a_justificatif_domicile'] as bool? ?? false,
      aContratSigne: json['a_contrat_signe'] as bool? ?? false,
      avatarUrl: json['avatar_url'] as String?,
      estActif: !(json['est_archive'] as bool? ?? false),
    );
  }

  Map<String, dynamic> toJson() => {
        'entreprise_id': entrepriseId,
        'genre': genre,
        'nom': nom,
        'prenom': prenom,
        'nom_de_naissance': nomNaissance,
        'numero_securite_sociale': numeroSecuriteSociale,
        'date_naissance': dateNaissance?.toIso8601String().split('T').first,
        'lieu_naissance': lieuNaissance,
        'nationalite': nationalite,
        'adresse_postale': adressePostale,
        'telephone': telephone,
        'email': email,
        'date_embauche': dateEmbauche?.toIso8601String().split('T').first,
        'type_contrat': typeContrat,
        'date_fin_contrat': dateFinContrat?.toIso8601String().split('T').first,
        'emploi_poste': emploiPoste,
        'est_archive': !estActif,
        'avatar_url': avatarUrl,
        'a_piece_identite': aPieceIdentite,
        'a_carte_vitale': aCarteVitale,
        'a_justificatif_domicile': aJustificatifDomicile,
        'a_contrat_signe': aContratSigne,
      };

  Salarie copyWith({
    String? id,
    String? entrepriseId,
    String? genre,
    String? nom,
    String? prenom,
    String? nomNaissance,
    String? cin,
    String? numeroSecuriteSociale,
    DateTime? dateNaissance,
    String? lieuNaissance,
    String? nationalite,
    String? adressePostale,
    String? telephone,
    String? email,
    DateTime? dateEmbauche,
    String? typeContrat,
    DateTime? dateFinContrat,
    String? emploiPoste,
    bool? aPieceIdentite,
    bool? aCarteVitale,
    bool? aJustificatifDomicile,
    bool? aContratSigne,
    String? avatarUrl,
    bool? estActif,
  }) {
    return Salarie(
      id: id ?? this.id,
      entrepriseId: entrepriseId ?? this.entrepriseId,
      genre: genre ?? this.genre,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      nomNaissance: nomNaissance ?? this.nomNaissance,
      cin: cin ?? this.cin,
      numeroSecuriteSociale: numeroSecuriteSociale ?? this.numeroSecuriteSociale,
      dateNaissance: dateNaissance ?? this.dateNaissance,
      lieuNaissance: lieuNaissance ?? this.lieuNaissance,
      nationalite: nationalite ?? this.nationalite,
      adressePostale: adressePostale ?? this.adressePostale,
      telephone: telephone ?? this.telephone,
      email: email ?? this.email,
      dateEmbauche: dateEmbauche ?? this.dateEmbauche,
      typeContrat: typeContrat ?? this.typeContrat,
      dateFinContrat: dateFinContrat ?? this.dateFinContrat,
      emploiPoste: emploiPoste ?? this.emploiPoste,
      aPieceIdentite: aPieceIdentite ?? this.aPieceIdentite,
      aCarteVitale: aCarteVitale ?? this.aCarteVitale,
      aJustificatifDomicile: aJustificatifDomicile ?? this.aJustificatifDomicile,
      aContratSigne: aContratSigne ?? this.aContratSigne,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      estActif: estActif ?? this.estActif,
    );
  }
}
