class NoteEntreprise {
  final String id;
  final String entrepriseId;
  final String titre;
  final String contenu;
  final DateTime dateCreation;
  final bool estRappel;
  final DateTime? dateRappel;

  // État local uniquement (non persisté en base)
  bool isPinned;
  final String tag;

  NoteEntreprise({
    required this.id,
    required this.entrepriseId,
    required this.titre,
    required this.contenu,
    required this.dateCreation,
    required this.estRappel,
    this.dateRappel,
    this.isPinned = false,
    this.tag = 'Note',
  });

  factory NoteEntreprise.fromJson(Map<String, dynamic> json) {
    return NoteEntreprise(
      id: json['id'] as String,
      entrepriseId: json['entreprise_id'] as String,
      titre: json['titre'] as String? ?? '',
      contenu: json['contenu'] as String? ?? '',
      dateCreation: json['cree_le'] != null
          ? DateTime.parse(json['cree_le'] as String)
          : DateTime.now(),
      estRappel: json['est_rappel'] as bool? ?? false,
      dateRappel: json['date_rappel'] != null
          ? DateTime.tryParse(json['date_rappel'] as String)
          : null,
      isPinned: json['is_pinned'] as bool? ?? false,
      tag: json['tag'] as String? ?? 'Note',
    );
  }

  Map<String, dynamic> toJson() => {
        'entreprise_id': entrepriseId,
        'titre': titre,
        'contenu': contenu,
        'est_rappel': estRappel,
        'date_rappel': dateRappel?.toIso8601String(),
        'is_pinned': isPinned,
        'tag': tag,
      };

  NoteEntreprise copyWith({
    String? id,
    String? entrepriseId,
    String? titre,
    String? contenu,
    DateTime? dateCreation,
    bool? estRappel,
    DateTime? dateRappel,
    bool? isPinned,
    String? tag,
  }) {
    return NoteEntreprise(
      id: id ?? this.id,
      entrepriseId: entrepriseId ?? this.entrepriseId,
      titre: titre ?? this.titre,
      contenu: contenu ?? this.contenu,
      dateCreation: dateCreation ?? this.dateCreation,
      estRappel: estRappel ?? this.estRappel,
      dateRappel: dateRappel ?? this.dateRappel,
      isPinned: isPinned ?? this.isPinned,
      tag: tag ?? this.tag,
    );
  }
}
