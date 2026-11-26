import 'dart:async';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../modeles/compte.dart';
import '../modeles/planification.dart';
import '../modeles/seance.dart';
import '../theme/dates_fr.dart';
import 'conflits.dart';
import 'donnees_demo.dart';
import 'planning_repository.dart';

/// Où le planning de démonstration est enregistré.
abstract interface class StockagePlanning {
  Future<String?> lire();
  Future<void> ecrire(String contenu);
}

class StockageAppareil implements StockagePlanning {
  final _prefs = SharedPreferencesAsync();
  static const _cle = 'planning.demo.v2';

  @override
  Future<String?> lire() => _prefs.getString(_cle);

  @override
  Future<void> ecrire(String contenu) => _prefs.setString(_cle, contenu);
}

/// Planning de démonstration, enregistré sur le téléphone.
///
/// Il applique les règles que le serveur appliquera : droits du chef sur les
/// groupes de son pôle, horaires cohérents, conflits de salle, de formateur
/// et de groupe. Les écritures passent une par une : deux publications
/// lancées en même temps ne peuvent pas réserver le même créneau.
class PlanningFictif implements PlanningRepository {
  PlanningFictif({DateTime Function()? horloge, StockagePlanning? stockage})
    : _horloge = horloge ?? DateTime.now,
      _stockage = stockage ?? StockageAppareil();

  final DateTime Function() _horloge;
  final StockagePlanning _stockage;

  Map<String, SeancePlanifiee>? _seances;
  int _compteur = 0;
  Future<void> _file = Future.value();

  /// Exécute [action] seule, après les opérations déjà lancées.
  Future<T> _exclusif<T>(Future<T> Function() action) {
    final resultat = _file.then((_) => action());
    _file = resultat.then((_) {}, onError: (_) {});
    return resultat;
  }

  Future<Map<String, SeancePlanifiee>> _charger() async {
    if (_seances case final seances?) return seances;
    final contenu = await _stockage.lire();
    if (contenu != null) {
      try {
        final json = jsonDecode(contenu) as Map<String, Object?>;
        final lues = [
          for (final s in json['seances']! as List)
            SeancePlanifiee.depuisJson((s as Map).cast<String, Object?>()),
        ];
        _compteur = json['compteur']! as int;
        return _seances = {for (final s in lues) s.id: s};
      } on Object {
        // Contenu illisible : on repart du planning de démonstration.
      }
    }
    final initial = _initial();
    try {
      await _ecrire(initial);
    } on EnregistrementImpossible {
      // Le planning reste utilisable pour cette ouverture.
    }
    return _seances = initial;
  }

  Map<String, SeancePlanifiee> _initial() => {
    for (final s in planningInitial(ancrageDemo(_horloge()))) s.id: s,
  };

  Future<void> _ecrire(Map<String, SeancePlanifiee> seances) async {
    try {
      await _stockage.ecrire(
        jsonEncode({
          'compteur': _compteur,
          'seances': [for (final s in seances.values) s.enJson()],
        }),
      );
    } on Object {
      throw const EnregistrementImpossible();
    }
  }

  /// Écrit d'abord, puis remplace l'état en mémoire : un échec ne laisse
  /// aucune trace.
  Future<SeancePlanifiee> _remplacer(SeancePlanifiee seance) async {
    final suivant = {...await _charger(), seance.id: seance};
    await _ecrire(suivant);
    _seances = suivant;
    return seance;
  }

  static Groupe? _groupe(String id) {
    for (final g in groupesDemo) {
      if (g.id == id) return g;
    }
    return null;
  }

  static String _nomGroupe(String id) => _groupe(id)?.code ?? id;

  static void _verifierDroit(ChefPole chef, String groupeId) {
    if (_groupe(groupeId)?.poleId != chef.poleId) {
      throw const PlanningRefuse([
        Probleme('Ce groupe ne fait pas partie de votre pôle.', Champ.groupe),
      ]);
    }
  }

  @override
  Future<List<Compte>> comptes() async => comptesDemo;

