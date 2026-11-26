import 'package:cmc_connect/modeles/apparence.dart';
import 'package:cmc_connect/widgets/carte_seance.dart';
import 'package:cmc_connect/widgets/carte_seance_chef.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'outils.dart';

Finder _liste(String label) =>
    find.widgetWithText(DropdownButtonFormField<String>, label);

Future<void> _choisirDansListe(
  WidgetTester tester,
  String label,
  String valeur,
) async {
  await toucher(tester, _liste(label));
  await tester.tap(find.text(valeur).last);
  await tester.pumpAndSettle();
}

Future<void> _saisirHeure(
  WidgetTester tester,
  String champ,
  int heure,
  int minute,
) async {
  await amener(tester, find.text(champ));
  await tester.tap(
    find.ancestor(of: find.text(champ), matching: find.byType(InkWell)).first,
  );
  await tester.pumpAndSettle();
  final saisies = find.descendant(
    of: find.byType(Dialog),
    matching: find.byType(TextField),
  );
  await tester.enterText(saisies.at(0), '$heure');
  await tester.enterText(saisies.at(1), minute.toString().padLeft(2, '0'));
  await tester.tap(find.text('Valider'));
  await tester.pumpAndSettle();
}

Finder _carteChef(String id) => find.byKey(ValueKey('chef-$id'));

String _etat(WidgetTester tester, String id) =>
    PastilleEtat.libelle(tester.widget<CarteSeanceChef>(_carteChef(id)).seance);

