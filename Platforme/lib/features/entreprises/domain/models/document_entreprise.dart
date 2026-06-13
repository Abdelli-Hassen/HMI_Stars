class DocumentEntreprise {
  final String id;
  final String entrepriseId;
  final String nom;
  final String categorie;
  final DateTime dateAjout;
  final String format;
  final String? url;

  DocumentEntreprise({
    required this.id,
    required this.entrepriseId,
    required this.nom,
    required this.categorie,
    required this.dateAjout,
    required this.format,
    this.url,
  });

  factory DocumentEntreprise.fromJson(Map<String, dynamic> json) {
    final fichierNom = json['fichier_nom'] as String? ?? json['nom'] as String? ?? '';
    final ext = fichierNom.contains('.')
        ? '.${fichierNom.split('.').last}'
        : '';
    return DocumentEntreprise(
      id: json['id'] as String,
      entrepriseId: json['entreprise_id'] as String,
      nom: fichierNom,
      categorie: _mapTypeToCategorie(json['type_document'] as String?),
      dateAjout: json['date_envoi'] != null
          ? DateTime.parse(json['date_envoi'] as String)
          : (json['cree_le'] != null
              ? DateTime.parse(json['cree_le'] as String)
              : DateTime.now()),
      format: ext,
      url: json['fichier_url'] as String? ?? json['url'] as String?,
    );
  }

  /// Maps the DB enum type_document to a display category string.
  static String _mapTypeToCategorie(String? type) {
    switch (type) {
      case 'fournisseur':
        return 'Fichiers clients / fournisseurs';
      case 'releve_bancaire':
        return 'Relevés bancaires';
      case 'chiffre_affaires':
        return 'Fichiers comptables';
      case 'kbis':
        return 'Juridique';
      case 'tva':
        return 'Fiscalité';
      case 'siret':
        return 'Juridique';
      case 'rib':
        return 'Relevés bancaires';
      case 'statuts':
        return 'Juridique';
      case 'media':
        return 'Médias & Photos';
      case 'autre':
      default:
        return 'Autres documents';
    }
  }
}
