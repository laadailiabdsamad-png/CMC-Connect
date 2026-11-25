class Seance {
  const Seance({
    required this.id,
    required this.module,
    required this.formateur,
    required this.debut,
    required this.fin,
    required this.salle,
    this.ancienneSalle,
  });

  final String id;
  final String module;
  final String formateur;
  final DateTime debut;
  final DateTime fin;
  final String salle;

  /// Renseignée uniquement si la salle a changé après publication.
  final String? ancienneSalle;

  bool get salleModifiee => ancienneSalle != null && ancienneSalle != salle;
}
