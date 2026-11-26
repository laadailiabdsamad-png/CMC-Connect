import 'dart:convert';
import 'dart:io';

import 'package:cmc_connect/donnees/donnees_demo.dart';
import 'package:cmc_connect/donnees/fichiers.dart';
import 'package:cmc_connect/donnees/planning_fictif.dart';
import 'package:cmc_connect/donnees/travaux_locaux.dart';
import 'package:cmc_connect/modeles/compte.dart';
import 'package:cmc_connect/modeles/planification.dart';
import 'package:cmc_connect/modeles/travaux.dart';
import 'package:flutter_test/flutter_test.dart';

import 'outils.dart';
import 'planification_test.dart' show StockageTest;

final _ines = comptesDemo[0] as Stagiaire;
final _yassine = comptesDemo[1] as Stagiaire;
final _amrani = comptesDemo.whereType<Formateur>().single;
final _chef = comptesDemo.whereType<ChefPole>().single;

/// Mme Tazi n'enseigne pas Développement mobile à DEV 201.
const _tazi = Formateur(
  id: 'formateur-tazi',
  nom: 'Mme Tazi',
  affectations: [
    Affectation(groupeId: 'dev-201', module: 'Conception d’interfaces'),
  ],
);

final _echeance = DateTime(2026, 12, 2, 18);

Future<List<String>> _refus(Future<Object?> action) async {
  try {
    await action;
  } on TravailRefuse catch (r) {
    return [for (final p in r.problemes) p.message];
  }
  fail('L’opération aurait dû être refusée.');
}

