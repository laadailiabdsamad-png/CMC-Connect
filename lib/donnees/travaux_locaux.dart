import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../modeles/compte.dart';
import '../modeles/planification.dart';
import '../modeles/travaux.dart';
import 'fichiers.dart';
import 'planning_fictif.dart';
import 'planning_repository.dart';
import 'travaux_repository.dart';

class StockageTravaux implements StockagePlanning {
  final _prefs = SharedPreferencesAsync();
  static const _cle = 'travaux.demo.v1';

  @override
  Future<String?> lire() => _prefs.getString(_cle);

  @override
  Future<void> ecrire(String contenu) => _prefs.setString(_cle, contenu);
}

class _Etat {
  _Etat(this.tps, this.supports, this.rendus);

  final Map<String, Tp> tps;
  final Map<String, Support> supports;

  /// Clé : TP et stagiaire. Un nouveau dépôt remplace l'ancien.
  final Map<String, Rendu> rendus;

  _Etat copie() => _Etat({...tps}, {...supports}, {...rendus});
}

/// TP, supports et rendus de démonstration, enregistrés sur le téléphone :
/// la description dans les préférences, les fichiers dans le dossier privé
/// de l'application.
///
/// Les droits viennent des mêmes données que le planning : la séance doit
/// être publiée, animée par ce formateur, pour un groupe et un module qu'il
/// enseigne.
class TravauxLocaux implements TravauxRepository {
  TravauxLocaux({
    required this.planning,
    DateTime Function()? horloge,
    StockagePlanning? stockage,
    CoffreFichiers? coffre,
  }) : _horloge = horloge ?? DateTime.now,
       _stockage = stockage ?? StockageTravaux(),
       _coffre = coffre ?? CoffreAppareil();

  final PlanningRepository planning;
  final DateTime Function() _horloge;
  final StockagePlanning _stockage;
  final CoffreFichiers _coffre;

  _Etat? _etat;
  int _compteur = 0;
  Future<void> _file = Future.value();

  Future<T> _exclusif<T>(Future<T> Function() action) {
    final resultat = _file.then((_) => action());
    _file = resultat.then((_) {}, onError: (_) {});
    return resultat;
  }

  Future<_Etat> _charger() async {
    if (_etat case final etat?) return etat;
    final contenu = await _stockage.lire();
    if (contenu != null) {
      try {
        final j = jsonDecode(contenu) as Map<String, Object?>;
        Map<String, Object?> m(Object? o) => (o! as Map).cast();
        final tps = [for (final t in j['tps']! as List) Tp.depuisJson(m(t))];
        final supports = [
          for (final s in j['supports']! as List) Support.depuisJson(m(s)),
        ];
        final rendus = [
          for (final r in j['rendus']! as List) Rendu.depuisJson(m(r)),
        ];
        _compteur = j['compteur']! as int;
        return _etat = _Etat(
          {for (final t in tps) t.id: t},
          {for (final s in supports) s.id: s},
          {for (final r in rendus) _cleRendu(r.tpId, r.stagiaireId): r},
        );
      } on Object {
        // Contenu illisible : on repart sans TP.
      }
    }
    return _etat = _Etat({}, {}, {});
  }

  static String _cleRendu(String tpId, String stagiaireId) =>
      '$tpId/$stagiaireId';

  Future<void> _ecrire(_Etat etat) async {
    try {
      await _stockage.ecrire(
        jsonEncode({
          'compteur': _compteur,
          'tps': [for (final t in etat.tps.values) t.enJson()],
          'supports': [for (final s in etat.supports.values) s.enJson()],
          'rendus': [for (final r in etat.rendus.values) r.enJson()],
        }),
      );
    } on Object {
      throw const EnregistrementImpossible();
    }
  }

  String _nouvelId(String prefixe) =>
      '$prefixe-${_horloge().millisecondsSinceEpoch}-${++_compteur}';

  Future<PieceJointe> _ranger(String id, FichierChoisi fichier) async {
    try {
      return await _coffre.ranger(id, fichier);
    } on Object {
      throw const EnregistrementImpossible();
    }
  }

  /// Écrit le fichier, puis la description ; si la description ne peut pas
  /// être enregistrée, le fichier est retiré et rien ne change.
  Future<T> _valider<T>(
    _Etat suivant,
    T resultat, {
    PieceJointe? nouvelle,
  }) async {
    try {
      await _ecrire(suivant);
    } on EnregistrementImpossible {
      if (nouvelle != null) await _supprimer(nouvelle);
      rethrow;
    }
    _etat = suivant;
    return resultat;
  }

  /// Un fichier qui n'est plus référencé ; son retrait peut échouer sans
  /// conséquence.
  Future<void> _supprimer(PieceJointe piece) async {
    try {
      await _coffre.supprimer(piece);
    } on Object {
      // Fichier orphelin, sans effet sur les données.
    }
  }

  /// La séance publiée, si le formateur l'anime et enseigne ce module à ce
  /// groupe.
  Future<({String groupeId, String module})> _seanceAutorisee(
    Formateur formateur,
    String seanceId,
  ) async {
    final seances = await planning.seancesFormateur(formateur);
    for (final s in seances) {
      if (s.id != seanceId) continue;
      final groupe = s.groupeId;
      if (groupe != null && formateur.enseigne(groupe, s.module)) {
        return (groupeId: groupe, module: s.module);
      }
    }
    throw const TravailRefuse([
      ProblemeTravail('Vous n’êtes pas affecté à ce groupe pour ce module.'),
    ]);
  }

