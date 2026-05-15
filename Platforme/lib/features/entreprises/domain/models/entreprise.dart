class Entreprise {
  final String id;
  // Générales
  final String nom;
  final String nomGerant;
  final String description;
  final String email;
  final String motDePasse;
  final String statut;
  final DateTime dateCreation;
  final DateTime? dateMiseAJour;
  final String adressePhysique;
  final String telephone;
  final String? logoUrl;
  final int effectif;

  // Juridiques
  final String nSiren;
  final String nSiret;
  final String formeJuridique;
  final String nTva;
  final String nRcs;
  final String capitaleSocial;
  final String codeApe;

  Entreprise({
    required this.id,
    required this.nom,
    required this.nomGerant,
    required this.description,
    required this.email,
    required this.motDePasse,
    required this.statut,
    required this.dateCreation,
    this.dateMiseAJour,
    this.adressePhysique = '',
    this.telephone = '',
    this.logoUrl,
    this.effectif = 0,
    this.nSiren = '',
    this.nSiret = '',
    this.formeJuridique = '',
    this.nTva = '',
    this.nRcs = '',
    this.capitaleSocial = '',
    this.codeApe = '',
  });

  /// Construction à partir d'une ligne Supabase `entreprises`.
  factory Entreprise.fromJson(Map<String, dynamic> json) {
    return Entreprise(
      id: json['id'] as String,
      nom: json['raison_sociale'] as String? ?? '',
      nomGerant: json['nom_gerant'] as String? ?? '',
      description: json['description'] as String? ?? '',
      email: json['email'] as String? ?? '',
      motDePasse: '', // jamais stocké côté client
      statut: json['statut'] as String? ?? 'EN COURS',
      dateCreation: json['cree_le'] != null
          ? DateTime.parse(json['cree_le'] as String)
          : DateTime.now(),
      dateMiseAJour: json['mis_a_jour_le'] != null
          ? DateTime.tryParse(json['mis_a_jour_le'] as String)
          : null,
      adressePhysique: json['adresse'] as String? ?? '',
      telephone: json['telephone'] as String? ?? '',
      logoUrl: json['logo_url'] as String?,
      effectif: json['effectif'] as int? ?? 0,
      nSiren: json['n_siren'] as String? ?? '',
      nSiret: json['siret'] as String? ?? '',
      formeJuridique: json['forme_juridique'] as String? ?? '',
      nTva: json['tva_intracommunautaire'] as String? ?? '',
      nRcs: json['n_rcs'] as String? ?? '',
      capitaleSocial: json['capital_social'] as String? ?? '',
      codeApe: json['code_ape'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'raison_sociale': nom,
        'nom_gerant': nomGerant,
        'description': description,
        'email': email,
        'statut': statut,
        'adresse': adressePhysique,
        'telephone': telephone,
        'logo_url': logoUrl,
        'effectif': effectif,
        'n_siren': nSiren,
        'siret': nSiret,
        'forme_juridique': formeJuridique,
        'tva_intracommunautaire': nTva,
        'n_rcs': nRcs,
        'capital_social': capitaleSocial,
        'code_ape': codeApe,
      };

  Entreprise copyWith({
    String? id,
    String? nom,
    String? nomGerant,
    String? description,
    String? email,
    String? motDePasse,
    String? statut,
    DateTime? dateCreation,
    DateTime? dateMiseAJour,
    String? adressePhysique,
    String? telephone,
    String? logoUrl,
    int? effectif,
    String? nSiren,
    String? nSiret,
    String? formeJuridique,
    String? nTva,
    String? nRcs,
    String? capitaleSocial,
    String? codeApe,
  }) {
    return Entreprise(
      id: id ?? this.id,
      nom: nom ?? this.nom,
      nomGerant: nomGerant ?? this.nomGerant,
      description: description ?? this.description,
      email: email ?? this.email,
      motDePasse: motDePasse ?? this.motDePasse,
      statut: statut ?? this.statut,
      dateCreation: dateCreation ?? this.dateCreation,
      dateMiseAJour: dateMiseAJour ?? this.dateMiseAJour,
      adressePhysique: adressePhysique ?? this.adressePhysique,
      telephone: telephone ?? this.telephone,
      logoUrl: logoUrl ?? this.logoUrl,
      effectif: effectif ?? this.effectif,
      nSiren: nSiren ?? this.nSiren,
      nSiret: nSiret ?? this.nSiret,
      formeJuridique: formeJuridique ?? this.formeJuridique,
      nTva: nTva ?? this.nTva,
      nRcs: nRcs ?? this.nRcs,
      capitaleSocial: capitaleSocial ?? this.capitaleSocial,
      codeApe: codeApe ?? this.codeApe,
    );
  }
}
