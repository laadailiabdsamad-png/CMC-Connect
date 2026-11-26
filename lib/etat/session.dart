import 'package:flutter/foundation.dart';

import '../donnees/planning_repository.dart';
import '../donnees/preferences_locales.dart';
import '../modeles/apparence.dart';
import '../modeles/compte.dart';
import '../modeles/seance.dart';

/// État partagé par tous les écrans : compte actif, séances et apparence.
/// Accueil et Planning lisent la même liste [seances], fournie par le même
/// [planning] que l'espace chef.
class Session extends ChangeNotifier {
  Session({
    required this.planning,
    required this.preferences,
    DateTime Function()? horloge,
  }) : _horloge = horloge ?? DateTime.now;

  final PlanningRepository planning;
  final PreferencesLocales preferences;
  final DateTime Function() _horloge;

  List<Compte> profils = const [];
  Compte? actif;
  Apparence apparence = const Apparence();
  List<Seance> seances = const [];
  bool erreur = false;

  /// Écarte la réponse d'un chargement dépassé par un changement de compte.
  int _demande = 0;

  DateTime get maintenant => _horloge();

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
    final resultat = compte is Stagiaire
        ? await _lireSeances(compte)
        : const <Seance>[];
    if (demande != _demande) return;
    actif = compte;
    apparence = choix;
    seances = resultat ?? const [];
    erreur = resultat == null;
    notifyListeners();
  }

  /// Relit le planning du stagiaire actif (retour dans l'application,
  /// geste d'actualisation, réessai).
  Future<void> rafraichir() async {
    final compte = stagiaire;
    if (compte == null) return;
    final demande = ++_demande;
    final resultat = await _lireSeances(compte);
    if (demande != _demande) return;
    // En cas d'échec, le dernier planning connu reste affiché.
    if (resultat != null) seances = resultat;
    erreur = resultat == null && seances.isEmpty;
    notifyListeners();
  }

  Future<void> changerDeCompte() async {
    ++_demande;
    actif = null;
    seances = const [];
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

  Future<List<Seance>?> _lireSeances(Stagiaire stagiaire) async {
    try {
      return [...await planning.seances(stagiaire)]
        ..sort((a, b) => a.debut.compareTo(b.debut));
    } catch (_) {
      return null;
    }
  }
}
