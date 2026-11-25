import 'package:material_ui/material_ui.dart';

import 'app.dart';
import 'donnees/planning_fictif.dart';
import 'donnees/preferences_locales.dart';
import 'etat/session.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final session = Session(
    // Pour brancher l'API PHP, remplacer uniquement cette source.
    planning: PlanningFictif(),
    preferences: PreferencesAppareil(),
  );
  await session.demarrer();
  runApp(CmcConnect(session: session));
}
