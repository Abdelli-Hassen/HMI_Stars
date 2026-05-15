class TacheUrgente {
  final String id;
  final String entrepriseId;
  final String titre;
  final String description;
  final DateTime dateEcheance;
  final bool accomplie;
  final DateTime dateCreation;

  TacheUrgente({
    required this.id,
    required this.entrepriseId,
    required this.titre,
    required this.description,
    required this.dateEcheance,
    this.accomplie = false,
    DateTime? dateCreation,
  }) : dateCreation = dateCreation ?? DateTime.now();

  factory TacheUrgente.fromJson(Map<String, dynamic> json) {
    return TacheUrgente(
      id: json['id'] as String,
      entrepriseId: json['entreprise_id'] as String,
      titre: json['titre'] as String? ?? '',
      description: json['description'] as String? ?? '',
      dateEcheance: json['date_echeance'] != null
          ? DateTime.parse(json['date_echeance'] as String)
          : DateTime.now(),
      accomplie: json['accomplie'] as bool? ?? false,
      dateCreation: json['cree_le'] != null
          ? DateTime.parse(json['cree_le'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'entreprise_id': entrepriseId,
        'titre': titre,
        'description': description,
        'date_echeance': dateEcheance.toIso8601String(),
        'accomplie': accomplie,
      };

  TacheUrgente copyWith({
    String? id,
    String? entrepriseId,
    String? titre,
    String? description,
    DateTime? dateEcheance,
    bool? accomplie,
  }) {
    return TacheUrgente(
      id: id ?? this.id,
      entrepriseId: entrepriseId ?? this.entrepriseId,
      titre: titre ?? this.titre,
      description: description ?? this.description,
      dateEcheance: dateEcheance ?? this.dateEcheance,
      accomplie: accomplie ?? this.accomplie,
      dateCreation: dateCreation,
    );
  }
}