  @override
  Future<List<Seance>> seances(Stagiaire stagiaire) async {
    final toutes = await _exclusif(_charger);
    return [
      for (final s in toutes.values)
        if (s.publiee case final p? when p.groupeId == stagiaire.groupeId)
          Seance(
            id: s.id,
            module: p.module,
            formateur: p.formateur,
            debut: p.debut,
            fin: p.fin,
            salle: p.salle,
            ancienneSalle: s.sallePrecedente,
          ),
    ]..sort((a, b) => a.debut.compareTo(b.debut));
  }

  @override
  Future<EspacePole> espacePole(ChefPole chef) async => EspacePole(
    groupes: [
      for (final g in groupesDemo)
        if (g.poleId == chef.poleId) g,
    ],
    modules: modulesParPole[chef.poleId] ?? const [],
    formateurs: formateursDemo,
    salles: sallesDemo,
  );

  @override
  Future<List<SeancePlanifiee>> semaine(
    ChefPole chef,
    String groupeId,
    DateTime lundi,
  ) async {
    _verifierDroit(chef, groupeId);
    final toutes = await _exclusif(_charger);
    final debut = minuit(lundi);
    final fin = DateTime(debut.year, debut.month, debut.day + 7);
    return [
      for (final s in toutes.values)
        if (s.courante.groupeId == groupeId &&
            !s.courante.debut.isBefore(debut) &&
            s.courante.debut.isBefore(fin))
          s,
    ]..sort((a, b) => a.courante.debut.compareTo(b.courante.debut));
  }

  @override
  Future<SeancePlanifiee> enregistrerBrouillon(
    ChefPole chef,
    DetailsSeance details, {
    String? seanceId,
  }) => _exclusif(() async {
    _verifierDroit(chef, details.groupeId);
    final problemes = verifierHoraires(details.debut, details.fin);
    if (problemes.isNotEmpty) throw PlanningRefuse(problemes);

    final toutes = await _charger();
    if (seanceId == null) {
      _compteur++;
      return _remplacer(
        SeancePlanifiee(
          id: 'seance-${_horloge().millisecondsSinceEpoch}-$_compteur',
          brouillon: details,
        ),
      );
    }
    final existante = toutes[seanceId];
    if (existante == null) {
      throw const PlanningRefuse([
        Probleme('Cette séance n’existe plus. Actualisez le planning.'),
      ]);
    }
    _verifierDroit(chef, existante.courante.groupeId);
    // Revenir exactement à la version publiée annule la modification.
    final brouillon = details == existante.publiee ? null : details;
    return _remplacer(existante.avec(brouillon: brouillon));
  });

  @override
  Future<SeancePlanifiee> publier(ChefPole chef, String seanceId) =>
      _exclusif(() async {
        final toutes = await _charger();
        final seance = toutes[seanceId];
        if (seance == null) {
          throw const PlanningRefuse([
            Probleme('Cette séance n’existe plus. Actualisez le planning.'),
          ]);
        }
        final brouillon = seance.brouillon;
        if (brouillon == null) return seance;
        _verifierDroit(chef, brouillon.groupeId);
        if (seance.publiee case final p?) _verifierDroit(chef, p.groupeId);

        final problemes = [
          ...verifierHoraires(brouillon.debut, brouillon.fin),
          if (!brouillon.debut.isAfter(_horloge()))
            const Probleme(
              'Cette séance a déjà commencé : choisissez un horaire à venir.',
              Champ.debut,
            ),
          ...chercherConflits(
            brouillon,
            toutes.values,
            exclure: seanceId,
            nomGroupe: _nomGroupe,
          ),
        ];
        if (problemes.isNotEmpty) throw PlanningRefuse(problemes);

        final avant = seance.publiee?.salle;
        final precedente = avant == null || avant == brouillon.salle
            ? seance.sallePrecedente
            : avant;
        return _remplacer(
          SeancePlanifiee(
            id: seance.id,
            publiee: brouillon,
            sallePrecedente: precedente == brouillon.salle ? null : precedente,
          ),
        );
      });

  @override
  Future<void> reinitialiser() => _exclusif(() async {
    final initial = _initial();
    _compteur = 0;
    await _ecrire(initial);
    _seances = initial;
  });
}
