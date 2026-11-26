import '../modeles/planification.dart';
import '../theme/dates_fr.dart';

/// Réservations publiées qui empêchent de publier [details].
///
/// Seules les séances publiées réservent une salle, un formateur ou un
/// groupe. Les créneaux qui se touchent (12 h – 12 h) ne se chevauchent pas.
/// [exclure] est la séance en cours de modification.
List<Probleme> chercherConflits(
  DetailsSeance details,
  Iterable<SeancePlanifiee> seances, {
  String? exclure,
  required String Function(String groupeId) nomGroupe,
}) {
  final problemes = <Probleme>[];
  for (final seance in seances) {
    final p = seance.publiee;
    if (seance.id == exclure || p == null || !details.chevauche(p)) continue;
    final creneau = 'de ${heureCourte(p.debut)} à ${heureCourte(p.fin)}';
    if (p.salle == details.salle) {
      problemes.add(
        Probleme(
          'Salle ${p.salle} déjà réservée $creneau '
          '(groupe ${nomGroupe(p.groupeId)}).',
          Champ.salle,
        ),
      );
    }
    if (p.formateur == details.formateur) {
      problemes.add(
        Probleme(
          '${p.formateur} a déjà cours $creneau '
          '(groupe ${nomGroupe(p.groupeId)}).',
          Champ.formateur,
        ),
      );
    }
    if (p.groupeId == details.groupeId) {
      problemes.add(
        Probleme(
          'Le groupe ${nomGroupe(p.groupeId)} a déjà une séance $creneau '
          '(${p.module}).',
          Champ.debut,
        ),
      );
    }
  }
  return problemes;
}
