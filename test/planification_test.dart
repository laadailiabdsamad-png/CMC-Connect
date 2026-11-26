import 'package:cmc_connect/donnees/donnees_demo.dart';
import 'package:cmc_connect/donnees/planning_fictif.dart';
import 'package:cmc_connect/modeles/compte.dart';
import 'package:cmc_connect/modeles/planification.dart';
import 'package:cmc_connect/widgets/carte_seance_chef.dart';
import 'package:flutter_test/flutter_test.dart';

import 'outils.dart';

final _chef = comptesDemo.whereType<ChefPole>().single;
final _ines = comptesDemo[0] as Stagiaire;
final _yassine = comptesDemo[1] as Stagiaire;
final _lundi = DateTime(2026, 11, 23);

/// Stockage en mémoire qui peut tomber en panne à la demande.
class StockageTest implements StockagePlanning {
  String? contenu;
  bool panne = false;

  @override
  Future<String?> lire() async => contenu;

  @override
  Future<void> ecrire(String valeur) async {
    if (panne) throw Exception('disque plein');
    contenu = valeur;
  }
}

DetailsSeance _details(
  String groupe,
  int jour,
  (int, int) debut,
  (int, int) fin, {
  String module = 'Développement mobile',
  String formateur = 'Mme Tazi',
  String salle = 'B05',
}) => DetailsSeance(
  groupeId: groupe,
  module: module,
  formateur: formateur,
  salle: salle,
  debut: DateTime(2026, 11, jour, debut.$1, debut.$2),
  fin: DateTime(2026, 11, jour, fin.$1, fin.$2),
);

Future<List<String>> _messagesRefus(Future<Object?> action) async {
  try {
    await action;
  } on PlanningRefuse catch (refus) {
    return [for (final p in refus.problemes) p.message];
  }
  fail('La publication aurait dû être refusée.');
}

