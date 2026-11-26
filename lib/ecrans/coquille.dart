import 'package:material_ui/material_ui.dart';

import '../etat/espace_chef.dart';
import '../etat/session.dart';
import '../modeles/compte.dart';
import '../theme/cmc_theme.dart';
import '../widgets/surfaces.dart';
import 'accueil.dart';
import 'chef/planning_chef.dart';
import 'formateur/planning_formateur.dart';
import 'formateur/suivi_tp.dart';
import 'planning.dart';
import 'profil.dart';
import 'stagiaire/modules.dart';

const _profil = NavigationDestination(
  icon: Icon(Icons.person_outline),
  selectedIcon: Icon(Icons.person),
  label: 'Profil',
);

/// Les onglets du compte actif :
/// - stagiaire : Accueil, Planning, Modules, Profil ;
/// - formateur : Planning, TP, Profil ;
/// - chef de pôle : Planning, Profil.
class Coquille extends StatefulWidget {
  const Coquille({super.key, required this.session});

  final Session session;

  @override
  State<Coquille> createState() => _CoquilleState();
}

class _CoquilleState extends State<Coquille> {
  int _onglet = 0;
  EspaceChef? _espace;

  @override
  void initState() {
    super.initState();
    if (widget.session.actif case final ChefPole chef) {
      _espace = EspaceChef(
        planning: widget.session.planning,
        chef: chef,
        horloge: () => widget.session.maintenant,
      )..charger();
    }
  }

  @override
  void dispose() {
    _espace?.dispose();
    super.dispose();
  }

  void _ouvrir(int onglet) => setState(() => _onglet = onglet);

  (List<Widget>, List<NavigationDestination>) _onglets() {
    final session = widget.session;
    switch (session.actif!) {
      case Stagiaire():
        return (
          [
            Accueil(session: session, ouvrirPlanning: () => _ouvrir(1)),
            Planning(session: session),
            Modules(session: session),
            Profil(session: session),
          ],
          const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Accueil',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month),
              label: 'Planning',
            ),
            NavigationDestination(
              icon: Icon(Icons.school_outlined),
              selectedIcon: Icon(Icons.school),
              label: 'Modules',
            ),
            _profil,
          ],
        );
      case Formateur():
        return (
          [
            PlanningFormateur(session: session),
            MesTp(session: session),
            Profil(session: session),
          ],
          const [
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month),
              label: 'Planning',
            ),
            NavigationDestination(
              icon: Icon(Icons.assignment_outlined),
              selectedIcon: Icon(Icons.assignment),
              label: 'TP',
            ),
            _profil,
          ],
        );
      case ChefPole():
        final espace = _espace!;
        return (
          [
            PlanningChef(espace: espace),
            Profil(session: session, apresReinitialisation: espace.recharger),
          ],
          const [
            NavigationDestination(
              icon: Icon(Icons.edit_calendar_outlined),
              selectedIcon: Icon(Icons.edit_calendar),
              label: 'Planning',
            ),
            _profil,
          ],
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final (pages, destinations) = _onglets();
    return FondCmc(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        // Le contenu ne passe derrière la barre que si elle est en verre.
        extendBody: context.cmc.verre,
        body: IndexedStack(index: _onglet, children: pages),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: SurfaceCmc(
            verre: true,
            rayon: 26,
            child: NavigationBar(
              height: 72,
              selectedIndex: _onglet,
              onDestinationSelected: _ouvrir,
              destinations: destinations,
            ),
          ),
        ),
      ),
    );
  }
}
