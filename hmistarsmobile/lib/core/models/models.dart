// Models with Supabase serialization

// ----- Salarie (Employee) -----
class Salarie {
  final String id;
  final String entrepriseId;
  final String nom;
  final String prenom;
  final String nomDeNaissance;
  final String? genre; // 'M' or 'F'
  final String? numeroSecuriteSociale;
  final DateTime? dateNaissance;
  final String? lieuNaissance;
  final String? nationalite;
  final String? adressePostale;
  final String? telephone;
  final String? email;
  final DateTime? dateEmbauche;
  final String typeContrat; // 'CDI', 'CDD', 'Apprentissage'
  final DateTime? dateFinContrat;
  final String? emploiPoste;
  final bool isArchived;
  final String? avatarUrl;
  final String cin;
  final String description;
  // Pieces jointes
  final bool hasPieceIdentite;
  final bool hasCarteVitale;
  final bool hasJustificatifDomicile;
  final bool hasContratSigne;

  const Salarie({
    required this.id,
    required this.entrepriseId,
    required this.nom,
    required this.prenom,
    required this.nomDeNaissance,
    this.genre,
    this.numeroSecuriteSociale,
    this.dateNaissance,
    this.lieuNaissance,
    this.nationalite,
    this.adressePostale,
    this.telephone,
    this.email,
    this.dateEmbauche,
    required this.typeContrat,
    this.dateFinContrat,
    this.emploiPoste,
    this.isArchived = false,
    this.avatarUrl,
    this.cin = '',
    this.description = '',
    this.hasPieceIdentite = false,
    this.hasCarteVitale = false,
    this.hasJustificatifDomicile = false,
    this.hasContratSigne = false,
  });

  String get nomComplet => '$prenom $nom';

  factory Salarie.fromJson(Map<String, dynamic> json) {
    return Salarie(
      id: json['id'] as String,
      entrepriseId: json['entreprise_id'] as String,
      nom: json['nom'] as String? ?? '',
      prenom: json['prenom'] as String? ?? '',
      nomDeNaissance: json['nom_de_naissance'] as String? ?? '',
      genre: json['genre'] as String?,
      numeroSecuriteSociale: json['numero_securite_sociale'] as String?,
      dateNaissance: json['date_naissance'] != null
          ? DateTime.tryParse(json['date_naissance'] as String)
          : null,
      lieuNaissance: json['lieu_naissance'] as String?,
      nationalite: json['nationalite'] as String?,
      adressePostale: json['adresse_postale'] as String?,
      telephone: json['telephone'] as String?,
      email: json['email'] as String?,
      dateEmbauche: json['date_embauche'] != null
          ? DateTime.tryParse(json['date_embauche'] as String)
          : null,
      typeContrat: json['type_contrat'] as String? ?? 'CDI',
      dateFinContrat: json['date_fin_contrat'] != null
          ? DateTime.tryParse(json['date_fin_contrat'] as String)
          : null,
      emploiPoste: json['emploi_poste'] as String?,
      isArchived: json['est_archive'] as bool? ?? false,
      avatarUrl: json['avatar_url'] as String?,
      cin: json['cin'] as String? ?? '',
      description: json['description'] as String? ?? '',
      hasPieceIdentite: json['a_piece_identite'] as bool? ?? false,
      hasCarteVitale: json['a_carte_vitale'] as bool? ?? false,
      hasJustificatifDomicile:
          json['a_justificatif_domicile'] as bool? ?? false,
      hasContratSigne: json['a_contrat_signe'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'entreprise_id': entrepriseId,
      'nom': nom,
      'prenom': prenom,
      'nom_de_naissance': nomDeNaissance,
      'genre': genre,
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
      'est_archive': isArchived,
      'avatar_url': avatarUrl,
      'cin': cin,
      'description': description,
      'a_piece_identite': hasPieceIdentite,
      'a_carte_vitale': hasCarteVitale,
      'a_justificatif_domicile': hasJustificatifDomicile,
      'a_contrat_signe': hasContratSigne,
    };
    if (id.isNotEmpty) {
      map['id'] = id;
    }
    return map;
  }

  Salarie copyWith({
    String? id,
    String? entrepriseId,
    String? nom,
    String? prenom,
    String? nomDeNaissance,
    String? genre,
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
    bool? isArchived,
    String? avatarUrl,
    String? cin,
    String? description,
    bool? hasPieceIdentite,
    bool? hasCarteVitale,
    bool? hasJustificatifDomicile,
    bool? hasContratSigne,
  }) {
    return Salarie(
      id: id ?? this.id,
      entrepriseId: entrepriseId ?? this.entrepriseId,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      nomDeNaissance: nomDeNaissance ?? this.nomDeNaissance,
      genre: genre ?? this.genre,
      numeroSecuriteSociale:
          numeroSecuriteSociale ?? this.numeroSecuriteSociale,
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
      isArchived: isArchived ?? this.isArchived,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      cin: cin ?? this.cin,
      description: description ?? this.description,
      hasPieceIdentite: hasPieceIdentite ?? this.hasPieceIdentite,
      hasCarteVitale: hasCarteVitale ?? this.hasCarteVitale,
      hasJustificatifDomicile:
          hasJustificatifDomicile ?? this.hasJustificatifDomicile,
      hasContratSigne: hasContratSigne ?? this.hasContratSigne,
    );
  }
}

// ----- PointageJour -----
enum StatutJour { complet, incomplet, absent }

class PointageEntree {
  final String? id; // null when not yet saved to DB
  final String salarieId;
  final String entrepriseId;
  final DateTime date;
  final bool estPointe;
  final String? note;

