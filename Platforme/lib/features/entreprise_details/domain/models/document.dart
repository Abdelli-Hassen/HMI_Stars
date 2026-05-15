class Document {
  final String id;
  final String entrepriseId;
  final String nomFichier;
  final String urlFichier;
  final DateTime dateTelechargement;
  final bool vu; // Si l'admin a vu ce document
  
  Document({
    required this.id,
    required this.entrepriseId,
    required this.nomFichier,
    required this.urlFichier,
    required this.dateTelechargement,
    this.vu = false,
  });

  Document copyWith({
    String? id,
    String? entrepriseId,
    String? nomFichier,
    String? urlFichier,
    DateTime? dateTelechargement,
    bool? vu,
  }) {
    return Document(
      id: id ?? this.id,
      entrepriseId: entrepriseId ?? this.entrepriseId,
      nomFichier: nomFichier ?? this.nomFichier,
      urlFichier: urlFichier ?? this.urlFichier,
      dateTelechargement: dateTelechargement ?? this.dateTelechargement,
      vu: vu ?? this.vu,
    );
  }
}
