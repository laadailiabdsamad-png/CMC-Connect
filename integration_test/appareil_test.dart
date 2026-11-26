import 'package:integration_test/integration_test.dart';

import '../test/donnees_test.dart' as donnees;
import '../test/parcours_chef_test.dart' as parcours_chef;
import '../test/parcours_formateur_test.dart' as parcours_formateur;
import '../test/parcours_test.dart' as parcours;
import '../test/planification_test.dart' as planification;
import '../test/theme_test.dart' as theme;
import '../test/travaux_test.dart' as travaux;

/// Les mêmes tests que dans test/, exécutés sur un vrai téléphone :
/// flutter test integration_test/appareil_test.dart
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  donnees.main();
  planification.main();
  travaux.main();
  theme.main();
  parcours.main();
  parcours_chef.main();
  parcours_formateur.main();
}