  const PointageEntree({
    this.id,
    required this.salarieId,
    required this.entrepriseId,
    required this.date,
    required this.estPointe,
    this.note,
  });

  factory PointageEntree.fromJson(Map<String, dynamic> json) {
    return PointageEntree(
      id: json['id'] as String?,
      salarieId: json['salarie_id'] as String,
      entrepriseId: json['entreprise_id'] as String,
      date: DateTime.parse(json['date'] as String),
      estPointe: json['est_pointe'] as bool? ?? false,
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'salarie_id': salarieId,
      'entreprise_id': entrepriseId,
      'date': date.toIso8601String().split('T').first,
      'est_pointe': estPointe,
      'note': note,
    };
  }

  PointageEntree copyWith({bool? estPointe, String? note}) {
    return PointageEntree(
      id: id,
      salarieId: salarieId,
      entrepriseId: entrepriseId,
      date: date,
      estPointe: estPointe ?? this.estPointe,
      note: note ?? this.note,
    );
  }
}

class PointageJour {
  final DateTime date;
  final List<PointageEntree> entrees;

  const PointageJour({required this.date, required this.entrees});

  StatutJour get statut {
    if (entrees.isEmpty) return StatutJour.absent;
    final totalPointed = entrees.where((e) => e.estPointe).length;
    if (totalPointed == 0) return StatutJour.absent;
    if (totalPointed == entrees.length) return StatutJour.complet;
    return StatutJour.incomplet;
  }

  int get nombrePointes => entrees.where((e) => e.estPointe).length;
  int get total => entrees.length;
}

// ----- Message -----
enum TypeDocument { fournisseur, releve_bancaire, chiffre_affaires, autre, kbis, tva, siret, rib, statuts, media }

extension TypeDocumentExtension on TypeDocument {
  String get value {
    switch (this) {
      case TypeDocument.fournisseur:
        return 'fournisseur';
      case TypeDocument.releve_bancaire:
        return 'releve_bancaire';
      case TypeDocument.chiffre_affaires:
        return 'chiffre_affaires';
      case TypeDocument.autre:
        return 'autre';
      case TypeDocument.kbis:
        return 'kbis';
      case TypeDocument.tva:
        return 'tva';
      case TypeDocument.siret:
        return 'siret';
      case TypeDocument.rib:
        return 'rib';
      case TypeDocument.statuts:
        return 'statuts';
      case TypeDocument.media:
        return 'media';
    }
  }

  static TypeDocument fromString(String s) {
    switch (s.toLowerCase()) {
      case 'fournisseur':
        return TypeDocument.fournisseur;
      case 'releve_bancaire':
        return TypeDocument.releve_bancaire;
      case 'chiffre_affaires':
        return TypeDocument.chiffre_affaires;
      case 'kbis':
        return TypeDocument.kbis;
      case 'tva':
        return TypeDocument.tva;
      case 'siret':
        return TypeDocument.siret;
      case 'rib':
        return TypeDocument.rib;
      case 'statuts':
        return TypeDocument.statuts;
      case 'media':
        return TypeDocument.media;
      default:
        return TypeDocument.autre;
    }
  }
}

class Message {
  final String id;
  final String entrepriseId;
  final String contenu;
  final DateTime dateEnvoi;
  final bool estEnvoyePar; // true = sent by user, false = received from HMI
  final String? fichierUrl;
  final String? fichierNom;
  final TypeDocument? typeDocument;
  final bool estFichier;
  final bool estLu;
  final String? userId;
  final String? contactId;

