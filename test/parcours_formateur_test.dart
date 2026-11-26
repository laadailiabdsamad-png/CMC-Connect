import 'dart:convert';

import 'package:cmc_connect/modeles/apparence.dart';
import 'package:cmc_connect/widgets/carte_seance.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'outils.dart';

Finder _dansSeance(String id, String texte) =>
    find.descendant(of: find.byKey(ValueKey(id)), matching: find.text(texte));

/// Le chef déplace la séance de 10 h d'Inès de B12 à B08 et publie.
Future<void> _chefPublieB08(WidgetTester tester) async {
  await toucher(tester, find.text('Chef du pôle Digital'));
  await toucher(tester, find.byKey(const ValueKey('chef-demo-1')));
  await toucher(
    tester,
    find.widgetWithText(DropdownButtonFormField<String>, 'Salle'),
  );
  await tester.tap(find.text('Salle B08').last);
  await tester.pumpAndSettle();
  await toucher(tester, find.text('Publier'));
  expect(
    find.text('Séance publiée pour le groupe DEV 201 et M. Amrani.'),
    findsOneWidget,
  );
}

/// M. Amrani ouvre sa séance de 10 h et publie un TP avec un énoncé joint.
Future<void> _amraniPublieTp(WidgetTester tester) async {
  await toucher(tester, find.byKey(const ValueKey('prochaine-demo-1')));
  await toucher(tester, find.text('Créer un TP'));
  expect(find.text('Groupe DEV 201'), findsOneWidget);
  expect(find.text('Développement mobile'), findsOneWidget);
  await tester.enterText(
    find.widgetWithText(TextField, 'Titre'),
    'Exercice Flutter',
  );
  await tester.enterText(
    find.widgetWithText(TextField, 'Consigne'),
    'Créer un écran de connexion avec validation du formulaire.',
  );
  // Comme l'utilisateur : le clavier se ferme avant de joindre le fichier.
  FocusManager.instance.primaryFocus?.unfocus();
  await tester.pumpAndSettle();
  fichiersTest.aChoisir.add(fichierTexte('enonce.txt', 'Énoncé détaillé'));
  await toucher(tester, find.text('Joindre un fichier'));
  expect(find.text('enonce.txt'), findsOneWidget);
  await toucher(tester, find.text('Publier le TP'));
}