void main() {
  setUp(preferencesVides);

  testWidgets('critères 1 à 4 et 6 : B12 → B08, du brouillon à la '
      'publication', (tester) async {
    ecran(tester, const Size(384, 832));
    await ouvrirApp(tester);

    // 1. Inès voit la séance publiée en B12.
    await toucher(tester, find.text('Inès'));
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('accueil-demo-1')),
        matching: find.text('10${nb}h${nb}00 · Salle${nb}B12'),
      ),
      findsOneWidget,
    );
    await toucher(tester, onglet('Planning'));
    final yassineAvant = <String>[];
    await changerDeCompte(tester, 'Yassine');
    await toucher(tester, onglet('Planning'));
    for (final carte in tester.widgetList<CarteSeance>(
      find.byType(CarteSeance),
    )) {
      final s = carte.seance;
      yassineAvant.add('${s.id} ${s.salle} ${s.debut} ${s.fin}');
    }
    expect(yassineAvant, isNotEmpty);

    // Le chef arrive directement sur son planning de la semaine.
    await changerDeCompte(tester, 'Chef du pôle Digital');
    expect(find.text('Planning de la semaine'), findsOneWidget);
    expect(
      find.text('Pôle Digital et Intelligence Artificielle'),
      findsOneWidget,
    );
    expect(find.text('Groupe DEV 201'), findsOneWidget);
    expect(find.text('Semaine du 23 au 28${nb}novembre'), findsOneWidget);
    expect(find.text('Mercredi 25${nb}novembre'), findsOneWidget);
    expect(_etat(tester, 'demo-1'), 'Publiée');

    // 2. Il prépare B08 et enregistre le brouillon.
    await toucher(tester, _carteChef('demo-1'));
    expect(find.text('Modifier la séance'), findsOneWidget);
    await _choisirDansListe(tester, 'Salle', 'Salle B08');
    await toucher(tester, find.text('Enregistrer le brouillon'));
    expect(
      find.text(
        'Brouillon enregistré. Le groupe voit toujours la version publiée.',
      ),
      findsOneWidget,
    );
    // Groupe, semaine et jour sont conservés au retour.
    expect(find.text('Groupe DEV 201'), findsOneWidget);
    expect(find.text('Mercredi 25${nb}novembre'), findsOneWidget);
    expect(_etat(tester, 'demo-1'), 'B12 → B08 · Modification en attente');

    await changerDeCompte(tester, 'Inès');
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('accueil-demo-1')),
        matching: find.text('10${nb}h${nb}00 · Salle${nb}B12'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('B08'), findsNothing);

    // 3. Le chef rouvre le brouillon et publie.
    await changerDeCompte(tester, 'Chef du pôle Digital');
    await toucher(tester, _carteChef('demo-1'));
    expect(find.textContaining('Le groupe voit encore'), findsOneWidget);
    await toucher(tester, find.text('Publier'));
    expect(
      find.text('Séance publiée pour le groupe DEV 201 et M. Amrani.'),
      findsOneWidget,
    );
    expect(_etat(tester, 'demo-1'), 'Publiée');

    await changerDeCompte(tester, 'Inès');
    final accueil = find.byKey(const ValueKey('accueil-demo-1'));
    expect(
      find.descendant(
        of: accueil,
        matching: find.text('10${nb}h${nb}00 · Salle${nb}B08'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: accueil,
        matching: find.text('Salle modifiée · B12 → B08'),
      ),
      findsOneWidget,
    );
    final vueAccueil = tester.widget<CarteSeance>(accueil).seance;
    await toucher(tester, onglet('Planning'));
    expect(find.byKey(const ValueKey('planning-demo-1')), findsOneWidget);
    final cartes = tester
        .widgetList<CarteSeance>(find.byType(CarteSeance))
        .where((c) => c.seance.id == 'demo-1');
    expect(cartes, hasLength(1));
    expect(cartes.single.seance.salle, vueAccueil.salle);

    // 4. Le planning de Yassine n'a pas changé.
    await changerDeCompte(tester, 'Yassine');
    await toucher(tester, onglet('Planning'));
    expect([
      for (final c in tester.widgetList<CarteSeance>(find.byType(CarteSeance)))
        '${c.seance.id} ${c.seance.salle} ${c.seance.debut} ${c.seance.fin}',
    ], yassineAvant);

    // 6. Redémarrage : publication et thèmes de chaque compte restaurés.
    await changerDeCompte(tester, 'Chef du pôle Digital');
    final session = await ouvrirApp(tester);
    await session.appliquer(
      const Apparence(
        style: StyleApp.liquidGlass,
        luminosite: Luminosite.sombre,
      ),
    );
    await ouvrirApp(tester);
    expect(find.text('Planning de la semaine'), findsOneWidget);
    expect(themeActif(tester).brightness, Brightness.dark);
    expect(_etat(tester, 'demo-1'), 'Publiée');
    await changerDeCompte(tester, 'Inès');
    expect(themeActif(tester).brightness, Brightness.light);
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('accueil-demo-1')),
        matching: find.text('10${nb}h${nb}00 · Salle${nb}B08'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('critère 5 : B08 occupée, refus précis, brouillon modifiable', (
    tester,
  ) async {
    ecran(tester, const Size(384, 832));
    await ouvrirApp(tester);
    await toucher(tester, find.text('Chef du pôle Digital'));

    // Jeudi 26 : Programmation Dart de 8 h 30 à 10 h 30.
    await toucher(tester, find.text('26'));
    expect(find.text('Jeudi 26${nb}novembre'), findsOneWidget);
    await toucher(tester, find.text('Ajouter une séance'));
    expect(find.text('Nouvelle séance'), findsOneWidget);

    // Publier sans rien remplir : chaque champ manquant est signalé.
    await toucher(tester, find.text('Publier'));
    expect(find.text('À corriger'), findsOneWidget);
    expect(find.text('Choisissez un module.'), findsWidgets);

    await _choisirDansListe(tester, 'Module', 'Développement mobile');
    await _choisirDansListe(tester, 'Formateur', 'Mme Tazi');
    await _choisirDansListe(tester, 'Salle', 'Salle B08');
    await _saisirHeure(tester, 'Heure de début', 10, 30);
    await _saisirHeure(tester, 'Heure de fin', 12, 30);
    await toucher(tester, find.text('Publier'));

    const message =
        'Salle B08 déjà réservée de 11${nb}h à 13${nb}h (groupe GE 102).';
    expect(find.text('Publication impossible'), findsOneWidget);
    // Dans l'encadré et sous le champ Salle.
    expect(find.text(message), findsNWidgets(2));
    expect(find.textContaining('Le brouillon est enregistré'), findsOneWidget);

    // Un seul champ à corriger, puis nouvelle publication.
    await _choisirDansListe(tester, 'Salle', 'Salle B05');
    await toucher(tester, find.text('Publier'));
    expect(
      find.text('Séance publiée pour le groupe DEV 201 et Mme Tazi.'),
      findsOneWidget,
    );
    expect(find.text('Jeudi 26${nb}novembre'), findsOneWidget);
    expect(find.text('Salle B05'), findsOneWidget);
  });

  testWidgets('un refus laisse le brouillon dans le planning', (tester) async {
    ecran(tester, const Size(384, 832));
    await ouvrirApp(tester);
    await toucher(tester, find.text('Chef du pôle Digital'));
    await toucher(tester, find.text('26'));
    await toucher(tester, find.text('Ajouter une séance'));
    await _choisirDansListe(tester, 'Module', 'Gestion de projet');
    await _choisirDansListe(tester, 'Formateur', 'Mme Tazi');
    await _choisirDansListe(tester, 'Salle', 'Salle B08');
    await _saisirHeure(tester, 'Heure de début', 11, 0);
    await _saisirHeure(tester, 'Heure de fin', 12, 0);
    await toucher(tester, find.text('Publier'));
    expect(find.text('Publication impossible'), findsOneWidget);

    // Rien n'est à perdre : le retour ne demande pas de confirmation.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Brouillon · non visible par le groupe'), findsOneWidget);
    expect(find.text('Jeudi 26${nb}novembre'), findsOneWidget);
  });

  testWidgets('une journée vide propose de créer la première séance', (
    tester,
  ) async {
    ecran(tester, const Size(384, 832));
    await ouvrirApp(tester);
    await toucher(tester, find.text('Chef du pôle Digital'));
    await toucher(tester, find.text('28'));
    expect(find.text('Aucune séance prévue'), findsOneWidget);
    await toucher(tester, find.text('Créer la première séance'));
    expect(find.text('Samedi 28${nb}novembre'), findsOneWidget);

    // Quitter après une saisie demande confirmation.
    await _choisirDansListe(tester, 'Module', 'Bases de données');
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(find.text('Quitter sans enregistrer ?'), findsOneWidget);
    await tester.tap(find.text('Quitter'));
    await tester.pumpAndSettle();
    expect(find.text('Aucune séance prévue'), findsOneWidget);
  });

  testWidgets('changer de groupe et de semaine, puis Aujourd’hui', (
    tester,
  ) async {
    ecran(tester, const Size(384, 832));
    await ouvrirApp(tester);
    await toucher(tester, find.text('Chef du pôle Digital'));
    await toucher(tester, find.text('Groupe DEV 201'));
    await tester.tap(find.text('Groupe DEV 101'));
    await tester.pumpAndSettle();
    expect(find.text('Groupe DEV 101'), findsOneWidget);
    expect(find.text('Bases de données'), findsOneWidget);

    await tester.tap(find.byTooltip('Semaine suivante'));
    await tester.pumpAndSettle();
    expect(
      find.text('Semaine du 30${nb}novembre au 5${nb}décembre'),
      findsOneWidget,
    );
    await toucher(tester, find.text('Aujourd’hui'));
    expect(find.text('Mercredi 25${nb}novembre'), findsOneWidget);
    expect(find.text('Groupe DEV 101'), findsOneWidget);
  });

  testWidgets('le jour choisi reste visible dans la bande des jours', (
    tester,
  ) async {
    // Texte doublé sur 320 px : la bande dépasse largement l'écran.
    ecran(tester, const Size(320, 568), texte: 2);
    await ouvrirApp(tester);
    await toucher(tester, find.text('Chef du pôle Digital'));
    await toucher(tester, find.text('28'));
    await toucher(tester, find.text('Aujourd’hui'));
    final mercredi = tester.getRect(find.text('25'));
    expect(mercredi.left, greaterThanOrEqualTo(0));
    expect(mercredi.right, lessThanOrEqualTo(320));
  });

  for (final echelle in [1.0, 2.0]) {
    for (final style in StyleApp.values) {
      for (final luminosite in [Luminosite.clair, Luminosite.sombre]) {
        testWidgets('chef, petit écran 320 × 568, texte × $echelle, '
            '${style.libelle} ${luminosite.libelle}', (tester) async {
          ecran(tester, const Size(320, 568), texte: echelle);
          Future<void> verifier() => verifierAccessibilite(
            tester,
            contraste: style == StyleApp.simple,
          );
          final semantique = tester.ensureSemantics();
          final session = await ouvrirApp(tester);
          await toucher(tester, find.text('Chef du pôle Digital'));
          await session.appliquer(
            Apparence(style: style, luminosite: luminosite),
          );
          await tester.pumpAndSettle();
          await verifier();

          // Une modification en attente, puis la fiche correspondante.
          await toucher(tester, _carteChef('demo-1'));
          await _choisirDansListe(tester, 'Salle', 'Salle B08');
          await toucher(tester, find.text('Enregistrer le brouillon'));
          await fermerNotification(tester);
          await amener(
            tester,
            find.text('B12 → B08 · Modification en attente'),
          );
          await verifier();
          await toucher(tester, _carteChef('demo-1'));
          await verifier();
          await amener(tester, find.text('Heure de fin'));
          await verifier();
          await tester.tap(find.byType(BackButton));
          await tester.pumpAndSettle();

          await toucher(tester, find.text('28'));
          expect(find.text('Aucune séance prévue'), findsOneWidget);
          await verifier();
          expect(tester.takeException(), isNull);
          semantique.dispose();
        });
      }
    }
  }
}