  const Message({
    required this.id,
    required this.entrepriseId,
    required this.contenu,
    required this.dateEnvoi,
    required this.estEnvoyePar,
    this.fichierUrl,
    this.fichierNom,
    this.typeDocument,
    this.estFichier = false,
    this.estLu = false,
    this.userId,
    this.contactId,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    final dateStr = json['date_envoi'] as String;
    final parsedDate = dateStr.endsWith('Z') || dateStr.contains('+')
        ? DateTime.parse(dateStr)
        : DateTime.parse('${dateStr}Z');

    final rawContenu = json['contenu'] as String? ?? '';
    final match = RegExp(r'<!--contact:([a-zA-Z0-9\-]+)-->').firstMatch(rawContenu);
    final contactId = match?.group(1);
    final cleanContenu = rawContenu.replaceAll(RegExp(r'<!--contact:[a-zA-Z0-9\-]+-->'), '');

    return Message(
      id: json['id'] as String,
      entrepriseId: json['entreprise_id'] as String,
      contenu: cleanContenu,
      dateEnvoi: parsedDate.toLocal(),
      estEnvoyePar: json['est_envoye_par_user'] as bool? ?? true,
      fichierUrl: json['fichier_url'] as String?,
      fichierNom: json['fichier_nom'] as String?,
      typeDocument: json['type_document'] != null
          ? TypeDocumentExtension.fromString(json['type_document'] as String)
          : null,
      estFichier: json['est_fichier'] as bool? ?? false,
      estLu: json['est_lu'] as bool? ?? false,
      userId: json['user_id'] as String?,
      contactId: contactId,
    );
  }

  Map<String, dynamic> toJson() {
    final taggedContenu = contactId != null ? '<!--contact:$contactId-->$contenu' : contenu;
    return {
      'entreprise_id': entrepriseId,
      'contenu': taggedContenu,
      'est_envoye_par_user': estEnvoyePar,
      'fichier_url': fichierUrl,
      'fichier_nom': fichierNom,
      'type_document': typeDocument?.value,
      'est_fichier': estFichier,
      'est_lu': estLu,
    };
  }

  Message copyWith({
    String? id,
    String? entrepriseId,
    String? contenu,
    DateTime? dateEnvoi,
    bool? estEnvoyePar,
    String? fichierUrl,
    String? fichierNom,
    TypeDocument? typeDocument,
    bool? estFichier,
    bool? estLu,
    String? userId,
    String? contactId,
  }) {
    return Message(
      id: id ?? this.id,
      entrepriseId: entrepriseId ?? this.entrepriseId,
      contenu: contenu ?? this.contenu,
      dateEnvoi: dateEnvoi ?? this.dateEnvoi,
      estEnvoyePar: estEnvoyePar ?? this.estEnvoyePar,
      fichierUrl: fichierUrl ?? this.fichierUrl,
      fichierNom: fichierNom ?? this.fichierNom,
      typeDocument: typeDocument ?? this.typeDocument,
      estFichier: estFichier ?? this.estFichier,
      estLu: estLu ?? this.estLu,
      userId: userId ?? this.userId,
      contactId: contactId ?? this.contactId,
    );
  }
}

// ----- Avertissement Template -----
enum TypeAvertissement { ficheAvertissement, convocation, information }

extension TypeAvertissementExtension on TypeAvertissement {
  String get value {
    switch (this) {
      case TypeAvertissement.ficheAvertissement:
        return 'ficheAvertissement';
      case TypeAvertissement.convocation:
        return 'convocation';
      case TypeAvertissement.information:
        return 'information';
    }
  }

  static TypeAvertissement fromString(String s) {
    switch (s) {
      case 'ficheAvertissement':
        return TypeAvertissement.ficheAvertissement;
      case 'convocation':
        return TypeAvertissement.convocation;
      default:
        return TypeAvertissement.information;
    }
  }
}

class TemplateAvertissement {
  final String id;
  final String? entrepriseId; // null = global template
  final String titre;
  final String contenu;
  final TypeAvertissement type;

