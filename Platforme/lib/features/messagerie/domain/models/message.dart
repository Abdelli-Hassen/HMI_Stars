class Message {
  final String id;
  final String expediteurId;
  final String destinataireId; // e.g. "admin"
  final String contenu;
  final DateTime timestamp;
  final bool estLu;

  Message({
    required this.id,
    required this.expediteurId,
    required this.destinataireId,
    required this.contenu,
    required this.timestamp,
    this.estLu = false,
  });
}
