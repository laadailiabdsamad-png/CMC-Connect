import 'package:flutter/foundation.dart';

import '../donnees/fichiers.dart';
import '../donnees/planning_repository.dart';
import '../donnees/preferences_locales.dart';
import '../donnees/travaux_locaux.dart';
import '../donnees/travaux_repository.dart';
import '../modeles/apparence.dart';
import '../modeles/compte.dart';
import '../modeles/seance.dart';
import '../modeles/travaux.dart';

/// État partagé par tous les écrans : compte actif, séances, travaux et
/// apparence. Stagiaire et formateur lisent leurs séances dans le même
/// [planning] que l'espace chef.
class Session extends ChangeNotifier {
  Session({
    required this.planning,
    required this.preferences,
    TravauxRepository? travaux,
    FichiersAppareil? fichiers,
    DateTime Function()? horloge,
  }) : _horloge = horloge ?? DateTime.now,
       travaux = travaux ?? TravauxLocaux(planning: planning, horloge: horloge),
       fichiers = fichiers ?? FichiersSysteme();

  final PlanningRepository planning;
  final PreferencesLocales preferences;
  final TravauxRepository travaux;
  final FichiersAppareil fichiers;
  final DateTime Function() _horloge;

  /// TP du groupe du stagiaire actif, avec son rendu.
  List<TravailStagiaire> mesTravaux = const [];

  /// Supports du groupe du stagiaire, ou publiés par le formateur actif.
  List<Support> supports = const [];

  /// TP publiés par le formateur actif, avec les rendus reçus.
  List<TpSuivi> tpsSuivis = const [];

  List<Compte> profils = const [];
  Compte? actif;
  Apparence apparence = const Apparence();
  List<Seance> seances = const [];
  bool erreur = false;

  /// Écarte la réponse d'un chargement dépassé par un changement de compte.
  int _demande = 0;

  DateTime get maintenant => _horloge();

  Formateur? get formateur => switch (actif) {
    final Formateur f => f,
    _ => null,
  };

  /// Le compte actif s'il s'agit d'un stagiaire.
  Stagiaire? get stagiaire => switch (actif) {
    final Stagiaire s => s,
    _ => null,
  };

  Seance? get prochaine {
    final instant = maintenant;
    for (final seance in seances) {
      if (seance.debut.isAfter(instant)) return seance;
    }
    return null;
  }

  /// À appeler avant le premier affichage : rouvre le dernier compte avec son
  /// thème, sans passer par un autre thème à l'écran.
  Future<void> demarrer() async {
    erreur = false;
    try {
      profils = await planning.comptes();
    } catch (_) {
      erreur = true;
      notifyListeners();
      return;
    }
    String? dernier;
    try {
      dernier = await preferences.dernierCompte();
    } catch (_) {
      // Sans réglage lisible, on repart du choix de profil.
    }
    for (final profil in profils) {
      if (profil.id == dernier) return choisir(profil);
    }
    notifyListeners();
  }

  Future<void> choisir(Compte compte) async {
    final demande = ++_demande;
    var choix = const Apparence();
    try {
      await preferences.retenirCompte(compte.id);
      choix = await preferences.apparence(compte.id);
    } catch (_) {
      // L'apparence par défaut reste utilisable.
    }
    final resultat = await _lire(compte);
    if (demande != _demande) return;
    actif = compte;
    apparence = choix;
    _appliquerLecture(resultat);
    erreur = resultat == null;
    notifyListeners();
  }

  /// Relit séances et travaux du stagiaire ou du formateur actif (retour
  /// dans l'application, geste d'actualisation, réessai).
  Future<void> rafraichir() async {
    final compte = actif;
    if (compte == null || compte is ChefPole) return;
    final demande = ++_demande;
    final resultat = await _lire(compte);
    if (demande != _demande) return;
    // En cas d'échec, les dernières données connues restent affichées.
    if (resultat != null) _appliquerLecture(resultat);
    erreur = resultat == null && seances.isEmpty;
    notifyListeners();
  }

  Future<void> changerDeCompte() async {
    ++_demande;
    actif = null;
    _appliquerLecture(null);
    apparence = const Apparence();
    erreur = false;
    notifyListeners();
    try {
      await preferences.retenirCompte(null);
    } catch (_) {
      // Le choix de profil est déjà affiché.
    }
  }

  /// Enregistre puis applique. Renvoie faux si l'enregistrement a échoué.
  Future<bool> appliquer(Apparence nouvelle) async {
    final compte = actif;
    if (compte == null) return false;
    try {
      await preferences.enregistrerApparence(compte.id, nouvelle);
    } catch (_) {
      return false;
    }
    if (actif?.id == compte.id) {
      apparence = nouvelle;
      notifyListeners();
    }
    return true;
  }

  void _appliquerLecture(_Lecture? l) {
    seances = l?.seances ?? const [];
    mesTravaux = l?.travaux ?? const [];
    supports = l?.supports ?? const [];
    tpsSuivis = l?.suivis ?? const [];
  }

  /// Null si les données n'ont pas pu être lues.
  Future<_Lecture?> _lire(Compte compte) async {
    try {
      switch (compte) {
        case Stagiaire():
          final (seances, travaux, supports) = await (
            planning.seances(compte),
            this.travaux.travauxStagiaire(compte),
            this.travaux.supportsStagiaire(compte),
          ).wait;
          return _Lecture(
            seances: _trier(seances),
            travaux: travaux,
            supports: supports,
          );
        case Formateur():
          final (seances, suivis, supports) = await (
            planning.seancesFormateur(compte),
            travaux.tpsFormateur(compte),
            travaux.supportsFormateur(compte),
          ).wait;
          return _Lecture(
            seances: _trier(seances),
            suivis: suivis,
            supports: supports,
          );
        case ChefPole():
          return const _Lecture();
      }
    } catch (_) {
      return null;
    }
  }

  static List<Seance> _trier(List<Seance> seances) =>
      [...seances]..sort((a, b) => a.debut.compareTo(b.debut));

  /// Remet séances et travaux de démonstration à zéro.
  Future<void> reinitialiserDemo() async {
    await planning.reinitialiser();
    await travaux.reinitialiser();
  }
}

class _Lecture {
  const _Lecture({
    this.seances = const [],
    this.travaux = const [],
    this.supports = const [],
    this.suivis = const [],
  });

  final List<Seance> seances;
  final List<TravailStagiaire> travaux;
  final List<Support> supports;
  final List<TpSuivi> suivis;
}
