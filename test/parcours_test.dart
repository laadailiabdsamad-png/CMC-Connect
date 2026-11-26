import 'package:cmc_connect/modeles/apparence.dart';
import 'package:cmc_connect/widgets/apercu.dart';
import 'package:cmc_connect/widgets/carte_seance.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import 'outils.dart';

void main() {
  setUp(preferencesVides);

  testWidgets('la démonstration complète', (tester) async {
    ecran(tester, const Size(384, 832)); // proche du S23+
    await ouvrirApp(tester);

    // 1. Trois comptes, dont deux stagiaires de groupes différents.
    expect(find.text('Groupe DEV 201'), findsOneWidget);
    expect(find.text('Groupe GE 102'), findsOneWidget);
    expect(find.text('Chef du pôle Digital'), findsOneWidget);
    await toucher(tester, find.text('Inès'));

    // 2. Accueil : la séance publiée en B12, sans changement de salle.
    expect(find.text('Inès · Groupe DEV 201'), findsOneWidget);
    final carteAccueil = find.byKey(const ValueKey('accueil-demo-1'));
    for (final texte in [
      '10${nb}h${nb}00 · Salle${nb}B12',
      'Formateur : M. Amrani',
      'Aujourd’hui, 25 novembre',
    ]) {
      expect(
        find.descendant(of: carteAccueil, matching: find.text(texte)),
        findsOneWidget,
        reason: texte,
      );
    }
    expect(find.textContaining('Salle modifiée'), findsNothing);

    // 3. Même objet séance dans le planning.
    final vueAccueil = tester.widget<CarteSeance>(carteAccueil).seance;
    await toucher(tester, onglet('Planning'));
    final cartePlanning = find.byKey(const ValueKey('planning-demo-1'));
    expect(tester.widget<CarteSeance>(cartePlanning).seance, same(vueAccueil));

    // 4. Aperçu avant application.
    await toucher(tester, onglet('Profil'));
    await toucher(tester, find.text('Apparence'));
    await toucher(tester, find.text('Liquid Glass'));
    await toucher(tester, find.text('Sombre'));
    expect(
      Theme.of(
        tester.element(
          find.descendant(
            of: find.byType(ApercuApparence),
            matching: find.byType(CarteSeance),
          ),
        ),
      ).brightness,
      Brightness.dark,
    );
    expect(themeActif(tester).brightness, Brightness.light);
    await toucher(tester, find.text('Appliquer'));
    expect(themeActif(tester).brightness, Brightness.dark);
    expect(find.text('Apparence appliquée au compte Inès.'), findsOneWidget);

    // 5. Réouverture, puis second compte.
    var session = await ouvrirApp(tester);
    expect(find.text('Inès · Groupe DEV 201'), findsOneWidget);
    expect(themeActif(tester).brightness, Brightness.dark);
    expect(find.byType(BackdropFilter), findsWidgets);

    await changerDeCompte(tester, 'Yassine');
    expect(find.text('Yassine · Groupe GE 102'), findsOneWidget);
    expect(themeActif(tester).brightness, Brightness.light);
    expect(find.byType(BackdropFilter), findsNothing);

    session = await ouvrirApp(tester);
    expect(session.actif?.nom, 'Yassine');
    expect(session.apparence, const Apparence());
  });

  testWidgets('revenir sans appliquer ne change rien', (tester) async {
    ecran(tester, const Size(384, 832));
    final session = await ouvrirApp(tester);
    await toucher(tester, find.text('Inès'));
    await toucher(tester, onglet('Profil'));
    await toucher(tester, find.text('Apparence'));
    await toucher(tester, find.text('Sombre'));
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(session.apparence, const Apparence());
    expect(themeActif(tester).brightness, Brightness.light);
  });

  testWidgets('Système suit le téléphone', (tester) async {
    ecran(tester, const Size(384, 832));
    await ouvrirApp(tester);
    await toucher(tester, find.text('Inès'));
    expect(themeActif(tester).brightness, Brightness.light);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pumpAndSettle();
    expect(themeActif(tester).brightness, Brightness.dark);
  });

  for (final echelle in [1.0, 2.0]) {
    for (final style in StyleApp.values) {
      for (final luminosite in [Luminosite.clair, Luminosite.sombre]) {
        testWidgets('stagiaire, petit écran 320 × 568, texte × $echelle, '
            '${style.libelle} ${luminosite.libelle}', (tester) async {
          ecran(tester, const Size(320, 568), texte: echelle);
          Future<void> verifier() => verifierAccessibilite(
            tester,
            contraste: style == StyleApp.simple,
          );

          final semantique = tester.ensureSemantics();
          final session = await ouvrirApp(tester);
          await verifier();
          await toucher(tester, find.text('Inès'));
          await session.appliquer(
            Apparence(style: style, luminosite: luminosite),
          );
          await tester.pumpAndSettle();
          await verifier();

          // L'heure et la salle restent entières à l'écran.
          final carte = find.byType(CarteSeance).first;
          final zone = tester.getRect(carte);
          final t = find.descendant(
            of: carte,
            matching: find.text('10${nb}h${nb}00 · Salle${nb}B12'),
          );
          final r = tester.getRect(t);
          expect(zone.left <= r.left && r.right <= zone.right, isTrue);

          await toucher(tester, onglet('Planning'));
          await verifier();
          await toucher(tester, onglet('Profil'));
          await verifier();
          await toucher(tester, find.text('Apparence'));
          await verifier();
          await amener(
            tester,
            find.text('Système suit le réglage du téléphone.'),
          );
          await verifier();
          expect(tester.takeException(), isNull);
          semantique.dispose();
        });
      }
    }
  }
}
