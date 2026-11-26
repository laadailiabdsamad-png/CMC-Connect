import 'dart:ui' show GestureSettings;

import 'package:cmc_connect/app.dart';
import 'package:cmc_connect/donnees/planning_fictif.dart';
import 'package:cmc_connect/donnees/preferences_locales.dart';
import 'package:cmc_connect/etat/session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

/// Espace insécable, comme dans les heures affichées (« 10 h 00 »).
const nb = ' ';

/// Mercredi 25 novembre 2026, 8 h. La démonstration démarre ce jour-là :
/// Inès a cours à 10 h, puis jeudi 26 et vendredi 27.
DateTime horlogeTest() => DateTime(2026, 11, 25, 8);

void preferencesVides() => SharedPreferencesAsyncPlatform.instance =
    InMemorySharedPreferencesAsync.empty();

/// Équivaut à fermer puis rouvrir l'application : nouvelle session, nouveau
/// repository, nouvel arbre de widgets, mêmes données enregistrées.
Future<Session> ouvrirApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  final session = Session(
    planning: PlanningFictif(horloge: horlogeTest),
    preferences: PreferencesAppareil(),
    horloge: horlogeTest,
  );
  await session.demarrer();
  await tester.pumpWidget(CmcConnect(session: session));
  await tester.pumpAndSettle();
  return session;
}

/// Fait défiler la liste verticale affichée jusqu'à ce que la cible soit
/// construite, en repartant du haut si elle n'est pas plus bas. Le défilement
/// au doigt est vérifié à part, sur le téléphone.
Future<void> amener(WidgetTester tester, Finder cible) async {
  final listes = find.byWidgetPredicate(
    (w) =>
        w is Scrollable &&
        axisDirectionToAxis(w.axisDirection) == Axis.vertical,
  );
  for (var i = 0; i < 60 && cible.evaluate().isEmpty; i++) {
    final p = tester.state<ScrollableState>(listes.last).position;
    if (i == 0 && p.pixels > p.minScrollExtent) {
      p.jumpTo(p.minScrollExtent);
    } else if (p.pixels >= p.maxScrollExtent) {
      break;
    } else {
      p.jumpTo(
        (p.pixels + p.viewportDimension * 0.6).clamp(0, p.maxScrollExtent),
      );
    }
    await tester.pump();
  }
  await tester.ensureVisible(cible);
  await tester.pumpAndSettle();
}

/// Retire la notification en bas d'écran, qui peut couvrir la liste sur un
/// petit écran avec du texte agrandi.
Future<void> fermerNotification(WidgetTester tester) async {
  tester
      .state<ScaffoldMessengerState>(find.byType(ScaffoldMessenger).first)
      .removeCurrentSnackBar();
  await tester.pumpAndSettle();
}

Future<void> toucher(WidgetTester tester, Finder cible) async {
  await amener(tester, cible);
  await tester.tap(cible);
  await tester.pumpAndSettle();
}

Finder onglet(String nom) =>
    find.descendant(of: find.byType(NavigationBar), matching: find.text(nom));

ThemeData themeActif(WidgetTester tester) =>
    Theme.of(tester.element(find.byType(Scaffold).last));

Future<void> changerDeCompte(WidgetTester tester, String nom) async {
  await toucher(tester, onglet('Profil'));
  await toucher(tester, find.text('Changer de compte'));
  await toucher(tester, find.text(nom));
}

void ecran(WidgetTester tester, Size taille, {double texte = 1}) {
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

/// Contraste et taille des zones tactiles. Sur les halos bicolores de
/// Liquid Glass, l'outil de contraste compare le fond à lui-même : ce
/// contraste-là est calculé dans theme_test.dart.
Future<void> verifierAccessibilite(
  WidgetTester tester, {
  required bool contraste,
}) async {
  if (contraste) {
    await expectLater(tester, meetsGuideline(textContrastGuideline));
  }
  await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
}