void main() {
  late StockageTest stockagePlanning;
  late StockageTest stockageTravaux;
  late CoffreMemoire coffre;
  late PlanningFictif planning;
  late TravauxLocaux travaux;

  void ouvrir() {
    planning = PlanningFictif(horloge: horlogeTest, stockage: stockagePlanning);
    travaux = TravauxLocaux(
      planning: planning,
      horloge: horlogeTest,
      stockage: stockageTravaux,
      coffre: coffre,
    );
  }

  setUp(() {
    stockagePlanning = StockageTest();
    stockageTravaux = StockageTest();
    coffre = CoffreMemoire();
    ouvrir();
  });

  Future<Tp> publierTp({FichierChoisi? piece}) => travaux.publierTp(
    _amrani,
    seanceId: 'demo-1',
    titre: 'Exercice Flutter',
    consigne: 'Créer un écran de connexion.',
    echeance: _echeance,
    piece: piece,
  );

  test('M. Amrani voit ses séances publiées, dans tous ses groupes', () async {
    final seances = await planning.seancesFormateur(_amrani);
    expect(seances.map((s) => s.id), ['demo-1', 'demo-3', 'demo-6']);
    expect(seances.first.groupe, 'DEV 201');
    expect(seances.every((s) => s.formateur == 'M. Amrani'), isTrue);
  });

  test('le changement de salle publié par le chef arrive chez le formateur '
      'et chez Inès, depuis la même source', () async {
    final d = (await planning.semaine(
      _chef,
      'dev-201',
      DateTime(2026, 11, 23),
    )).firstWhere((s) => s.id == 'demo-1').publiee!;
    await planning.enregistrerBrouillon(
      _chef,
      DetailsSeance(
        groupeId: d.groupeId,
        module: d.module,
        formateur: d.formateur,
        salle: 'B08',
        debut: d.debut,
        fin: d.fin,
      ),
      seanceId: 'demo-1',
    );
    // Brouillon : personne ne voit B08.
    expect((await planning.seancesFormateur(_amrani)).first.salle, 'B12');
    await planning.publier(_chef, 'demo-1');
    expect((await planning.seancesFormateur(_amrani)).first.salle, 'B08');
    expect((await planning.seances(_ines)).first.salle, 'B08');
  });

  test('du TP au rendu, avec isolation du groupe de Yassine', () async {
    final tp = await publierTp(piece: fichierTexte('enonce.txt', 'Énoncé'));
    expect((tp.groupeId, tp.module), ('dev-201', 'Développement mobile'));
    expect(await coffre.lire(tp.piece!), utf8.encode('Énoncé'));

    final travauxInes = await travaux.travauxStagiaire(_ines);
    expect(travauxInes.single.tp.id, tp.id);
    expect(travauxInes.single.rendu, isNull);
    expect(await travaux.travauxStagiaire(_yassine), isEmpty);
    expect(
      await _refus(
        travaux.deposer(_yassine, tp.id, fichierTexte('y.txt', 'y')),
      ),
      ['Ce TP n’est pas destiné à votre groupe.'],
    );

    final rendu = await travaux.deposer(
      _ines,
      tp.id,
      fichierTexte('reponse.txt', 'Réponse d’Inès'),
    );
    expect(rendu.stagiaireNom, 'Inès');
    expect(rendu.deposeLe, horlogeTest());

    final suivi = (await travaux.tpsFormateur(_amrani)).single;
    expect(suivi.rendus.single.piece.nom, 'reponse.txt');
    expect(
      await coffre.lire(suivi.rendus.single.piece),
      utf8.encode('Réponse d’Inès'),
    );

    // Redémarrage : TP, pièce jointe et rendu sont toujours là.
    ouvrir();
    final apres = (await travaux.travauxStagiaire(_ines)).single;
    expect(apres.tp.titre, 'Exercice Flutter');
    expect(apres.rendu?.piece.nom, 'reponse.txt');
    expect(await coffre.lire(apres.tp.piece!), utf8.encode('Énoncé'));
  });

  test(
    'un nouveau dépôt remplace le précédent et retire l’ancien fichier',
    () async {
      final tp = await publierTp();
      final premier = await travaux.deposer(
        _ines,
        tp.id,
        fichierTexte('v1.txt', '1'),
      );
      await travaux.deposer(_ines, tp.id, fichierTexte('v2.txt', '2'));
      final suivi = (await travaux.tpsFormateur(_amrani)).single;
      expect(suivi.rendus.map((r) => r.piece.nom), ['v2.txt']);
      expect(coffre.contenus.containsKey(premier.piece.chemin), isFalse);
    },
  );

  test('un formateur ne publie que pour ses affectations', () async {
    // Mme Tazi n'anime pas demo-1 et n'enseigne pas ce module à DEV 201.
    expect(
      await _refus(
        travaux.publierTp(
          _tazi,
          seanceId: 'demo-1',
          titre: 'TP',
          consigne: 'Consigne',
          echeance: _echeance,
        ),
      ),
      ['Vous n’êtes pas affecté à ce groupe pour ce module.'],
    );
    // Séance d'un autre pôle, animée par un autre formateur.
    expect(
      await _refus(
        travaux.ajouterSupport(
          _amrani,
          seanceId: 'demo-9',
          titre: 'Cours',
          fichier: fichierTexte('c.pdf', 'c'),
        ),
      ),
      ['Vous n’êtes pas affecté à ce groupe pour ce module.'],
    );
  });

  test('champs du TP et du support vérifiés', () async {
    expect(
      await _refus(
        travaux.publierTp(
          _amrani,
          seanceId: 'demo-1',
          titre: ' ',
          consigne: '',
          echeance: DateTime(2026, 11, 25, 7),
        ),
      ),
      [
        'Indiquez un titre.',
        'Rédigez la consigne.',
        'L’échéance doit être à venir.',
      ],
    );
    expect(
      await _refus(
        travaux.ajouterSupport(
          _amrani,
          seanceId: 'demo-1',
          titre: '',
          fichier: null,
        ),
      ),
      ['Indiquez un titre.', 'Choisissez un fichier.'],
    );
    expect(
      verifierFichier(
        FichierChoisi(
          nom: 'video.mp4',
          octets: utf8.encode(''),
          taille: tailleMaxFichier + 1,
        ),
      ).single.message,
      'Ce fichier dépasse 20 Mo. Choisissez un fichier plus léger.',
    );
  });

  test('si l’enregistrement échoue, aucun TP n’apparaît et le fichier est '
      'retiré', () async {
    stockageTravaux.panne = true;
    await expectLater(
      publierTp(piece: fichierTexte('enonce.txt', 'x')),
      throwsA(isA<EnregistrementImpossible>()),
    );
    expect(coffre.contenus, isEmpty);
    stockageTravaux.panne = false;
    expect(await travaux.travauxStagiaire(_ines), isEmpty);
  });

  test('réinitialiser efface TP, supports, rendus et fichiers', () async {
    final tp = await publierTp(piece: fichierTexte('e.txt', 'e'));
    await travaux.deposer(_ines, tp.id, fichierTexte('r.txt', 'r'));
    await travaux.reinitialiser();
    expect(await travaux.travauxStagiaire(_ines), isEmpty);
    expect(coffre.contenus, isEmpty);
  });

  test('sur le téléphone, les fichiers sont écrits puis relus du dossier '
      'privé de l’application', () async {
    final coffreReel = CoffreAppareil(sousDossier: 'test-pieces');
    final piece = await coffreReel.ranger(
      'essai',
      fichierTexte('réponse finale.txt', 'Bonjour'),
    );
    expect(File(piece.chemin).existsSync(), isTrue);
    expect(piece.chemin, isNot(contains(' ')));
    expect(utf8.decode(await coffreReel.lire(piece)), 'Bonjour');
    await coffreReel.vider();
    expect(File(piece.chemin).existsSync(), isFalse);
  }, skip: !Platform.isAndroid && !Platform.isIOS);
}
