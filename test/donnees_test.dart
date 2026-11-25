import 'package:cmc_connect/donnees/planning_fictif.dart';
import 'package:cmc_connect/donnees/planning_repository.dart';
import 'package:cmc_connect/donnees/preferences_locales.dart';
import 'package:cmc_connect/etat/session.dart';
import 'package:cmc_connect/modeles/apparence.dart';
import 'package:cmc_connect/modeles/seance.dart';
import 'package:cmc_connect/modeles/stagiaire.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  group('Données fictives', () {
    test('deux profils, deux groupes différents', () async {
      final profils = await PlanningFictif().profils();
      expect(profils, hasLength(2));
      expect(profils.map((p) => p.groupe).toSet(), hasLength(2));
    });

    test('il y a toujours une prochaine séance, un jour ouvré', () async {
      final profils = await PlanningFictif().profils();
      // Deux semaines, toutes les demi-heures, passage du week-end compris.
      for (var i = 0; i < 14 * 48; i++) {
        final instant = DateTime(2026, 12, 21, 0, 30 * i);
        final source = PlanningFictif(horloge: () => instant);
        for (final profil in profils) {
          final seances = await source.seances(profil);
          expect(seances.first.debut.isAfter(instant), isTrue);
          expect(
            seances.every((s) => s.debut.weekday <= DateTime.friday),
            isTrue,
          );
        }
        final ines = (await source.seances(profils.first)).first;
        expect((ines.ancienneSalle, ines.salle), ('B12', 'B08'));
        expect((ines.debut.hour, ines.formateur), (10, 'M. Amrani'));
      }
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

    test('chaque compte retrouve son réglage après redémarrage', () async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      Session nouvelle() => Session(
        planning: PlanningFictif(),
        preferences: PreferencesAppareil(),
      );
      const verreSombre = Apparence(
        style: StyleApp.liquidGlass,
        luminosite: Luminosite.sombre,
      );
      const simpleClair = Apparence(luminosite: Luminosite.clair);

      final premiere = nouvelle();
      await premiere.demarrer();
      expect(premiere.actif, isNull);
      await premiere.choisir(premiere.profils[0]);
      expect(await premiere.appliquer(verreSombre), isTrue);
      await premiere.changerDeCompte();
      await premiere.choisir(premiere.profils[1]);
      expect(premiere.apparence, const Apparence());
      expect(await premiere.appliquer(simpleClair), isTrue);

      final seconde = nouvelle();
      await seconde.demarrer();
      expect(seconde.actif?.id, seconde.profils[1].id);
      expect(seconde.apparence, simpleClair);
      await seconde.changerDeCompte();
      await seconde.choisir(seconde.profils[0]);
      expect(seconde.apparence, verreSombre);
    });

    test('un enregistrement refusé ne change pas le thème', () async {
      final session = Session(
        planning: PlanningFictif(),
        preferences: _PreferencesEnPanne(),
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
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
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
  Future<List<Stagiaire>> profils() => PlanningFictif().profils();
  @override
  Future<List<Seance>> seances(Stagiaire stagiaire) async =>
      throw Exception('panne');
}
