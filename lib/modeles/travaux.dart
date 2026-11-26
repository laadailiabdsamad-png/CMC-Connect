import 'package:flutter/foundation.dart';

/// Taille maximale d'une pièce jointe ou d'un rendu.
const tailleMaxFichier = 20 * 1024 * 1024;

/// Un fichier que la personne vient de choisir sur son téléphone.
class FichierChoisi {
  FichierChoisi({required this.nom, required this.octets, int? taille})
    : taille = taille ?? octets.length;

  final String nom;

  /// Vide si le fichier est trop lourd pour être lu.
  final Uint8List octets;
  final int taille;
}

/// Un fichier conservé par l'application.
@immutable
class PieceJointe {
  const PieceJointe({
    required this.id,
    required this.nom,
    required this.taille,
    required this.chemin,
  });

  final String id;
  final String nom;
  final int taille;

  /// Emplacement sur le téléphone. Avec l'API, ce sera une adresse de
  /// téléchargement contrôlée par le serveur.
  final String chemin;

  Map<String, Object> enJson() => {
    'id': id,
    'nom': nom,
    'taille': taille,
    'chemin': chemin,
  };

  static PieceJointe depuisJson(Map<String, Object?> j) => PieceJointe(
    id: j['id']! as String,
    nom: j['nom']! as String,
    taille: j['taille']! as int,
    chemin: j['chemin']! as String,
  );
}

PieceJointe? _piece(Object? j) => j == null
    ? null
    : PieceJointe.depuisJson((j as Map).cast<String, Object?>());

/// Un document de cours déposé par le formateur pour un groupe.
@immutable
class Support {
  const Support({
    required this.id,
    required this.groupeId,
    required this.module,
    required this.seanceId,
    required this.formateurId,
    required this.formateurNom,
    required this.titre,
    required this.piece,
    required this.publieLe,
  });

  final String id;
  final String groupeId;
  final String module;
  final String seanceId;
  final String formateurId;
  final String formateurNom;
  final String titre;
  final PieceJointe piece;
  final DateTime publieLe;

  Map<String, Object> enJson() => {
    'id': id,
    'groupe': groupeId,
    'module': module,
    'seance': seanceId,
    'formateur': formateurId,
    'formateurNom': formateurNom,
    'titre': titre,
    'piece': piece.enJson(),
    'publieLe': publieLe.toIso8601String(),
  };

  static Support depuisJson(Map<String, Object?> j) => Support(
    id: j['id']! as String,
    groupeId: j['groupe']! as String,
    module: j['module']! as String,
    seanceId: j['seance']! as String,
    formateurId: j['formateur']! as String,
    formateurNom: j['formateurNom']! as String,
    titre: j['titre']! as String,
    piece: _piece(j['piece'])!,
    publieLe: DateTime.parse(j['publieLe']! as String),
  );
}

/// Un travail pratique publié pour un groupe.
@immutable
class Tp {
  const Tp({
    required this.id,
    required this.groupeId,
    required this.module,
    required this.seanceId,
    required this.formateurId,
    required this.formateurNom,
    required this.titre,
    required this.consigne,
    required this.echeance,
    required this.publieLe,
    this.piece,
  });

  final String id;
  final String groupeId;
  final String module;
  final String seanceId;
  final String formateurId;
  final String formateurNom;
  final String titre;
  final String consigne;
  final DateTime echeance;
  final DateTime publieLe;
  final PieceJointe? piece;

  Map<String, Object> enJson() => {
    'id': id,
    'groupe': groupeId,
    'module': module,
    'seance': seanceId,
    'formateur': formateurId,
    'formateurNom': formateurNom,
    'titre': titre,
    'consigne': consigne,
    'echeance': echeance.toIso8601String(),
    'publieLe': publieLe.toIso8601String(),
    'piece': ?piece?.enJson(),
  };

  static Tp depuisJson(Map<String, Object?> j) => Tp(
    id: j['id']! as String,
    groupeId: j['groupe']! as String,
    module: j['module']! as String,
    seanceId: j['seance']! as String,
    formateurId: j['formateur']! as String,
    formateurNom: j['formateurNom']! as String,
    titre: j['titre']! as String,
    consigne: j['consigne']! as String,
    echeance: DateTime.parse(j['echeance']! as String),
    publieLe: DateTime.parse(j['publieLe']! as String),
    piece: _piece(j['piece']),
  );
}

