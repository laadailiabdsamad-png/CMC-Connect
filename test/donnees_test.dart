import 'package:cmc_connect/donnees/donnees_demo.dart';
import 'package:cmc_connect/donnees/planning_fictif.dart';
import 'package:cmc_connect/donnees/planning_repository.dart';
import 'package:cmc_connect/donnees/preferences_locales.dart';
import 'package:cmc_connect/etat/session.dart';
import 'package:cmc_connect/modeles/apparence.dart';
import 'package:cmc_connect/modeles/compte.dart';
import 'package:cmc_connect/modeles/planification.dart';
import 'package:cmc_connect/modeles/seance.dart';
import 'package:flutter_test/flutter_test.dart';

import 'outils.dart';

void main() {
  setUp(preferencesVides);

  group('Données de démonstration', () {
    test('comptes : deux stagiaires de groupes différents, un formateur, '
        'un chef', () {
      final stagiaires = comptesDemo.whereType<Stagiaire>().toList();
      expect(stagiaires, hasLength(2));
      expect(stagiaires.map((s) => s.groupeId).toSet(), hasLength(2));
      final amrani = comptesDemo.whereType<Formateur>().single;
      expect(amrani.nom, 'M. Amrani');
      expect(amrani.enseigne('dev-201', 'Développement mobile'), isTrue);
      expect(amrani.enseigne('ge-102', 'Comptabilité générale'), isFalse);
      final chef = comptesDemo.whereType<ChefPole>().single;
      expect(chef.nom, 'Chef du pôle Digital');
      final groupes = groupesDemo.where((g) => g.poleId == chef.poleId);
      expect(groupes.map((g) => g.code), containsAll(['DEV 201', 'DEV 101']));
      expect(groupes.any((g) => g.code == 'GE 102'), isFalse);
    });

    test('le départ est le premier jour ouvré où 10 h est à venir', () {
      // Deux semaines, toutes les demi-heures, week-ends compris.
      for (var i = 0; i < 14 * 48; i++) {
        final instant = DateTime(2026, 12, 21, 0, 30 * i);
        final ancrage = ancrageDemo(instant);
        expect(ancrage.weekday, lessThanOrEqualTo(DateTime.friday));
        expect(
          DateTime(
            ancrage.year,
            ancrage.month,
            ancrage.day,
            10,
          ).isAfter(instant),
          isTrue,
        );
        final initial = planningInitial(ancrage);
        expect(
          initial.every((s) => s.courante.debut.weekday <= DateTime.friday),
          isTrue,
        );
        // Aucun conflit dans le planning de départ.
        final publiees = [
          for (final s in initial)
            if (s.publiee != null) s,
        ];
        for (final a in publiees) {
          for (final b in publiees) {
            if (a.id == b.id || !a.publiee!.chevauche(b.publiee!)) continue;
            expect(a.publiee!.salle, isNot(b.publiee!.salle));
            expect(a.publiee!.formateur, isNot(b.publiee!.formateur));
            expect(a.publiee!.groupeId, isNot(b.publiee!.groupeId));
          }
        }
      }
    });

    test('Inès a d’abord sa séance de 10 h en B12, sans changement', () async {
      final planning = PlanningFictif(horloge: horlogeTest);
      final ines = comptesDemo.first as Stagiaire;
      final premiere = (await planning.seances(ines)).first;
      expect(premiere.debut, DateTime(2026, 11, 25, 10));
      expect((premiere.salle, premiere.formateur), ('B12', 'M. Amrani'));
      expect(premiere.salleModifiee, isFalse);
    });
  });

  group('Apparence enregistrée', () {
    test('toutes les combinaisons se relisent', () {
      for (final style in StyleApp.values) {
        for (final luminosite in Luminosite.values) {
          final a = Apparence(style: style, luminosite: luminosite);
          expect(Apparence.decoder(a.encoder()), a);
        }
      }
    });

    test('une valeur inconnue redonne le réglage par défaut', () {
      for (final v in [null, '', 'x', 'simple', 'simple/x', 'a/b/c']) {
        expect(Apparence.decoder(v), const Apparence());
      }
    });

    test('chaque compte, chef compris, retrouve son réglage', () async {
      Session nouvelle() => Session(
        planning: PlanningFictif(horloge: horlogeTest),
        preferences: PreferencesAppareil(),
        horloge: horlogeTest,
      );
      const verreSombre = Apparence(
        style: StyleApp.liquidGlass,
        luminosite: Luminosite.sombre,
      );
      const simpleClair = Apparence(luminosite: Luminosite.clair);
      const verreClair = Apparence(
        style: StyleApp.liquidGlass,
        luminosite: Luminosite.clair,
      );

      final premiere = nouvelle();
      await premiere.demarrer();
      expect(premiere.actif, isNull);
      final [ines, yassine, _, chef] = premiere.profils;
      await premiere.choisir(ines);
      expect(await premiere.appliquer(verreSombre), isTrue);
      await premiere.choisir(chef);
      expect(premiere.apparence, const Apparence());
      expect(await premiere.appliquer(verreClair), isTrue);
      await premiere.choisir(yassine);
      expect(await premiere.appliquer(simpleClair), isTrue);

      final seconde = nouvelle();
      await seconde.demarrer();
      expect(seconde.actif?.id, yassine.id);
      expect(seconde.apparence, simpleClair);
      await seconde.choisir(ines);
      expect(seconde.apparence, verreSombre);
      await seconde.choisir(chef);
      expect(seconde.apparence, verreClair);
      expect(seconde.seances, isEmpty);
    });

    test('un enregistrement refusé ne change pas le thème', () async {
      final session = Session(
        planning: PlanningFictif(horloge: horlogeTest),
        preferences: _PreferencesEnPanne(),
        horloge: horlogeTest,
      );
      await session.demarrer();
      await session.choisir(session.profils.first);
      final ok = await session.appliquer(
        const Apparence(style: StyleApp.liquidGlass),
      );
      expect(ok, isFalse);
      expect(session.apparence, const Apparence());
      expect(session.prochaine, isNotNull);
    });
  });

  test('un planning illisible est signalé, sans planter', () async {
    final session = Session(
      planning: _PlanningEnPanne(),
      preferences: PreferencesAppareil(),
    );
    await session.demarrer();
    await session.choisir(session.profils.first);
    expect(session.erreur, isTrue);
    expect(session.prochaine, isNull);
  });
}

