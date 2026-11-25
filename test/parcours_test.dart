import 'dart:ui' show GestureSettings;

import 'package:cmc_connect/app.dart';
import 'package:cmc_connect/donnees/planning_fictif.dart';
import 'package:cmc_connect/donnees/preferences_locales.dart';
import 'package:cmc_connect/etat/session.dart';
import 'package:cmc_connect/modeles/apparence.dart';
import 'package:cmc_connect/widgets/apercu.dart';
import 'package:cmc_connect/widgets/carte_seance.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

// Mercredi 25 novembre 2026, 8 h : la prochaine séance a lieu aujourd'hui.
DateTime _horloge() => DateTime(2026, 11, 25, 8);

/// Équivaut à fermer puis rouvrir l'application : nouvelle session, nouvel
/// arbre de widgets, mêmes réglages enregistrés.
Future<Session> _ouvrir(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  final session = Session(
    planning: PlanningFictif(horloge: _horloge),
    preferences: PreferencesAppareil(),
    horloge: _horloge,
  );
  await session.demarrer();
  await tester.pumpWidget(CmcConnect(session: session));
  await tester.pumpAndSettle();
  return session;
}

/// Fait défiler la liste affichée jusqu'à la cible, comme un doigt.
Future<void> _amener(WidgetTester tester, Finder cible) async {
  for (var i = 0; i < 30 && cible.evaluate().isEmpty; i++) {
    await tester.drag(
      find.byType(ListView).hitTestable().last,
      const Offset(0, -120),
    );
    await tester.pumpAndSettle();
  }
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
}

Future<void> _toucher(WidgetTester tester, Finder cible) async {
  await _amener(tester, cible);
  await tester.tap(cible);
  await tester.pumpAndSettle();
}

Finder _onglet(String nom) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(nom));

ThemeData _themeActif(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(Scaffold).last));

void _ecran(WidgetTester tester, Size taille, {double texte = 1}) {
  tester.view.physicalSize = taille;
  tester.view.devicePixelRatio = 1;
  // Sur un vrai téléphone, ces marges seraient en pixels de son propre écran.
  tester.view.padding = FakeViewPadding.zero;
  tester.view.viewPadding = FakeViewPadding.zero;
  tester.view.systemGestureInsets = FakeViewPadding.zero;
  tester.view.gestureSettings = const GestureSettings(physicalTouchSlop: 18);
  tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
  tester.platformDispatcher.textScaleFactorTestValue = texte;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);
}

