/// Modèle d'utilisateur de la plateforme — Admin ou Secrétaire.
/// Lié à Supabase auth.users via [id].
class UtilisateurPlateforme {
  final String id;
  final String nom;
  final String email;
  final String role; // 'admin', 'secretaire'
  final String telephone;
  final String cin;
  final String? avatarUrl;
  final String organisation;
  final Map<String, dynamic> preferences;
  final DateTime creeLe;
  final DateTime misAJourLe;
  final bool estApprouve;

  UtilisateurPlateforme({
    required this.id,
    required this.nom,
    required this.email,
    required this.role,
    this.telephone = '',
    this.cin = '',
    this.avatarUrl,
    this.organisation = 'HMI Stars Consulting',
    this.preferences = const {},
    required this.creeLe,
    required this.misAJourLe,
    this.estApprouve = false,
  });

  String get libelleRole {
    switch (role) {
      case 'admin':
        return 'Admin';
      case 'secretaire':
        return 'Secrétaire';
      default:
        return role;
    }
  }

  factory UtilisateurPlateforme.fromJson(Map<String, dynamic> json) {
    return UtilisateurPlateforme(
      id: json['id'] as String,
      nom: json['nom'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'secretaire',
      telephone: json['telephone'] as String? ?? '',
      cin: json['cin'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      organisation: json['organisation'] as String? ?? 'HMI Stars Consulting',
      preferences: json['preferences'] as Map<String, dynamic>? ?? {},
      creeLe: json['cree_le'] != null
          ? DateTime.parse(json['cree_le'] as String)
          : DateTime.now(),
      misAJourLe: json['mis_a_jour_le'] != null
          ? DateTime.parse(json['mis_a_jour_le'] as String)
          : DateTime.now(),
      estApprouve: json['est_approuve'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'nom': nom,
        'email': email,
        'role': role,
        'telephone': telephone,
        'cin': cin,
        'avatar_url': avatarUrl,
        'organisation': organisation,
        'preferences': preferences,
        'est_approuve': estApprouve,
      };

  UtilisateurPlateforme copyWith({
    String? nom,
    String? email,
    String? role,
    String? telephone,
    String? cin,
    String? avatarUrl,
    String? organisation,
    Map<String, dynamic>? preferences,
    bool? estApprouve,
  }) {
    return UtilisateurPlateforme(
      id: id,
      nom: nom ?? this.nom,
      email: email ?? this.email,
      role: role ?? this.role,
      telephone: telephone ?? this.telephone,
      cin: cin ?? this.cin,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      organisation: organisation ?? this.organisation,
      preferences: preferences ?? this.preferences,
      creeLe: creeLe,
      misAJourLe: DateTime.now(),
      estApprouve: estApprouve ?? this.estApprouve,
    );
  }
}
