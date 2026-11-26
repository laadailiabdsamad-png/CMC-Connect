/// Comptes de démonstration. Avec l'API, le serveur renverra le compte de la
/// session ouverte et ses droits ; l'application ne décidera plus seule.
sealed class Compte {
  const Compte({required this.id, required this.nom});

  final String id;

  /// Prénom d'un stagiaire, intitulé du compte pour un chef de pôle.
  final String nom;
}

class Stagiaire extends Compte {
  const Stagiaire({
    required super.id,
    required String prenom,
    required this.groupeId,
    required this.groupe,
    required this.filiere,
    required this.pole,
  }) : super(nom: prenom);

  String get prenom => nom;
  final String groupeId;

  /// Code affiché du groupe, par exemple « DEV 201 ».
  final String groupe;
  final String filiere;
  final String pole;
}

class ChefPole extends Compte {
  const ChefPole({
    required super.id,
    required super.nom,
    required this.poleId,
    required this.pole,
  });

  final String poleId;
  final String pole;
}

class Groupe {
  const Groupe({
    required this.id,
    required this.code,
    required this.filiere,
    required this.annee,
    required this.poleId,
  });

  final String id;
  final String code;
  final String filiere;
  final String annee;
  final String poleId;
}

/// Un formateur enseigne un module à un groupe.
class Affectation {
  const Affectation({required this.groupeId, required this.module});

  final String groupeId;
  final String module;
}

class Formateur extends Compte {
  const Formateur({
    required super.id,
    required super.nom,
    required this.affectations,
  });

  /// Groupes et modules pour lesquels il peut publier supports et TP.
  final List<Affectation> affectations;

  bool enseigne(String groupeId, String module) =>
      affectations.any((a) => a.groupeId == groupeId && a.module == module);
}