  const TemplateAvertissement({
    required this.id,
    this.entrepriseId,
    required this.titre,
    required this.contenu,
    required this.type,
  });

  factory TemplateAvertissement.fromJson(Map<String, dynamic> json) {
    return TemplateAvertissement(
      id: json['id'] as String,
      entrepriseId: json['entreprise_id'] as String?,
      titre: json['titre'] as String,
      contenu: json['contenu'] as String,
      type: TypeAvertissementExtension.fromString(json['type'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'entreprise_id': entrepriseId,
      'titre': titre,
      'contenu': contenu,
      'type': type.value,
    };
  }

  TemplateAvertissement copyWith({String? contenu}) {
    return TemplateAvertissement(
      id: id,
      entrepriseId: entrepriseId,
      titre: titre,
      contenu: contenu ?? this.contenu,
      type: type,
    );
  }
}

// ----- Parametres / Client -----
class ClientParametres {
  final String id;
  final String raisonSociale;
  final String siret;
  final String? telephone;
  final String? email;
  final String? adresse;
  final String? logoUrl;
  final String? tvaIntracommunautaire;
  final String? formeJuridique;
  final String? capitalSocial;
  final String? codeAPE;
  final String? nomGerant;
  final String? description;
  final String? nSiren;
  final String? nRcs;

  const ClientParametres({
    required this.id,
    required this.raisonSociale,
    required this.siret,
    this.telephone,
    this.email,
    this.adresse,
    this.logoUrl,
    this.tvaIntracommunautaire,
    this.formeJuridique,
    this.capitalSocial,
    this.codeAPE,
    this.nomGerant,
    this.description,
    this.nSiren,
    this.nRcs,
  });

  factory ClientParametres.fromJson(Map<String, dynamic> json) {
    String? logoUrl = json['logo_url'] as String?;
    if (logoUrl != null && logoUrl.startsWith('http')) {
      final cleanUrl = logoUrl.split('?').first;
      logoUrl = '$cleanUrl?t=${DateTime.now().millisecondsSinceEpoch}';
    }

    return ClientParametres(
      id: json['id'] as String,
      raisonSociale: json['raison_sociale'] as String,
      siret: json['siret'] as String,
      telephone: json['telephone'] as String?,
      email: json['email'] as String?,
      adresse: json['adresse'] as String?,
      logoUrl: logoUrl,
      tvaIntracommunautaire: json['tva_intracommunautaire'] as String?,
      formeJuridique: json['forme_juridique'] as String?,
      capitalSocial: json['capital_social'] as String?,
      codeAPE: json['code_ape'] as String?,
      nomGerant: json['nom_gerant'] as String?,
      description: json['description'] as String?,
      nSiren: json['n_siren'] as String?,
      nRcs: json['n_rcs'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'raison_sociale': raisonSociale,
      'siret': siret,
      'telephone': telephone,
      'email': email,
      'adresse': adresse,
      'logo_url': logoUrl,
      'tva_intracommunautaire': tvaIntracommunautaire,
      'forme_juridique': formeJuridique,
      'capital_social': capitalSocial,
      'code_ape': codeAPE,
      'nom_gerant': nomGerant,
      'description': description,
      'n_siren': nSiren,
      'n_rcs': nRcs,
    };
    map.remove('name');
    return map;
  }

  ClientParametres copyWith({
    String? raisonSociale,
    String? siret,
    String? telephone,
    String? email,
    String? adresse,
    String? logoUrl,
    String? tvaIntracommunautaire,
    String? formeJuridique,
    String? capitalSocial,
    String? codeAPE,
    String? nomGerant,
    String? description,
    String? nSiren,
    String? nRcs,
  }) {
    return ClientParametres(
      id: id,
      raisonSociale: raisonSociale ?? this.raisonSociale,
      siret: siret ?? this.siret,
      telephone: telephone ?? this.telephone,
      email: email ?? this.email,
      adresse: adresse ?? this.adresse,
      logoUrl: logoUrl ?? this.logoUrl,
      tvaIntracommunautaire:
          tvaIntracommunautaire ?? this.tvaIntracommunautaire,
      formeJuridique: formeJuridique ?? this.formeJuridique,
      capitalSocial: capitalSocial ?? this.capitalSocial,
      codeAPE: codeAPE ?? this.codeAPE,
      nomGerant: nomGerant ?? this.nomGerant,
      description: description ?? this.description,
      nSiren: nSiren ?? this.nSiren,
      nRcs: nRcs ?? this.nRcs,
    );
  }
}

// ----- Conge (Leave/Absence Request) -----
class Conge {
  final String? id; // null if not yet saved to DB
  final String salarieId;
  final String entrepriseId;
  final String typeConge; // 'conge_paye', 'maladie', 'rtt', 'exceptionnel', 'autre'
  final DateTime dateDebut;
  final DateTime dateFin;
  final bool estDemiJournee;
  final String statut; // 'en_attente', 'approuve', 'refuse'
  final String commentaire;
  final DateTime? creeLe;

  const Conge({
    this.id,
    required this.salarieId,
    required this.entrepriseId,
    required this.typeConge,
    required this.dateDebut,
    required this.dateFin,
    this.estDemiJournee = false,
    this.statut = 'en_attente',
    this.commentaire = '',
    this.creeLe,
  });

  factory Conge.fromJson(Map<String, dynamic> json) {
    return Conge(
      id: json['id'] as String?,
      salarieId: json['salarie_id'] as String,
      entrepriseId: json['entreprise_id'] as String,
      typeConge: json['type_conge'] as String,
      dateDebut: DateTime.parse(json['date_debut'] as String),
      dateFin: DateTime.parse(json['date_fin'] as String),
      estDemiJournee: json['est_demi_journee'] as bool? ?? false,
      statut: json['statut'] as String? ?? 'en_attente',
      commentaire: json['commentaire'] as String? ?? '',
      creeLe: json['cree_le'] != null ? DateTime.parse(json['cree_le'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'salarie_id': salarieId,
      'entreprise_id': entrepriseId,
      'type_conge': typeConge,
      'date_debut': dateDebut.toIso8601String().split('T').first,
      'date_fin': dateFin.toIso8601String().split('T').first,
      'est_demi_journee': estDemiJournee,
      'statut': statut,
      'commentaire': commentaire,
    };
    if (id != null) {
      data['id'] = id;
    }
    return data;
  }

  Conge copyWith({
    String? id,
    String? salarieId,
    String? entrepriseId,
    String? typeConge,
    DateTime? dateDebut,
    DateTime? dateFin,
    bool? estDemiJournee,
    String? statut,
    String? commentaire,
    DateTime? creeLe,
  }) {
    return Conge(
      id: id ?? this.id,
      salarieId: salarieId ?? this.salarieId,
      entrepriseId: entrepriseId ?? this.entrepriseId,
      typeConge: typeConge ?? this.typeConge,
      dateDebut: dateDebut ?? this.dateDebut,
      dateFin: dateFin ?? this.dateFin,
      estDemiJournee: estDemiJournee ?? this.estDemiJournee,
      statut: statut ?? this.statut,
      commentaire: commentaire ?? this.commentaire,
      creeLe: creeLe ?? this.creeLe,
    );
  }
}

class Fichier {
  final String id;
  final String entrepriseId;
  final String nom;
  final String url;
  final bool estEnvoyeParUser;
  final DateTime creeLe;
  final TypeDocument? typeDocument;

  const Fichier({
    required this.id,
    required this.entrepriseId,
    required this.nom,
    required this.url,
    required this.estEnvoyeParUser,
    required this.creeLe,
    this.typeDocument,
  });

  factory Fichier.fromJson(Map<String, dynamic> json) {
    final dateStr = json['cree_le'] as String;
    final parsedDate = dateStr.endsWith('Z') || dateStr.contains('+')
        ? DateTime.parse(dateStr)
        : DateTime.parse('${dateStr}Z');

    return Fichier(
      id: json['id'] as String,
      entrepriseId: json['entreprise_id'] as String,
      nom: json['nom'] as String? ?? 'fichier',
      url: json['url'] as String? ?? '',
      estEnvoyeParUser: json['est_envoye_par_user'] as bool? ?? false,
      creeLe: parsedDate.toLocal(),
      typeDocument: json['type_document'] != null
          ? TypeDocumentExtension.fromString(json['type_document'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'entreprise_id': entrepriseId,
      'nom': nom,
      'url': url,
      'est_envoye_par_user': estEnvoyeParUser,
      'type_document': typeDocument?.value,
    };
  }
}