void main() {
  late StockageTest stockage;
  late PlanningFictif planning;

  setUp(() {
    stockage = StockageTest();
    planning = PlanningFictif(horloge: horlogeTest, stockage: stockage);
  });

  Future<SeancePlanifiee> seanceDemo(String id) async {
    final semaine = await planning.semaine(_chef, 'dev-201', _lundi);
    return semaine.firstWhere((s) => s.id == id);
  }

  group('Brouillon puis publication', () {
    test('le brouillon B08 laisse B12 visible, la publication bascule', () async {
      final b12 = await seanceDemo('demo-1');
      expect(b12.etat, EtatSeance.publiee);
      final yassineAvant = await planning.seances(_yassine);

      // Le chef prépare le déplacement.
      final details = DetailsSeance(
        groupeId: 'dev-201',
        module: b12.courante.module,
        formateur: b12.courante.formateur,
        salle: 'B08',
        debut: b12.courante.debut,
        fin: b12.courante.fin,
      );
      await planning.enregistrerBrouillon(_chef, details, seanceId: 'demo-1');
      final attente = await seanceDemo('demo-1');
      expect(attente.etat, EtatSeance.modificationEnAttente);
      expect(
        PastilleEtat.libelle(attente),
        'B12 → B08 · Modification en attente',
      );
      var vue = (await planning.seances(_ines)).where((s) => s.id == 'demo-1');
      expect(vue.single.salle, 'B12');

      // Redémarrage : le brouillon est toujours là, la version publique aussi.
      planning = PlanningFictif(horloge: horlogeTest, stockage: stockage);
      expect((await seanceDemo('demo-1')).brouillon?.salle, 'B08');
      expect(
        (await planning.seances(_ines))
            .firstWhere((s) => s.id == 'demo-1')
            .salle,
        'B12',
      );

      await planning.publier(_chef, 'demo-1');
      vue = (await planning.seances(_ines)).where((s) => s.id == 'demo-1');
      expect(vue.single.salle, 'B08');
      expect(vue.single.ancienneSalle, 'B12');
      expect((await seanceDemo('demo-1')).etat, EtatSeance.publiee);

      // Le groupe de Yassine n'a pas bougé.
      final yassineApres = await planning.seances(_yassine);
      expect(
        [for (final s in yassineApres) (s.id, s.salle, s.debut, s.fin)],
        [for (final s in yassineAvant) (s.id, s.salle, s.debut, s.fin)],
      );

      // Et la publication survit à un redémarrage.
      planning = PlanningFictif(horloge: horlogeTest, stockage: stockage);
      expect(
        (await planning.seances(_ines))
            .firstWhere((s) => s.id == 'demo-1')
            .salle,
        'B08',
      );
    });

    test('revenir à la version publiée annule la modification', () async {
      final s = await seanceDemo('demo-1');
      final autre = _details('dev-201', 25, (10, 0), (12, 0), salle: 'B08');
      await planning.enregistrerBrouillon(_chef, autre, seanceId: s.id);
      final annule = await planning.enregistrerBrouillon(
        _chef,
        s.publiee!,
        seanceId: s.id,
      );
      expect(annule.etat, EtatSeance.publiee);
    });

    test(
      'une nouvelle séance reste invisible tant qu’elle est en brouillon',
      () async {
        final avant = (await planning.seances(_ines)).length;
        final s = await planning.enregistrerBrouillon(
          _chef,
          _details('dev-201', 27, (14, 0), (16, 0)),
        );
        expect(s.etat, EtatSeance.brouillon);
        expect(await planning.seances(_ines), hasLength(avant));
        await planning.publier(_chef, s.id);
        expect(await planning.seances(_ines), hasLength(avant + 1));
      },
    );
  });

  group('Conflits', () {
    test('salle B08 occupée de 11 h à 13 h : message précis, brouillon '
        'conservé, puis correction d’un seul champ', () async {
      final brouillon = await planning.enregistrerBrouillon(
        _chef,
        _details('dev-201', 26, (10, 30), (12, 30), salle: 'B08'),
      );
      final messages = await _messagesRefus(
        planning.publier(_chef, brouillon.id),
      );
      expect(messages, [
        'Salle B08 déjà réservée de 11${nb}h à 13${nb}h '
            '(groupe GE 102).',
      ]);
      final apres = await planning.semaine(_chef, 'dev-201', _lundi);
      expect(
        apres.firstWhere((s) => s.id == brouillon.id).etat,
        EtatSeance.brouillon,
      );

      await planning.enregistrerBrouillon(
        _chef,
        _details('dev-201', 26, (10, 30), (12, 30), salle: 'B05'),
        seanceId: brouillon.id,
      );
      final publiee = await planning.publier(_chef, brouillon.id);
      expect(publiee.publiee?.salle, 'B05');
    });

    test('10 h – 12 h chevauche 11 h – 13 h ; 12 h peut suivre 12 h', () {
      final reservation = _details('ge-102', 26, (11, 0), (13, 0));
      expect(
        _details('dev-201', 26, (10, 0), (12, 0)).chevauche(reservation),
        isTrue,
      );
      final matin = _details('dev-201', 26, (10, 0), (12, 0));
      expect(
        _details('dev-201', 26, (12, 0), (14, 0)).chevauche(matin),
        isFalse,
      );
      expect(
        matin.chevauche(_details('dev-201', 26, (12, 0), (14, 0))),
        isFalse,
      );
    });

    test('limites du créneau, vérifiées à la publication', () async {
      // B08 est réservée mercredi de 8 h à 10 h (DEV 101). ID 102, Mme
      // Alaoui et ce créneau sont libres par ailleurs.
      for (final ((d, f), conflit) in [
        (((9, 0), (11, 0)), true),
        (((9, 59), (11, 0)), true),
        (((10, 0), (12, 0)), false),
      ]) {
        final s = await planning.enregistrerBrouillon(
          _chef,
          _details('id-102', 25, d, f, salle: 'B08', formateur: 'Mme Alaoui'),
        );
        if (conflit) {
          await expectLater(
            planning.publier(_chef, s.id),
            throwsA(isA<PlanningRefuse>()),
            reason: '$d – $f',
          );
        } else {
          final ok = await planning.publier(_chef, s.id);
          expect(ok.etat, EtatSeance.publiee, reason: '$d – $f');
          // Libère la salle pour le cas suivant.
          await planning.reinitialiser();
        }
      }
    });

    test('un formateur partagé avec un autre pôle est vérifié', () async {
      final s = await planning.enregistrerBrouillon(
        _chef,
        _details('dev-101', 26, (9, 0), (10, 0), formateur: 'M. Chraibi'),
      );
      expect(await _messagesRefus(planning.publier(_chef, s.id)), [
        'M. Chraibi a déjà cours de 8${nb}h${nb}30 à 10${nb}h${nb}30 '
            '(groupe GE 102).',
      ]);
    });

    test('un groupe ne peut pas avoir deux séances en même temps', () async {
      final s = await planning.enregistrerBrouillon(
        _chef,
        _details('dev-201', 26, (9, 0), (10, 0), salle: 'C07'),
      );
      expect(await _messagesRefus(planning.publier(_chef, s.id)), [
        'Le groupe DEV 201 a déjà une séance de 8${nb}h${nb}30 à '
            '10${nb}h${nb}30 (Programmation Dart).',
      ]);
    });

    test('une séance modifiée n’entre pas en conflit avec elle-même', () async {
      final s = await seanceDemo('demo-1');
      // Même salle, même formateur, même groupe, décalée d'une demi-heure.
      await planning.enregistrerBrouillon(
        _chef,
        _details(
          'dev-201',
          25,
          (10, 30),
          (12, 30),
          module: 'Développement mobile',
          formateur: 'M. Amrani',
          salle: 'B12',
        ),
        seanceId: s.id,
      );
      final publiee = await planning.publier(_chef, s.id);
      expect(publiee.publiee?.debut, DateTime(2026, 11, 25, 10, 30));
    });

    test(
      'deux publications simultanées : une seule obtient la salle',
      () async {
        final a = await planning.enregistrerBrouillon(
          _chef,
          _details('dev-101', 27, (14, 0), (16, 0), salle: 'B08'),
        );
        final b = await planning.enregistrerBrouillon(
          _chef,
          _details(
            'id-102',
            27,
            (15, 0),
            (17, 0),
            salle: 'B08',
            formateur: 'Mme Alaoui',
          ),
        );
        final resultats = await Future.wait([
          planning
              .publier(_chef, a.id)
              .then(
                (_) => true,
                onError: (Object e) => e is PlanningRefuse ? false : throw e,
              ),
          planning
              .publier(_chef, b.id)
              .then(
                (_) => true,
                onError: (Object e) => e is PlanningRefuse ? false : throw e,
              ),
        ]);
        expect(resultats.where((ok) => ok), hasLength(1));
      },
    );
  });

  group('Droits et échecs', () {
    test('le chef ne touche pas aux groupes d’un autre pôle', () async {
      await expectLater(
        planning.semaine(_chef, 'ge-102', _lundi),
        throwsA(isA<PlanningRefuse>()),
      );
      await expectLater(
        planning.enregistrerBrouillon(
          _chef,
          _details('ge-102', 27, (14, 0), (16, 0)),
        ),
        throwsA(isA<PlanningRefuse>()),
      );
      final groupes = (await planning.espacePole(_chef)).groupes;
      expect(groupes.map((g) => g.code), ['DEV 201', 'DEV 101', 'ID 102']);
    });

    test('si l’enregistrement échoue, la version publique reste B12 et le '
        'brouillon B08 est intact', () async {
      final s = await seanceDemo('demo-1');
      await planning.enregistrerBrouillon(
        _chef,
        _details(
          'dev-201',
          25,
          (10, 0),
          (12, 0),
          formateur: 'M. Amrani',
          salle: 'B08',
        ),
        seanceId: s.id,
      );
      stockage.panne = true;
      await expectLater(
        planning.publier(_chef, s.id),
        throwsA(isA<EnregistrementImpossible>()),
      );
      expect(
        (await planning.seances(_ines)).firstWhere((x) => x.id == s.id).salle,
        'B12',
      );
      expect((await seanceDemo('demo-1')).brouillon?.salle, 'B08');
      // Rien n'a été écrit non plus.
      stockage.panne = false;
      planning = PlanningFictif(horloge: horlogeTest, stockage: stockage);
      expect(
        (await seanceDemo('demo-1')).etat,
        EtatSeance.modificationEnAttente,
      );
    });

    test('une séance déjà commencée ne se publie pas', () async {
      final s = await planning.enregistrerBrouillon(
        _chef,
        _details('dev-201', 25, (8, 0), (9, 0), salle: 'C07'),
      );
      expect(await _messagesRefus(planning.publier(_chef, s.id)), [
        'Cette séance a déjà commencé : choisissez un horaire à venir.',
      ]);
    });
  });

  group('Formulaire', () {
    test('champs obligatoires', () {
      final messages = [for (final p in ValeursFiche().verifier()) p.message];
      expect(messages, [
        'Choisissez un groupe.',
        'Choisissez un module.',
        'Choisissez un formateur.',
        'Choisissez une salle.',
        'Choisissez une date.',
        'Indiquez l’heure de début.',
        'Indiquez l’heure de fin.',
      ]);
    });

    test('cohérence des horaires', () {
      List<String> verifier(int debut, int fin, {int jour = 26}) => [
        for (final p in ValeursFiche(
          groupeId: 'dev-201',
          module: 'Développement mobile',
          formateur: 'Mme Tazi',
          salle: 'B05',
          date: DateTime(2026, 11, jour),
          debut: debut,
          fin: fin,
        ).verifier())
          p.message,
      ];
      expect(verifier(600, 720), isEmpty);
      expect(verifier(720, 600), [
        'L’heure de fin doit être après l’heure de début.',
      ]);
      expect(verifier(600, 600), [
        'L’heure de fin doit être après l’heure de début.',
      ]);
      expect(verifier(600, 615), ['Une séance dure au moins 30 minutes.']);
      expect(verifier(420, 540), ['Les séances commencent à 8 h au plus tôt.']);
      expect(verifier(1140, 1230), [
        'Les séances se terminent à 20 h au plus tard.',
      ]);
      expect(verifier(600, 720, jour: 29), [
        'Le dimanche n’est pas un jour de cours.',
      ]);
    });
  });
}
