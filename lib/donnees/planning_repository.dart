import '../modeles/compte.dart';
import '../modeles/planification.dart';
import '../modeles/seance.dart';

/// Ce dont l'espace chef a besoin pour remplir le formulaire.
class EspacePole {
  const EspacePole({
    required this.groupes,
    required this.modules,
    required this.formateurs,
    required this.salles,
  });

  final List<Groupe> groupes;
  final List<String> modules;
  final List<String> formateurs;
  final List<String> salles;
}

/// Contrat entre les écrans et les données. L'espace chef, l'accueil et le
/// planning stagiaire passent tous par lui.
///
/// Aujourd'hui : `PlanningFictif`, enregistré sur le téléphone. Avec l'API
/// PHP, une autre classe implémentera ce contrat et le serveur appliquera
/// les mêmes règles ; les écrans ne changeront pas.
abstract interface class PlanningRepository {
  Future<List<Compte>> comptes();

  /// Séances publiées du groupe du stagiaire.
  Future<List<Seance>> seances(Stagiaire stagiaire);

  /// Groupes du pôle et listes de choix du formulaire.
  Future<EspacePole> espacePole(ChefPole chef);

  /// Séances du groupe du lundi au samedi, brouillons compris.
  Future<List<SeancePlanifiee>> semaine(
    ChefPole chef,
    String groupeId,
    DateTime lundi,
  );

  /// Crée ou met à jour le brouillon. La version publiée ne change pas.
  /// Lève [PlanningRefuse] ou [EnregistrementImpossible].
  Future<SeancePlanifiee> enregistrerBrouillon(
    ChefPole chef,
    DetailsSeance details, {
    String? seanceId,
  });

  /// Publie le brouillon après contrôle des conflits.
  /// Lève [PlanningRefuse] ou [EnregistrementImpossible] ; dans les deux cas
  /// le brouillon et l'ancienne version publiée restent intacts.
  Future<SeancePlanifiee> publier(ChefPole chef, String seanceId);

  /// Remet les données de démonstration à zéro, à partir d'aujourd'hui.
  Future<void> reinitialiser();
}
