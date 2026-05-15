class ModeleAvertissement {
  final String id;
  final String? entrepriseId; // null = modèle global
  final String titre;
  final String contenu;
  final String type; // 'ficheAvertissement', 'convocation', 'information'
  final DateTime dateCreation;

  ModeleAvertissement({
    required this.id,
    this.entrepriseId,
    required this.titre,
    required this.contenu,
    required this.type,
    DateTime? dateCreation,
  }) : dateCreation = dateCreation ?? DateTime.now();

  /// Libellé lisible du type.
  String get libelleType {
    switch (type) {
      case 'ficheAvertissement':
        return 'Fiche Avertissement';
      case 'convocation':
        return 'Convocation';
      case 'information':
        return 'Information';
      default:
        return type;
    }
  }

  bool get estGlobal => entrepriseId == null;

  factory ModeleAvertissement.fromJson(Map<String, dynamic> json) {
    return ModeleAvertissement(
      id: json['id'] as String,
      entrepriseId: json['entreprise_id'] as String?,
      titre: json['titre'] as String? ?? '',
      contenu: json['contenu'] as String? ?? '',
      type: json['type'] as String? ?? 'information',
      dateCreation: json['cree_le'] != null
          ? DateTime.parse(json['cree_le'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'entreprise_id': entrepriseId,
        'titre': titre,
        'contenu': contenu,
        'type': type,
      };

  ModeleAvertissement copyWith({
    String? id,
    String? entrepriseId,
    String? titre,
    String? contenu,
    String? type,
  }) {
    return ModeleAvertissement(
      id: id ?? this.id,
      entrepriseId: entrepriseId ?? this.entrepriseId,
      titre: titre ?? this.titre,
      contenu: contenu ?? this.contenu,
      type: type ?? this.type,
      dateCreation: dateCreation,
    );
  }
}
