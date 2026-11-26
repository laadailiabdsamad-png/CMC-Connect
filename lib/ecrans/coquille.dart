import 'package:material_ui/material_ui.dart';

import '../etat/espace_chef.dart';
import '../etat/session.dart';
import '../modeles/compte.dart';
import '../theme/cmc_theme.dart';
import '../widgets/surfaces.dart';
import 'accueil.dart';
import 'chef/planning_chef.dart';
import 'planning.dart';
import 'profil.dart';

/// Les onglets du compte actif : Accueil, Planning et Profil pour un
/// stagiaire ; Planning et Profil pour un chef de pôle.
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

  @override
  Widget build(BuildContext context) {
    final espace = _espace;
    final session = widget.session;
    final (pages, destinations) = espace == null
        ? (
            [
              Accueil(session: session, ouvrirPlanning: () => _ouvrir(1)),
              Planning(session: session),
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
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profil',
              ),
            ],
          )
        : (
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
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profil',
              ),
            ],
          );
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
