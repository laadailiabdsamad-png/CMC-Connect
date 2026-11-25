import '../modeles/seance.dart';
import '../modeles/stagiaire.dart';

/// Contrat entre les écrans et les données.
///
/// Aujourd'hui : `PlanningFictif`. Plus tard : une classe qui appelle l'API
/// PHP/JSON, sans rien changer dans les écrans.
abstract interface class PlanningRepository {
  Future<List<Stagiaire>> profils();

  /// Séances publiées du groupe du stagiaire.
  Future<List<Seance>> seances(Stagiaire stagiaire);
}
