/// Compte stagiaire, tel que l'API pourra le renvoyer plus tard.
class Stagiaire {
  const Stagiaire({
    required this.id,
    required this.prenom,
    required this.groupe,
    required this.filiere,
    required this.pole,
  });

  final String id;
  final String prenom;
  final String groupe;
  final String filiere;
  final String pole;
}