void main() {
  setUp(preferencesVides);

  testWidgets('chef → formateur → Inès → formateur, et isolation de '
      'Yassine', (tester) async {
    ecran(tester, const Size(384, 832));
    await ouvrirApp(tester);

    // 1. Le chef publie le changement de salle.
    await _chefPublieB08(tester);

    // 2. M. Amrani voit B08 dans sa prochaine séance et dans sa semaine.
    await changerDeCompte(tester, 'M. Amrani');
    expect(find.text('Mon planning'), findsOneWidget);
    expect(
      _dansSeance('prochaine-demo-1', '10${nb}h${nb}00 · Salle${nb}B08'),
      findsOneWidget,
    );
    expect(_dansSeance('prochaine-demo-1', 'Groupe DEV 201'), findsOneWidget);
    expect(
      _dansSeance('prochaine-demo-1', 'Salle modifiée · B12 → B08'),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('formateur-demo-1')), findsOneWidget);

    // 3. Fiche de la séance, puis TP prérempli.
    await toucher(tester, find.byKey(const ValueKey('prochaine-demo-1')));
    expect(find.text('Groupe DEV 201'), findsOneWidget);
    expect(find.text('Mercredi 25${nb}novembre'), findsOneWidget);
    expect(find.text('10${nb}h${nb}00$nb– 12${nb}h${nb}00'), findsOneWidget);
    expect(find.text('Salle B08'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    await _amraniPublieTp(tester);
    expect(
      find.text(
        'TP publié pour le groupe DEV 201, à rendre le mercredi '
        '2${nb}décembre à 18${nb}h.',
      ),
      findsOneWidget,
    );
    expect(find.text('Exercice Flutter'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    // 4. Inès retrouve le TP, ouvre la consigne et l'énoncé, puis rend.
    await changerDeCompte(tester, 'Inès');
    expect(find.text('TP À RENDRE'), findsOneWidget);
    await toucher(tester, onglet('Modules'));
    expect(find.text('Exercice Flutter'), findsOneWidget);
    expect(
      find.text('À rendre avant le mercredi 2${nb}décembre à 18${nb}h'),
      findsOneWidget,
    );
    await toucher(tester, find.text('Exercice Flutter'));
    expect(
      find.text('Créer un écran de connexion avec validation du formulaire.'),
      findsOneWidget,
    );
    await toucher(tester, find.text('Énoncé joint'));
    expect(fichiersTest.ouverts.last.nom, 'enonce.txt');
    expect(
      utf8.decode(await coffreTest.lire(fichiersTest.ouverts.last)),
      'Énoncé détaillé',
    );
    expect(find.text('Vous n’avez pas encore rendu ce TP.'), findsOneWidget);
    fichiersTest.aChoisir.add(
      fichierTexte('reponse_ines.txt', 'Réponse d’Inès'),
    );
    await toucher(tester, find.text('Déposer mon fichier'));
    expect(find.text('Rendu déposé : reponse_ines.txt.'), findsOneWidget);
    expect(
      find.text('Rendu le mercredi 25${nb}novembre à 8${nb}h'),
      findsOneWidget,
    );
    expect(find.text('Remplacer mon fichier'), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    // 5. Yassine, autre groupe : ni TP ni rendu.
    await changerDeCompte(tester, 'Yassine');
    expect(find.text('TP À RENDRE'), findsNothing);
    await toucher(tester, onglet('Modules'));
    expect(find.text('Aucun TP pour votre groupe.'), findsOneWidget);
    expect(find.text('Exercice Flutter'), findsNothing);

    // 6. Réouverture de l'application, puis M. Amrani ouvre le rendu.
    await changerDeCompte(tester, 'M. Amrani');
    await ouvrirApp(tester);
    expect(find.text('Mon planning'), findsOneWidget);
    await toucher(tester, onglet('TP'));
    expect(find.text('1 rendu'), findsOneWidget);
    await toucher(tester, find.text('Exercice Flutter'));
    expect(find.text('Rendus (1)'), findsOneWidget);
    expect(find.text('Inès'), findsOneWidget);
    expect(
      find.textContaining('Déposé le mercredi 25${nb}novembre à 8${nb}h'),
      findsOneWidget,
    );
    await toucher(tester, find.text('Inès'));
    final ouvert = fichiersTest.ouverts.last;
    expect(ouvert.nom, 'reponse_ines.txt');
    expect(utf8.decode(await coffreTest.lire(ouvert)), 'Réponse d’Inès');
  });

  testWidgets('support de cours : M. Amrani l’ajoute, Inès l’ouvre', (
    tester,
  ) async {
    ecran(tester, const Size(384, 832));
    await ouvrirApp(tester);
    await toucher(tester, find.text('M. Amrani'));
    await toucher(tester, find.byKey(const ValueKey('prochaine-demo-1')));
    await toucher(tester, find.text('Ajouter un support'));
    fichiersTest.aChoisir.add(fichierTexte('cours_navigation.pdf', 'PDF'));
    await toucher(tester, find.text('Choisir le fichier'));
    // Le titre reprend le nom du fichier, modifiable.
    expect(
      tester
          .widget<TextField>(find.widgetWithText(TextField, 'Titre'))
          .controller
          ?.text,
      'cours_navigation',
    );
    await toucher(tester, find.text('Ajouter le support'));
    expect(find.text('Support ajouté pour le groupe DEV 201.'), findsOneWidget);
    expect(find.text('cours_navigation'), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await changerDeCompte(tester, 'Inès');
    await toucher(tester, onglet('Modules'));
    await toucher(tester, find.text('cours_navigation'));
    expect(fichiersTest.ouverts.last.nom, 'cours_navigation.pdf');
  });

  testWidgets('TP incomplet : chaque champ manquant est signalé', (
    tester,
  ) async {
    ecran(tester, const Size(384, 832));
    await ouvrirApp(tester);
    await toucher(tester, find.text('M. Amrani'));
    await toucher(tester, find.byKey(const ValueKey('prochaine-demo-1')));
    await toucher(tester, find.text('Créer un TP'));
    await toucher(tester, find.text('Publier le TP'));
    expect(find.text('Indiquez un titre.'), findsOneWidget);
    expect(find.text('Rédigez la consigne.'), findsOneWidget);
    expect(find.text('Nouveau TP'), findsOneWidget);
  });

  testWidgets('M. Amrani voit ses séances dans ses deux groupes', (
    tester,
  ) async {
    ecran(tester, const Size(384, 832));
    await ouvrirApp(tester);
    await toucher(tester, find.text('M. Amrani'));
    expect(find.byType(CarteSeance), findsWidgets);
    // Ses trois séances de départ : DEV 201 (deux) et DEV 101 jeudi.
    await amener(tester, find.byKey(const ValueKey('formateur-demo-6')));
    expect(_dansSeance('formateur-demo-6', 'Groupe DEV 101'), findsOneWidget);
    expect(find.byKey(const ValueKey('formateur-demo-3')), findsOneWidget);
  });

  for (final (echelle, style, luminosite) in [
    (1.0, StyleApp.simple, Luminosite.clair),
    (1.0, StyleApp.liquidGlass, Luminosite.sombre),
    (2.0, StyleApp.simple, Luminosite.sombre),
    (2.0, StyleApp.liquidGlass, Luminosite.clair),
  ]) {
    testWidgets('formateur et modules, petit écran 320 × 568, texte × '
        '$echelle, ${style.libelle} ${luminosite.libelle}', (tester) async {
      ecran(tester, const Size(320, 568), texte: echelle);
      Future<void> verifier() =>
          verifierAccessibilite(tester, contraste: style == StyleApp.simple);
      final semantique = tester.ensureSemantics();
      final session = await ouvrirApp(tester);
      await toucher(tester, find.text('M. Amrani'));
      await session.appliquer(Apparence(style: style, luminosite: luminosite));
      await tester.pumpAndSettle();
      await verifier();

      await _amraniPublieTp(tester);
      await fermerNotification(tester);
      await verifier();
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      await toucher(tester, onglet('TP'));
      await verifier();

      await changerDeCompte(tester, 'Inès');
      await session.appliquer(Apparence(style: style, luminosite: luminosite));
      await tester.pumpAndSettle();
      await toucher(tester, onglet('Modules'));
      await verifier();
      await toucher(tester, find.text('Exercice Flutter'));
      await verifier();
      expect(tester.takeException(), isNull);
      semantique.dispose();
    });
  }
}