class _PreferencesEnPanne implements PreferencesLocales {
  @override
  Future<String?> dernierCompte() async => throw Exception('panne');
  @override
  Future<void> retenirCompte(String? stagiaireId) async =>
      throw Exception('panne');
  @override
  Future<Apparence> apparence(String stagiaireId) async =>
      throw Exception('panne');
  @override
  Future<void> enregistrerApparence(String stagiaireId, Apparence a) async =>
      throw Exception('panne');
}

class _PlanningEnPanne implements PlanningRepository {
  @override
  Future<List<Compte>> comptes() async => comptesDemo;
  @override
  Future<List<Seance>> seances(Stagiaire stagiaire) async =>
      throw Exception('panne');
  @override
  Future<List<Seance>> seancesFormateur(Formateur formateur) async =>
      throw Exception('panne');
  @override
  Future<EspacePole> espacePole(ChefPole chef) async =>
      throw Exception('panne');
  @override
  Future<List<SeancePlanifiee>> semaine(
    ChefPole chef,
    String groupeId,
    DateTime lundi,
  ) async => throw Exception('panne');
  @override
  Future<SeancePlanifiee> enregistrerBrouillon(
    ChefPole chef,
    DetailsSeance details, {
    String? seanceId,
  }) async => throw Exception('panne');
  @override
  Future<SeancePlanifiee> publier(ChefPole chef, String seanceId) async =>
      throw Exception('panne');
  @override
  Future<void> reinitialiser() async => throw Exception('panne');
}