/// Le fichier rendu par un stagiaire pour un TP. Un nouveau dépôt remplace
/// le précédent.
@immutable
class Rendu {
  const Rendu({
    required this.id,
    required this.tpId,
    required this.stagiaireId,
    required this.stagiaireNom,
    required this.piece,
    required this.deposeLe,
  });

  final String id;
  final String tpId;
  final String stagiaireId;
  final String stagiaireNom;
  final PieceJointe piece;
  final DateTime deposeLe;

  Map<String, Object> enJson() => {
    'id': id,
    'tp': tpId,
    'stagiaire': stagiaireId,
    'stagiaireNom': stagiaireNom,
    'piece': piece.enJson(),
    'deposeLe': deposeLe.toIso8601String(),
  };

  static Rendu depuisJson(Map<String, Object?> j) => Rendu(
    id: j['id']! as String,
    tpId: j['tp']! as String,
    stagiaireId: j['stagiaire']! as String,
    stagiaireNom: j['stagiaireNom']! as String,
    piece: _piece(j['piece'])!,
    deposeLe: DateTime.parse(j['deposeLe']! as String),
  );
}

/// Un TP vu par un stagiaire, avec son propre rendu s'il existe.
class TravailStagiaire {
  const TravailStagiaire({required this.tp, this.rendu});

  final Tp tp;
  final Rendu? rendu;

  bool enRetard(DateTime maintenant) => rendu == null
      ? maintenant.isAfter(tp.echeance)
      : rendu!.deposeLe.isAfter(tp.echeance);
}

/// Un TP vu par son formateur, avec les rendus reçus.
class TpSuivi {
  const TpSuivi({required this.tp, required this.rendus});

  final Tp tp;
  final List<Rendu> rendus;
}

/// Champs du formulaire de TP et de support.
enum ChampTravail { titre, consigne, echeance, fichier }

class ProblemeTravail {
  const ProblemeTravail(this.message, [this.champ]);

  final String message;
  final ChampTravail? champ;

  @override
  String toString() => message;
}

/// Refus motivé : champ manquant, échéance passée, droit insuffisant.
class TravailRefuse implements Exception {
  const TravailRefuse(this.problemes);

  final List<ProblemeTravail> problemes;

  @override
  String toString() => problemes.join(' ');
}

List<ProblemeTravail> verifierFichier(FichierChoisi? fichier) => [
  if (fichier != null && fichier.taille > tailleMaxFichier)
    const ProblemeTravail(
      'Ce fichier dépasse 20 Mo. Choisissez un fichier plus léger.',
      ChampTravail.fichier,
    ),
  if (fichier != null &&
      fichier.taille <= tailleMaxFichier &&
      fichier.octets.isEmpty)
    const ProblemeTravail('Ce fichier est vide.', ChampTravail.fichier),
];

/// Règles communes au formulaire et au repository.
List<ProblemeTravail> verifierTp({
  required String titre,
  required String consigne,
  required DateTime? echeance,
  required DateTime maintenant,
  FichierChoisi? piece,
}) => [
  if (titre.trim().isEmpty)
    const ProblemeTravail('Indiquez un titre.', ChampTravail.titre)
  else if (titre.trim().length > 120)
    const ProblemeTravail(
      'Le titre ne doit pas dépasser 120 caractères.',
      ChampTravail.titre,
    ),
  if (consigne.trim().isEmpty)
    const ProblemeTravail('Rédigez la consigne.', ChampTravail.consigne),
  if (echeance == null)
    const ProblemeTravail('Choisissez une échéance.', ChampTravail.echeance)
  else if (!echeance.isAfter(maintenant))
    const ProblemeTravail(
      'L’échéance doit être à venir.',
      ChampTravail.echeance,
    ),
  ...verifierFichier(piece),
];

List<ProblemeTravail> verifierSupport({
  required String titre,
  required FichierChoisi? fichier,
}) => [
  if (titre.trim().isEmpty)
    const ProblemeTravail('Indiquez un titre.', ChampTravail.titre),
  if (fichier == null)
    const ProblemeTravail('Choisissez un fichier.', ChampTravail.fichier),
  ...verifierFichier(fichier),
];
