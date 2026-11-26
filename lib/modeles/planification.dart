import 'package:flutter/foundation.dart';

import '../theme/dates_fr.dart';

/// Champs du formulaire, pour placer chaque message au bon endroit.
enum Champ { groupe, module, formateur, salle, date, debut, fin }

/// Contenu d'une séance : ce que le chef saisit et ce que le groupe voit.
@immutable
class DetailsSeance {
  const DetailsSeance({
    required this.groupeId,
    required this.module,
    required this.formateur,
    required this.salle,
    required this.debut,
    required this.fin,
  });

  final String groupeId;
  final String module;
  final String formateur;
  final String salle;
  final DateTime debut;
  final DateTime fin;

  bool chevauche(DetailsSeance autre) =>
      debut.isBefore(autre.fin) && autre.debut.isBefore(fin);

  Map<String, Object> enJson() => {
    'groupe': groupeId,
    'module': module,
    'formateur': formateur,
    'salle': salle,
    'debut': debut.toIso8601String(),
    'fin': fin.toIso8601String(),
  };

  static DetailsSeance depuisJson(Map<String, Object?> j) => DetailsSeance(
    groupeId: j['groupe']! as String,
    module: j['module']! as String,
    formateur: j['formateur']! as String,
    salle: j['salle']! as String,
    debut: DateTime.parse(j['debut']! as String),
    fin: DateTime.parse(j['fin']! as String),
  );

  @override
  bool operator ==(Object other) =>
      other is DetailsSeance &&
      other.groupeId == groupeId &&
      other.module == module &&
      other.formateur == formateur &&
      other.salle == salle &&
      other.debut == debut &&
      other.fin == fin;

  @override
  int get hashCode =>
      Object.hash(groupeId, module, formateur, salle, debut, fin);
}

enum EtatSeance {
  brouillon('Brouillon'),
  publiee('Publiée'),
  modificationEnAttente('Modification en attente');

  const EtatSeance(this.libelle);
  final String libelle;
}

/// Une séance côté chef de pôle : sa version publique et, éventuellement,
/// un brouillon. Le groupe ne voit que [publiee].
@immutable
class SeancePlanifiee {
  const SeancePlanifiee({
    required this.id,
    this.publiee,
    this.brouillon,
    this.sallePrecedente,
  }) : assert(publiee != null || brouillon != null);

  final String id;
  final DetailsSeance? publiee;
  final DetailsSeance? brouillon;

  /// Salle de la version publiée précédente, montrée aux stagiaires.
  final String? sallePrecedente;

  EtatSeance get etat => publiee == null
      ? EtatSeance.brouillon
      : brouillon == null
      ? EtatSeance.publiee
      : EtatSeance.modificationEnAttente;

  /// La version sur laquelle le chef travaille.
  DetailsSeance get courante => brouillon ?? publiee!;

  /// Ce qui changera à la publication, par exemple « B12 → B08 ».
  List<String> get changements {
    final avant = publiee;
    final apres = brouillon;
    if (avant == null || apres == null) return const [];
    final heuresAvant = plageHoraire(avant.debut, avant.fin);
    final heuresApres = plageHoraire(apres.debut, apres.fin);
    return [
      if (avant.salle != apres.salle) '${avant.salle} → ${apres.salle}',
      if (!memeJour(avant.debut, apres.debut))
        '${jourMois(avant.debut)} → ${jourMois(apres.debut)}',
      if (heuresAvant != heuresApres) '$heuresAvant → $heuresApres',
      if (avant.formateur != apres.formateur)
        '${avant.formateur} → ${apres.formateur}',
      if (avant.module != apres.module) '${avant.module} → ${apres.module}',
      if (avant.groupeId != apres.groupeId) 'Changement de groupe',
    ];
  }

  SeancePlanifiee avec({
    DetailsSeance? publiee,
    required DetailsSeance? brouillon,
    String? sallePrecedente,
  }) => SeancePlanifiee(
    id: id,
    publiee: publiee ?? this.publiee,
    brouillon: brouillon,
    sallePrecedente: sallePrecedente ?? this.sallePrecedente,
  );

  Map<String, Object> enJson() => {
    'id': id,
    'publiee': ?publiee?.enJson(),
    'brouillon': ?brouillon?.enJson(),
    'sallePrecedente': ?sallePrecedente,
  };