void main() {
  setUp(
    () => SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty(),
  );

  testWidgets('la démonstration complète', (tester) async {
    _ecran(tester, const Size(384, 832)); // proche du S23+
    await _ouvrir(tester);

    // 1. Deux profils.
    expect(find.text('Groupe DEV 201'), findsOneWidget);
    expect(find.text('Groupe GE 102'), findsOneWidget);
    await _toucher(tester, find.text('Inès'));

    // 2. Accueil.
    expect(find.text('Inès · Groupe DEV 201'), findsOneWidget);
    final carteAccueil = find.byKey(const ValueKey('accueil-stagiaire-ines-0'));
    for (final texte in [
      '10 h 00 · Salle B08',
      'Formateur : M. Amrani',
      'Salle modifiée · B12 → B08',
      'Aujourd’hui, 25 novembre',
    ]) {
      expect(
        find.descendant(of: carteAccueil, matching: find.text(texte)),
        findsOneWidget,
        reason: texte,
      );
    }

    // 3. Même objet séance dans le planning.
    final vueAccueil = tester.widget<CarteSeance>(carteAccueil).seance;
    await _toucher(tester, _onglet('Planning'));
    final cartePlanning = find.byKey(
      const ValueKey('planning-stagiaire-ines-0'),
    );
    expect(tester.widget<CarteSeance>(cartePlanning).seance, same(vueAccueil));

    // 4. Aperçu avant application.
    await _toucher(tester, _onglet('Profil'));
    await _toucher(tester, find.text('Apparence'));
    await _toucher(tester, find.text('Liquid Glass'));
    await _toucher(tester, find.text('Sombre'));
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
    expect(_themeActif(tester).brightness, Brightness.light);
    await _toucher(tester, find.text('Appliquer'));
    expect(_themeActif(tester).brightness, Brightness.dark);
    expect(find.text('Apparence appliquée au compte Inès.'), findsOneWidget);

    // 5. Réouverture, puis second compte.
    var session = await _ouvrir(tester);
    expect(find.text('Inès · Groupe DEV 201'), findsOneWidget);
    expect(_themeActif(tester).brightness, Brightness.dark);
    expect(find.byType(BackdropFilter), findsWidgets);

    await _toucher(tester, _onglet('Profil'));
    await _toucher(tester, find.text('Changer de compte'));
    await _toucher(tester, find.text('Yassine'));
    expect(find.text('Yassine · Groupe GE 102'), findsOneWidget);
    expect(find.textContaining('Salle modifiée'), findsNothing);
    expect(_themeActif(tester).brightness, Brightness.light);
    expect(find.byType(BackdropFilter), findsNothing);

    session = await _ouvrir(tester);
    expect(session.actif?.prenom, 'Yassine');
    expect(session.apparence, const Apparence());
  });

  testWidgets('revenir sans appliquer ne change rien', (tester) async {
    _ecran(tester, const Size(384, 832));
    final session = await _ouvrir(tester);
    await _toucher(tester, find.text('Inès'));
    await _toucher(tester, _onglet('Profil'));
    await _toucher(tester, find.text('Apparence'));
    await _toucher(tester, find.text('Sombre'));
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(session.apparence, const Apparence());
    expect(_themeActif(tester).brightness, Brightness.light);
  });

  testWidgets('Système suit le téléphone', (tester) async {
    _ecran(tester, const Size(384, 832));
    await _ouvrir(tester);
    await _toucher(tester, find.text('Inès'));
    expect(_themeActif(tester).brightness, Brightness.light);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pumpAndSettle();
    expect(_themeActif(tester).brightness, Brightness.dark);
  });

  for (final echelle in [1.0, 2.0]) {
    for (final style in StyleApp.values) {
      for (final luminosite in [Luminosite.clair, Luminosite.sombre]) {
        testWidgets('petit écran 320 × 568, texte × $echelle, '
            '${style.libelle} ${luminosite.libelle}', (tester) async {
          _ecran(tester, const Size(320, 568), texte: echelle);
          // Un débordement ou un contraste trop faible fait échouer le test.
          Future<void> verifier() async {
            // Sur les halos bicolores, cet outil compare le fond à lui-même :
            // le contraste de Liquid Glass est calculé dans theme_test.dart.
            if (style == StyleApp.simple) {
              await expectLater(tester, meetsGuideline(textContrastGuideline));
            }
            await expectLater(
              tester,
              meetsGuideline(androidTapTargetGuideline),
            );
          }

          final semantique = tester.ensureSemantics();
          final session = await _ouvrir(tester);
          await verifier();
          await _toucher(tester, find.text('Inès'));
          await session.appliquer(
            Apparence(style: style, luminosite: luminosite),
          );
          await tester.pumpAndSettle();
          await verifier();

          // L'heure, la salle et le changement restent entiers à l'écran.
          final carte = find.byType(CarteSeance).first;
          final zone = tester.getRect(carte);
          for (final texte in [
            '10 h 00 · Salle B08',
            'Salle modifiée · B12 → B08',
          ]) {
            final t = find.descendant(of: carte, matching: find.text(texte));
            final r = tester.getRect(t);
            expect(zone.left <= r.left && r.right <= zone.right, isTrue);
          }

          await _toucher(tester, _onglet('Planning'));
          await verifier();
          await _toucher(tester, _onglet('Profil'));
          await verifier();
          await _toucher(tester, find.text('Apparence'));
          await verifier();
          await _amener(
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