  @override
  Future<List<TpSuivi>> tpsFormateur(Formateur formateur) =>
      _exclusif(() async {
        final etat = await _charger();
        return [
          for (final tp in etat.tps.values)
            if (tp.formateurId == formateur.id)
              TpSuivi(
                tp: tp,
                rendus: [
                  for (final r in etat.rendus.values)
                    if (r.tpId == tp.id) r,
                ]..sort((a, b) => a.deposeLe.compareTo(b.deposeLe)),
              ),
        ]..sort((a, b) => a.tp.echeance.compareTo(b.tp.echeance));
      });

  @override
  Future<List<Support>> supportsFormateur(Formateur formateur) =>
      _exclusif(() async {
        final etat = await _charger();
        return [
          for (final s in etat.supports.values)
            if (s.formateurId == formateur.id) s,
        ]..sort((a, b) => b.publieLe.compareTo(a.publieLe));
      });

  @override
  Future<Support> ajouterSupport(
    Formateur formateur, {
    required String seanceId,
    required String titre,
    required FichierChoisi? fichier,
  }) => _exclusif(() async {
    final problemes = verifierSupport(titre: titre, fichier: fichier);
    if (problemes.isNotEmpty) throw TravailRefuse(problemes);
    final seance = await _seanceAutorisee(formateur, seanceId);
    final etat = (await _charger()).copie();
    final id = _nouvelId('support');
    final piece = await _ranger(id, fichier!);
    final support = Support(
      id: id,
      groupeId: seance.groupeId,
      module: seance.module,
      seanceId: seanceId,
      formateurId: formateur.id,
      formateurNom: formateur.nom,
      titre: titre.trim(),
      piece: piece,
      publieLe: _horloge(),
    );
    etat.supports[id] = support;
    return _valider(etat, support, nouvelle: piece);
  });

  @override
  Future<Tp> publierTp(
    Formateur formateur, {
    required String seanceId,
    required String titre,
    required String consigne,
    required DateTime? echeance,
    FichierChoisi? piece,
  }) => _exclusif(() async {
    final problemes = verifierTp(
      titre: titre,
      consigne: consigne,
      echeance: echeance,
      maintenant: _horloge(),
      piece: piece,
    );
    if (problemes.isNotEmpty) throw TravailRefuse(problemes);
    final seance = await _seanceAutorisee(formateur, seanceId);
    final etat = (await _charger()).copie();
    final id = _nouvelId('tp');
    final jointe = piece == null ? null : await _ranger(id, piece);
    final tp = Tp(
      id: id,
      groupeId: seance.groupeId,
      module: seance.module,
      seanceId: seanceId,
      formateurId: formateur.id,
      formateurNom: formateur.nom,
      titre: titre.trim(),
      consigne: consigne.trim(),
      echeance: echeance!,
      publieLe: _horloge(),
      piece: jointe,
    );
    etat.tps[id] = tp;
    return _valider(etat, tp, nouvelle: jointe);
  });

  @override
  Future<List<TravailStagiaire>> travauxStagiaire(Stagiaire stagiaire) =>
      _exclusif(() async {
        final etat = await _charger();
        return [
          for (final tp in etat.tps.values)
            if (tp.groupeId == stagiaire.groupeId)
              TravailStagiaire(
                tp: tp,
                rendu: etat.rendus[_cleRendu(tp.id, stagiaire.id)],
              ),
        ]..sort((a, b) => a.tp.echeance.compareTo(b.tp.echeance));
      });

  @override
  Future<List<Support>> supportsStagiaire(Stagiaire stagiaire) =>
      _exclusif(() async {
        final etat = await _charger();
        return [
          for (final s in etat.supports.values)
            if (s.groupeId == stagiaire.groupeId) s,
        ]..sort((a, b) => b.publieLe.compareTo(a.publieLe));
      });

  @override
  Future<Rendu> deposer(
    Stagiaire stagiaire,
    String tpId,
    FichierChoisi? fichier,
  ) => _exclusif(() async {
    final etat = (await _charger()).copie();
    final tp = etat.tps[tpId];
    if (tp == null || tp.groupeId != stagiaire.groupeId) {
      throw const TravailRefuse([
        ProblemeTravail('Ce TP n’est pas destiné à votre groupe.'),
      ]);
    }
    if (fichier == null) {
      throw const TravailRefuse([
        ProblemeTravail('Choisissez un fichier.', ChampTravail.fichier),
      ]);
    }
    final problemes = verifierFichier(fichier);
    if (problemes.isNotEmpty) throw TravailRefuse(problemes);

    final cle = _cleRendu(tpId, stagiaire.id);
    final ancien = etat.rendus[cle];
    final id = _nouvelId('rendu');
    final piece = await _ranger(id, fichier);
    final rendu = Rendu(
      id: id,
      tpId: tpId,
      stagiaireId: stagiaire.id,
      stagiaireNom: stagiaire.prenom,
      piece: piece,
      deposeLe: _horloge(),
    );
    etat.rendus[cle] = rendu;
    final resultat = await _valider(etat, rendu, nouvelle: piece);
    if (ancien != null) await _supprimer(ancien.piece);
    return resultat;
  });

  @override
  Future<void> reinitialiser() => _exclusif(() async {
    final vide = _Etat({}, {}, {});
    _compteur = 0;
    await _ecrire(vide);
    _etat = vide;
    try {
      await _coffre.vider();
    } on Object {
      // Les anciens fichiers ne sont plus référencés.
    }
  });
}