  static SeancePlanifiee depuisJson(Map<String, Object?> j) {
    DetailsSeance? lire(String cle) => j[cle] == null
        ? null
        : DetailsSeance.depuisJson((j[cle]! as Map).cast<String, Object?>());
    return SeancePlanifiee(
      id: j['id']! as String,
      publiee: lire('publiee'),
      brouillon: lire('brouillon'),
      sallePrecedente: j['sallePrecedente'] as String?,
    );
  }
}

class Probleme {
  const Probleme(this.message, [this.champ]);

  final String message;
  final Champ? champ;

  @override
  String toString() => message;
}

/// Refus motivé : champ manquant, horaire incohérent, conflit ou droit.
class PlanningRefuse implements Exception {
  const PlanningRefuse(this.problemes);

  final List<Probleme> problemes;

  @override
  String toString() => problemes.join(' ');
}

/// Les données n'ont pas pu être enregistrées ; rien n'a changé.
class EnregistrementImpossible implements Exception {
  const EnregistrementImpossible();
}

const _ouverture = 8 * 60;
const _fermeture = 20 * 60;

/// Règles d'horaire communes au formulaire et au repository.
List<Probleme> verifierHoraires(DateTime debut, DateTime fin) {
  final d = debut.hour * 60 + debut.minute;
  final f = memeJour(debut, fin) ? fin.hour * 60 + fin.minute : 24 * 60;
  return [
    if (debut.weekday == DateTime.sunday)
      const Probleme('Le dimanche n’est pas un jour de cours.', Champ.date),
    if (f <= d)
      const Probleme(
        'L’heure de fin doit être après l’heure de début.',
        Champ.fin,
      )
    else if (f - d < 30)
      const Probleme('Une séance dure au moins 30 minutes.', Champ.fin),
    if (d < _ouverture)
      const Probleme('Les séances commencent à 8 h au plus tôt.', Champ.debut),
    if (f > _fermeture)
      const Probleme(
        'Les séances se terminent à 20 h au plus tard.',
        Champ.fin,
      ),
  ];
}

/// Valeurs du formulaire, encore incomplètes pendant la saisie.
class ValeursFiche {
  ValeursFiche({
    this.groupeId,
    this.module,
    this.formateur,
    this.salle,
    this.date,
    this.debut,
    this.fin,
  });

  factory ValeursFiche.depuis(DetailsSeance d) => ValeursFiche(
    groupeId: d.groupeId,
    module: d.module,
    formateur: d.formateur,
    salle: d.salle,
    date: DateTime(d.debut.year, d.debut.month, d.debut.day),
    debut: d.debut.hour * 60 + d.debut.minute,
    fin: d.fin.hour * 60 + d.fin.minute,
  );

  String? groupeId;
  String? module;
  String? formateur;
  String? salle;
  DateTime? date;

  /// Minutes depuis minuit.
  int? debut;
  int? fin;

  List<Probleme> verifier() {
    final problemes = <Probleme>[
      if (groupeId == null)
        const Probleme('Choisissez un groupe.', Champ.groupe),
      if (module == null) const Probleme('Choisissez un module.', Champ.module),
      if (formateur == null)
        const Probleme('Choisissez un formateur.', Champ.formateur),
      if (salle == null) const Probleme('Choisissez une salle.', Champ.salle),
      if (date == null) const Probleme('Choisissez une date.', Champ.date),
      if (debut == null)
        const Probleme('Indiquez l’heure de début.', Champ.debut),
      if (fin == null) const Probleme('Indiquez l’heure de fin.', Champ.fin),
    ];
    final details = _details();
    if (details != null) {
      problemes.addAll(verifierHoraires(details.debut, details.fin));
    }
    return problemes;
  }

  /// Les détails complets, ou null s'il manque quelque chose.
  DetailsSeance? enDetails() => verifier().isEmpty ? _details() : null;

  DetailsSeance? _details() {
    final (g, m, f, s, j, d, fi) = (
      groupeId,
      module,
      formateur,
      salle,
      date,
      debut,
      fin,
    );
    if (g == null ||
        m == null ||
        f == null ||
        s == null ||
        j == null ||
        d == null ||
        fi == null) {
      return null;
    }
    return DetailsSeance(
      groupeId: g,
      module: m,
      formateur: f,
      salle: s,
      debut: DateTime(j.year, j.month, j.day, d ~/ 60, d % 60),
      fin: DateTime(j.year, j.month, j.day, fi ~/ 60, fi % 60),
    );
  }
}
