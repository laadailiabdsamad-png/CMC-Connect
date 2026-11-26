import '../modeles/compte.dart';
import '../modeles/travaux.dart';

/// Supports, TP et rendus. Les droits suivent les affectations : un
/// formateur publie pour les groupes et modules qu'il enseigne, un stagiaire
/// ne voit et ne rend que les TP de son groupe.
///
/// Aujourd'hui : `TravauxLocaux`, enregistré sur le téléphone. Avec l'API,
/// le serveur appliquera ces contrôles à partir de la session.
abstract interface class TravauxRepository {
  /// TP publiés par le formateur, avec les rendus reçus.
  Future<List<TpSuivi>> tpsFormateur(Formateur formateur);

  Future<List<Support>> supportsFormateur(Formateur formateur);

  /// Lève [TravailRefuse] ou `EnregistrementImpossible`.
  Future<Support> ajouterSupport(
    Formateur formateur, {
    required String seanceId,
    required String titre,
    required FichierChoisi? fichier,
  });

  /// Lève [TravailRefuse] ou `EnregistrementImpossible`.
  Future<Tp> publierTp(
    Formateur formateur, {
    required String seanceId,
    required String titre,
    required String consigne,
    required DateTime? echeance,
    FichierChoisi? piece,
  });

  /// TP du groupe du stagiaire, avec son rendu.
  Future<List<TravailStagiaire>> travauxStagiaire(Stagiaire stagiaire);

  Future<List<Support>> supportsStagiaire(Stagiaire stagiaire);

  /// Dépose ou remplace le rendu. Lève [TravailRefuse] ou
  /// `EnregistrementImpossible`.
  Future<Rendu> deposer(
    Stagiaire stagiaire,
    String tpId,
    FichierChoisi? fichier,
  );

  /// Remet les données de démonstration à zéro.
  Future<void> reinitialiser();
}
